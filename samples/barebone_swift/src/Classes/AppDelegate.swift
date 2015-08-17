//
//  AppDelegate.swift
//

import UIKit
import Sparrow

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var _window: UIWindow!
    var _viewController: SPViewController!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        _viewController = SPViewController()
        _viewController.showStats = true
        _viewController.multitouchEnabled = true
        _viewController.preferredFramesPerSecond = 60
        _viewController.startWithRoot(Game.self, supportHighResolutions: true, doubleOnPad: true)

        _window = UIWindow(frame: UIScreen.mainScreen().bounds)
        _window.rootViewController = _viewController
        _window.makeKeyAndVisible()

        return true
    }
}

