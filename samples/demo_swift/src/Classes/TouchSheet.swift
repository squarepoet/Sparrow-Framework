//
//  TouchSheet.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class TouchSheet: SPSprite {
    private var _quad: SPQuad!
    
    init(quad: SPQuad) {
        super.init()
        
        // move quad to center, so that scaling works like expected
        _quad = quad
        _quad.x = Float(Int(_quad.width))  / -2
        _quad.y = Float(Int(_quad.height)) / -2
        _quad.addEventListener("onTouchEvent:", atObject: self, forType: SPEventTypeTouch)
        addChild(_quad)
    }
    
    override convenience init() {
        self.init(quad: SPQuad())
    }
    
    deinit {
        // event listeners should always be removed to avoid memory leaks!
        _quad.removeEventListenersAtObject(self, forType: SPEventTypeTouch)
    }
    
    private dynamic func onTouchEvent(event: SPTouchEvent) {
        let touches = Array<SPTouch>(event.touchesWithTarget(self, andPhase: .Moved))
        
        if touches.count == 1
        {
            // one finger touching -> move
            let touch = touches[0]
            let movement = touch.movementInSpace(parent!)
            
            self.x += movement.x
            self.y += movement.y
        }
        else if touches.count >= 2
        {
            // two fingers touching -> rotate and scale
            let touch1 = touches[0]
            let touch2 = touches[1]
            
            let touch1PrevPos = touch1.previousLocationInSpace(parent!)
            let touch1Pos = touch1.locationInSpace(parent!)
            let touch2PrevPos = touch2.previousLocationInSpace(parent!)
            let touch2Pos = touch2.locationInSpace(parent!)
            
            let prevVector = touch1PrevPos.subtractPoint(touch2PrevPos)
            let vector = touch1Pos.subtractPoint(touch2Pos)
            
            // update pivot point based on previous center
            let touch1PrevLocalPos = touch1.previousLocationInSpace(self)
            let touch2PrevLocalPos = touch2.previousLocationInSpace(self)
            pivotX = (touch1PrevLocalPos.x + touch2PrevLocalPos.x) * 0.5
            pivotY = (touch1PrevLocalPos.y + touch2PrevLocalPos.y) * 0.5
            
            // update location based on the current center
            x = (touch1Pos.x + touch2Pos.x) * 0.5
            y = (touch1Pos.y + touch2Pos.y) * 0.5
            
            let angleDiff = vector.angle - prevVector.angle
            rotation += angleDiff
            
            let sizeDiff = vector.length / prevVector.length
            scale = max(0.5, scaleX * sizeDiff)
        }
    }
}
