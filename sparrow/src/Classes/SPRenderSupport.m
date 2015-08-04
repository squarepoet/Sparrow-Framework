//
//  SPRenderSupport.m
//  Sparrow
//
//  Created by Daniel Sperl on 28.09.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPBlendMode.h"
#import "SPContext.h"
#import "SPDisplayObject.h"
#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPMatrix3D.h"
#import "SPOpenGL.h"
#import "SPPoint.h"
#import "SPQuad.h"
#import "SPQuadBatch.h"
#import "SPRectangle.h"
#import "SPRenderSupport.h"
#import "SPStage.h"
#import "SPTexture.h"
#import "SPVector3D.h"
#import "SPVertexData.h"

#pragma mark - SPRenderState

@interface SPRenderState : NSObject
@end

@implementation SPRenderState
{
  @package
    SPMatrix *_modelViewMatrix;
    float _alpha;
    uint _blendMode;
}

#pragma mark Initialization

- (instancetype)init
{
    if ((self = [super init]))
    {
        _modelViewMatrix = [[SPMatrix alloc] init];
        _alpha = 1.0f;
        _blendMode = SPBlendModeNormal;
    }
    return self;
}

- (void)dealloc
{
    [_modelViewMatrix release];
    [super dealloc];
}

+ (instancetype)renderState
{
    return [[[self alloc] init] autorelease];
}

#pragma mark Methods

- (void)setupDerivedFromState:(SPRenderState *)state withModelviewMatrix:(SPMatrix *)matrix
                        alpha:(float)alpha blendMode:(uint)blendMode
{
    _alpha = alpha * state->_alpha;
    _blendMode = blendMode == SPBlendModeAuto ? state->_blendMode : blendMode;
    
    [_modelViewMatrix copyFromMatrix:state->_modelViewMatrix];
    [_modelViewMatrix prependMatrix:matrix];
}

@end

#pragma mark - SPRenderSupport

@implementation SPRenderSupport
{
    SPMatrix *_projectionMatrix;
    SPMatrix *_mvpMatrix;
    SPMatrix3D *_projectionMatrix3D;
    SPMatrix3D *_mvpMatrix3D;
    int _numDrawCalls;

    NSMutableArray<SPRenderState*> *_stateStack;
    SPRenderState *_stateStackTop;
    int _stateStackIndex;
    int _stateStackSize;
    
    NSMutableArray<SPMatrix3D*> *_matrix3DStack;
    int _matrix3DStackSize;
    SPMatrix3D *_modelViewMatrix3D;

    NSMutableArray<SPQuadBatch*> *_quadBatches;
    SPQuadBatch *_quadBatchTop;
    int _quadBatchIndex;
    int _quadBatchSize;

    NSMutableArray<SPRectangle*> *_clipRectStack;
    int _clipRectStackSize;
    
    NSMutableArray<SPDisplayObject*> *_maskStack;
    int _maskStackSize;
    uint _stencilReferenceValue;
}

#pragma mark Initialization

- (instancetype)init
{
    if ((self = [super init]))
    {
        _projectionMatrix = [[SPMatrix alloc] init];
        _mvpMatrix = [[SPMatrix alloc] init];

        _stateStack = [[NSMutableArray alloc] initWithObjects:[SPRenderState renderState], nil];
        _stateStackIndex = 0;
        _stateStackSize = 1;
        _stateStackTop = _stateStack[0];
        
        _projectionMatrix3D = [[SPMatrix3D alloc] init];
        _modelViewMatrix3D = [[SPMatrix3D alloc] init];
        _mvpMatrix3D = [[SPMatrix3D alloc] init];
        _matrix3DStack = [[NSMutableArray alloc] init];
        _matrix3DStackSize = 0;

        _quadBatches = [[NSMutableArray alloc] initWithObjects:[SPQuadBatch quadBatch], nil];
        _quadBatchIndex = 0;
        _quadBatchSize = 1;
        _quadBatchTop = _quadBatches[0];

        _clipRectStack = [[NSMutableArray alloc] init];
        _clipRectStackSize = 0;
        
        _maskStack = [[NSMutableArray alloc] init];
        _maskStackSize = 0;

        [self setProjectionMatrixWithX:0 y:0 width:320 height:480];
    }
    return self;
}

