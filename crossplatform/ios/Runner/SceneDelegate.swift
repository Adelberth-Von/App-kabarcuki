import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidEnterBackground(_ scene: UIScene) { super.sceneDidEnterBackground(scene); if let app=UIApplication.shared.delegate as? AppDelegate {app.bridge.model.cancelLocation();app.bridge.model.stop()} }
  override func sceneDidBecomeActive(_ scene: UIScene) { super.sceneDidBecomeActive(scene); (UIApplication.shared.delegate as? AppDelegate)?.bridge.model.start() }
}
