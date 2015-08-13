//
//  Scene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

let EventTypeSceneClosing = "closing"

class Scene: SPSprite {
    private var _backButton: SPButton!
    
    override required init() {
        super.init()
        
        // create a button with the text "back" and display it at the bottom of the screen.
        let buttonTexture = SPTexture(contentsOfFile: "button_back.png")
        
        _backButton = SPButton(upState: buttonTexture, text: "back")
        _backButton.x = CENTER_X - _backButton.width / 2.0
        _backButton.y = GAME_HEIGHT - _backButton.height + 1
        _backButton.addEventListener("onBackButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(_backButton)
    }
    
    private dynamic func onBackButtonTriggered(event: SPEvent) {
        _backButton.removeEventListenersAtObject(self, forType: SPEventTypeTriggered)
        dispatchEventWithType(EventTypeSceneClosing, bubbles: true)
    }
}
