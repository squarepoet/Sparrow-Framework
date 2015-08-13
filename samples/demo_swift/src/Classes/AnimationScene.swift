//
//  AnimationScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class AnimationScene: Scene {
    private var _startButton: SPButton!
    private var _delayButton: SPButton!
    private var _egg: SPImage!
    private var _transitionLabel: SPTextField!
    private var _transitions: [String] = []
    
    required init() {
        super.init()
        
        // define some sample transitions for the animation demo. There are more available!
        _transitions = [SPTransitionLinear, SPTransitionEaseInOut, SPTransitionEaseOutBack,
                        SPTransitionEaseOutBounce, SPTransitionEaseOutElastic]
        
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        
        // we create a button that is used to start the tween.
        _startButton = SPButton(upState: buttonTexture, text: "Start animation")
        _startButton.addEventListener("onStartButtonPressed:", atObject: self,
            forType: SPEventTypeTriggered)
        _startButton.x = 160 - floor(_startButton.width) / 2
        _startButton.y = 20
        addChild(_startButton)
        
        // this button will show you how to call a method with a delay
        _delayButton = SPButton(upState: buttonTexture, text: "Delayed call")
        _startButton.addEventListener("onDelayButtonPressed:", atObject: self,
            forType: SPEventTypeTriggered)
        _delayButton.x = _startButton.x
        _delayButton.y = _startButton.y + 40
        addChild(_delayButton)
        
        // the egg image will be tweened.
        _egg = SPImage(contentsOfFile: "sparrow_front.png")
        resetEgg()
        addChild(_egg)
        
        _transitionLabel = SPTextField()
        _transitionLabel.color = 0x0
        _transitionLabel.x = 0
        _transitionLabel.y = _delayButton.y + 40
        _transitionLabel.width = 320
        _transitionLabel.height = 30
        _transitionLabel.alpha = 0.0 // invisible, will be shown later
        addChild(_transitionLabel)
    }
    
    deinit {
        _startButton.removeEventListenersAtObject(self, forType: SPEventTypeTriggered)
        _delayButton.removeEventListenersAtObject(self, forType: SPEventTypeTriggered)
    }
    
    private func resetEgg() {
        _egg.x = 15
        _egg.y = 100
        _egg.scale = 1.0
        _egg.rotation = 0.0
    }
    
    private dynamic func onStartButtonPressed(event: SPEvent) {
        _startButton.enabled = false
        resetEgg()
        
        // get next transition style from array and enqueue it at the end
        let transition = _transitions[0]
        _transitions.removeAtIndex(0)
        _transitions.append(transition)
        
        // to animate any numeric property of an arbitrary object (not just display objects!), you
        // can create a 'Tween'. One tween object animates one target for a certain time, with
        // a certain transition function.
        let tween = SPTween(target: _egg, time: 2.0, transition: transition)
        
        // you can animate any property as long as it's numeric (float, double, int).
        // it is animated from it's current value to a target value.
        tween.moveToX(305, y: 365)
        tween.scaleTo(0.5)
        tween.animateProperty("rotation", targetValue: PI_HALF)
        
        tween.onComplete = { self._startButton.enabled = true }
        
        // the tween alone is useless -- once in every frame, it has to be advanced, so that the
        // animation occurs. This is done by the 'Juggler'. It receives the tween and will use it to
        // animate the object.
        // There is a default juggler at the stage, but you can create your own jugglers, as well.
        // That way, you can group animations into logical parts.
        Sparrow.juggler()!.addObject(tween)
        
        // show which tweening function is used
        _transitionLabel.text = transition
        _transitionLabel.alpha = 1.0
        
        // hide
        Sparrow.juggler()!.tweenWithTarget(_transitionLabel, time: 2.0, properties: [
            "transition" : SPTransitionEaseIn,
            "alpha" : 0.0 ])
    }
    
    private dynamic func onDelayButtonPressed(event: SPEvent) {
        _delayButton.enabled = false
        
        // Using the juggler, you can delay a method call.
        //
        // This is especially useful when used with your own juggler. Assume your game has one class
        // that handles the playing field. This class has its own juggler, and advances it in every
        // frame. (By calling [myJuggler advanceTime:]).
        // All animations and delayed calls (!) within the playing field are added to this
        // juggler. Now, when the game is paused, all you have to do is *not* to advance this juggler.
        // Everything will be paused: animations as well as the delayed calls.
        //
        // the method [SPJuggler delayInvocationAtTarget:byTime:] returns a proxy object. Call
        // the method you would like to call on this proxy object instead of the real method target.
        // In this sample, [self colorizeEgg:] will be called after the specified delay.
        
        let juggler = Sparrow.juggler()!
        juggler.delayInvocationAtTarget(self, byTime: 1.0).colorizeEgg(true)
        juggler.delayInvocationAtTarget(self, byTime: 2.0).colorizeEgg(false)
    }
    
    private dynamic func colorizeEgg(colorize: Bool) {
        if colorize { _egg.color = 0xff3333 } // 0xrrggbb
        else
        {
            _egg.color = 0xffffff // white, the standard color of a quad
            _delayButton.enabled = true
        }
    }
}
