//
//  Sparrow.h
//  Sparrow
//
//  Created by Daniel Sperl on 21.03.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Availability.h>
#import <Foundation/Foundation.h>

#ifndef __IPHONE_6_0
    #warning "This project uses features only available in iOS SDK 6.0 and later."
#endif

#define SPARROW_VERSION @"2.2"

//! Project version number for Sparrow.
FOUNDATION_EXPORT double SparrowVersionNumber;

//! Project version string for Sparrow.
FOUNDATION_EXPORT const unsigned char SparrowVersionString[];

#import <Sparrow/SparrowClass.h>
#import <Sparrow/SPALSound.h>
#import <Sparrow/SPALSoundChannel.h>
#import <Sparrow/SPAudioEngine.h>
#import <Sparrow/SPAVSound.h>
#import <Sparrow/SPAVSoundChannel.h>
#import <Sparrow/SPBaseEffect.h>
#import <Sparrow/SPBitmapChar.h>
#import <Sparrow/SPBitmapFont.h>
#import <Sparrow/SPBlendMode.h>
#import <Sparrow/SPBlurFilter.h>
#import <Sparrow/SPButton.h>
#import <Sparrow/SPCache.h>
#import <Sparrow/SPCanvas.h>
#import <Sparrow/SPColorMatrix.h>
#import <Sparrow/SPColorMatrixFilter.h>
#import <Sparrow/SPContext.h>
#import <Sparrow/SPDelayedInvocation.h>
#import <Sparrow/SPDisplacementMapFilter.h>
#import <Sparrow/SPDisplayObject.h>
#import <Sparrow/SPDisplayObjectContainer.h>
#import <Sparrow/SPEnterFrameEvent.h>
#import <Sparrow/SPEvent.h>
#import <Sparrow/SPEventDispatcher.h>
#import <Sparrow/SPGLTexture.h>
#import <Sparrow/SPJuggler.h>
#import <Sparrow/SPImage.h>
#import <Sparrow/SPIndexData.h>
#import <Sparrow/SPMacros.h>
#import <Sparrow/SPMatrix.h>
#import <Sparrow/SPMatrix3D.h>
#import <Sparrow/SPMovieClip.h>
#import <Sparrow/SPNSExtensions.h>
#import <Sparrow/SPOpenGL.h>
#import <Sparrow/SPOverlayView.h>
#import <Sparrow/SPPolygon.h>
#import <Sparrow/SPPoint.h>
#import <Sparrow/SPProgram.h>
#import <Sparrow/SPPVRData.h>
#import <Sparrow/SPQuad.h>
#import <Sparrow/SPQuadBatch.h>
#import <Sparrow/SPRectangle.h>
#import <Sparrow/SPRenderSupport.h>
#import <Sparrow/SPRenderTexture.h>
#import <Sparrow/SPResizeEvent.h>
#import <Sparrow/SPSound.h>
#import <Sparrow/SPSoundChannel.h>
#import <Sparrow/SPSprite.h>
#import <Sparrow/SPSprite3D.h>
#import <Sparrow/SPStage.h>
#import <Sparrow/SPSubTexture.h>
#import <Sparrow/SPTextField.h>
#import <Sparrow/SPTexture.h>
#import <Sparrow/SPTextureAtlas.h>
#import <Sparrow/SPTouchEvent.h>
#import <Sparrow/SPTouchProcessor.h>
#import <Sparrow/SPTransitions.h>
#import <Sparrow/SPTween.h>
#import <Sparrow/SPURLConnection.h>
#import <Sparrow/SPUtils.h>
#import <Sparrow/SPVector3D.h>
#import <Sparrow/SPVertexData.h>
#import <Sparrow/SPView.h>
#import <Sparrow/SPViewController.h>
