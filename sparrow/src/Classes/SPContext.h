//
//  SPContext.h
//  Sparrow
//
//  Created by Robert Carone on 1/11/14.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SPDisplayObject;
@class SPRectangle;
@class SPTexture;

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

/// Sets the back rendering buffer as the render target.
- (void)renderToBackBuffer;

/// Displays a renderbuffer’s contents on screen.
- (void)presentBufferForDisplay;

/// Returns an image of the current render target.
- (UIImage *)snapshot;

/// Returns an image of a specified texture.
- (UIImage *)snapshotOfTexture:(SPTexture *)texture;

/// Returns an image of a display object and it's children.
- (UIImage *)snapshotOfDisplayObject:(SPDisplayObject *)object;

/// Makes the receiver the current current rendering context.
- (BOOL)makeCurrentContext;

/// Makes the specified context the current rendering context for the calling thread.
+ (BOOL)setCurrentContext:(nullable SPContext *)context;

/// Returns the current rendering context for the calling thread.
+ (nullable SPContext *)currentContext;

/// Returns YES if the current devices supports the extension.
+ (BOOL)deviceSupportsOpenGLExtension:(NSString *)extensionName;

/// ----------------
/// @name Properties
/// ----------------

/// The receiver’s sharegroup object.
@property (atomic, readonly) id sharegroup;

/// The receiver’s native context object.
@property (atomic, readonly) id nativeContext;

/// The current OpenGL viewport rectangle in pixels.
@property (nonatomic, assign, nullable) SPRectangle *viewport;

/// The current OpenGL scissor rectangle in pixels.
@property (nonatomic, assign, nullable) SPRectangle *scissorBox;

/// The specified texture as the rendering target or nil if rendering to the default framebuffer.
@property (nonatomic, retain, nullable) SPTexture *renderTarget;

/// A dictionary for storing data assoicate with this context. Useful for storing objects that
/// depend on the lifetime of the context.
@property (nonatomic, readonly) NSMutableDictionary<id, id> *data;

@end

NS_ASSUME_NONNULL_END
