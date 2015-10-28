//
//  SPStage.m
//  Sparrow
//
//  Created by Daniel Sperl on 15.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPContext.h"
#import "SPDisplayObject_Internal.h"
#import "SPDisplayObjectContainer_Internal.h"
#import "SPEnterFrameEvent.h"
#import "SPGLTexture.h"
#import "SPPoint.h"
#import "SPPress_Internal.h"
#import "SPPressEvent.h"
#import "SPMacros.h"
#import "SPMatrix3D.h"
#import "SPOpenGL.h"
#import "SPRenderSupport.h"
#import "SPStage.h"
#import "SPPoint3D.h"

// --- class implementation ------------------------------------------------------------------------

@implementation SPStage
{
    float _width;
    float _height;
    uint _color;
    float _fieldOfView;
    SPPoint *_projectionOffset;
    SP_GENERIC(NSMutableArray, SPPress*) *_queuedPresses;
    SP_GENERIC(NSMutableOrderedSet, SPPress*) *_currentPresses;
    SP_GENERIC(NSMutableArray, SPDisplayObject*) *_enterFrameListeners;
}

@synthesize width  = _width;
@synthesize height = _height;

#pragma mark Initialization

- (instancetype)initWithWidth:(float)width height:(float)height
{    
    if ((self = [super init]))
    {
        _width = width;
        _height = height;
        _fieldOfView = 1.0f;
        _projectionOffset = [[SPPoint alloc] init];
        _queuedPresses = [[NSMutableArray alloc] init];
        _enterFrameListeners = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)init
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    return [self initWithWidth:screenSize.width height:screenSize.height];
}

- (void)dealloc
{
    [_projectionOffset release];
    [_queuedPresses release];
    [_currentPresses release];
    [_enterFrameListeners release];
    [super dealloc];
}

#pragma mark Methods

- (SPPoint3D *)cameraPositionInSpace:(SPDisplayObject *)targetSpace
{
    return [[self transformationMatrix3DToSpace:targetSpace] transformPoint3DWithX:_width  / 2.0f + _projectionOffset.x
                                                                                 y:_height / 2.0f + _projectionOffset.y
                                                                                 z:-self.focalLength];
}

- (UIImage *)drawToImage
{
    return [self drawToImage:YES];
}

- (UIImage *)drawToImage:(BOOL)transparent
{
    __block UIImage *image = nil;
    
    [Sparrow.currentController executeInResourceQueueAsynchronously:NO block:^
    {
        SPRenderSupport *support = [[SPRenderSupport alloc] init];
        float scale = Sparrow.contentScaleFactor;
        
        SPTextureProperties properties = {
            .format = SPTextureFormatRGBA,
            .scale  = scale,
            .width  = _width  * scale,
            .height = _height * scale,
            .numMipmaps = 0,
            .generateMipmaps = NO,
            .premultipliedAlpha = YES
        };
        
        [support setRenderTarget:[[[SPGLTexture alloc] initWithData:NULL properties:properties] autorelease]];
        [support setProjectionMatrixWithX:0 y:0 width:_width height:_height
                               stageWidth:_width stageHeight:_height cameraPos:self.cameraPosition];
        
        if (transparent) [support clear];
        else             [support clearWithColor:_color alpha:1];
        
        [super render:support];
        
        [support finishQuadBatch];
        image = [[SPContext currentContext] drawToImage];
        [support release];
    }];
    
    [Sparrow.context present];
    
    return image;
}

- (void)enqueuePress:(SPPress *)press
{
    [_queuedPresses addObject:press];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot copy a stage object"];
    return nil;
}

#pragma mark SPDisplayObject

- (void)render:(SPRenderSupport *)support
{
    [SPRenderSupport clearWithColor:_color alpha:1.0f];
    [support setProjectionMatrixWithX:0 y:0 width:_width height:_height
                           stageWidth:_width stageHeight:_height
                            cameraPos:self.cameraPosition];

    [super render:support];
}

