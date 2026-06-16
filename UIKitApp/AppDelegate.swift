import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = makeTabBarController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    private func makeTabBarController() -> UITabBarController {
        let basics = UINavigationController(rootViewController: BasicElementsViewController())
        basics.tabBarItem = UITabBarItem(
            title: "基本要素",
            image: UIImage(systemName: "square.grid.2x2"),
            tag: 0
        )

        let idLabel = UINavigationController(rootViewController: IdentifierLabelViewController())
        idLabel.tabBarItem = UITabBarItem(
            title: "ID/Label",
            image: UIImage(systemName: "tag"),
            tag: 1
        )

        let about = UINavigationController(rootViewController: AboutViewController())
        about.tabBarItem = UITabBarItem(
            title: "About",
            image: UIImage(systemName: "info.circle"),
            tag: 2
        )

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [basics, idLabel, about]
        return tabBarController
    }
}
