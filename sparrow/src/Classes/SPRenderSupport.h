//
//  SPRenderSupport.h
//  Sparrow
//
//  Created by Daniel Sperl on 28.09.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class SPDisplayObject;
@class SPMatrix;
@class SPMatrix3D;
@class SPQuad;
@class SPQuadBatch;
@class SPTexture;
@class SPVector3D;

/** ------------------------------------------------------------------------------------------------

 A class that contains helper methods simplifying OpenGL rendering.
 
 An SPRenderSupport instance is passed to any render: method. It saves information about the
 current render state, like the alpha value, modelview matrix, and blend mode.
 
 It also keeps a list of quad batches, which can be used to render a high number of quads
 very efficiently; only changes in the state of added quads trigger OpenGL draw calls.
 
 Furthermore, several static helper methods can be used for different needs whenever some
 OpenGL processing is required.
 
------------------------------------------------------------------------------------------------- */

@interface SPRenderSupport : NSObject

/// -------------
/// @name Methods
/// -------------

/// Resets the render state stack to the default.
- (void)nextFrame;

/// Adds a quad or image to the current batch of unrendered quads. If there is a state change,
/// all previous quads are rendered at once, and the batch is reset. Note that the values for
/// alpha and blend mode are taken from the current render state, not the quad.
- (void)batchQuad:(SPQuad *)quad;

/// Adds a batch of quads to the current batch of unrendered quads. If there is a state
/// change, all previous quads are rendered at once.
///
/// @note Copying the contents of the QuadBatch to the current "cumulative" batch takes some time.
/// If the batch consists of more than just a few quads, you may be better off calling the
/// "renderWithMatrix" method on the batch instead. Otherwise, the additional CPU effort will be
/// more expensive than what you save by avoiding the draw call. (Rule of thumb: no more than
/// 16-20 quads.)
- (void)batchQuadBatch:(SPQuadBatch *)quadBatch;

/// Renders the current quad batch and resets it.
- (void)finishQuadBatch;

/// Clears all vertex and index buffers, releasing the associated memory. Useful in low-memory
/// situations. Don't call from within a render method!
- (void)purgeBuffers;

/// Clears OpenGL's color buffer.
- (void)clear;

/// Clears OpenGL's color buffer with a specified color.
- (void)clearWithColor:(uint)color;

/// Clears OpenGL's color buffer with a specified color and alpha.
- (void)clearWithColor:(uint)color alpha:(float)alpha;

/// Clears OpenGL's color buffer with a specified color and alpha.
+ (void)clearWithColor:(uint)color alpha:(float)alpha;

/// Checks for an OpenGL error. If there is one, it is logged an the error code is returned.
+ (uint)checkForOpenGLError;

/// Raises the number of draw calls by a specific value. Call this method in custom render methods
/// to keep the statistics display in sync.
- (void)addDrawCalls:(NSInteger)count;

/// Sets up the projection matrices for 2D and 3D rendering.
///
/// The first 4 parameters define which area of the stage you want to view. The camera
/// will 'zoom' to exactly this region. The perspective in which you're looking at the
/// stage is determined by the final 3 parameters.
///
/// The stage is always on the rectangle that is spawned up between x- and y-axis (with
/// the given size). All objects that are exactly on that rectangle (z equals zero) will be
/// rendered in their true size, without any distortion.
- (void)setProjectionMatrixWithX:(float)x y:(float)y width:(float)width height:(float)height
                      stageWidth:(float)stageWidth stageHeight:(float)stageHeight
                       cameraPos:(nullable SPVector3D *)cameraPos;

/// Sets up the projection matrices for 2D and 3D rendering.
- (void)setProjectionMatrixWithX:(float)x y:(float)y width:(float)width height:(float)height;

/// Sets up the projection matrices for ortographic 2D rendering.
- (void)setupOrthographicProjectionWithLeft:(float)left right:(float)right
                                        top:(float)top bottom:(float)bottom;

/// ------------------------
/// @name State Manipulation
/// ------------------------

/// Adds a new render state to the stack. The passed matrix is prepended to the modelview matrix;
/// the alpha value is multiplied with the current alpha; the blend mode replaces the existing
/// mode (except `SPBlendModeAuto`, which will cause the current mode to prevail).
- (void)pushStateWithMatrix:(SPMatrix *)matrix alpha:(float)alpha blendMode:(uint)blendMode;

/// Restores the previous render state.
- (void)popState;

/// Activates the current blend mode.
- (void)applyBlendModeForPremultipliedAlpha:(BOOL)pma;

