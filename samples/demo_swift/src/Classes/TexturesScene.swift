//
//  TexturesScene.swift
//  Demo
//
//  Created by Robert Carone on 8/6/15.
//
//

import Foundation

class TexturesScene: Scene {
    required init() {
        super.init()
        
        // texture atlas
        //
        // create a texture atlas e.g. with the 'atlas_generator' that's part of Sparrow, e.g.:
        // ./generate_atlas.rb input/*.png atlas.xml
        
        let atlas = SPTextureAtlas(contentsOfFile: "atlas.xml")
        print("found \(atlas.numTextures) textures.")
        
        let image1 = SPImage(texture: atlas.textureByName("walk_00")!)
        image1.x = 30
        image1.y = 20
        addChild(image1)
        
        let image2 = SPImage(texture: atlas.textureByName("walk_01")!)
        image2.x = 90
        image2.y = 50
        addChild(image2)
        
        let image3 = SPImage(texture: atlas.textureByName("walk_03")!)
        image3.x = 150
        image3.y = 80
        addChild(image3)
        
        let image4 = SPImage(texture: atlas.textureByName("walk_05")!)
        image4.x = 210
        image4.y = 110
        addChild(image4)
        
        let atlasText = SPTextField(width: 128, height: 40,
            text: "Load textures from an atlas!", fontName: "Helvetica", fontSize: 14, color: SPColorBlack)
        atlasText.bold = true
        atlasText.x = 140
        atlasText.y = 30
        atlasText.hAlign = .Right
        addChild(atlasText)
        
        // pvrtc texture
        //
        // create compressed PVR textures with the 'texturetool' (part of the iOS SDK), e.g.:
        // texturetool -m -e PVRTC -f PVR -p preview.png -o texture.pvr texture.png
        
        let logoPvrtc = SPImage(contentsOfFile: "logo_rect_tc.pvr")
        logoPvrtc.x = 172
        logoPvrtc.y = 300
        addChild(logoPvrtc)
        
        // pvr texture, gzip-compressed
        //
        // compress a PVR texture with gzip to save space, e.g.:
        // gzip texture.pvr (-> creates texture.pvr.gz)
        
        let logoPvrGz = SPImage(contentsOfFile: "logo_rect.pvr.gz")
        logoPvrGz.x = 96
        logoPvrGz.y = 260
        addChild(logoPvrGz)
        
        // pvr texture
        //
        // create uncompressed PVR textures with the PVRTexTool, which can be downloaded here:
        // http://www.imgtec.com/powervr/insider/powervr-pvrtextool.asp
        
        let logoPvr = SPImage(contentsOfFile: "logo_rect.pvr")
        logoPvr.x = 20
        logoPvr.y = 220
        addChild(logoPvr)
    }
}
