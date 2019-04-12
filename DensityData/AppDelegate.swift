//  Copyright © 2019 cincas. All rights reserved.

import UIKit
import DensityDataAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    self.window = window
    let viewModel = DataGridViewModel(apiClient: DensityDataAPI())
    window.rootViewController = ViewController(viewModel: viewModel)
    window.makeKeyAndVisible()
    return true
  }
}
