import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  let bridge = NativeBridge()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    bridge.attach(engineBridge.applicationRegistrar.messenger())
  }
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    SharedStore.defaults.set(deviceToken.map{String(format:"%02x",$0)}.joined(),forKey:"deviceToken")
    bridge.model.registerPush()
    super.application(application,didRegisterForRemoteNotificationsWithDeviceToken:deviceToken)
  }
}
