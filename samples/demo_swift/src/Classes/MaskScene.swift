//
//  MaskScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class MaskScene: Scene {
    private var _contents: SPSprite!
    private var _mask: SPCanvas!
    private var _maskDisplay: SPCanvas!
    
    required init() {
        super.init()
        
        _contents = SPSprite()
        addChild(_contents)
        
        let stageWidth  = Sparrow.stage()!.width
        let stageHeight = Sparrow.stage()!.height
        
        let touchQuad = SPQuad(width: stageWidth, height: stageHeight)
        touchQuad.alpha = 0 // only used to get touch events
        addChild(touchQuad, atIndex: 0)
        
        let image = SPImage(contentsOfFile: "sparrow_front.png")
        image.x = (stageWidth - image.width) / 2
        image.y = 80
        _contents.addChild(image)
        
        // just to prove it works, use a filter on the image.
        let cm = SPColorMatrixFilter()
        cm.adjustHue(-0.5)
        image.filter = cm
        
        let maskString = "Move a finger over the screen to move the clipping rectangle."
        let maskText = SPTextField(width: 256, height: 128, text: maskString)
        maskText.x = (stageWidth - maskText.width) / 2
        maskText.y = 240
        _contents.addChild(maskText)
        
        _maskDisplay = createCircle()
        _maskDisplay.alpha = 0.3
        _maskDisplay.touchable = false
        addChild(_maskDisplay)
        
        _mask = createCircle()
        _contents.mask = _mask
        
        _mask.x = stageWidth  / 2
        _mask.y = stageHeight / 2
        _maskDisplay.x = stageWidth  / 2
        _maskDisplay.y = stageHeight / 2
        
        touchQuad.addEventListener("onTouch:", atObject: self, forType: SPEventTypeTouch)
    }
    
    private dynamic func onTouch(event: SPTouchEvent) {
        if let touch = event.touches.first {
            if touch.phase == .Began || touch.phase == .Moved {
                let localPos = touch.locationInSpace(self)
                
                _mask.x = localPos.x
                _mask.y = localPos.y
                _maskDisplay.x = localPos.x
                _maskDisplay.y = localPos.y
            }
        }
    }
    
    private func createCircle() -> SPCanvas {
        let circle = SPCanvas()
        circle.beginFill(SPColorRed)
        circle.drawCircleWithX(0, y: 0, radius: 100)
        circle.endFill()
        return circle
    }
}
