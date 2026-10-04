import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  let bridge = NativeBridge()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    NSLog("abc-QA: application launch")
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    #if DEBUG
    NSLog("abc-QA: implicit engine ready")
    #endif
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    bridge.attach(engineBridge.applicationRegistrar.messenger())
    #if DEBUG
    NSLog("abc-QA: native bridge attached")
    #endif
  }
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    SharedStore.defaults.set(deviceToken.map{String(format:"%02x",$0)}.joined(),forKey:"deviceToken")
    bridge.model.registerPush()
    super.application(application,didRegisterForRemoteNotificationsWithDeviceToken:deviceToken)
  }
  override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey:Any] = [:]) -> Bool {
    if bridge.open(url) {return true};return super.application(application,open:url,options:options)
  }
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    if response.notification.request.content.userInfo["abcPeer"] as? Bool == true {_=bridge.open(URL(string:"kabar://home?peer=1")!)}
    super.userNotificationCenter(center,didReceive:response,withCompletionHandler:completionHandler)
  }

}
