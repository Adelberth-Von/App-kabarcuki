import UserNotifications
import WidgetKit
import KabarCore
final class NotificationService: UNNotificationServiceExtension {
    private var completion: ((UNNotificationContent) -> Void)?
    private var fallback: UNMutableNotificationContent?
    private var work: Task<Void,Never>?
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        completion = contentHandler
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else { contentHandler(request.content); completion = nil; return }
        content.title = "abc"; content.body = PhoneText.text("Ada kabar baru. Buka aplikasi untuk melihatnya.","There is a new update. Open the app to see it.","Es gibt ein neues Update. Öffne die App, um es zu sehen."); content.sound=UNNotificationSound(named:UNNotificationSoundName("abc_chime.wav")); fallback = content
        work = Task {
            do {
                guard SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true, let pair = SharedStore.incomingPairing(), request.content.userInfo["topic"] as? String == pair.topic else { finish(content); return }
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
                guard SharedStore.incomingPairing()?.topic == pair.topic else { finish(content); return }
                _ = try SharedStore.receive(packet,topic:pair.topic)
                content.title = "abc · \(packet.state.name)"; content.body = PhoneText.notification(packet)
                content.subtitle=SharedStore.isTwoWay ? "Seirama":PhoneText.text("Kabar baru","New update","Neues Update");content.threadIdentifier="abc-updates"
                for (key,value) in PhoneText.notificationData(packet) {content.userInfo[key]=value}
                content.userInfo["abcPeer"]=SharedStore.isTwoWay
                WidgetCenter.shared.reloadAllTimelines(); finish(content)
            } catch { finish(content) }
        }
    }
    private func finish(_ content: UNNotificationContent) { if let handler = completion { completion = nil; handler(content) } }
    override func serviceExtensionTimeWillExpire() { work?.cancel(); if let content = fallback { finish(content) } }
}
