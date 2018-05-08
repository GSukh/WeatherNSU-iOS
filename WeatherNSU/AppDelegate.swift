import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow.init()
        let viewController = ViewController()
        
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
        
        
        return true
	}

}

