//
//  BenchmarkScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class BenchmarkScene: Scene {
    private var _startButton: SPButton!
    private var _resultText: SPTextField!
    private var _texture: SPTexture!
    private var _container: SPSprite!
    private var _frameCount: Int = 0
    private var _elapsed: Double = 0
    private var _started: Bool = false
    private var _failCount: Int = 0
    private var _waitFrames: Int = 0
    
    required init() {
        super.init()
        
        _texture = SPTexture(contentsOfFile: "benchmark_object.png")
        
        // the container will hold all test objects
        _container = SPSprite()
        _container.touchable = false // we do not need touch events on the test objects -- thus,
                                     // it is more efficient to disable them.
        addChild(_container, atIndex: 0)
        
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        
        // we create a button that is used to start the benchmark.
        _startButton = SPButton(upState: buttonTexture, text: "Start benchmark")
        _startButton.addEventListener("onStartButtonPressed:", atObject: self, forType: SPEventTypeTriggered)
        _startButton.x = 160 - floor(_startButton.width / 2)
        _startButton.y = 20
        addChild(_startButton)
        
        addEventListener("onEnterFrame:", atObject: self, forType: SPEventTypeEnterFrame)
    }
    
    deinit {
        removeEventListenersAtObject(self, forType: SPEventTypeEnterFrame)
        _startButton.removeEventListenersAtObject(self, forType: SPEventTypeTriggered)
    }
    
    private dynamic func onEnterFrame(event: SPEnterFrameEvent) {
        if !_started { return }
        
        _elapsed += event.passedTime
        ++_frameCount
        
        if _frameCount % _waitFrames == 0 {
            let targetFPS = Float(Sparrow.currentController()!.framesPerSecond)
            let realFPS   = Float(_waitFrames) / Float(_elapsed)
            
            if ceilf(realFPS) >= targetFPS {
                let numObjects = _failCount != 0 ? 5 : 25
                addTestObjects(numObjects)
                _failCount = 0
            }
            else {
                ++_failCount
                
                if (_failCount > 15) {
                    _waitFrames = 5 // slow down creation process to be more exact
                }
                if (_failCount > 20) {
                    _waitFrames = 10
                }
                if (_failCount == 25) {
                    benchmarkComplete() // target fps not reached for a while
                }
            }
            
            _elapsed = 0
            _frameCount = 0
        }
        
        for child in _container.children {
            child.rotation += 0.05
        }
    }
    
    private dynamic func onStartButtonPressed(event: SPEvent) {
        print("starting benchmark")
        
        _startButton.visible = false
        _started = true
        _failCount = 0
        _waitFrames = 3
        
        _resultText?.removeFromParent()
        _resultText = nil
        
        _frameCount = 0
        addTestObjects(500)
    }
    
    private func benchmarkComplete() {
        _started = false
        _startButton.visible = true
        
        let frameRate = Int(Sparrow.currentController()!.framesPerSecond)
        
        print("benchmark complete!")
        print("fps: \(frameRate)")
        print("number of objects: \(_container.numChildren)")
        
        let resultString = "Result:\n\(_container.numChildren) objects\nwith \(frameRate) fps"
        
        _resultText = SPTextField(width: 250, height: 200, text: resultString)
        _resultText.fontSize = 30
        _resultText.color = 0x0
        _resultText.x = (320 - _resultText.width) / 2
        _resultText.y = (480 - _resultText.height) / 2
        addChild(_resultText)
        
        _container.removeAllChildren()
    }
    
    private func addTestObjects(numObjects: Int) {
        let border: Float = 15
        
        for _ in 0 ..< numObjects {
            let egg = SPImage(texture: _texture)
            egg.x = SPUtils.randomFloatBetweenMin(border, andMax: GAME_WIDTH  - border)
            egg.y = SPUtils.randomFloatBetweenMin(border, andMax: GAME_HEIGHT - border)
            egg.rotation = SPUtils.randomFloat() * TWO_PI
            _container.addChild(egg)
        }
    }
}
