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

        DoubleQuoteNamespacedLogger().log(withMessage: "Hello World, from DoubleQuoteNamespacedLogger")

        DoubleQuoteLogger().log(withMessage: "Hello World, from DoubleQuoteLogger")

        let swiftLogger = SwiftLogger()
        swiftLogger.swiftLog("Hello World, from SwiftLogger!")

        return true
    }
}
