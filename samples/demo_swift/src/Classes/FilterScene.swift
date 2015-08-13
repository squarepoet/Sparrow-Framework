//
//  FilterScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class FilterScene: Scene {
    private var _button: SPButton!
    private var _infoText: SPTextField!
    private var _image: SPImage!
    private var _filterInfos: [(String, SPFragmentFilter)]!
    
    required init() {
        super.init()
        
        let buttonTexture = SPTexture(contentsOfFile: "button_normal.png")
        
        _button = SPButton(upState: buttonTexture, text: "Switch Filter")
        _button.addEventListener("onButtonPressed:", atObject: self, forType: SPEventTypeTriggered)
        _button.x = CENTER_X - floor(_button.width) / 2
        _button.y = 15
        addChild(_button)
        
        _image = SPImage(contentsOfFile: "sparrow_rocket.png")
        _image.x = CENTER_X - floor(_image.width) / 2
        _image.y = 170
        addChild(_image)
        
        _infoText = SPTextField(width: 300, height: 32, text: "", fontName: "Verdana", fontSize: 19, color: 0x0)
        _infoText.x = 10
        _infoText.y = 330
        addChild(_infoText)
        
        initFilters()
        onButtonPressed(SPTouchEvent())
    }
    
    private dynamic func onButtonPressed(event: SPTouchEvent) {
        let text   = _filterInfos[0].0
        let filter = _filterInfos[0].1
        
        _filterInfos.removeAtIndex(0)
        _filterInfos.append((text, filter))
        
        _infoText.text = text
        _image.filter = filter
    }
    
    private func initFilters() {
        _filterInfos = [
            ("Identity", SPColorMatrixFilter()),
            ("Blur", SPBlurFilter()),
            ("Drop Shadow", SPBlurFilter.dropShadow()),
            ("Glow", SPBlurFilter.glow())
        ]
        
        let noiseTexture = SPTexture(contentsOfFile: "noise.jpg")
        let dispMapFilter = SPDisplacementMapFilter(mapTexture: noiseTexture)
        dispMapFilter.componentX = .Red
        dispMapFilter.componentY = .Green
        dispMapFilter.scaleX = 25
        dispMapFilter.scaleY = 25
        _filterInfos.append(("Displacement Map", dispMapFilter))
        
        let invertFilter = SPColorMatrixFilter()
        invertFilter.invert()
        _filterInfos.append(("Invert", invertFilter))
        
        let grayscaleFilter = SPColorMatrixFilter()
        grayscaleFilter.adjustSaturation(-1)
        _filterInfos.append(("Grayscale", grayscaleFilter))
        
        let saturationFilter = SPColorMatrixFilter()
        saturationFilter.adjustSaturation(1)
        _filterInfos.append(("Saturation", saturationFilter))
        
        let contrastFilter = SPColorMatrixFilter()
        contrastFilter.adjustContrast(0.75)
        _filterInfos.append(("Contrast", contrastFilter))
        
        let brightnessFilter = SPColorMatrixFilter()
        brightnessFilter.adjustContrast(-0.25)
        _filterInfos.append(("Brightness", brightnessFilter))
        
        let hueFilter = SPColorMatrixFilter()
        hueFilter.adjustHue(1)
        _filterInfos.append(("Hue", hueFilter))
    }
}
