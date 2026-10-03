import SwiftUI
import UserNotifications

final class KabarDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self; return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SharedStore.defaults.set(deviceToken.map { String(format: "%02x", $0) }.joined(), forKey: "deviceToken")
        NotificationCenter.default.post(name: .init("KabarToken"), object: nil)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner,.sound]) }
}
@main struct KabarApp: App {
    @UIApplicationDelegateAdaptor(KabarDelegate.self) var delegate
    @AppStorage("appearanceDark",store:SharedStore.defaults) private var dark = false
    @StateObject private var model = KabarModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            KabarView().environmentObject(model).preferredColorScheme(dark ? .dark:.light)
                .onAppear { model.start() }
                .onChange(of: phase) { phase in if phase == .active { model.start() } else if phase == .background { model.cancelLocation(); model.stop() } }
                .onReceive(NotificationCenter.default.publisher(for: .init("KabarToken"))) { _ in model.registerPush() }
        }
    }
}
