import UIKit
import MixedSourceFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - <UIApplicationDelegate>

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let mainWindow = UIWindow(frame: UIScreen.main.bounds)
        defer { window = mainWindow }

        mainWindow.rootViewController = ViewController()
        mainWindow.makeKeyAndVisible()

        Logger.sharedInstance().log(withMessage: "Hello World")

        return true
    }
}
