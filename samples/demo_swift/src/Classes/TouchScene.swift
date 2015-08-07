//
//  TouchScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class TouchScene: Scene {
    required init() {
        super.init()
        
        let description = "Touch and drag to move the image, \n"
                          "pinch with 2 fingers to scale and rotate."
        
        let infoText = SPTextField(width: 300, height: 64,
            text: description, fontName: "Verdana", fontSize: 13, color: 0x0)
        infoText.x = 10
        infoText.y = 10
        addChild(infoText)
        
        let sparrow = SPImage(contentsOfFile: "sparrow_sheet.png")
        
        // to find out how to react to touch events have a look at the TouchSheet class!
        // It's part of the demo.
        
        let sheet = TouchSheet(quad: sparrow)
        sheet.x = CENTER_X
        sheet.y = CENTER_Y
        addChild(sheet)
    }
}