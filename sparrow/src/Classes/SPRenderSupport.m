//
//  SPRenderSupport.m
//  Sparrow
//
//  Created by Daniel Sperl on 28.09.09.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SPBlendMode.h>
#import <Sparrow/SPDisplayObject.h>
#import <Sparrow/SPMacros.h>
#import <Sparrow/SPMatrix.h>
#import <Sparrow/SPOpenGL.h>
#import <Sparrow/SPPoint.h>
#import <Sparrow/SPQuad.h>
#import <Sparrow/SPQuadBatch.h>
#import <Sparrow/SPRectangle.h>
#import <Sparrow/SPRenderSupport.h>
#import <Sparrow/SPTexture.h>
#import <Sparrow/SPVertexData.h>

// --- helper class --------------------------------------------------------------------------------

@interface SPRenderState : NSObject {
@public
    SPMatrix *_modelviewMatrix;
    float _alpha;
    uint _blendMode;
}

+ (instancetype)renderState;

- (void)setupDerivedFromState:(SPRenderState *)state withModelviewMatrix:(SPMatrix *)matrix
                        alpha:(float)alpha blendMode:(uint)blendMode;

@end

@implementation SPRenderState

- (instancetype)init
{
    if ((self = [super init]))
    {
        _modelviewMatrix = [[SPMatrix alloc] init];
        _alpha = 1.0f;
        _blendMode = SPBlendModeNormal;
    }
    return self;
}

- (void)dealloc
{
    [_modelviewMatrix release];
    [super dealloc];
}

- (void)setupDerivedFromState:(SPRenderState *)state withModelviewMatrix:(SPMatrix *)matrix
                        alpha:(float)alpha blendMode:(uint)blendMode
{
    _alpha = alpha * state->_alpha;
    _blendMode = blendMode == SPBlendModeAuto ? state->_blendMode : blendMode;

    [_modelviewMatrix copyFromMatrix:state->_modelviewMatrix];
    [_modelviewMatrix prependMatrix:matrix];
}

+ (instancetype)renderState
{
    return [[[self alloc] init] autorelease];
}

@end

// --- class implementation ------------------------------------------------------------------------

@implementation SPRenderSupport
{
    SPMatrix *_projectionMatrix;
    SPMatrix *_mvpMatrix;
    int _numDrawCalls;

    NSMutableArray *_stateStack;
    SPRenderState* _stateStackTop;
    int _stateStackIndex;
    int _stateStackSize;

    NSMutableArray *_quadBatches;
    SPQuadBatch* _quadBatchTop;
    int _quadBatchIndex;
    int _quadBatchSize;

    NSMutableArray *_clipRectStack;
    int _clipRectStackSize;
}

@synthesize projectionMatrix = _projectionMatrix;
@synthesize mvpMatrix = _mvpMatrix;
@synthesize numDrawCalls = _numDrawCalls;

- (instancetype)init
{
    if ((self = [super init]))
    {
        _projectionMatrix = [[SPMatrix alloc] init];
        _mvpMatrix        = [[SPMatrix alloc] init];

        _stateStack = [[NSMutableArray alloc] initWithObjects:[SPRenderState renderState], nil];
        _stateStackIndex = 0;
        _stateStackSize = 1;
        _stateStackTop = _stateStack[0];

        _quadBatches = [[NSMutableArray alloc] initWithObjects:[SPQuadBatch quadBatch], nil];
        _quadBatchIndex = 0;
        _quadBatchSize = 1;
        _quadBatchTop = _quadBatches[0];

        _clipRectStack = [[NSMutableArray alloc] init];
        _clipRectStackSize = 0;

        [self setupOrthographicProjectionWithLeft:0 right:320 top:0 bottom:480];
    }
    return self;
}

- (void)dealloc
{
    [_projectionMatrix release];
    [_mvpMatrix release];
    [_stateStack release];
    [_quadBatches release];
    [super dealloc];
}

- (void)nextFrame
{
    _clipRectStackSize = 0;
    _stateStackIndex = 0;
    _quadBatchIndex = 0;
    _numDrawCalls = 0;
    _quadBatchTop = _quadBatches[0];
    _stateStackTop = _stateStack[0];
}

- (void)purgeBuffers
{
    [_quadBatches removeAllObjects];

    _quadBatchTop = [SPQuadBatch quadBatch];
    [_quadBatches addObject:_quadBatchTop];

    _quadBatchIndex = 0;
    _quadBatchSize = 1;
}

