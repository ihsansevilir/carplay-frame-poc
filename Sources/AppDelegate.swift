import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        PlayerEngine.shared.setupAudioSession()
        return true
    }

    // Scene'ler Info.plist manifest'inden bağlanır:
    //   PhoneSceneDelegate      -> UIWindowSceneSessionRoleApplication
    //   CarPlaySceneDelegate    -> CPTemplateApplicationSceneSessionRoleApplication
}
