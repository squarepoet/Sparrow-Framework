//
//  AppDelegate.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow
import UIKit

let GAME_WIDTH: Float  = 320.0
let GAME_HEIGHT: Float = 480.0

let CENTER_X: Float = GAME_WIDTH  / 2.0
let CENTER_Y: Float = GAME_HEIGHT / 2.0

@UIApplicationMain
class DemoAppDelegate: UIResponder, UIApplicationDelegate {
    @IBOutlet var viewController: SPViewController?
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        NSSetUncaughtExceptionHandler() { exception in
            print("uncaught exception: \(exception.description)")
        }
        
        SPAudioEngine.start()
        
        return true
    }
}