+ (void)clearWithColor:(uint)color alpha:(float)alpha;
{
    float red   = SP_COLOR_PART_RED(color)   / 255.0f;
    float green = SP_COLOR_PART_GREEN(color) / 255.0f;
    float blue  = SP_COLOR_PART_BLUE(color)  / 255.0f;

    glClearColor(red, green, blue, alpha);
    glClear(GL_COLOR_BUFFER_BIT);
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

- (void)setupOrthographicProjectionWithLeft:(float)left right:(float)right
                                        top:(float)top bottom:(float)bottom;
{
    [_projectionMatrix setA:2.0f/(right-left) b:0.0f c:0.0f d:2.0f/(top-bottom)
                         tx:-(right+left) / (right-left)
                         ty:-(top+bottom) / (top-bottom)];
}

#pragma mark - state stack

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

- (float)alpha
{
    return _stateStackTop->_alpha;
}

- (uint)blendMode
{
    return _stateStackTop->_blendMode;
}

- (SPMatrix *)modelviewMatrix
{
    return _stateStackTop->_modelviewMatrix;
}

- (SPMatrix *)mvpMatrix
{
    [_mvpMatrix copyFromMatrix:_stateStackTop->_modelviewMatrix];
    [_mvpMatrix appendMatrix:_projectionMatrix];
    return _mvpMatrix;
}

- (void)applyBlendModeForPremultipliedAlpha:(BOOL)pma
{
    [SPBlendMode applyBlendFactorsForBlendMode:_stateStackTop->_blendMode premultipliedAlpha:pma];
}

- (SPRectangle *)viewport
{
    struct { int x, y, w, h; } viewport;
    glGetIntegerv(GL_VIEWPORT, (int *)&viewport);
    return [SPRectangle rectangleWithX:viewport.x y:viewport.y width:viewport.w height:viewport.h];
}

- (void)setViewport:(SPRectangle *)viewport
{
    glViewport(viewport.x, viewport.y, viewport.width, viewport.height);
}

#pragma mark - rendering

- (void)batchQuad:(SPQuad *)quad
{
    float alpha = _stateStackTop->_alpha;
    uint blendMode = _stateStackTop->_blendMode;
    SPMatrix *modelviewMatrix = _stateStackTop->_modelviewMatrix;

    if ([_quadBatchTop isStateChangeWithTinted:quad.tinted texture:quad.texture alpha:alpha
                            premultipliedAlpha:quad.premultipliedAlpha blendMode:blendMode
                                      numQuads:1])
    {
        [self finishQuadBatch]; // next batch
    }

    [_quadBatchTop addQuad:quad alpha:alpha blendMode:blendMode matrix:modelviewMatrix];
}

- (void)finishQuadBatch
{
    if (_quadBatchTop.numQuads)
    {
        [_quadBatchTop renderWithMvpMatrix:_projectionMatrix];
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

#pragma mark - clipping stack

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

    if (_clipRectStackSize > 0)
    {
        SPRectangle *rect = _clipRectStack[_clipRectStackSize - 1];
        SPRectangle *clip = [SPRectangle rectangle];
        SPRectangle *viewport = self.viewport;

        BOOL inverted = _projectionMatrix.ty > 0 ? YES : NO;

        // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
        SPPoint *topLeft = [_projectionMatrix transformPointWithX:rect.x y:rect.y];
        if (inverted) topLeft.y = -topLeft.y;
        clip.x = (topLeft.x * 0.5f + 0.5f) * viewport.width;
        clip.y = (topLeft.y * 0.5f + 0.5f) * viewport.height;

        SPPoint *bottomRight = [_projectionMatrix transformPointWithX:rect.right y:rect.bottom];
        if (inverted) bottomRight.y = -bottomRight.y;
        clip.right  = (bottomRight.x * 0.5f + 0.5f) * viewport.width;
        clip.bottom = (bottomRight.y * 0.5f + 0.5f) * viewport.height;

        // flip if needed
        if (inverted) clip.y = viewport.height - clip.y - clip.height;

        // intersect with viewport
        SPRectangle *scissor = [clip intersectionWithRectangle:viewport];

        // a negative rectangle is not allowed
        if (scissor.width < 0 || scissor.height < 0)
            [scissor setEmpty];

        glEnable(GL_SCISSOR_TEST);
        glScissor(scissor.x, scissor.y, scissor.width, scissor.height);
    }
    else
    {
        glDisable(GL_SCISSOR_TEST);
    }
}

@end
