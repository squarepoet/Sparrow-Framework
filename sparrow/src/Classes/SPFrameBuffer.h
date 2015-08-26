//
//  SPFrameBuffer.h
//  Sparrow
//
//  Created by Robert Carone on 8/24/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>

NS_ASSUME_NONNULL_BEGIN

@class SPContext;
@class SPGLTexture;

/** ------------------------------------------------------------------------------------------------
 
 This class holds information about framebuffer objects bound to texture or drawable objects.
 
 _This is an internal class. You do not have to use it manually._
 
------------------------------------------------------------------------------------------------- */

@interface SPFrameBuffer : NSObject

/// Creates a framebuffer with the specified texture.
- (instancetype)initWithContext:(SPContext *)context texture:(SPGLTexture *)texture;

/// Creates a framebuffer with the specified drawable object.
- (instancetype)initWithContext:(SPContext *)context drawable:(id<EAGLDrawable>)drawable;

/// Resets and destroys the framebuffer.
- (void)reset;

/// Bind the receiver's framebuffer object.
- (void)bind;

/// Presents the framebuffer; only valid for framebuffers created with a drawable object.
- (void)present;

/// Draws the framebuffer to an image.
- (UIImage *)drawToImageInRegion:(SPRectangle *)region;

/// Returns the framebuffer's drawable object or nil if this a texture based framebuffer.
@property (nonatomic, readonly, nullable) id drawable;

/// Returns the framebuffer's texture object or nil if this a drawable based framebuffer.
@property (nonatomic, readonly, weak, nullable) SPGLTexture *texture;

/// Controls whether or not this framebuffer has an attached depth and stecil renderbuffer.
@property (nonatomic, assign) BOOL enableDepthAndStencil;

/// Controls the number of samples for the buffer's image.
@property (nonatomic, assign) NSInteger antiAlias;

/// Returns the width of the framebuffer object.
@property (nonatomic, readonly) NSInteger width;

/// Returns the height of the framebuffer object.
@property (nonatomic, readonly) NSInteger height;

@end

NS_ASSUME_NONNULL_END
