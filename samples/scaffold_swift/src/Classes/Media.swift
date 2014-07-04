//
//  Media.swift
//  Scaffold
//
//  Ported from Media.h/m in non-Swift project
//

import Foundation

// XXX: class var not yet supported
var atlas: SPTextureAtlas! = nil
var sounds: NSMutableDictionary! = nil

class Media {
    
// MARK: Texture Atlas

    class func initAtlas() {
        if !atlas {
            atlas = SPTextureAtlas(contentsOfFile: "atlas.xml")
        }
    }
    
    class func releaseAtlas() {
        atlas = nil
    }
    
    class func atlasTexture(name: String!) -> SPTexture? {
        if !atlas {
            self.initAtlas()
        }
        return atlas.textureByName(name)
    }
    
    class func atlasTexturesWithPrefix(prefix: String!) -> SPTexture[]? {
        if !atlas {
            self.initAtlas()
        }
        return atlas.texturesStartingWith(prefix) as? SPTexture[]
    }

// MARK: Audio

    class func initSound() {
        if sounds { return }
    
        SPAudioEngine.start()
        sounds = NSMutableDictionary()
    
        // enumerate all sounds
    
        let soundDir = NSBundle.mainBundle().resourcePath
        let dirEnum = NSFileManager.defaultManager().enumeratorAtPath(soundDir)
    
        while let filename = dirEnum.nextObject() as? String {
            if filename.pathExtension == "caf" {
                let sound: SPSound? = SPSound(contentsOfFile: filename)
                sounds[filename] = sound
            }
        }
    }
    
    class func releaseSound() {
        sounds = nil
        SPAudioEngine.stop()
    }
    
    class func playSound(soundName: String!) {
        let sound:SPSound? = sounds?[soundName] as? SPSound
        
        if sound {
            sound!.play()
        } else {
            SPSound.soundWithContentsOfFile(soundName).play()
        }
    }
    
    class func soundChannel(soundName: String!) -> SPSoundChannel? {
        var sound: SPSound? = sounds?[soundName] as? SPSound
    
        // sound was not preloaded
        if !sound {
            sound = SPSound.soundWithContentsOfFile(soundName)
        }
        return sound?.createChannel()
    }
}
