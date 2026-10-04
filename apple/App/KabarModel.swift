import Foundation
import Security
import SwiftUI
import UserNotifications
import WidgetKit
import KabarCore

@MainActor final class KabarModel: ObservableObject {
    @Published var state = SharedStore.state()
    @Published var peerState = SharedStore.peerState()
    var isTwoWay: Bool {SharedStore.isTwoWay}
    var canSend: Bool {SharedStore.canSend}
    @Published var role = SharedStore.defaults.string(forKey: "role") ?? ""
    @Published var connection = "Belum terhubung"
    @Published var error: String?
    @Published var pending = 0
    @Published var locating = false
    @Published var locationNote = ""
    private var sampler: LocationSampler?
    @Published var pushEndpoint = SharedStore.defaults.string(forKey: "pushEndpoint") ?? ""
    private var sync: Task<Void, Never>?
    private var peerSync: Task<Void,Never>?
    private var registration: Task<Void, Never>?
    private var notificationRefresh: Task<Void,Never>?
    private var notificationGeneration = UUID()
    private var waiting: CheckedContinuation<Void,Never>?
    private var waitToken: UUID?
    private var idleWake: Task<Void,Never>?
    var code: String { SharedStore.pairing()?.code ?? "" }
    var queue: [String] { SharedStore.defaults.stringArray(forKey: "queue") ?? [] }
    var retiredQueue: [[String:String]] {SharedStore.defaults.array(forKey:"retiredQueue") as? [[String:String]] ?? []}
    var enabled: Bool { SharedStore.defaults.object(forKey: "enabled") as? Bool ?? true }
    init() {
        #if DEBUG
        if CommandLine.arguments.contains("-KabarQAClean") { SharedStore.reset(); role = ""; state = KabarState() }
        #endif
        pending = queue.count
    }
    func beginSender() {
        do {
            let pair = Pairing(); try install(pair, role: "sender"); state.revision = 1
            state.name = SharedStore.defaults.dictionary(forKey:"abcProfile")?["nickname"] as? String ?? "Aku"
            try enqueue(state, notify: false); start()
        } catch { self.error = error.localizedDescription }
    }
    func join(_ code: String) {
        do { try install(Pairing(code: code), role: "receiver"); start(); requestNotifications() } catch { self.error = error.localizedDescription }
    }
    private func install(_ pair: Pairing, role: String) throws {
        stop(); SharedStore.reset()
        self.role = ""; state = KabarState(); pending = 0
        do {
            try SharedStore.saveSecret(Data(pair.code.utf8), name: "code")
            if let key = pair.privateKey { try SharedStore.saveSecret(key.rawRepresentation, name: "private") }
        } catch { SharedStore.reset(); throw error }
        SharedStore.defaults.set(role, forKey: "role"); SharedStore.defaults.set(true, forKey: "enabled")
        self.role = role; state = KabarState(); try SharedStore.save(state); pending = 0; pushEndpoint = ""
        WidgetCenter.shared.reloadAllTimelines()
    }
    func enableSeirama(confirmed: Bool) throws {
        guard confirmed else {throw KabarError.invalid("Explicit confirmation required")}
        guard !isTwoWay else {return}
        if canSend && pending>=25 {throw KabarError.invalid("Antrean 25 kabar penuh")}
        let oldRole=role,old=state,oldPair=SharedStore.pairing()
        if oldRole=="sender" && oldPair?.privateKey == nil {throw KabarError.invalid("Kunci pengirim belum tersedia")}
        let own=oldRole=="sender" ? oldPair!:Pairing()
        stop()
        if oldRole=="receiver",let oldPair {
            try SharedStore.saveSecret(Data(oldPair.code.utf8),name:"peerCode")
            try SharedStore.saveSecret(Data(oldPair.code.utf8),name:"oneWayCode")
            SharedStore.defaults.set(try JSONEncoder().encode(old),forKey:"peerState")
            SharedStore.defaults.set(try JSONEncoder().encode(old),forKey:"oneWayState")
        }
        // Stage the new private key before switching the read capability/role.
        // A receiver ignores this account until the local confirmation completes.
        try SharedStore.saveSecret(own.privateKey!.rawRepresentation,name:"private");try SharedStore.saveSecret(Data(own.code.utf8),name:"code")
        SharedStore.defaults.set(oldRole=="receiver" ? "receiver":"sender",forKey:"oneWayRole");SharedStore.defaults.set("duplex",forKey:"role");SharedStore.defaults.set(true,forKey:"enabled");SharedStore.defaults.set(false,forKey:"peerConfirmed");SharedStore.defaults.set(false,forKey:"peerRevoked");SharedStore.defaults.set(true,forKey:"appearanceRelationship")
        if oldRole != "sender" {SharedStore.defaults.set([],forKey:"queue");state=KabarState();state.name=SharedStore.defaults.dictionary(forKey:"abcProfile")?["nickname"] as? String ?? "Aku"}
        role="duplex";state.revision+=1;try enqueue(state,notify:false);start();requestNotifications()
    }
    func joinSeirama(_ invite: String, confirmed: Bool) throws {
        guard confirmed,isTwoWay,let own=SharedStore.pairing() else {throw KabarError.invalid("Explicit Seirama confirmation required")}
        guard pending<25 else {throw KabarError.invalid("Antrean 25 kabar penuh")}
        let incoming=try Seirama.parseInvite(invite);try Seirama.requireDifferent(own,incoming)
        let previous=SharedStore.incomingPairing();stop()
        if let previous,previous.topic != incoming.topic,let token=SharedStore.defaults.string(forKey:"deviceToken"),let endpoint=validPushURL(){Task{try? await sendRegistration(endpoint:endpoint,pair:previous,token:token,remove:true)}}
        try SharedStore.saveSecret(Data(incoming.code.utf8),name:"peerCode")
        if previous?.topic != incoming.topic {SharedStore.defaults.removeObject(forKey:"peerState")}
        SharedStore.defaults.removeObject(forKey:"cursor");SharedStore.defaults.set(false,forKey:"peerConfirmed");SharedStore.defaults.set(false,forKey:"peerRevoked");SharedStore.defaults.set(false,forKey:"pushRegistered")
        state.revision+=1;try enqueue(state,notify:false);start()
    }
    func disableSeirama(confirmed: Bool) throws {
        guard confirmed else {throw KabarError.invalid("Explicit confirmation required")};guard isTwoWay else {return}
        let previous=SharedStore.defaults.string(forKey:"oneWayRole") ?? "sender"
        if previous=="sender" && pending>=25 {throw KabarError.invalid("Antrean 25 kabar penuh")}
        let incoming=SharedStore.incomingPairing()
        if previous=="receiver",let writer=SharedStore.pairing() {
            var q=retiredQueue;guard q.count<4 else {throw KabarError.invalid("Hubungkan internet sebelum menghentikan pasangan lainnya")}
            var last=state;last.revision+=1;try last.fitRelay()
            q.append(["topic":writer.topic,"body":try Packet(state:last,notify:false,seirama:false).envelope(pairing:writer)])
            SharedStore.defaults.set(q,forKey:"retiredQueue")
        }
        stop()
        if previous=="receiver",let code=SharedStore.secret("oneWayCode") {
            let original=String(decoding:code,as:UTF8.self)
            if incoming?.code==original {state=SharedStore.peerState() ?? KabarState()}
            else if let data=SharedStore.defaults.data(forKey:"oneWayState"),let originalState=try? JSONDecoder().decode(KabarState.self,from:data){state=originalState}
            try SharedStore.saveSecret(code,name:"code");SecItemDelete(SharedStore.key("private") as CFDictionary);SharedStore.defaults.set([],forKey:"queue");try SharedStore.save(state)
        }
        for name in ["peerCode","oneWayCode"] {SecItemDelete(SharedStore.key(name) as CFDictionary)}
        for key in ["peerState","peerConfirmed","peerRevoked","oneWayRole","oneWayState","cursor","publishedAt"] {SharedStore.defaults.removeObject(forKey:key)}
        SharedStore.defaults.set(previous,forKey:"role");SharedStore.defaults.set(false,forKey:"appearanceRelationship");role=previous;peerState=nil
        SharedStore.defaults.set(false,forKey:"pushRegistered")
        if let incoming,incoming.topic != SharedStore.incomingPairing()?.topic,let token=SharedStore.defaults.string(forKey:"deviceToken"),let endpoint=validPushURL(){Task{try? await sendRegistration(endpoint:endpoint,pair:incoming,token:token,remove:true)}}
        if previous=="sender" {state.revision+=1;try enqueue(state,notify:false,revoking:true)}
        start()
    }
    func record(_ kind: String, meal: String? = nil, share: Bool = false, completion: ((Bool)->Void)? = nil) {
        guard canSend, !locating else { return }
        guard pending<25 else { error = "Antrean 25 kabar penuh. Hubungkan internet sebelum menambah kabar."; return }
        let session = code
        let save: (GpsPoint?,String) -> Void = { [weak self] point,note in
            guard let self, self.canSend, self.code == session else { return }
            self.locating = false; self.sampler = nil; self.locationNote = note
            if kind.isEmpty && point == nil { self.error = note; completion?(false); return }
            do {
                var next = self.state; next.zone = TimeZone.current.identifier
                if kind.isEmpty { next.gps = point; next.revision += 1 }
                else { try next.record(kind,meal:meal,point:point) }
                try self.enqueue(next,notify:!kind.isEmpty)
                completion?(true)
            } catch { self.error = error.localizedDescription; completion?(false) }
        }
        if share { locating = true; sampler = LocationSampler(completion:save); sampler?.start() }
        else { save(nil,"") }
    }
    func refreshLocation() { SharedStore.defaults.set(true,forKey:"shareLocation"); record("",share:true) }
    func cancelLocation() { sampler?.cancel() }
    func clearGps() {
        do {
            var next = state; next.gps = nil; for i in next.events.indices { next.events[i].gps = nil }; next.revision += 1
            try enqueue(next,notify:false); SharedStore.defaults.set(false,forKey:"shareLocation"); locationNote = "Lokasi dihapus dari kabar terbaru"
        } catch { self.error = error.localizedDescription }
    }
    func enqueue(_ incoming: KabarState, notify: Bool, revoking: Bool = false) throws {
        var next=incoming;try next.fitRelay()
        guard canSend, let pair = SharedStore.pairing() else { throw KabarError.invalid("Pasangan pengirim belum tersedia") }
        var q = queue; guard q.count < 25 else { throw KabarError.invalid("Antrean 25 kabar penuh. Hubungkan internet sebelum menambah kabar.") }
        q.append(try Packet(state:next,notify:notify,peerTopic:isTwoWay && !revoking ? SharedStore.incomingPairing()?.topic:nil,seirama:revoking ? false:nil).envelope(pairing:pair))
        try SharedStore.save(next); SharedStore.defaults.set(q, forKey: "queue"); pending = q.count; state = next
        wakeSender()
        WidgetCenter.shared.reloadAllTimelines()
    }
    func edit(name: String, outside: String, home: String, meal: String, windows: [Int]) -> Bool {
        do {
            var next = state; next.name = name.trimmingCharacters(in: .whitespacesAndNewlines); next.outside = outside.trimmingCharacters(in: .whitespacesAndNewlines)
            next.home = home.trimmingCharacters(in: .whitespacesAndNewlines); next.meal = meal.trimmingCharacters(in: .whitespacesAndNewlines); next.windows = windows; next.revision += 1
            try enqueue(next, notify: false); return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func clearHistory() {
        var next = state; next.location = ""; next.locationAt = 0; next.homeAt = 0; next.mealAt = 0; next.breakfastAt = 0; next.lunchAt = 0; next.dinnerAt = 0
        next.mealCategory = ""; next.events = []; next.gps = nil; next.revision += 1
        do { try enqueue(next, notify: false) } catch { self.error = error.localizedDescription }
    }
    func rotate() throws {
        guard role == "sender" else { throw KabarError.invalid("Disable Seirama before rotating a one-way code") }
        let pair = Pairing(); stop()
        try SharedStore.saveSecret(Data(pair.code.utf8),name:"code")
        try SharedStore.saveSecret(pair.privateKey!.rawRepresentation,name:"private")
        SharedStore.defaults.set([],forKey:"queue"); SharedStore.defaults.removeObject(forKey:"cursor"); SharedStore.defaults.removeObject(forKey:"publishedAt")
        var next=state; next.revision += 1; try enqueue(next,notify:false); start()
    }
    func pause() {
        SharedStore.defaults.set(!enabled, forKey: "enabled")
        if enabled { start() }
        else {
            stop(); connection = "Koneksi dijeda"
            SharedStore.defaults.set(false,forKey:"pushRegistered")
            if let pair = SharedStore.incomingPairing(), let token = SharedStore.defaults.string(forKey:"deviceToken"), let endpoint = validPushURL() {
                Task { try? await sendRegistration(endpoint:endpoint,pair:pair,token:token,remove:true) }
            }
        }
    }
    private func wakeSender() {
        idleWake?.cancel();idleWake=nil;waitToken=nil
        let continuation=waiting;waiting=nil;continuation?.resume()
    }
    private func waitForOutgoing(milliseconds:Int64) async throws {
        let token=UUID()
        await withTaskCancellationHandler(operation:{
            await withCheckedContinuation { (continuation:CheckedContinuation<Void,Never>) in
                if Task.isCancelled || !queue.isEmpty {continuation.resume();return}
                waiting=continuation;waitToken=token
                idleWake=Task {
                    do {try await Task.sleep(nanoseconds:UInt64(max(1000,min(milliseconds,14_400_000)))*1_000_000)}catch{return}
                    if waitToken==token {wakeSender()}
                }
            }
        },onCancel:{[weak self] in Task { @MainActor in if self?.waitToken==token {self?.wakeSender()} }})
        try Task.checkCancellation()
    }
    func stop() {
        sync?.cancel(); sync = nil;peerSync?.cancel();peerSync=nil; wakeSender(); registration?.cancel(); registration = nil
        notificationRefresh?.cancel();notificationRefresh=nil;notificationGeneration=UUID()
    }
    func prepareRemoval() throws {
        let pair=SharedStore.incomingPairing(), token=SharedStore.defaults.string(forKey:"deviceToken"), endpoint=validPushURL()
        cancelLocation();stop()
        try SharedStore.eraseAll()
        role="";state=KabarState();peerState=nil;pending=0;pushEndpoint="";connection="Belum terhubung";error=nil;locationNote="";locating=false;sampler=nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.unregisterForRemoteNotifications()
        WidgetCenter.shared.reloadAllTimelines()
        if let pair,let token,let endpoint {Task {try? await sendRegistration(endpoint:endpoint,pair:pair,token:token,remove:true)}}
    }
    func disconnect() {
        if let pair = SharedStore.incomingPairing(), let token = SharedStore.defaults.string(forKey: "deviceToken"), let endpoint = validPushURL() {
            Task { try? await sendRegistration(endpoint: endpoint, pair: pair, token: token, remove: true) }
        }
        stop(); SharedStore.reset(); role = ""; state = KabarState();peerState=nil; pending = 0; pushEndpoint = ""; connection = "Belum terhubung"
        WidgetCenter.shared.reloadAllTimelines()
    }
    func start() {
        stop(); state = SharedStore.state();peerState=SharedStore.peerState(); pending = queue.count
        guard enabled, let pair = SharedStore.pairing() else { connection = "Koneksi dijeda"; return }
        let sender = canSend
        sync = Task {
            var delay: UInt64 = 1
            while !Task.isCancelled && SharedStore.pairing()?.topic == pair.topic {
                do {
                    try await drainRetired(session:pair.topic)
                    if sender {
                        if let envelope = queue.first {
                            let packet = try Packet.decode(envelope, pairing: pair)
                            try await RelayClient.publish(topic: pair.topic, envelope: envelope, proof: packet.notify ? pair.alertProof(envelope) : nil)
                            guard !Task.isCancelled, SharedStore.pairing()?.topic == pair.topic else { return }
                            var q = queue; if q.first == envelope { q.removeFirst(); SharedStore.defaults.set(q, forKey: "queue") }
                            pending = q.count; SharedStore.defaults.set(KabarState.now, forKey: "publishedAt"); connection = "Kabar terkirim ke relay"
                        } else {
                            let last = SharedStore.defaults.object(forKey: "publishedAt") as? Int64 ?? 0
                            if KabarState.now-last >= 4*60*60*1000 { try enqueue(state, notify: false) }
                            try await waitForOutgoing(milliseconds:4*60*60*1000-(KabarState.now-last))
                        }
                    } else {
                        try await receiveOnce(pair)
                    }
                    delay = 1
                } catch {
                    if Task.isCancelled { return }; connection = "Menunggu internet · kabar tetap tersimpan"
                    try? await Task.sleep(nanoseconds: delay*1_000_000_000); delay = min(delay*2,60)
                }
            }
        }
        if sender,isTwoWay,let incoming=SharedStore.incomingPairing() {
            peerSync=Task {
                var delay:UInt64=1
                while !Task.isCancelled,SharedStore.incomingPairing()?.topic==incoming.topic {
                    do {try await receiveOnce(incoming);delay=1}
                    catch {if Task.isCancelled{return};connection="Menunggu internet · kabar tetap tersimpan";try? await Task.sleep(nanoseconds:delay*1_000_000_000);delay=min(delay*2,60)}
                }
            }
        }
        registerPush()
    }
    private func drainRetired(session: String) async throws {
        while let item=retiredQueue.first {
            try Task.checkCancellation();guard SharedStore.pairing()?.topic==session,let topic=item["topic"],let body=item["body"] else {return}
            try await RelayClient.publish(topic:topic,envelope:body)
            try Task.checkCancellation();guard SharedStore.pairing()?.topic==session else {return}
            var q=retiredQueue;if q.first==item {q.removeFirst();SharedStore.defaults.set(q,forKey:"retiredQueue")}
        }
    }
    private func receiveOnce(_ pair: Pairing) async throws {
        guard SharedStore.incomingPairing()?.topic==pair.topic else {return}
        let cursor=SharedStore.defaults.string(forKey:"cursor") ?? "latest",listenedAt=KabarState.now
        var request=URLRequest(url:URL(string:"https://ntfy.sh/\(pair.topic)/json?since=\(cursor)")!);request.timeoutInterval=100
        let (bytes,response)=try await URLSession.shared.bytes(for:request)
        if (response as? HTTPURLResponse)?.statusCode==400 {SharedStore.defaults.removeObject(forKey:"cursor");return}
        guard (response as? HTTPURLResponse)?.statusCode==200 else {throw KabarError.invalid("Relay belum terhubung")}
        connection="Terhubung ke relay"
        for try await line in bytes.lines {
            guard !Task.isCancelled,SharedStore.incomingPairing()?.topic==pair.topic else {return}
            guard line.utf8.count<=16000,let msg=try? JSONDecoder().decode(RelayMessage.self,from:Data(line.utf8)),msg.event=="message",let text=msg.message,let packet=try? Packet.decode(text,pairing:pair) else {continue}
            let previous=isTwoWay ? SharedStore.peerState()?.revision ?? 0:SharedStore.state().revision
            if try SharedStore.receive(packet,topic:pair.topic) {
                if isTwoWay {peerState=packet.state}else{state=packet.state}
                WidgetCenter.shared.reloadAllTimelines()
                if packet.notify && (previous>0 || (msg.time ?? 0)*1000>=listenedAt-2000) && !SharedStore.defaults.bool(forKey:"pushRegistered") {await notify(packet)}
            }
            if isTwoWay {peerState=SharedStore.peerState()}else{state=SharedStore.state()}
            if let id=msg.id,id.range(of:"^[a-zA-Z0-9]+$",options:.regularExpression) != nil {SharedStore.defaults.set(id,forKey:"cursor")}
        }
    }
    func requestNotifications() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound])
                if granted { UIApplication.shared.registerForRemoteNotifications() }
                else { self.error = "Notifikasi belum diizinkan. Aktifkan Kabar di Pengaturan > Notifikasi." }
            } catch { self.error = error.localizedDescription }
        }
    }
    func notify(_ packet: Packet) async {
        guard !Task.isCancelled, !role.isEmpty, let topic=SharedStore.incomingPairing()?.topic else {return}
        let content = UNMutableNotificationContent(); content.title = "abc · \(packet.state.name)"; content.body = PhoneText.notification(packet); content.sound = UNNotificationSound(named:UNNotificationSoundName("abc_chime.wav"))
        content.subtitle=isTwoWay ? "Seirama":PhoneText.text("Kabar baru","New update","Neues Update");content.threadIdentifier="abc-updates"
        content.userInfo=PhoneText.notificationData(packet)
        content.userInfo["abcPeer"]=isTwoWay
        let identifier="kabar-\(topic)-\(packet.state.revision)",center=UNUserNotificationCenter.current()
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
        if role.isEmpty || SharedStore.incomingPairing()?.topic != topic {
            center.removePendingNotificationRequests(withIdentifiers:[identifier])
            center.removeDeliveredNotifications(withIdentifiers:[identifier])
        }
    }
    func refreshNotifications() {
        notificationRefresh?.cancel();notificationGeneration=UUID()
        guard !role.isEmpty,let topic=SharedStore.incomingPairing()?.topic else {return}
        let generation=notificationGeneration
        notificationRefresh=Task {
            let center=UNUserNotificationCenter.current()
            for delivered in await center.deliveredNotifications() {
                guard !Task.isCancelled,notificationGeneration==generation,!role.isEmpty,SharedStore.incomingPairing()?.topic==topic else {return}
                guard let at=(delivered.request.content.userInfo["abcAt"] as? NSNumber)?.int64Value,
                      let label=delivered.request.content.userInfo["abcLabel"] as? String,
                      let content=delivered.request.content.mutableCopy() as? UNMutableNotificationContent else {continue}
                content.body=PhoneText.notificationBody(label,at,content.userInfo["abcCity"] as? String ?? "")
                content.sound=nil;content.interruptionLevel = .passive
                try? await center.add(UNNotificationRequest(identifier:delivered.request.identifier,content:content,trigger:nil))
                if role.isEmpty || SharedStore.incomingPairing()?.topic != topic {
                    center.removePendingNotificationRequests(withIdentifiers:[delivered.request.identifier])
                    center.removeDeliveredNotifications(withIdentifiers:[delivered.request.identifier])
                }
            }
        }
    }
    private func validPushURL() -> URL? {
        guard let url = URL(string: pushEndpoint), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        return url.appendingPathComponent("devices")
    }
    func savePushEndpoint() {
        guard pushEndpoint.isEmpty || validPushURL() != nil else { error = "Alamat notifikasi harus berupa URL HTTPS"; return }
        SharedStore.defaults.set(pushEndpoint, forKey: "pushEndpoint"); SharedStore.defaults.set(false,forKey:"pushRegistered"); registerPush()
    }
    func registerPush() {
        registration?.cancel()
        guard enabled, let pair = SharedStore.incomingPairing(), let token = SharedStore.defaults.string(forKey: "deviceToken"), let endpoint = validPushURL() else { return }
        registration = Task {
            do {
                try await sendRegistration(endpoint: endpoint, pair: pair, token: token, remove: false)
                if !Task.isCancelled && SharedStore.incomingPairing()?.topic == pair.topic { SharedStore.defaults.set(true,forKey:"pushRegistered") }
            }
            catch { if !Task.isCancelled { self.error = "Server notifikasi Apple belum terhubung. Kabar tetap dapat dibaca saat aplikasi dibuka." } }
        }
    }
    private func sendRegistration(endpoint: URL, pair: Pairing, token: String, remove: Bool) async throws {
        var r = URLRequest(url: endpoint); r.httpMethod = remove ? "DELETE" : "POST"; r.timeoutInterval = 15
        r.setValue("application/json", forHTTPHeaderField: "Content-Type"); r.setValue("Bearer " + pair.pushCapability, forHTTPHeaderField: "Authorization")
        r.httpBody = try JSONSerialization.data(withJSONObject: ["topic": pair.topic, "publicKey": Encoding.b64(pair.publicKey.derRepresentation), "token": token])
        let (_, response) = try await URLSession.shared.data(for: r)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw KabarError.invalid("Pendaftaran notifikasi gagal") }
    }
}