/// Changes the 3D and 2D modelview matrixces to an identity matrix.
- (void)loadIdentity;

/// ------------------------
/// @name 3D Transformations
/// ------------------------

/// Prepends translation, scale and rotation of an object to the 3D modelview matrix. The current
/// contents of the 2D modelview matrix is stored in the 3D modelview matrix before doing so; the
/// 2D state modelview matrix is then reset to the identity matrix.
- (void)transformMatrix3DWithObject:(SPDisplayObject *)object;

/// Pushes the current 3D modelview matrix to a stack from which it can be restored later.
- (void)pushMatrix3D;

/// Restores the 3D modelview matrix that was last pushed to the stack.
- (void)popMatrix3D;

/// --------------
/// @name Clipping
/// --------------

/// The clipping rectangle can be used to limit rendering in the current render target to a certain
/// area. This method expects the rectangle in stage coordinates. Internally, it uses the
/// 'glScissor' command of OpenGL, which works with pixel coordinates. Any pushed rectangle is
/// intersected with the previous rectangle; the method returns that intersection.
- (SPRectangle *)pushClipRect:(SPRectangle *)clipRect;

/// The clipping rectangle can be used to limit rendering in the current render target to a certain
/// area. This method expects the rectangle in stage coordinates. Internally, it uses the
/// 'glScissor' command of OpenGL, which works with pixel coordinates.
- (SPRectangle *)pushClipRect:(SPRectangle *)clipRect intersectWithCurrent:(BOOL)intersect;

/// Restores the clipping rectangle that was last pushed to the stack.
- (void)popClipRect;

/// Updates the scissor rectangle using the current clipping rectangle. This method is called
/// automatically when either the projection matrix or the clipping rectangle changes.
- (void)applyClipRect;

/// -------------------
/// @name Stencil Masks
/// -------------------

/// Draws a display object into the stencil buffer, incrementing the buffer on each used pixel. The
/// stencil reference value is incremented as well; thus, any subsequent stencil tests outside of
/// this area will fail.
///
/// If 'mask' is part of the display list, it will be drawn at its conventional stage coordinates.
/// Otherwise, it will be drawn with the current modelview matrix.
- (void)pushMask:(SPDisplayObject *)mask;

/// Redraws the most recently pushed mask into the stencil buffer, decrementing the buffer on each
/// used pixel. This effectively removes the object from the stencil buffer, restoring the previous
/// state. The stencil reference value will be decremented.
- (void)popMask;

/// ----------------
/// @name Properties
/// ----------------

/// Returns the current projection matrix.
/// CAUTION: Use with care! Each call returns the same instance.
@property (nonatomic, copy) SPMatrix *projectionMatrix;

/// Calculates the product of modelview and projection matrix.
/// CAUTION: Use with care! Each call returns the same instance.
@property (nonatomic, readonly) SPMatrix *mvpMatrix;

/// Returns the current modelview matrix.
/// CAUTION: Use with care! Returns not a copy, but the internally used instance.
@property (nonatomic, readonly) SPMatrix *modelViewMatrix;

/// Returns the current 3D projection matrix.
/// CAUTION: Use with care! Each call returns the same instance.
@property (nonatomic, copy) SPMatrix3D *projectionMatrix3D;

/// Calculates the product of modelview and projection matrix and stores it in a 3D matrix.
/// Different to 'mvpMatrix', this also takes 3D transformations into account.
/// CAUTION: Use with care! Each call returns the same instance.
@property (nonatomic, readonly) SPMatrix3D *mvpMatrix3D;

/// Returns the current 3D modelview matrix.
/// CAUTION: Use with care! Returns not a copy, but the internally used instance.
@property (nonatomic, readonly) SPMatrix3D *modelViewMatrix3D;

/// The current (accumulated) alpha value.
@property (nonatomic, assign) float alpha;

/// The current blend mode.
@property (nonatomic, assign) uint blendMode;

/// The texture that is currently being rendered into, or 'nil' to render into the back buffer.
/// If you set a new target, it is immediately activated.
@property (nonatomic, strong, nullable) SPTexture *renderTarget;

/// The current stencil reference value, which is per default the depth of the current
/// stencil mask stack. Only change this value if you know what you're doing.
@property (nonatomic, assign) uint stencilReferenceValue;

/// Indicates the number of OpenGL ES draw calls since the last call to `nextFrame`.
@property (nonatomic, readonly) NSInteger numDrawCalls;

@end

NS_ASSUME_NONNULL_END