- (void)dealloc
{
    [_projectionMatrix release];
    [_mvpMatrix release];
    [_projectionMatrix3D release];
    [_modelViewMatrix3D release];
    [_mvpMatrix3D release];
    [_matrix3DStack release];
    [_stateStack release];
    [_quadBatches release];
    [_clipRectStack release];
    [_maskStack release];
    [super dealloc];
}

#pragma mark Methods

- (void)purgeBuffers
{
    [_quadBatches removeAllObjects];

    _quadBatchTop = [SPQuadBatch quadBatch];
    [_quadBatches addObject:_quadBatchTop];

    _quadBatchIndex = 0;
    _quadBatchSize = 1;
}

- (void)clear
{
    [SPRenderSupport clearWithColor:0 alpha:0];
}

- (void)clearWithColor:(uint)color
{
    [SPRenderSupport clearWithColor:color alpha:1];
}

- (void)clearWithColor:(uint)color alpha:(float)alpha
{
    [SPRenderSupport clearWithColor:color alpha:alpha];
}

+ (void)clearWithColor:(uint)color alpha:(float)alpha;
{
    float red   = SP_COLOR_PART_RED(color)   / 255.0f;
    float green = SP_COLOR_PART_GREEN(color) / 255.0f;
    float blue  = SP_COLOR_PART_BLUE(color)  / 255.0f;
    
    GLboolean scissorEnabled = glIsEnabled(GL_SCISSOR_TEST);
    if (scissorEnabled)
        glDisable(GL_SCISSOR_TEST);

    glClearColor(red, green, blue, alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (scissorEnabled)
        glEnable(GL_SCISSOR_TEST);
}

+ (uint)checkForOpenGLError
{
    GLenum error;
    while ((error = glGetError())) NSLog(@"There was an OpenGL error: %s", sglGetErrorString(error));
    return error;
}

- (void)addDrawCalls:(int)count
{
    _numDrawCalls += count;
}

- (void)setProjectionMatrixWithX:(float)x y:(float)y width:(float)width height:(float)height
                      stageWidth:(float)stageWidth stageHeight:(float)stageHeight
                       cameraPos:(nullable SPVector3D *)cameraPos
{
    if (stageWidth  <= 0) stageWidth = width;
    if (stageHeight <= 0) stageHeight = height;
    if (!cameraPos)
    {
        cameraPos = [SPVector3D vector];
        [cameraPos setX:stageWidth / 2.0f y:stageHeight / 2.0f // -> center of stage
                      z:stageWidth / tanf(0.5f) * 0.5f];       // -> fieldOfView = 1.0 rad
    }
    
    // set up 2d (orthographic) projection
    [_projectionMatrix setA:2.0f/width b:0.0f c:0.0f d:-2.0f/height
                         tx:-(2*x + width) / width ty:(2*y + height) / height];
    
    const float focalLength = fabsf(cameraPos.z);
    const float offsetX = cameraPos.x - stageWidth  / 2.0f;
    const float offsetY = cameraPos.y - stageHeight / 2.0f;
    const float far = focalLength * 20.0f;
    const float near = 1.0f;
    const float scaleX = stageWidth  / width;
    const float scaleY = stageHeight / height;
    
    GLKMatrix4 matrix = (GLKMatrix4){ 0 };
    
    // set up general perspective
    matrix.m[ 0] =  2 * focalLength / stageWidth;  // 0,0
    matrix.m[ 5] = -2 * focalLength / stageHeight; // 1,1  [negative to invert y-axis]
    matrix.m[10] =  far / (far - near);            // 2,2
    matrix.m[14] = -far * near / (far - near);     // 2,3
    matrix.m[11] =  1;                             // 3,2
    
    // now zoom in to visible area
    matrix.m[0] *=  scaleX;
    matrix.m[5] *=  scaleY;
    matrix.m[8]  =  scaleX - 1 - 2 * scaleX * (x - offsetX) / stageWidth;
    matrix.m[9]  = -scaleY + 1 + 2 * scaleY * (y - offsetY) / stageHeight;
    
    _projectionMatrix3D.rawData = matrix.m;
    [_projectionMatrix3D prependTranslationX:-stageWidth /2.0f - offsetX
                                           y:-stageHeight/2.0f - offsetY
                                           z:focalLength];
    
    [self applyClipRect];
}

- (void)setProjectionMatrixWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    [self setProjectionMatrixWithX:x y:y width:width height:height
                        stageWidth:-1 stageHeight:-1 cameraPos:nil];
}

