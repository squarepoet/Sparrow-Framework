//
//  SPContext.h
//  Sparrow
//
//  Created by Robert Carone on 1/11/14.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>

NS_ASSUME_NONNULL_BEGIN

@class SPDisplayObject;
@class SPRectangle;
@class SPGLTexture;

/// Defines the values to use for specifying Context clear masks.
typedef NS_OPTIONS(NSInteger, SPClearMask)
{
    SPClearMaskColor   = 1 << 0,
    SPClearMaskDepth   = 1 << 1,
    SPClearMaskStencil = 1 << 2,
    SPClearMaskAll     = 0xff,
};

/** ------------------------------------------------------------------------------------------------
 
 An SPContext object manages the state information, commands, and resources needed to draw using
 OpenGL. All OpenGL commands are executed in relation to a context. SPContext wraps the native 
 context and provides additional functionality.

------------------------------------------------------------------------------------------------- */

@interface SPContext : NSObject

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes and returns a rendering context with a native context object.
- (instancetype)initWithNativeContext:(id)nativeContext NS_DESIGNATED_INITIALIZER;

/// Initializes and returns a rendering context with the specified sharegroup.
- (instancetype)initWithSharegroup:(nullable id)sharegroup;

/// Initializes and returns a rendering context.
- (instancetype)init;

/// -------------
/// @name Methods
/// -------------

/// Clears the color, depth, and stencil buffers associated with this context and fills them with
/// the specified values.
- (void)clearWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
               depth:(float)depth stencil:(uint)stencil mask:(SPClearMask)mask;

/// Clears the color buffer associated with this context.
- (void)clearWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

/// Sets the viewport dimensions base on the specified drawable and other attributes of the back
/// rendering buffer.
- (BOOL)configureBackBufferForDrawable:(id<EAGLDrawable>)drawable antiAlias:(NSInteger)antiAlias
                 enableDepthAndStencil:(BOOL)enableDepthAndStencil
                   wantsBestResolution:(BOOL)wantsBestResolution;

/// Draws the current render buffer to an image.
- (UIImage *)drawToImage;

/// Draws a region of the current render buffer to an image.
- (UIImage *)drawToImageInRegion:(nullable SPRectangle *)region;

/// Displays the back rendering buffer.
- (void)present;

/// Sets the back rendering buffer as the render target.
- (void)setRenderToBackBuffer;

/// Sets the specified texture as the rendering target.
- (void)setRenderToTexture:(nullable SPGLTexture *)texture;

/// Sets the specified texture as the rendering target, optionally with a depth and stencil buffer.
- (void)setRenderToTexture:(nullable SPGLTexture *)texture enableDepthAndStencil:(BOOL)enableDepthAndStencil;

/// Sets a scissor rectangle, which is type of drawing mask.
- (void)setScissorRectangle:(nullable SPRectangle *)rectangle;

/// Specifies the viewport to use for rendering operations.
- (void)setViewportRectangle:(SPRectangle *)rectangle;

/// Makes the receiver the current current rendering context.
- (BOOL)makeCurrentContext;

/// Returns the current rendering context for the calling thread.
+ (nullable SPContext *)currentContext;

/// Makes the specified context the current rendering context for the calling thread.
+ (BOOL)setCurrentContext:(nullable SPContext *)context;

/// ----------------
/// @name Properties
/// ----------------

/// The receiver’s sharegroup object.
@property (atomic, readonly) id sharegroup;

/// The receiver’s native context object.
@property (atomic, readonly) id nativeContext;

/// The width of the back buffer.
@property (nonatomic, readonly) NSInteger backBufferWidth;

/// The height of the back buffer.
@property (nonatomic, readonly) NSInteger backBufferHeight;

/// A dictionary for storing data assoicate with this context. Useful for storing objects that
/// depend on the lifetime of the context.
@property (nonatomic, readonly) NSMutableDictionary<id, id> *data;

@end

NS_ASSUME_NONNULL_END
