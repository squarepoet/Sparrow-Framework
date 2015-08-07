//
//  AppDelegate.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import UIKit

let GAME_WIDTH: Float  = 320.0
let GAME_HEIGHT: Float = 480.0

let CENTER_X: Float = GAME_WIDTH  / 2.0
let CENTER_Y: Float = GAME_HEIGHT / 2.0

@UIApplicationMain
class DemoAppDelegate: UIResponder, UIApplicationDelegate {
    var _viewController: SPViewController!
    var _window: UIWindow!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        NSSetUncaughtExceptionHandler() { exception in
            print("uncaught exception: \(exception.description)")
        }
        
        _window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        SPAudioEngine.start()
        
        _viewController = SPViewController()
        _viewController.multitouchEnabled = true
        _viewController.preferredFramesPerSecond = 60
        _viewController.startWithRoot(Game.self, supportHighResolutions: true, doubleOnPad: true)
        
        _window.rootViewController = _viewController
        _window.makeKeyAndVisible()
        
        // What follows is a very simple approach to support the iPad:
        // we just center the stage on the screen!
        //
        // (Beware: to support autorotation, this would need a little more work.)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            _viewController.view.frame = CGRectMake(64, 32, 640, 960)
            _viewController.stage.width = 320
            _viewController.stage.height = 480
        }
        
        return true
    }
}
