import Flutter
import UIKit

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
}