- (void)setupOrthographicProjectionWithLeft:(float)left right:(float)right
                                        top:(float)top bottom:(float)bottom;
{
    SPStage *stage = Sparrow.stage;
    [self setProjectionMatrixWithX:left y:top width:right-left height:bottom-top
                        stageWidth:stage.width stageHeight:stage.height
                         cameraPos:stage.cameraPosition];
}

#pragma mark Rendering

- (void)nextFrame
{
    _clipRectStackSize = 0;
    _stateStackIndex = 0;
    _quadBatchIndex = 0;
    _numDrawCalls = 0;
    _quadBatchTop = _quadBatches[0];
    _stateStackTop = _stateStack[0];
}

- (void)batchQuad:(SPQuad *)quad
{
    float alpha = _stateStackTop->_alpha;
    uint blendMode = _stateStackTop->_blendMode;
    SPMatrix *modelViewMatrix = _stateStackTop->_modelViewMatrix;

    if ([_quadBatchTop isStateChangeWithTinted:quad.tinted texture:quad.texture alpha:alpha
                            premultipliedAlpha:quad.premultipliedAlpha blendMode:blendMode
                                      numQuads:1])
    {
        [self finishQuadBatch]; // next batch
    }

    [_quadBatchTop addQuad:quad alpha:alpha blendMode:blendMode matrix:modelViewMatrix];
}

- (void)batchQuadBatch:(SPQuadBatch *)quadBatch
{
    float alpha = _stateStackTop->_alpha;
    uint blendMode = _stateStackTop->_blendMode;
    SPMatrix *modelViewMatrix = _stateStackTop->_modelViewMatrix;
    
    if ([_quadBatchTop isStateChangeWithTinted:quadBatch.tinted texture:quadBatch.texture
                                         alpha:quadBatch.alpha premultipliedAlpha:quadBatch.premultipliedAlpha
                                     blendMode:quadBatch.blendMode numQuads:quadBatch.numQuads])
    {
        [self finishQuadBatch]; // next batch
    }
    
    [_quadBatchTop addQuadBatch:quadBatch alpha:alpha blendMode:blendMode matrix:modelViewMatrix];
}

- (void)finishQuadBatch
{
    if (_quadBatchTop.numQuads)
    {
        if (_matrix3DStackSize == 0)
        {
            [_quadBatchTop renderWithMvpMatrix3D:_projectionMatrix3D];
        }
        else
        {
            [_mvpMatrix3D copyFromMatrix:_projectionMatrix3D];
            [_mvpMatrix3D prependMatrix:_modelViewMatrix3D];
            [_quadBatchTop renderWithMvpMatrix3D:_mvpMatrix3D];
        }
        
        [_quadBatchTop reset];

        if (_quadBatchSize == _quadBatchIndex + 1)
        {
            [_quadBatches addObject:[SPQuadBatch quadBatch]];
            ++_quadBatchSize;
        }

        ++_numDrawCalls;
        _quadBatchTop = _quadBatches[++_quadBatchIndex];
    }
}

#pragma mark State Manipulation

- (void)pushStateWithMatrix:(SPMatrix *)matrix alpha:(float)alpha blendMode:(uint)blendMode
{
    SPRenderState *previousState = _stateStackTop;

    if (_stateStackSize == _stateStackIndex + 1)
    {
        [_stateStack addObject:[SPRenderState renderState]];
        ++_stateStackSize;
    }

    _stateStackTop = _stateStack[++_stateStackIndex];
    [_stateStackTop setupDerivedFromState:previousState withModelviewMatrix:matrix
                                    alpha:alpha blendMode:blendMode];
}

