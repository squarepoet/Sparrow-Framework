//
//  CustomHitTestScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class CustomHitTestScene: Scene {
    required init() {
        super.init()
        
        let description = "Pushing the button only works when the touch occurs within a circle."
                          "This can be accomplished by overriding the method 'hitTestPoint:'."
        
        let infoText = SPTextField(width: 300, height: 100,
            text: description, fontName: "Verdana", fontSize: 13, color: 0x0)
        infoText.x = 10
        infoText.y = 10
        infoText.vAlign = .Top
        addChild(infoText)
        
        // 'RoundButton' is a helper class of the Demo, not a part of Sparrow!
        // have a look at its code to understand this sample.
        
        let roundSparrow = SPTexture(contentsOfFile: "sparrow_round.png")
        
        let button = RoundButton(upState: roundSparrow)
        button.x = CENTER_X - floor(button.width) / 2
        button.y = CENTER_Y - floor(button.height) / 2
        addChild(button)
    }
}
