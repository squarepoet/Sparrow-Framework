//
//  ViewController.swift
//  Demo
//
//  Created by Robert Carone on 1/24/16.
//
//

import UIKit
import Sparrow

class ViewController: SPViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showStats = true
        multitouchEnabled = true
        preferredFramesPerSecond = 60
        startWithRoot(Game.self, supportHighResolutions: true, doubleOnPad: true)
        
        // What follows is a very simple approach to support the iPad:
        // we just center the stage on the screen!
        //
        // (Beware: to support autorotation, this would need a little more work.)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            view.frame = CGRectMake(64, 32, 640, 960)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