- (void)popState
{
    if (_stateStackIndex == 0)
        [NSException raise:SPExceptionInvalidOperation format:@"The state stack must not be empty"];

    _stateStackTop = _stateStack[--_stateStackIndex];
}

- (void)applyBlendModeForPremultipliedAlpha:(BOOL)pma
{
    [SPBlendMode applyBlendFactorsForBlendMode:_stateStackTop->_blendMode premultipliedAlpha:pma];
}

#pragma mark 3D Transformations

- (void)transformMatrix3DWithObject:(SPDisplayObject *)object
{
    [_modelViewMatrix3D prependMatrix:[_stateStackTop->_modelViewMatrix convertTo3D]];
    [_modelViewMatrix3D prependMatrix:object.transformationMatrix3D];
    [_stateStackTop->_modelViewMatrix identity];
}

- (void)pushMatrix3D
{
    if (_matrix3DStack.count < _matrix3DStackSize + 1)
        [_matrix3DStack addObject:[SPMatrix3D matrixWithIdentity]];
    
    [_matrix3DStack[_matrix3DStackSize++] copyFromMatrix:_modelViewMatrix3D];
}

- (void)popMatrix3D
{
    [_modelViewMatrix3D copyFromMatrix:_matrix3DStack[--_matrix3DStackSize]];
}

#pragma mark Clipping

- (SPRectangle *)pushClipRect:(SPRectangle *)clipRect
{
    if (_clipRectStack.count < _clipRectStackSize + 1)
        [_clipRectStack addObject:[SPRectangle rectangle]];

    SPRectangle* rectangle = _clipRectStack[_clipRectStackSize];
    [rectangle copyFromRectangle:clipRect];

    // intersect with the last pushed clip rect
    if (_clipRectStackSize > 0)
        rectangle = [rectangle intersectionWithRectangle:_clipRectStack[_clipRectStackSize - 1]];

    ++ _clipRectStackSize;
    [self applyClipRect];

    // return the intersected clip rect so callers can skip draw calls if it's empty
    return rectangle;
}

- (void)popClipRect
{
    if (_clipRectStackSize > 0)
    {
        -- _clipRectStackSize;
        [self applyClipRect];
    }
}

- (void)applyClipRect
{
    [self finishQuadBatch];

    SPContext *context = Sparrow.context;
    if (!context) return;

    if (_clipRectStackSize > 0)
    {
        int width, height;
        SPRectangle *rect = _clipRectStack[_clipRectStackSize-1];
        SPRectangle *clipRect = [SPRectangle rectangle];
        SPTexture *renderTarget = context.renderTarget;

        if (renderTarget)
        {
            width  = renderTarget.nativeWidth;
            height = renderTarget.nativeHeight;
        }
        else
        {
            width  = (int)Sparrow.currentController.view.drawableWidth;
            height = (int)Sparrow.currentController.view.drawableHeight;
        }

        // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
        SPPoint *topLeft = [_projectionMatrix transformPointWithX:rect.x y:rect.y];
        if (renderTarget) topLeft.y = -topLeft.y;
        clipRect.x = (topLeft.x * 0.5f + 0.5f) * width;
        clipRect.y = (0.5f - topLeft.y * 0.5f) * height;

        SPPoint *bottomRight = [_projectionMatrix transformPointWithX:rect.right y:rect.bottom];
        if (renderTarget) bottomRight.y = -bottomRight.y;
        clipRect.right  = (bottomRight.x * 0.5f + 0.5f) * width;
        clipRect.bottom = (0.5f - bottomRight.y * 0.5f) * height;

        // flip y coordiantes when rendering to backbuffer
        if (!renderTarget) clipRect.y = height - clipRect.y - clipRect.height;

        SPRectangle *bufferRect = [SPRectangle rectangleWithX:0 y:0 width:width height:height];
        SPRectangle *scissorRect = [clipRect intersectionWithRectangle:bufferRect];

        // a negative rectangle is not allowed
        if (scissorRect.width < 0 || scissorRect.height < 0)
            [scissorRect setEmpty];

        context.scissorBox = scissorRect;
    }
    else
    {
        context.scissorBox = nil;
    }
}

#pragma mark Stencil Masks

