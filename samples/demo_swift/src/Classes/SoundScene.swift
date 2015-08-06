//
//  SoundScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

let FONTNAME = "Helvetica-Bold"

class SoundScene: Scene {
    private var _musicChannel: SPSoundChannel!
    private var _soundChannel: SPSoundChannel!
    private var _channelButton: SPButton!
    
    required init() {
        super.init()
        
        // notice these lines in 'DemoAppDelegate!'
        // [SPAudioEngine start]
        // [SPAudioEngine stop]
        
        // Create music channel:
        
        let music = SPSound(contentsOfFile: "music.aifc")!
        _musicChannel = music.createChannel()
        _musicChannel.loop = true
        
        let sound = SPSound(contentsOfFile: "sound0.caf")!
        _soundChannel = sound.createChannel()
        _soundChannel.addEventListener("onSoundCompleted:", atObject: self,
            forType: SPEventTypeCompleted)
        
        let buttonTexture = SPTexture(contentsOfFile: "button_square.png")
        
        // music control
        
        let musicLabel = SPTextField(text: "Background Music (compressed)")
        musicLabel.x = 30
        musicLabel.y = 55
        musicLabel.fontName = FONTNAME
        musicLabel.width = 260
        musicLabel.height = 30
        addChild(musicLabel)
        
        let playButton = SPButton(upState: buttonTexture, text: ">")
        playButton.x = 80
        playButton.y = 105
        playButton.fontName = FONTNAME
        playButton.addEventListener("onPlayButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(playButton)
        
        let pauseButton = SPButton(upState: buttonTexture, text: "||")
        pauseButton.x = 140
        pauseButton.y = playButton.y
        pauseButton.fontName = FONTNAME
        pauseButton.addEventListener("onPauseButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(pauseButton)
        
        let stopButton = SPButton(upState: buttonTexture, text: "[]")
        stopButton.x = 200
        stopButton.y = playButton.y
        stopButton.fontName = FONTNAME
        stopButton.addEventListener("onStopButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(stopButton)
        
        // simple sound button
        
        let simpleLabel = SPTextField(text: "Simple")
        simpleLabel.x = 60
        simpleLabel.y = 180
        simpleLabel.fontName = FONTNAME
        simpleLabel.width = 80
        simpleLabel.height = 30
        addChild(simpleLabel)
        
        let simpleButton = SPButton(upState: buttonTexture, text: ">")
        simpleButton.x = 80
        simpleButton.y = 230
        simpleButton.fontName = FONTNAME
        simpleButton.addEventListener("onSimpleButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(simpleButton)
        
        // channel sound button
        
        let channelLabel = SPTextField(text: "Channel")
        channelLabel.x = 180
        channelLabel.y = simpleLabel.y
        channelLabel.fontName = FONTNAME
        channelLabel.width = 80
        channelLabel.height = 30
        addChild(channelLabel)
        
        _channelButton = SPButton(upState: buttonTexture, text: ">")
        _channelButton.x = 200
        _channelButton.y = simpleButton.y
        _channelButton.fontName = FONTNAME
        _channelButton.addEventListener("onChannelButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(_channelButton)
        
        // volume buttons
        
        let volumeLabel = SPTextField(text: "Master Volume")
        volumeLabel.x = 30
        volumeLabel.y = 305
        volumeLabel.fontName = FONTNAME
        volumeLabel.width = 260
        volumeLabel.height = 30
        addChild(volumeLabel)
        
        let volume0Button = SPButton(upState: buttonTexture, text: "0")
        volume0Button.x = 80
        volume0Button.y = 355
        volume0Button.fontName = FONTNAME
        volume0Button.addEventListener("onVolume0ButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(volume0Button)
        
        let volume50Button = SPButton(upState: buttonTexture, text: "50")
        volume50Button.x = 140
        volume50Button.y = volume0Button.y
        volume50Button.fontName = FONTNAME
        volume50Button.addEventListener("onVolume50ButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(volume50Button)
        
        let volume100Button = SPButton(upState: buttonTexture, text: "100")
        volume100Button.x = 200
        volume100Button.y = volume0Button.y
        volume100Button.fontName = FONTNAME
        volume100Button.addEventListener("onVolume100ButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(volume100Button)
    }
    
    deinit {
        // This is really IMPORTANT: either stop the sound or remove the event listener!!!
        // Otherwise the sound continues to play, and when it completes, the event handler will
        // already be garbage -> crash!
        _soundChannel.stop()
        
        // The music channel has no event listener attached, so technically, this call is not
        // necessary. But it's a good habit to stop any sound before releasing it (see above.)
        _musicChannel.stop()
    }
    
    private dynamic func onPlayButtonTriggered(event: SPEvent) {
        _musicChannel.play()
    }
    
    private dynamic func onPauseButtonTriggered(event: SPEvent) {
        _musicChannel.pause()
    }
    
    private dynamic func onStopButtonTriggered(event: SPEvent) {
        _musicChannel.stop()
    }
    
    private dynamic func onSimpleButtonTriggered(event: SPEvent) {
        // that's the easiest way to play a sound!
        SPSound(contentsOfFile: "sound1.caf")?.play()
    }
    
    private dynamic func onChannelButtonTriggered(event: SPEvent) {
        // we change the color to demonstrate the "onCompleted" feature
        _channelButton.fontColor = 0xff0000
        _soundChannel.play()
    }
    
    private dynamic func onVolume0ButtonTriggered(event: SPEvent) {
        SPAudioEngine.setMasterVolume(0)
    }
    
    private dynamic func onVolume50ButtonTriggered(event: SPEvent) {
        SPAudioEngine.setMasterVolume(0.5)
    }
    
    private dynamic func onVolume100ButtonTriggered(event: SPEvent) {
        SPAudioEngine.setMasterVolume(1.0)
    }
    
    private dynamic func onSoundCompleted(event: SPEvent) {
        _channelButton.fontColor = 0x0
    }
}
