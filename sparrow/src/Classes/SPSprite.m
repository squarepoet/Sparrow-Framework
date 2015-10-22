//
//  SPSprite.m
//  Sparrow
//
//  Created by Daniel Sperl on 21.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPBlendMode.h"
#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPPoint.h"
#import "SPQuadBatch.h"
#import "SPRectangle.h"
#import "SPRenderSupport.h"
#import "SPSprite.h"
#import "SPStage.h"

// --- class implementation ------------------------------------------------------------------------

@implementation SPSprite
{
    SP_GENERIC(NSMutableArray, SPQuadBatch*) *_flattenedContents;
    BOOL _flattenRequested;
    BOOL _flattenOptimized;
    SPRectangle *_clipRect;
}

#pragma mark Initialization

- (void)dealloc
{
    [_flattenedContents release];
    [_clipRect release];
    [super dealloc];
}

+ (instancetype)sprite
{
    return [[[self alloc] init] autorelease];
}

#pragma mark Methods

- (void)flatten
{
    [self flattenIgnoringChildOrder:NO];
}

- (void)flattenIgnoringChildOrder:(BOOL)ignoreChildOrder
{
    _flattenOptimized = ignoreChildOrder;
    _flattenRequested = YES;
    [self broadcastEventWithType:SPEventTypeFlatten];
}

- (void)unflatten
{
    _flattenRequested = NO;
    SP_RELEASE_AND_NIL(_flattenedContents);
}

- (BOOL)isFlattened
{
    return _flattenedContents || _flattenRequested;
}

- (SPRectangle *)clipRectInSpace:(SPDisplayObject *)targetSpace
{
    if (!_clipRect)
        return nil;

    float minX =  FLT_MAX;
    float maxX = -FLT_MAX;
    float minY =  FLT_MAX;
    float maxY = -FLT_MAX;

    float clipLeft = _clipRect.left;
    float clipRight = _clipRect.right;
    float clipTop = _clipRect.top;
    float clipBottom = _clipRect.bottom;

    SPMatrix *transform = [self transformationMatrixToSpace:targetSpace];

    float x = 0.0f;
    float y = 0.0f;

    for (int i=0; i<4; ++i)
    {
        switch (i)
        {
            case 0: x = clipLeft;  y = clipTop;    break;
            case 1: x = clipLeft;  y = clipBottom; break;
            case 2: x = clipRight; y = clipTop;    break;
            case 3: x = clipRight; y = clipBottom; break;
        }

        SPPoint *transformedPoint = [transform transformPointWithX:x y:y];
        if (minX > transformedPoint.x) minX = transformedPoint.x;
        if (maxX < transformedPoint.x) maxX = transformedPoint.x;
        if (minY > transformedPoint.y) minY = transformedPoint.y;
        if (maxY < transformedPoint.y) maxY = transformedPoint.y;
    }

    return [SPRectangle rectangleWithX:minX y:minY width:maxX-minX height:maxY-minY];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPSprite *sprite = [super copyWithZone:zone];
    sprite.clipRect = self.clipRect;
    sprite->_flattenRequested = _flattenRequested || _flattenedContents != nil;
    sprite->_flattenOptimized = _flattenOptimized;
    return sprite;
}

#pragma mark SPDisplayObject

- (void)render:(SPRenderSupport *)support
{
    if (_clipRect)
    {
        SPRectangle *stageClipRect = [support pushClipRect:[self clipRectInSpace:self.stage]];
        if (!stageClipRect || stageClipRect.isEmpty)
        {
            // empty clipping bounds - no need to render children
            [support popClipRect];
            return;
        }
    }

    if (_flattenRequested)
    {
        _flattenedContents = [[SPQuadBatch compileObject:self intoArray:[_flattenedContents autorelease]] retain];
        if (_flattenOptimized) [SPQuadBatch optimize:_flattenedContents];
        [support applyClipRect]; // compiling filters might change scissor rect.
        _flattenRequested = NO;
    }

    if (_flattenedContents)
    {
        [support finishQuadBatch];
        [support addDrawCalls:_flattenedContents.count];

        SPMatrix3D *mvpMatrix = support.mvpMatrix3D;
        float alpha = support.alpha;
        uint supportBlendMode = support.blendMode;

        for (SPQuadBatch *quadBatch in _flattenedContents)
        {
            uint blendMode = quadBatch.blendMode;
            if (blendMode == SPBlendModeAuto) blendMode = supportBlendMode;

            [quadBatch renderWithMvpMatrix3D:mvpMatrix alpha:alpha blendMode:blendMode];
        }
    }
    else [super render:support];

    if (_clipRect)
        [support popClipRect];
}

- (SPRectangle *)boundsInSpace:(SPDisplayObject *)targetSpace
{
    SPRectangle *bounds = [super boundsInSpace:targetSpace];

    // if we have a scissor rect, intersect it with our bounds
    if (_clipRect)
        bounds = [bounds intersectionWithRectangle:[self clipRectInSpace:targetSpace]];

    return bounds;
}

- (SPDisplayObject *)hitTestPoint:(SPPoint *)localPoint forTouch:(BOOL)forTouch
{
    if (_clipRect && ![_clipRect containsPoint:localPoint])
        return nil;
    else
        return [super hitTestPoint:localPoint forTouch:forTouch];
}

@end
