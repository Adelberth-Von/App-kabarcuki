import Flutter
import UIKit
import WidgetKit
import KabarCore
import Combine
import CoreLocation

@MainActor final class NativeBridge: NSObject, FlutterStreamHandler {
    let model = KabarModel()
    private var channel: FlutterMethodChannel?
    private var updates:FlutterEventSink?
    private var observation:AnyCancellable?
    private var notifications:[NSObjectProtocol]=[]
    private var settingsObserver:NSObjectProtocol?
    private var quickAction=""
    private var quickPeer=false
    func open(_ url: URL) -> Bool {
        guard url.scheme=="kabar",let parts=URLComponents(url:url,resolvingAgainstBaseURL:false) else {return false}
        let query=parts.queryItems ?? []
        if url.host=="home",query.contains(where:{$0.name=="peer" && $0.value=="1"}),SharedStore.isTwoWay,SharedStore.peerState() != nil {quickPeer=true}
        else if url.host=="action",model.canSend,let kind=query.first(where:{$0.name=="kind"})?.value,["outside","home","meal"].contains(kind){quickAction=kind}
        else if url.host != "home" {return false}
        updates?(nil);return true
    }
    var profile: [String:Any] { SharedStore.defaults.dictionary(forKey:"abcProfile") ?? [:] }
    func attach(_ messenger: FlutterBinaryMessenger) {
        #if DEBUG
        NSLog("abc-QA: attaching channels")
        #endif
        channel=FlutterMethodChannel(name:"abc/native",binaryMessenger:messenger)
        channel?.setMethodCallHandler { [weak self] call,result in self?.handle(call,result) }
        FlutterEventChannel(name:"abc/updates",binaryMessenger:messenger).setStreamHandler(self)
        #if DEBUG
        NSLog("abc-QA: channels ready")
        #endif
        model.start()
        #if DEBUG
        NSLog("abc-QA: native model started")
        #endif
    }
    func onListen(withArguments arguments:Any?,eventSink events:@escaping FlutterEventSink)->FlutterError? {
        _=onCancel(withArguments:nil);updates=events
        observation=model.objectWillChange.sink { [weak self] _ in DispatchQueue.main.async {self?.updates?(nil)} }
        for name in [UserDefaults.didChangeNotification, NSNotification.Name.NSSystemTimeZoneDidChange,
                     UIApplication.significantTimeChangeNotification, NSNotification.Name.NSProcessInfoPowerStateDidChange] {
            notifications.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:.main) { [weak self] _ in
                DispatchQueue.main.async {self?.updates?(nil)}
            })
        }
        events(nil);return nil
    }
    func onCancel(withArguments arguments:Any?)->FlutterError? {
        observation?.cancel();observation=nil
        for item in notifications {NotificationCenter.default.removeObserver(item)}
        notifications=[];updates=nil;return nil
    }
    func validName(_ raw:String)->Bool {let s=raw.trimmingCharacters(in:.whitespacesAndNewlines);return !s.isEmpty && s.utf16.count<=24 && !s.unicodeScalars.contains(where:{$0.value<32 || $0.value==127})}
    func zone(_ z:TimeZone,_ at:Int64,offset:Bool)->[String:Any] {
        let locale=Locale(identifier:profile["language"] as? String ?? "id")
        let country=LocalClock.regionCode(z).flatMap { locale.localizedString(forRegionCode:$0) } ?? "UTC"
        var info:[String:Any]=["id":z.identifier,"short":LocalClock.shortZone(z,at:at),"country":country]
        if offset {info["offsetMinutes"]=z.secondsFromGMT(for:Date(timeIntervalSince1970:Double(at)/1000))/60};return info
    }
    func snapshot() throws->[String:Any] {
        var s=try JSONSerialization.jsonObject(with:JSONEncoder().encode(model.state)) as! [String:Any]
        var local:[String:Any]=[:]
        for at in [model.state.locationAt,model.state.homeAt,model.state.mealAt,model.state.breakfastAt,model.state.lunchAt,model.state.dinnerAt] where at>0 {local[String(at)]=zone(.current,at,offset:false)}
        var events=s["events"] as? [[String:Any]] ?? []
        for i in events.indices {let at=(events[i]["at"] as! NSNumber).int64Value; local[String(at)]=zone(.current,at,offset:false);events[i]["originInfo"]=zone(TimeZone(identifier:events[i]["zone"] as? String ?? model.state.zone) ?? .gmt,at,offset:true)
            if let gps=events[i]["gps"] as? [String:Any],let at=(gps["at"] as? NSNumber)?.int64Value {local[String(at)]=zone(.current,at,offset:false)}
        }
        s["events"]=events
        if let gps=model.state.gps {local[String(gps.at)]=zone(.current,gps.at,offset:false)}
        var p=profile;p["dark"]=SharedStore.defaults.bool(forKey:"appearanceDark");p["relationship"]=SharedStore.defaults.bool(forKey:"appearanceRelationship")
        let old=model.connection
        let connection = !model.enabled ? "paused" : old.hasPrefix("Terhubung") ? "online" : old.hasPrefix("Kabar terkirim") ? "sent" : old.hasPrefix("Menunggu") ? "offline" : "connecting"
        var output:[String:Any]=["mode":SharedStore.mode,"reciprocity":SharedStore.reciprocity,"modeUpgradeSuggested":!SharedStore.isTwoWay && SharedStore.defaults.bool(forKey:"appearanceRelationship"),"state":s,"profile":p,"role":model.role,"enabled":model.enabled,"pending":model.queue.count,"connection":connection,"shareLocation":SharedStore.defaults.bool(forKey:"shareLocation"),"zone":zone(.current,KabarState.now,offset:false),"localTimes":local,"platform":"ios","energySaver":ProcessInfo.processInfo.isLowPowerModeEnabled,"pushEndpoint":model.pushEndpoint,"mealsToday":["Sarapan","Makan siang","Makan malam"].map{model.state.hasMealToday($0)}]
        if let peer=SharedStore.peerState() {
            var times:[String:Any]=[:];output["peerState"]=try decorate(peer,local:&times)
            output["peerLocalTimes"]=times;output["peerZone"]=zone(peer.timeZone,KabarState.now,offset:true);output["peerMealsToday"]=["Sarapan","Makan siang","Makan malam"].map{peer.hasMealToday($0)}
        }
        if !quickAction.isEmpty {output["quickAction"]=quickAction;quickAction=""};if quickPeer {output["quickPeer"]=true;quickPeer=false}
        return output
    }
    private func decorate(_ state: KabarState,local: inout [String:Any]) throws -> [String:Any] {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any]
        for at in [state.locationAt,state.homeAt,state.mealAt,state.breakfastAt,state.lunchAt,state.dinnerAt] where at>0 {local[String(at)]=zone(.current,at,offset:false)}
        var events=json["events"] as? [[String:Any]] ?? []
        for i in events.indices {let at=(events[i]["at"] as! NSNumber).int64Value;local[String(at)]=zone(.current,at,offset:false);events[i]["originInfo"]=zone(TimeZone(identifier:events[i]["zone"] as? String ?? state.zone) ?? .gmt,at,offset:true);if let point=events[i]["gps"] as? [String:Any],let g=(point["at"] as? NSNumber)?.int64Value{local[String(g)]=zone(.current,g,offset:false)}}
        json["events"]=events;if let point=state.gps {local[String(point.at)]=zone(.current,point.at,offset:false)};return json
    }
    func encoded(_ value:[String:Any]) throws->String {String(decoding:try JSONSerialization.data(withJSONObject:value),as:UTF8.self)}
    func answer(_ result:FlutterResult,note:String?=nil){do {var v:[String:Any]=["snapshot":try snapshot()];if let note {v["note"]=note};result(try encoded(v))}catch{result(FlutterError(code:"error",message:"Unable to complete action",details:nil))}}
    func requireSender() throws {if !model.canSend || SharedStore.pairing()?.privateKey == nil {throw KabarError.invalid("Sender required")}}
    func handle(_ call:FlutterMethodCall,_ result:@escaping FlutterResult) {
        let a=call.arguments as? [String:Any] ?? [:]
        do {
            // Snapshot reads must not publish changes: that would feed the event
            // listener back into another snapshot read indefinitely.
            if call.method=="snapshot" {result(try encoded(snapshot()));return}
            model.error=nil
            switch call.method {
            case "locationServices":result(try encoded(["enabled":CLLocationManager.locationServicesEnabled()]));return
            case "locationSettings":
                settingsObserver=NotificationCenter.default.addObserver(forName:UIApplication.didBecomeActiveNotification,object:nil,queue:.main) { [weak self] _ in
                    guard let self else {return};if let observer=self.settingsObserver {NotificationCenter.default.removeObserver(observer)};self.settingsObserver=nil;self.answer(result)
                }
                UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!) { [weak self] opened in
                    if !opened,let self {if let observer=self.settingsObserver {NotificationCenter.default.removeObserver(observer)};self.settingsObserver=nil;self.answer(result)}
                };return
            #if DEBUG
            case "qaCleanupProbe":result(try encoded(CleanupProbe.inspect(seed:a["seed"] as? Bool ?? false)));return
            #endif
            case "preferences":
                var p=profile
                if let name=a["nickname"] as? String {guard validName(name) else {result(FlutterError(code:"invalid_name",message:"Invalid nickname",details:nil));return};p["nickname"]=name.trimmingCharacters(in:.whitespacesAndNewlines)}
                if let language=a["language"] as? String {guard ["id","en","de"].contains(language) else {throw KabarError.invalid("Language")};p["language"]=language}
                if let v=a["clock12"] as? Bool {p["clock12"]=v}
                if let v=a["animations"] as? Bool {p["animations"]=v}
                if let v=a["dark"] as? Bool {SharedStore.defaults.set(v,forKey:"appearanceDark")}
                if let v=a["relationship"] as? Bool {SharedStore.defaults.set(v,forKey:"appearanceRelationship")}
                SharedStore.defaults.set(p,forKey:"abcProfile");WidgetCenter.shared.reloadAllTimelines();model.refreshNotifications()
            case "setupSender":guard model.role.isEmpty else {throw KabarError.invalid("Already paired")};model.beginSender()
            case "setupReceiver":
                guard model.role.isEmpty else {throw KabarError.invalid("Already paired")}
                guard let code=a["code"] as? String,(try? Pairing(code:code)) != nil else {result(FlutterError(code:"invalid_code",message:"Invalid code",details:nil));return};model.join(code)
            case "enableSeirama":try model.enableSeirama(confirmed:a["confirmed"] as? Bool ?? false)
            case "joinSeirama":
                guard let invite=a["code"] as? String,let incoming=try? Seirama.parseInvite(invite) else {result(FlutterError(code:"invalid_code",message:"Invalid Seirama code",details:nil));return}
                guard let own=SharedStore.pairing(),!Seirama.isOwn(own,incoming) else {result(FlutterError(code:"own_code",message:"Use your partner's code",details:nil));return}
                try model.joinSeirama(invite,confirmed:a["confirmed"] as? Bool ?? false)
            case "disableSeirama":try model.disableSeirama(confirmed:a["confirmed"] as? Bool ?? false)
            case "record":
                try requireSender();guard model.pending<25 else {result(FlutterError(code:"queue_full",message:"Queue full",details:nil));return}
                let kind=a["kind"] as? String ?? "",share=a["shareLocation"] as? Bool ?? false
                SharedStore.defaults.set(share,forKey:"shareLocation")
                model.record(kind,meal:a["category"] as? String,share:share) { [weak self] okay in
                    guard let self else {return}
                    if !okay && !kind.isEmpty {result(FlutterError(code:"error",message:"Could not save update",details:nil))}
                    else {self.answer(result,note:!okay ? "locationFailed" : !self.model.locationNote.isEmpty ? "locationUnavailable" : nil)}
                };return
            case "edit":
                try requireSender();var s=model.state
                for k in ["name","outside","home","meal"] {if let v=a[k] as? String {guard validName(v) else {throw KabarError.invalid("Name")};let clean=v.trimmingCharacters(in:.whitespacesAndNewlines);switch k {case "name":s.name=clean;case "outside":s.outside=clean;case "home":s.home=clean;default:s.meal=clean}}}
                if let w=a["windows"] as? [Int] {guard KabarState.validWindows(w) else {throw KabarError.invalid("Schedule")};s.windows=w};s.revision+=1;try model.enqueue(s,notify:false)
            case "pairCode":try requireSender();result(try encoded(["code":SharedStore.isTwoWay ? Seirama.invite(SharedStore.pairing()!):model.code]));return
            case "shareCode":
                try requireSender();let vc=UIActivityViewController(activityItems:[SharedStore.isTwoWay ? Seirama.invite(SharedStore.pairing()!):model.code],applicationActivities:nil)
                if let root=UIApplication.shared.connectedScenes.compactMap({($0 as? UIWindowScene)?.keyWindow?.rootViewController}).first {vc.popoverPresentationController?.sourceView=root.view;root.present(vc,animated:true)}
            case "openMap":
                guard let lat=a["lat"] as? Double,let lon=a["lon"] as? Double,lat.isFinite,lon.isFinite,abs(lat)<=90,abs(lon)<=180 else {throw KabarError.invalid("Location")}
                UIApplication.shared.open(URL(string:"https://maps.apple.com/?ll=\(lat),\(lon)&q=\(lat),\(lon)")!)
            case "toggleConnection":model.pause()
            case "notifications":model.requestNotifications()
            case "appSettings":UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            case "clearGps":try requireSender();model.clearGps()
            case "clearHistory":try requireSender();model.clearHistory()
            case "rotate":try model.rotate()
            case "disconnect":model.disconnect()
            case "prepareUninstall":try model.prepareRemoval()
            case "pushServer":model.pushEndpoint=a["url"] as? String ?? "";model.savePushEndpoint()
            default:result(FlutterMethodNotImplemented);return
            }
            if model.error != nil {throw KabarError.invalid("Action failed")};answer(result)
        } catch {result(FlutterError(code:model.pending>=25 ? "queue_full":"error",message:"Unable to complete action",details:nil))}
    }
}