- (void)pushMask:(SPDisplayObject *)mask
{
    [_maskStack addObject:mask];
    _stencilReferenceValue++;
    
    [self finishQuadBatch];
    
    GLint prevStencilRef = 0;
    glGetIntegerv(GL_STENCIL_REF, &prevStencilRef);
    
    glEnable(GL_STENCIL_TEST);
    glStencilOp(GL_KEEP, GL_KEEP, GL_INCR);
    glStencilFunc(GL_EQUAL, prevStencilRef, 0xff);
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glDepthMask(GL_FALSE);
    
    [self drawMask:mask];
    
    glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
    glStencilFunc(GL_EQUAL, _stencilReferenceValue, 0xff);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask(GL_TRUE);
}

- (void)popMask
{
    SPDisplayObject *mask = [_maskStack lastObject];
    _stencilReferenceValue--;
    
    [self finishQuadBatch];
    
    GLint prevStencilRef = 0;
    glGetIntegerv(GL_STENCIL_REF, &prevStencilRef);
    
    glEnable(GL_STENCIL_TEST);
    glStencilOp(GL_KEEP, GL_KEEP, GL_DECR);
    glStencilFunc(GL_EQUAL, prevStencilRef, 0xff);
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glDepthMask(GL_FALSE);
    
    [self drawMask:mask];
    
    glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
    glStencilFunc(GL_EQUAL, _stencilReferenceValue, 0xff);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask(GL_TRUE);
    
    [_maskStack removeLastObject];
}

- (void)drawMask:(SPDisplayObject *)mask
{
    [self pushStateWithMatrix:mask.transformationMatrix alpha:1.0f blendMode:SPBlendModeAuto];
    
    SPStage *stage = mask.stage;
    if (stage) [_stateStackTop->_modelViewMatrix copyFromMatrix:[mask transformationMatrixToSpace:stage]];
    
    [mask render:self];
    [self finishQuadBatch];
    
    [self popState];
}

#pragma mark Properties

- (void)setProjectionMatrix:(SPMatrix *)projectionMatrix
{
    [_projectionMatrix copyFromMatrix:projectionMatrix];
    [self applyClipRect];
}

- (SPMatrix *)mvpMatrix
{
    [_mvpMatrix copyFromMatrix:_stateStackTop->_modelViewMatrix];
    [_mvpMatrix appendMatrix:_projectionMatrix];
    return _mvpMatrix;
}

- (SPMatrix *)modelViewMatrix
{
    return _stateStackTop->_modelViewMatrix;
}

- (void)setProjectionMatrix3D:(SPMatrix3D *)projectionMatrix3D
{
    [_projectionMatrix3D copyFromMatrix:projectionMatrix3D];
}

- (SPMatrix3D *)mvpMatrix3D
{
    if (_matrix3DStackSize == 0) {
        return [self.mvpMatrix convertTo3D];
    }
    else
    {
        [_mvpMatrix3D copyFromMatrix:_projectionMatrix3D];
        [_mvpMatrix3D prependMatrix:_modelViewMatrix3D];
        [_mvpMatrix3D prependMatrix:[_stateStackTop->_modelViewMatrix convertTo3D]];
        return _mvpMatrix3D;
    }
}

- (SPMatrix3D *)modelViewMatrix3D
{
    return _modelViewMatrix3D;
}

- (float)alpha
{
    return _stateStackTop->_alpha;
}

- (void)setAlpha:(float)alpha
{
    _stateStackTop->_alpha = alpha;
}

- (uint)blendMode
{
    return _stateStackTop->_blendMode;
}

- (void)setBlendMode:(uint)blendMode
{
    if (blendMode != SPBlendModeAuto)
        _stateStackTop->_blendMode = blendMode;
}

- (SPTexture *)renderTarget
{
    return Sparrow.context.renderTarget;
}

- (void)setRenderTarget:(SPTexture *)renderTarget
{
    [self applyClipRect];

    Sparrow.context.renderTarget = renderTarget;
}

- (void)setStencilReferenceValue:(uint)stencilReferenceValue
{
    _stencilReferenceValue = stencilReferenceValue;
}

@end
