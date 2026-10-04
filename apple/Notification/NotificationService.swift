import UserNotifications
import WidgetKit
import KabarCore
final class NotificationService: UNNotificationServiceExtension {
    private var completion: ((UNNotificationContent) -> Void)?
    private var fallback: UNMutableNotificationContent?
    private var work: Task<Void,Never>?
    private var expectedTopic: String?
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        completion = contentHandler
        expectedTopic=request.content.userInfo["topic"] as? String
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else { contentHandler(request.content); completion = nil; return }
        content.title = "abc"; content.body = PhoneText.text("Ada kabar baru. Buka aplikasi untuk melihatnya.","There is a new update. Open the app to see it.","Es gibt ein neues Update. Öffne die App, um es zu sehen."); content.sound=UNNotificationSound(named:UNNotificationSoundName("abc_chime.wav")); fallback = content
        work = Task {
            do {
                guard SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true, let pair = SharedStore.incomingPairing(), request.content.userInfo["topic"] as? String == pair.topic else { finishQuietly(content); return }
                var envelope = request.content.userInfo["envelope"] as? String
                if envelope == nil, let id = request.content.userInfo["messageId"] as? String,
                   id.range(of:"^[a-f0-9]{32}$",options:.regularExpression) != nil,
                   let base = SharedStore.defaults.string(forKey:"pushEndpoint"), let url = URL(string:base), url.scheme == "https", url.host != nil {
                    var r = URLRequest(url:url.appendingPathComponent("messages").appendingPathComponent(id)); r.timeoutInterval = 12
                    r.setValue("Bearer "+pair.pushCapability,forHTTPHeaderField:"Authorization")
                    let (data,response) = try await URLSession.shared.data(for:r)
                    guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 8192 else { finish(content); return }
                    envelope = String(data:data,encoding:.utf8)
                }
                guard let envelope, !Task.isCancelled else { finish(content); return }
                let packet = try Packet.decode(envelope,pairing:pair)
                guard SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true,SharedStore.incomingPairing()?.topic == pair.topic else { finishQuietly(content); return }
                _ = try SharedStore.receive(packet,topic:pair.topic)
                content.title = "abc · \(packet.state.name)"; content.body = PhoneText.notification(packet)
                content.subtitle=SharedStore.isTwoWay ? "Seirama":PhoneText.text("Kabar baru","New update","Neues Update");content.threadIdentifier="abc-updates"
                for (key,value) in PhoneText.notificationData(packet) {content.userInfo[key]=value}
                content.userInfo["abcPeer"]=SharedStore.isTwoWay
                WidgetCenter.shared.reloadAllTimelines(); finish(content)
            } catch { finish(content) }
        }
    }
    private func finish(_ content: UNNotificationContent) {
        guard let handler=completion else {return};completion=nil
        // Recheck when fetches fail or the extension deadline arrives: the app
        // may have paused, left Seirama or disconnected while this request ran.
        if (!(SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true) || expectedTopic==nil || SharedStore.incomingPairing()?.topic != expectedTopic),let quiet=content.mutableCopy() as? UNMutableNotificationContent {
            quiet.sound=nil;quiet.interruptionLevel = .passive;quiet.badge=nil
            quiet.title="abc";quiet.subtitle=""
            quiet.body=PhoneText.text("Sambungan ini tidak aktif. Buka abc untuk melihat sambungan saat ini.","This connection is inactive. Open abc to view your current connection.","Diese Verbindung ist inaktiv. Öffne abc für deine aktuelle Verbindung.")
            for key in ["abcAt","abcLabel","abcCity","abcName","abcPeer"] {quiet.userInfo.removeValue(forKey:key)}
            handler(quiet)
        } else {handler(content)}
    }
    private func finishQuietly(_ content: UNMutableNotificationContent) {
        content.sound=nil;content.interruptionLevel = .passive;content.badge=nil
        finish(content)
    }
    override func serviceExtensionTimeWillExpire() { work?.cancel(); if let content = fallback { finish(content) } }
}
