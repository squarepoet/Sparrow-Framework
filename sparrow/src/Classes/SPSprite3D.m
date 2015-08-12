//
//  SPSprite3D.m
//  Sparrow
//
//  Created by Robert Carone on 7/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPDisplayObject_Internal.h"
#import "SPMatrix.h"
#import "SPMatrix3D.h"
#import "SPPoint.h"
#import "SPRenderSupport.h"
#import "SPSprite3D.h"
#import "SPStage.h"
#import "SPVector3D.h"

#define E 0.00001

@implementation SPSprite3D
{
    float _rotationX;
    float _rotationY;
    float _scaleZ;
    float _pivotZ;
    float _z;
    
    SPMatrix *_transformationMatrix;
    SPMatrix3D *_transformationMatrix3D;
    BOOL _transformationChanged;
}

// --- helpers -------------------------------------------------------------------------------------

SP_INLINE BOOL is2D(SPSprite3D *self)
{
    return self->_z > -E         && self->_z < E &&
           self->_rotationX > -E && self->_rotationX < E &&
           self->_rotationY > -E && self->_rotationY < E &&
           self->_pivotZ > -E    && self->_pivotZ < E;
}

SP_INLINE void recursivelySetIs3D(SPDisplayObject *object, BOOL value)
{
    if ([object isKindOfClass:[SPSprite3D class]])
        return;
    
    if ([object isKindOfClass:[SPDisplayObjectContainer class]])
    {
        for (SPDisplayObject *child in (SPDisplayObjectContainer *)object)
            recursivelySetIs3D(child, value);
    }
    
    [object setIs3D:value];
}

#pragma mark Initialization

- (instancetype)init
{
    if (self = [super init])
    {
        _scaleZ = 1.0f;
        _rotationX = _rotationY = _pivotZ = _z = 0.0f;
        _transformationMatrix = [[SPMatrix alloc] init];
        _transformationMatrix3D = [[SPMatrix3D alloc] init];
        [self setIs3D:YES];
        
        [self addEventListener:@selector(onAddedChild:) atObject:self forType:SPEventTypeAdded];
        [self addEventListener:@selector(onRemovedChild:) atObject:self forType:SPEventTypeRemoved];
    }
    
    return self;
}

- (void)dealloc
{
    [_transformationMatrix release];
    [_transformationMatrix3D release];
    [super dealloc];
}

+ (instancetype)sprite3D
{
    return [[[self alloc] init] autorelease];
}

#pragma mark SPDisplayObject

- (void)render:(SPRenderSupport *)support
{
    if (is2D(self)) [super render:support];
    else
    {
        [support finishQuadBatch];
        [support pushMatrix3D];
        [support transformMatrix3DWithObject:self];
        
        [super render:support];
        
        [support finishQuadBatch];
        [support popMatrix3D];
    }
}

- (SPDisplayObject *)hitTestPoint:(SPPoint *)localPoint forTouch:(BOOL)forTouch
{
    if (is2D(self)) return [super hitTestPoint:localPoint forTouch:forTouch];
    else
    {
        if (forTouch && (!self.visible || !self.touchable))
            return nil;
        
        // We calculate the interception point between the 3D plane that is spawned up
        // by this sprite3D and the straight line between the camera and the hit point.
        
        SPMatrix3D *matrix = [[self.transformationMatrix3D copy] autorelease];
        [matrix invert];
        
        SPVector3D *camPos = [self.stage cameraPositionInSpace:self];
        SPVector3D *xyPlane = [matrix transformVectorWithX:localPoint.x y:localPoint.y z:0];
        return [super hitTestPoint:[camPos intersectWithXYPlane:xyPlane] forTouch:forTouch];
    }
}

#pragma mark Events

- (void)onAddedChild:(SPEvent *)event
{
    recursivelySetIs3D((SPDisplayObject *)event.target, YES);
}

- (void)onRemovedChild:(SPEvent *)event
{
    recursivelySetIs3D((SPDisplayObject *)event.target, NO);
}

#pragma mark Private

