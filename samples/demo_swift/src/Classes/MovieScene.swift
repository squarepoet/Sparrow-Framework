//
//  MovieScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class MovieScene: Scene {
    private var _movie: SPMovieClip!
    
    required init() {
        super.init()
        
        let description = "[Animation provided by angryanimator.com]"
        let infoText = SPTextField(width: 300, height: 30, text: description,
            fontName: "Verdana", fontSize: 13, color: 0x0)
        infoText.x = 10
        infoText.y = 10
        infoText.vAlign = .Top
        infoText.hAlign = .Center
        addChild(infoText)
        
        // all our animation textures are in the atlas
        let atlas = SPTextureAtlas(contentsOfFile: "atlas.xml")
        
        // add frames to movie
        let frames = atlas.texturesStartingWith("walk_")
        _movie = SPMovieClip(frames: frames, fps: 12)
        
        // add sounds
        let stepSound = SPSound(contentsOfFile: "step.caf")
        _movie.setSound(stepSound?.createChannel(), atIndex: 1)
        _movie.setSound(stepSound?.createChannel(), atIndex: 7)
        
        // move the clip to the center and add it to the stage
        _movie.x = CENTER_X - floor(_movie.width)  / 2
        _movie.y = CENTER_Y - floor(_movie.height) / 2
        addChild(_movie)
        
        // like any animation, the movie needs to be added to the juggler!
        // this is the recommended way to do that.
        addEventListener("onAddedToStage:", atObject: self, forType: SPEventTypeAddedToStage)
        addEventListener("onRemovedFromStage:", atObject: self, forType: SPEventTypeRemovedFromStage)
    }
    
    private dynamic func onAddedToStage(event: SPEvent) {
        Sparrow.juggler()!.addObject(_movie)
    }
    
    private dynamic func onRemovedFromStage(event: SPEvent) {
        Sparrow.juggler()!.removeObject(_movie)
    }
}