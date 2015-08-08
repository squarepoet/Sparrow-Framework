//
//  Sprite3DScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class Sprite3DScene: Scene {
    private var _cube: SPSprite3D!
    
    required init() {
        super.init()
        
        let texture = SPTexture(contentsOfFile: "gamua_logo.png")
        _cube = createCube(texture)
        _cube.x = CENTER_X
        _cube.y = CENTER_Y
        _cube.z = 100
        addChild(_cube)
        
        addEventListener("start", atObject: self, forType: SPEventTypeAddedToStage)
        addEventListener("stop", atObject: self, forType: SPEventTypeRemovedFromStage)
    }
    
    private dynamic func start() {
        Sparrow.juggler()!.tweenWithTarget(_cube, time: 6, properties: ["rotationX" : TWO_PI, "repeatCount" : 0])
        Sparrow.juggler()!.tweenWithTarget(_cube, time: 7, properties: ["rotationY" : TWO_PI, "repeatCount" : 0])
        Sparrow.juggler()!.tweenWithTarget(_cube, time: 8, properties: ["rotationZ" : TWO_PI, "repeatCount" : 0])
    }
    
    private dynamic func stop() {
        Sparrow.juggler()!.removeObjectsWithTarget(_cube)
    }
    
    private func createCube(texture: SPTexture) -> SPSprite3D {
        let offset = texture.width / 2.0
        
        let front = createSideWall(texture, color: 0xff0000)
        front.z = -offset
        
        let back = createSideWall(texture, color: 0x00ff00)
        back.rotationX = PI
        back.z = offset
        
        let top = createSideWall(texture, color: 0x0000ff)
        top.y = -offset
        top.rotationX = PI / -2.0
        
        let bottom = createSideWall(texture, color: 0xffff00)
        bottom.y = offset
        bottom.rotationX = PI / 2.0
        
        let left = createSideWall(texture, color: 0xff00ff)
        left.x = -offset
        left.rotationY = PI / 2.0
        
        let right = createSideWall(texture, color: 0x00ffff)
        right.x = offset
        right.rotationY = PI / -2.0
        
        let cube = SPSprite3D()
        cube.addChild(front)
        cube.addChild(back)
        cube.addChild(top)
        cube.addChild(bottom)
        cube.addChild(left)
        cube.addChild(right)
        return cube
    }
    
    private func createSideWall(texture: SPTexture, color: uint) -> SPSprite3D {
        let image = SPImage(texture: texture)
        image.color = color
        image.alignPivotToCenter()
        
        let sprite = SPSprite3D()
        sprite.addChild(image)
        return sprite
    }
    
    override func render(support: SPRenderSupport) {
        // Sparrow does not make any depth-tests, so we use a trick in order to only show
        // the front quads: we're activating backface culling, i.e. we hide triangles at which
        // we look from behind.
        
        glEnable(GLenum(GL_CULL_FACE))
        glCullFace(GLenum(GL_FRONT))
        super.render(support)
        glDisable(GLenum(GL_CULL_FACE))
    }
}