- (SPDisplayObject *)hitTestPoint:(SPPoint *)localPoint forTouch:(BOOL)forTouch
{
    if (forTouch && (!self.visible || !self.touchable))
        return nil;
    
    // locations outside of the stage area shouldn't be accepted
    if (localPoint.x < 0.0f || localPoint.x > _width ||
        localPoint.y < 0.0f || localPoint.y > _height)
        return nil;
    
    // if nothing else is hit, the stage returns itself as target
    SPDisplayObject *target = [super hitTestPoint:localPoint forTouch:forTouch];
    if (!target) target = self;
    
    return target;
}

#pragma mark SPDisplayObjectContainer (Internal)

- (void)appendDescendantEventListenersOfObject:(SPDisplayObject *)object withEventType:(NSString *)type
                                       toArray:(SP_GENERIC(NSMutableArray, SPDisplayObject*) *)listeners
{
    if (object == self && [type isEqualToString:SPEventTypeEnterFrame])
        [listeners addObjectsFromArray:_enterFrameListeners];
    else
        [super appendDescendantEventListenersOfObject:object withEventType:type toArray:listeners];
}

#pragma mark Properties

- (float)focalLength
{
    return _width / (2.0f * tanf(_fieldOfView / 2.0f));
}

- (void)setFocalLength:(float)focalLength
{
    _fieldOfView = 2.0f * atanf(_width / (2.0f * focalLength));
}

- (void)setProjectionOffset:(SPPoint *)projectionOffset
{
    [_projectionOffset setX:projectionOffset.x y:projectionOffset.y];
}

- (SPPoint3D *)cameraPosition
{
    return [self cameraPositionInSpace:nil];
}

- (void)setX:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot set x-coordinate of stage"];
}

- (void)setY:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot set y-coordinate of stage"];
}

- (void)setPivotX:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot set pivot coordinates of stage"];
}

- (void)setPivotY:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot set pivot coordinates of stage"];
}

- (void)setScaleX:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot scale stage"];
}

- (void)setScaleY:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot scale stage"];
}

- (void)setSkewX:(float)skewX
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot skew stage"];
}

- (void)setSkewY:(float)skewY
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot skew stage"];
}

- (void)setRotation:(float)value
{
    [NSException raise:SPExceptionInvalidOperation format:@"cannot rotate stage"];
}

@end

// -------------------------------------------------------------------------------------------------

@implementation SPStage (Internal)

- (void)advanceTime:(double)passedTime
{
    SPEnterFrameEvent *enterFrameEvent = [[SPEnterFrameEvent alloc] initWithType:SPEventTypeEnterFrame passedTime:passedTime];
    [self broadcastEvent:enterFrameEvent];
    [enterFrameEvent release];
    
    if (_queuedPresses.count)
    {
        [_currentPresses addObjectsFromArray:_queuedPresses];
        
        SPPressEvent *event = [[SPPressEvent alloc] initWithType:SPEventTypePress presses:_currentPresses.set];
        [self dispatchEvent:event];
        SP_RELEASE_AND_NIL(event);
        
        NSMutableOrderedSet *remainingTouches = [NSMutableOrderedSet orderedSet];
        for (SPPress *touch in _currentPresses)
            if (touch.phase != SPPressPhaseEnded && touch.phase != SPPressPhaseCancelled)
                [remainingTouches addObject:touch];
        
        SP_RELEASE_AND_RETAIN(_currentPresses, remainingTouches);
        [_queuedPresses removeAllObjects];
    }
}

- (void)addEnterFrameListener:(SPDisplayObject *)listener
{
    [_enterFrameListeners addObject:listener];
}

- (void)removeEnterFrameListener:(SPDisplayObject *)listener
{
    NSUInteger index = [_enterFrameListeners indexOfObject:listener];
    if (index != NSNotFound) [_enterFrameListeners removeObjectAtIndex:index];
}

@end
