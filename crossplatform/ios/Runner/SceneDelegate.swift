import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidEnterBackground(_ scene: UIScene) { super.sceneDidEnterBackground(scene); if let app=UIApplication.shared.delegate as? AppDelegate {app.bridge.model.cancelLocation();app.bridge.model.stop()} }
  override func sceneDidBecomeActive(_ scene: UIScene) { super.sceneDidBecomeActive(scene); (UIApplication.shared.delegate as? AppDelegate)?.bridge.model.start() }
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene,openURLContexts:URLContexts)
    if let app=UIApplication.shared.delegate as? AppDelegate {for context in URLContexts {_=app.bridge.open(context.url)}}
  }
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene,willConnectTo:session,options:connectionOptions)
    if let app=UIApplication.shared.delegate as? AppDelegate {for context in connectionOptions.urlContexts {_=app.bridge.open(context.url)}}
  }

}
