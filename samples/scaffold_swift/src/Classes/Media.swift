//
//  Media.swift
//  Scaffold
//
//  Ported from Media.h/m in non-Swift project
//

import Foundation
import Sparrow

// XXX: class var not yet supported
var atlas: SPTextureAtlas! = nil
var sounds: Dictionary<String, SPSound>! = nil

class Media {
    
// MARK: Texture Atlas

    class func initAtlas() {
        if atlas == nil {
            atlas = SPTextureAtlas(contentsOfFile: "atlas.xml")
        }
    }
    
    class func releaseAtlas() {
        atlas = nil
    }
    
    class func atlasTexture(name: String!) -> SPTexture? {
        if atlas == nil { self.initAtlas() }
        return atlas.textureByName(name)
    }
    
    class func atlasTexturesWithPrefix(prefix: String!) -> [SPTexture] {
        if atlas == nil { self.initAtlas() }
        return atlas.texturesStartingWith(prefix)
    }

// MARK: Audio

    class func initSound() {
        if sounds != nil { return }
    
        SPAudioEngine.start()
        sounds = [:]
    
        // enumerate all sounds
        if let soundDir = NSBundle.mainBundle().resourcePath,
            let dirEnum = NSFileManager.defaultManager().enumeratorAtPath(soundDir) {
                while let filename = dirEnum.nextObject() as? String {
                    if (filename as NSString).pathExtension == "caf" {
                        if let sound = SPSound(contentsOfFile: filename) {
                            sounds[filename] = sound
                        }
                    }
                }
        }
    }
    
    class func releaseSound() {
        sounds = nil
        SPAudioEngine.stop()
    }
    
    class func playSound(soundName: String) {
        if let sound = sounds[soundName] {
            sound.play()
        } else {
            SPSound(contentsOfFile: soundName)?.play()
        }
    }
    
    class func soundChannel(soundName: String) -> SPSoundChannel? {
        if let sound = sounds[soundName] {
            return sound.createChannel()
        } else {
            return SPSound(contentsOfFile: soundName)?.createChannel()
        }
    }
}
