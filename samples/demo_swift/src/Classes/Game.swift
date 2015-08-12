//
//  Game.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class Game: SPSprite {
    private var _currentScene: Scene!
    private var _mainMenu: SPSprite!
    private var _offsetY: Float = 0
    
    override init() {
        super.init()
        
        // make simple adjustments for iPhone 5+ screens:
        _offsetY = (Sparrow.stage()!.height - 480) / 2
        
        // add background image
        let background = SPImage(contentsOfFile: "background.jpg")
        background.y = _offsetY > 0.0 ? 0.0 : -44
        background.blendMode = SPBlendModeNone
        addChild(background)
        
        // this sprite will contain objects that are only visible in the main menu
        _mainMenu = SPSprite()
        _mainMenu.y = _offsetY
        addChild(_mainMenu)
        
        let logo = SPImage(contentsOfFile: "logo.png")
        logo.y = _offsetY + 5
        _mainMenu.addChild(logo)
        
        // choose which scenes will be accessible
        let scenesToCreate: [(String, Scene.Type)] = [
            ("Textures", TexturesScene.self),
            ("Async Textures", AsyncTextureScene.self),
            ("Multitouch", TouchScene.self),
            ("TextFields", TextScene.self),
            ("Animations", AnimationScene.self),
            ("Custom Hit-Test", CustomHitTestScene.self),
            ("Movie Clip", MovieScene.self),
            ("Sound", SoundScene.self),
            ("Masking", MaskScene.self),
            ("Filters", FilterScene.self),
            ("Sprite3D", Sprite3DScene.self),
            ("RenderTexture", RenderTextureScene.self),
            ("Benchmark", BenchmarkScene.self),
        ]
        
        let buttonTexture = SPTexture(contentsOfFile: "button_medium.png")
        var count = 0
        var index = 0
        
        // create buttons for each scene
        while (index < scenesToCreate.count)
        {
            let sceneTitle = scenesToCreate[index].0
            let sceneClass = scenesToCreate[index].1
            index++
            
            let button = SPButton(upState: buttonTexture, text: sceneTitle)
            button.x = count % 2 == 0 ? 28 : 167
            button.y = _offsetY + 150 + Float(count / 2) * 46
            button.name = NSStringFromClass(sceneClass)
            
            if (scenesToCreate.count*2) % 2 != 0 && count % 2 == 1 {
                button.y += 26
            }
            
            button.addEventListener("onButtonTriggered:", atObject: self,
                forType: SPEventTypeTriggered)
            _mainMenu.addChild(button)
            ++count
        }
        
        addEventListener("onSceneClosing:", atObject: self, forType: EventTypeSceneClosing)
    }
    
    private dynamic func onButtonTriggered(event: SPEvent) {
        if _currentScene != nil { return }
        
        // the class name of the scene is saved in the "name" property of the button.
        let button = event.target as! SPButton
        let sceneClass = NSClassFromString(button.name!) as! Scene.Type
        
        // create an instance of that class and add it to the display tree.
        _currentScene = sceneClass.init()
        _currentScene.y = _offsetY
        _mainMenu.visible = false
        addChild(_currentScene)
    }
    
    private dynamic func onSceneClosing(event: SPEvent) {
        _currentScene.removeFromParent()
        _currentScene = nil
        _mainMenu.visible = true
    }
}
