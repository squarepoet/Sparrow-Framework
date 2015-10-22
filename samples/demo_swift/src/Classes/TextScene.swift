//
//  TextScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation
import Sparrow

class TextScene: Scene {
    required init() {
        super.init()
        
        let offset: Float = 10
        
        let colorTF = SPTextField(width: 300, height: 60,
            text: "TextFields can have a border and a color.")
        colorTF.x = offset
        colorTF.y = offset
        colorTF.border = true
        colorTF.color = 0x333399
        addChild(colorTF)
        
        let leftTF = SPTextField(width: 145, height: 80,
            text: "Text can be aligned in different ways, e.g. top-left ...")
        leftTF.x = offset
        leftTF.y = colorTF.y + colorTF.height + offset
        leftTF.hAlign = .Left
        leftTF.vAlign = .Top
        leftTF.border = true
        leftTF.color = 0x993333
        addChild(leftTF)
        
        let rightTF = SPTextField(width: 145, height: 80,
            text: "... or bottom right ...")
        rightTF.x = 2*offset + leftTF.width
        rightTF.y = colorTF.y + colorTF.height + offset
        rightTF.hAlign = .Right
        rightTF.vAlign = .Bottom
        rightTF.color = 0x228822
        rightTF.border = true
        addChild(rightTF)
        
        let fontTF = SPTextField(width: 300, height: 100,
            text: "... or centered. And of course the type of font and the size are arbitrary.")
        fontTF.x = offset
        fontTF.y = leftTF.y + leftTF.height + offset
        fontTF.hAlign = .Center
        fontTF.vAlign = .Center
        fontTF.fontSize = 18
        fontTF.fontName = "Georgia-Bold"
        fontTF.border = true
        fontTF.color = 0x0
        addChild(fontTF)
        
        // Bitmap fonts
        
        // First, you will need to create a bitmap font texture.
        //
        // E.g. with this tool: www.angelcode.com/products/bmfont/ or one that uses the same
        // data format. Export the font data as an XML file, and the texture as a png with white
        // characters on a transparent background (32 bit).
        //
        // Then, you just have to call the following method:
        // (the returned font name is the one that is defined in the font XML.)
        let bmpFontName = SPTextField.registerBitmapFontFromFile("desyrel.fnt")
        
        // That's it! If you use this font now, the textField will be rendered with the bitmap font.
        let bmpFontTF = SPTextField(width: 300, height: 150,
            text: "It is very easy to use Bitmap fonts, as well!")
        bmpFontTF.fontSize = SPNativeFontSize // use the native bitmap font size, no scaling
        bmpFontTF.fontName = bmpFontName
        bmpFontTF.color = SPColorWhite // use white if you want to use the texture as it is
        bmpFontTF.hAlign = .Center
        bmpFontTF.vAlign = .Center
        bmpFontTF.kerning = true
        bmpFontTF.x = offset
        bmpFontTF.y = fontTF.y + fontTF.height + offset
        addChild(bmpFontTF)
        
        // A tip: you can add the font-texture to your standard texture atlas, and reference it from
        // there. That way, you save texture space, and avoid another texture-switch.
    }
    
    deinit {
        // when you are done with it, you should unregister your bitmap font.
        // (Only if you no longer need it!)
        SPTextField.unregisterBitmapFont("Desyrel")
    }
}