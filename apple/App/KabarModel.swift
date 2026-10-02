import Foundation
import SwiftUI
import UserNotifications
import WidgetKit
import KabarCore

@MainActor final class KabarModel: ObservableObject {
    @Published var state = SharedStore.state()
    @Published var role = SharedStore.defaults.string(forKey: "role") ?? ""
    @Published var connection = "Belum terhubung"
    @Published var error: String?
    @Published var pending = 0
    @Published var pushEndpoint = SharedStore.defaults.string(forKey: "pushEndpoint") ?? ""
    private var sync: Task<Void, Never>?
    private var registration: Task<Void, Never>?
    var code: String { SharedStore.pairing()?.code ?? "" }
    var queue: [String] { SharedStore.defaults.stringArray(forKey: "queue") ?? [] }
    var enabled: Bool { SharedStore.defaults.object(forKey: "enabled") as? Bool ?? true }
    init() { pending = queue.count }
    func beginSender() {
        do {
            let pair = Pairing(); try install(pair, role: "sender"); try enqueue(state, notify: false); start()
        } catch { self.error = error.localizedDescription }
    }
    func join(_ code: String) {
        do { try install(Pairing(code: code), role: "receiver"); start() } catch { self.error = error.localizedDescription }
    }
    private func install(_ pair: Pairing, role: String) throws {
        stop(); SharedStore.reset()
        do {
            try SharedStore.saveSecret(Data(pair.code.utf8), name: "code")
            if let key = pair.privateKey { try SharedStore.saveSecret(key.rawRepresentation, name: "private") }
        } catch { SharedStore.reset(); throw error }
        SharedStore.defaults.set(role, forKey: "role"); SharedStore.defaults.set(true, forKey: "enabled")
        self.role = role; state = KabarState(); try SharedStore.save(state); pending = 0; pushEndpoint = ""
        WidgetCenter.shared.reloadAllTimelines()
    }
    func record(_ kind: String) {
        do { var next = state; try next.record(kind); try enqueue(next, notify: true) } catch { self.error = error.localizedDescription }
    }
    private func enqueue(_ next: KabarState, notify: Bool) throws {
        guard role == "sender", let pair = SharedStore.pairing() else { throw KabarError.invalid("Pasangan pengirim belum tersedia") }
        var q = queue; guard q.count < 25 else { throw KabarError.invalid("Antrean 25 kabar penuh. Hubungkan internet sebelum menambah kabar.") }
        q.append(try Packet(state: next, notify: notify).envelope(pairing: pair))
        try SharedStore.save(next); SharedStore.defaults.set(q, forKey: "queue"); pending = q.count; state = next
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
        next.mealCategory = ""; next.events = []; next.revision += 1
        do { try enqueue(next, notify: false) } catch { self.error = error.localizedDescription }
    }
    func pause() { SharedStore.defaults.set(!enabled, forKey: "enabled"); if enabled { start() } else { stop(); connection = "Koneksi dijeda" } }
    func stop() { sync?.cancel(); sync = nil; registration?.cancel(); registration = nil }
    func disconnect() {
        if let pair = SharedStore.pairing(), let token = SharedStore.defaults.string(forKey: "deviceToken"), let endpoint = validPushURL() {
            Task { try? await sendRegistration(endpoint: endpoint, pair: pair, token: token, remove: true) }
        }
        stop(); SharedStore.reset(); role = ""; state = KabarState(); pending = 0; pushEndpoint = ""; connection = "Belum terhubung"
        WidgetCenter.shared.reloadAllTimelines()
    }
    func start() {
        stop(); state = SharedStore.state(); pending = queue.count
        guard enabled, let pair = SharedStore.pairing() else { connection = "Koneksi dijeda"; return }
        let sender = role == "sender"
        sync = Task {
            var delay: UInt64 = 1
            while !Task.isCancelled && SharedStore.pairing()?.topic == pair.topic {
                do {
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
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                    } else {
                        let cursor = SharedStore.defaults.string(forKey: "cursor") ?? "latest"
                        var request = URLRequest(url: URL(string: "https://ntfy.sh/\(pair.topic)/json?since=\(cursor)")!); request.timeoutInterval = 100
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)
                        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw KabarError.invalid("Relay belum terhubung") }
                        connection = "Terhubung ke relay"
                        for try await line in bytes.lines {
                            guard !Task.isCancelled, SharedStore.pairing()?.topic == pair.topic else { return }
                            guard line.utf8.count <= 16000, let msg = try? JSONDecoder().decode(RelayMessage.self, from: Data(line.utf8)), msg.event == "message", let text = msg.message,
                                  let packet = try? Packet.decode(text, pairing: pair) else { continue }
                            let previous = SharedStore.state().revision
                            if try SharedStore.receive(packet, topic: pair.topic) {
                                state = packet.state; WidgetCenter.shared.reloadAllTimelines()
                                if packet.notify && previous > 0 { await notify(packet) }
                            }
                            if let id = msg.id, id.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil { SharedStore.defaults.set(id, forKey: "cursor") }
                        }
                    }
                    delay = 1
                } catch {
                    if Task.isCancelled { return }; connection = "Menunggu internet · kabar tetap tersimpan"
                    try? await Task.sleep(nanoseconds: delay*1_000_000_000); delay = min(delay*2,60)
                }
            }
        }
        registerPush()
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
        let content = UNMutableNotificationContent(); content.title = "Kabar \(packet.state.name)"; content.body = packet.notificationBody; content.sound = .default
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "kabar-\(packet.state.revision)", content: content, trigger: nil))
    }
    private func validPushURL() -> URL? {
        guard let url = URL(string: pushEndpoint), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        return url.appendingPathComponent("devices")
    }
    func savePushEndpoint() {
        guard pushEndpoint.isEmpty || validPushURL() != nil else { error = "Alamat notifikasi harus berupa URL HTTPS"; return }
        SharedStore.defaults.set(pushEndpoint, forKey: "pushEndpoint"); registerPush()
    }
    func registerPush() {
        registration?.cancel()
        guard role == "receiver", let pair = SharedStore.pairing(), let token = SharedStore.defaults.string(forKey: "deviceToken"), let endpoint = validPushURL() else { return }
        registration = Task {
            do { try await sendRegistration(endpoint: endpoint, pair: pair, token: token, remove: false) }
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
