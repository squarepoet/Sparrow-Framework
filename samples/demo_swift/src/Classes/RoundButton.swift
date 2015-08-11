//
//  RoundButton.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class RoundButton: SPButton {
    override init(upState: SPTexture) {
        super.init(upState: upState, downState: nil, disabledState: nil)
    }
    
    override func hitTestPoint(localPoint: SPPoint, forTouch: Bool = false) -> SPDisplayObject? {
        // when the user touches the screen, this method is used to find out if it hit an object.
        // by default, this method uses the bounding box.
        // by overriding this method, we can change the box (rectangle) to a circle (or whatever
        // necessary).
        
        // invisible or untouchable objects must cause the hit test to fail.
        if forTouch && (!visible || !touchable) {
            return nil
        }
        
        // get center of button
        let bounds = self.bounds
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        // calculate distance of localPoint to center.
        // we keep it squared, since we want to avoid the 'sqrt()'-call.
        let sqDist = (localPoint.x - centerX) * (localPoint.x - centerX) +
                     (localPoint.y - centerY) * (localPoint.y - centerY)
        
        // when the squared distance is smaller than the squared radius, the point is inside
        // the circle
        let radius = bounds.width / 2 * 0.9
        if sqDist < radius * radius { return self }
        else { return nil }
    }
}