- (void)updateMatrices
{
    float x = self.x;
    float y = self.y;
    float scaleX = self.scaleX;
    float scaleY = self.scaleY;
    float pivotX = self.pivotX;
    float pivotY = self.pivotY;
    float rotationZ = self.rotation;
    
    [_transformationMatrix3D identity];
    
    if (scaleX != 1.0f || scaleY != 1.0f || _scaleZ != 1.0f)
        [_transformationMatrix3D appendScaleX:scaleX != 0.0f ?: E y:scaleY != 0.0f ?: E z:_scaleZ != 0.0f ?: E];
    if (_rotationX != 0.0f)
        [_transformationMatrix3D appendRotation:_rotationX axis:[SPVector3D xAxis]];
    if (_rotationY != 0.0f)
        [_transformationMatrix3D appendRotation:_rotationY axis:[SPVector3D yAxis]];
    if (rotationZ != 0.0f)
        [_transformationMatrix3D appendRotation:rotationZ axis:[SPVector3D zAxis]];
    if (x != 0.0f || y != 0.0f || _z != 0.0f)
        [_transformationMatrix3D appendTranslationX:x y:y z:_z];
    if (pivotX != 0.0f || pivotY != 0.0f || _pivotZ != 0.0f)
        [_transformationMatrix3D prependTranslationX:-pivotX y:-pivotY z:-_pivotZ];
    
    if (is2D(self)) SP_RELEASE_AND_RETAIN(_transformationMatrix, [_transformationMatrix3D convertTo2D]);
    else            [_transformationMatrix identity];
}

#pragma mark Properties

- (SPMatrix *)transformationMatrix
{
    if (_transformationChanged)
    {
        [self updateMatrices];
        _transformationChanged = NO;
    }
    
    return _transformationMatrix;
}

- (void)setTransformationMatrix:(SPMatrix *)transformationMatrix
{
    super.transformationMatrix = transformationMatrix;
    _rotationX = _rotationY = _pivotZ = _z = 0;
    _transformationChanged = YES;
}

- (SPMatrix3D *)transformationMatrix3D
{
    if (_transformationChanged)
    {
        [self updateMatrices];
        _transformationChanged = NO;
    }
    
    return _transformationMatrix3D;
}

- (void)setX:(float)x
{
    super.x = x;
    _transformationChanged = YES;
}

- (void)setY:(float)y
{
    super.y = y;
    _transformationChanged = YES;
}

- (void)setZ:(float)z
{
    _z = z;
    _transformationChanged = YES;
}

- (void)setPivotX:(float)pivotX
{
    super.pivotX = pivotX;
    _transformationChanged = YES;
}

- (void)setPivotY:(float)pivotY
{
    super.pivotY = pivotY;
    _transformationChanged = YES;
}

- (void)setPivotZ:(float)pivotZ
{
    _pivotZ = pivotZ;
    _transformationChanged = YES;
}

- (void)setScaleX:(float)scaleX
{
    super.scaleX = scaleX;
    _transformationChanged = YES;
}

- (void)setScaleY:(float)scaleY
{
    super.scaleY = scaleY;
    _transformationChanged = YES;
}

- (void)setScaleZ:(float)scaleZ
{
    _scaleZ = scaleZ;
    _transformationChanged = YES;
}

- (void)setSkewX:(float)skewX
{
    [NSException raise:SPExceptionInvalidOperation format:@"3D objects do not support skewing"];
}

- (void)setSkewY:(float)skewY
{
    [NSException raise:SPExceptionInvalidOperation format:@"3D objects do not support skewing"];
}

- (void)setRotation:(float)rotation
{
    super.rotation = rotation;
    _transformationChanged = YES;
}

- (void)setRotationX:(float)rotationX
{
    _rotationX = rotationX;
    _transformationChanged = YES;
}

- (void)setRotationY:(float)rotationY
{
    _rotationY = rotationY;
    _transformationChanged = YES;
}

- (float)rotationZ
{
    return super.rotation;
}

- (void)setRotationZ:(float)rotationZ
{
    self.rotation = rotationZ;
}

@end
