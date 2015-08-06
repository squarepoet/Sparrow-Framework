//
//  RenderTextureScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class RenderTextureScene: Scene {
    private var _renderTexture: SPRenderTexture!
    private var _brush: SPImage!
    private var _button: SPButton!
    private var _colors: Dictionary<Int, uint> = [:]
    
    required init() {
        super.init()
        
        // we load the "brush" image from disk
        _brush = SPImage(contentsOfFile: "brush.png")
        _brush.pivotX = floor(_brush.width  / 2)
        _brush.pivotY = floor(_brush.height / 2)
        _brush.blendMode = SPBlendModeNormal
        
        // the render texture is a dyanmic texture. We will draw the egg on that texture on
        // every touch event.
        _renderTexture = SPRenderTexture(width: 320, height: 435)
        
        // the canvas image will display the render texture
        let canvas = SPImage(texture: _renderTexture)
        canvas.addEventListener("onTouch:", atObject: self, forType: SPEventTypeTouch)
        addChild(canvas)
        
        // we draw a text into that canvas
        let infoText = SPTextField(width: 256, height: 128,
            text: "Touch the screen\nto draw!", fontName: "Verdana", fontSize: 24, color: 0x0)
        infoText.x = CENTER_X - infoText.width / 2
        infoText.y = CENTER_Y - infoText.height / 2
        _renderTexture.drawObject(infoText)
        
        // add a button to let the user switch between "draw" and "erase" mode
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        _button = SPButton(upState: buttonTexture, text: "Mode: Draw")
        _button.x = floor(CENTER_X - _button.width / 2)
        _button.y = 15
        _button.addEventListener("onButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(_button)
    }
    
    private dynamic func onButtonTriggered(event: SPEvent) {
        if _brush.blendMode == SPBlendModeNormal {
            _brush.blendMode = SPBlendModeErase
            _button.text = "Mode: Erase"
        } else {
            _brush.blendMode = SPBlendModeNormal
            _button.text = "Mode: Draw"
        }
    }
    
    private dynamic func onTouch(event: SPTouchEvent) {
        let allTouches = event.touchesWithTarget(self)
        
        _renderTexture.drawBundled() {
            for touch in allTouches {
                let touchID = touch.touchID
                
                // don't draw on 'finger up'
                if touch.phase == .Ended
                {
                    self._colors.removeValueForKey(touchID)
                    continue
                }
                
                if touch.phase == .Began {
                    self._colors[touchID] = uint(SPUtils.randomIntBetweenMin(0, andMax: 0xffffff))
                }
                
                // find out location of touch event
                let currentLocation = touch.locationInSpace(self)
                
                // center brush over location
                self._brush.x = currentLocation.x
                self._brush.y = currentLocation.y
                self._brush.color = self._colors[touchID]!
                self._brush.rotation = SPUtils.randomFloat() * TWO_PI
                
                // draw brush to render texture
                self._renderTexture.drawObject(self._brush)
            }
        }
    }
}
