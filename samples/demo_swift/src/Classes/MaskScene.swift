//
//  MaskScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class MaskScene: Scene {
    private var _clipButton: SPButton!
    private var _contents: SPSprite!
    private var _mask: SPCanvas!
    private var _maskDisplay: SPCanvas!
    private var _clipRect: SPRectangle!
    private var _clipDisplay: SPQuad!
    
    required init() {
        super.init()
        
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        
        _clipButton = SPButton(upState: buttonTexture, text: "Use Clip-Rect")
        _clipButton.addEventListener("onClipButtonPressed:", atObject: self, forType: SPEventTypeTriggered)
        _clipButton.x = 160 - floor(_clipButton.width) / 2
        _clipButton.y = 20
        addChild(_clipButton)
        
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
        
        _clipRect = SPRectangle(x: 0, y: 0, width: 150, height: 150)
        _clipRect.x = (stageWidth - _clipRect.width)   / 2
        _clipRect.y = (stageHeight - _clipRect.height) / 2 + 5
        
        _clipDisplay = SPQuad(width: _clipRect.width, height: _clipRect.height, color: SPColorRed)
        _clipDisplay.x = _clipRect.x
        _clipDisplay.y = _clipRect.y
        _clipDisplay.alpha = 0.1
        _clipDisplay.touchable = false
        
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
        
        addEventListener("onTouch:", atObject: self, forType: SPEventTypeTouch)
    }
    
    private dynamic func onClipButtonPressed(event: SPEvent) {
        if _contents.clipRect != nil {
            _contents.clipRect = nil
            _contents.mask = _mask
            
            _clipDisplay.removeFromParent()
            addChild(_maskDisplay)
            
            _clipButton.text = "Use Clip-Rect"
        }
        else {
            _contents.clipRect = _clipRect
            _contents.mask = nil
            
            _maskDisplay.removeFromParent()
            addChild(_clipDisplay)
            
            _clipButton.text = "Use Stencil Mask"
        }
    }
    
    private dynamic func onTouch(event: SPTouchEvent) {
        if let touch = event.touches.first {
            if touch.phase == .Began || touch.phase == .Moved {
                let localPos = touch.locationInSpace(self)
                
                _mask.x = localPos.x; _maskDisplay.x = localPos.x
                _mask.y = localPos.y; _maskDisplay.y = localPos.y
                
                let clipX = localPos.x - _clipRect.width  / 2
                let clipY = localPos.y - _clipRect.height  / 2
                
                _clipRect.x = clipX; _clipDisplay.x = clipX
                _clipRect.y = clipY; _clipDisplay.y = clipY
                
                if _contents.clipRect != nil {
                    _contents.clipRect = _clipRect
                }
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
