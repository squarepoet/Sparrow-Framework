//
//  BenchmarkScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

let FRAME_TIME_WINDOW_SIZE = 10
let MAX_FAIL_COUNT         = 100

class BenchmarkScene: Scene {
    private var _startButton: SPButton!
    private var _resultText: SPTextField!
    private var _statusText: SPTextField!
    private var _container: SPSprite!
    private var _objectPool: [SPDisplayObject] = []
    private var _objectTexture: SPTexture!
    
    private var _frameCount: Int = 0
    private var _failCount: Int = 0
    private var _started: Bool = false
    private var _frameTimes: [Double] = []
    private var _targetFps: Float = 0
    
    private var _phase: Int = 0
    
    required init() {
        super.init()
    
        // the container will hold all test objects
        _container = SPSprite()
        _container.x = CENTER_X
        _container.y = CENTER_Y
        _container.touchable = false // we do not need touch events on the test objects --
                                     // thus, it is more efficient to disable them.
        addChild(_container, atIndex: 0)
        
        _statusText = SPTextField(width: GAME_WIDTH - 40, height: 30, text: "",
                                  fontName: SPBitmapFontMiniName, fontSize: SPNativeFontSize * 2, color: 0x0)
        _statusText.x = 20
        _statusText.y = 10
        addChild(_statusText)
        
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        _startButton = SPButton(upState: buttonTexture, text: "Start benchmark")
        _startButton.addEventListener("onStartButtonTriggered", atObject: self, forType: SPEventTypeTriggered)
        _startButton.x = CENTER_X - floor(_startButton.width / 2)
        _startButton.y = 20
        addChild(_startButton)
        
        _started = false
        _frameTimes = []
        _objectPool = []
        _objectTexture = SPTexture(contentsOfFile: "benchmark_object.png")
        
        _startButton.addEventListener("onEnterFrame:", atObject: self, forType: SPEventTypeEnterFrame)
    }
    
    deinit {
        removeEventListenersAtObject(self, forType: SPEventTypeEnterFrame)
        _startButton.removeEventListenersAtObject(self, forType: SPEventTypeTriggered)
    }
    
    dynamic func onStartButtonTriggered() {
        print("Starting benchmark")
        
        _startButton.visible = false
        _started = true
        _targetFps = Float(Sparrow.currentController()!.framesPerSecond)
        _frameCount = 0
        _failCount = 0
        _phase = 0
        
        for _ in 0 ... FRAME_TIME_WINDOW_SIZE {
            _frameTimes.append(1.0 / Double(_targetFps))
        }
        
        if _resultText != nil {
            _resultText.removeFromParent()
            _resultText = nil
        }
    }
    
    dynamic func onEnterFrame(event: SPEnterFrameEvent) {
        if !_started { return }
    
        _frameCount++
        _container.rotation += Float(event.passedTime) * 0.5
        
        _frameTimes.append(0)
        for i in 0 ..< FRAME_TIME_WINDOW_SIZE {
            _frameTimes[i] += event.passedTime
        }
        
        let measuredFps = Float(FRAME_TIME_WINDOW_SIZE) / Float(_frameTimes.removeFirst())
        
        if _phase == 0 {
            if measuredFps < 0.985 * _targetFps {
                _failCount++
            
                if _failCount == MAX_FAIL_COUNT {
                    _phase = 1
                }
            }
            else {
                addTestObjects(16)
                _container.scale *= 0.99
                _failCount = 0
            }
        }
        if _phase == 1 {
            if measuredFps > 0.99 * _targetFps {
                _failCount--
        
                if _failCount == 0 {
                    benchmarkComplete()
                }
            }
        else {
            removeTestObjects(1)
            _container.scale /= 0.9993720513 // 0.99 ^ (1/16)
        }
    }
    
        if _frameCount % Int(_targetFps / 4) == 0 {
            _statusText.text = "\(_container.numChildren) objects"
        }
    }
    
    func addTestObjects(count: Int) {
        let scale = 1.0 / _container.scale
    
        for _ in 0 ..< count {
            let egg = getObjectFromPool()
            let distance = (100 + SPUtils.randomFloat() * 100) * scale
            let angle = SPUtils.randomFloat() * PI * 2.0
            
            egg.x = cos(angle) * distance
            egg.y = sin(angle) * distance
            egg.rotation = angle + PI / 2.0
            egg.scale = scale
            
            _container.addChild(egg)
        }
    }
    
    func removeTestObjects(var count: Int) {
        let numChildren = _container.numChildren
    
        if count >= numChildren {
            count = numChildren
        }
    
        for _ in 0 ..< count {
            let last = _container.children.last!
            _container.removeChildAtIndex(_container.numChildren-1)
            putObjectToPool(last)
        }
    }
    
    func getObjectFromPool() -> SPDisplayObject {
        // we pool mainly to avoid any garbage collection while the benchmark is running
        
        if _objectPool.count == 0 {
            let image = SPImage(texture: _objectTexture)
            image.alignPivotToCenter()
            return image
        }
        else {
            return _objectPool.removeLast()
        }
    }
    
    func putObjectToPool(object: SPDisplayObject) {
        _objectPool.append(object)
    }
    
    func benchmarkComplete() {
        _started = false
        _startButton.visible = true
        
        let fps = Sparrow.currentController()!.framesPerSecond
        let numChildren = _container.numChildren
        let resultString = "Result:\n\(numChildren) objects\nwith \(fps) fps"
        
        _resultText = SPTextField(width: 240, height: 200, text: resultString)
        _resultText.fontSize = 30
        _resultText.x = CENTER_X - _resultText.width / 2
        _resultText.y = CENTER_Y - _resultText.height / 2
        
        addChild(_resultText)
        
        _container.scale = 1.0
        _frameTimes.removeAll()
        _statusText.text = ""
    
        for i in numChildren-1 ... 0 {
            let child = _container[i]
            _container.removeChildAtIndex(i)
            putObjectToPool(child)
        }
    }
}
