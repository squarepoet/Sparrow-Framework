//
//  AsyncTextureScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class AsyncTextureScene: Scene {
    private var _fileButton: SPButton!
    private var _urlButton: SPButton!
    private var _fileImage: SPImage!
    private var _urlImage: SPImage!
    private var _logText: SPTextField!
    private var _movingQuad: SPQuad!
    
    required init() {
        super.init()
        
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        
        _fileButton = SPButton(upState: buttonTexture, text: "Load from File")
        _fileButton.x = 20
        _fileButton.y = 20
        _fileButton.addEventListener("onFileButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(_fileButton)
        
        _urlButton = SPButton(upState: buttonTexture, text: "Load from Web")
        _urlButton.x = 300 - _urlButton.width
        _urlButton.y = 20
        _urlButton.addEventListener("onUrlButtonTriggered:", atObject: self,
            forType: SPEventTypeTriggered)
        addChild(_urlButton)
        
        _logText = SPTextField(width: 280, height: 50, text: "", fontName: "Verdana", fontSize: 12, color: 0x0)
        _logText.x = 20
        _logText.y = _fileButton.y + _fileButton.height + 5
        addChild(_logText)
        
        // a continously moving quad proves that texture loading does not cause stuttering
        
        _movingQuad = SPQuad(width: 32, height: 12, color: 0xffffff)
        _movingQuad.alpha = 0.25
        _movingQuad.x = 20
        _movingQuad.y = _logText.y
        addChild(_movingQuad)
        
        Sparrow.juggler()!.tweenWithTarget(_movingQuad, time: 2.0, properties: [
            "x" : 300 - _movingQuad.width,
            "repeatCount" : 0,
            "reverse" : true ])
    }
    
    private dynamic func onFileButtonTriggered(event: SPEvent) {
        _fileImage?.visible = true
        _logText.text = "Loading texture ..."
        
        SPTexture.loadFromFile("async_local.png", generateMipmaps: false) { texture, outError in
            if let error = outError {
                self._logText.text = error.localizedDescription
            }
            else {
                self._logText.text = "File loaded successfully."
                
                if self._fileImage == nil
                {
                    self._fileImage = SPImage(texture: texture!)
                    self._fileImage.x = floor(self.stage!.width - texture!.width) / 2
                    self._fileImage.y = 110
                    self.addChild(self._fileImage)
                }
                else
                {
                    self._fileImage.visible = true
                    self._fileImage.texture = texture!
                }
            }
        }
    }
    
    private dynamic func onUrlButtonTriggered(event: SPEvent) {
        _urlImage?.visible = false
        _logText.text = "Loading texture ..."
        
        // If your texture name contains a suffix like "@2x", you can use
        // "[SPTexture loadTextureFromSuffixedURL:...]". In this case, we have
        // no control over the image name, so we assign the scale factor directly.
        
        let scale: Float = Sparrow.contentScaleFactor() == 1.0 ? 1.0 : 2.0 // we've got only 2 textures
        
        let url = scale == 1.0 ? NSURL(string: "http://i.imgur.com/24mT16x.png") :
                                 NSURL(string: "http://i.imgur.com/kE2Bqnk.png")
        
        SPTexture.loadFromURL(url!, generateMipmaps: false, scale: scale) { texture, outError in
            if let error = outError {
                self._logText.text = error.localizedDescription
            }
            else {
                self._logText.text = "File loaded successfully."
                
                if self._urlImage == nil
                {
                    self._urlImage = SPImage(texture: texture!)
                    self._urlImage.x = floor(self.stage!.width - texture!.width) / 2
                    self._urlImage.y = 275
                    self.addChild(self._urlImage)
                }
                else
                {
                    self._urlImage.visible = true
                    self._urlImage.texture = texture!
                }
            }
        }
    }
}
