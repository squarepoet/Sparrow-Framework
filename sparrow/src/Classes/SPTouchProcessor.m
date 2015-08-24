//
//  SPTouchProcessor.m
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPDisplayObjectContainer.h"
#import "SPPoint.h"
#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPStage.h"
#import "SPTouch.h"
#import "SPTouchEvent.h"
#import "SPTouchProcessor.h"
#import "SPTouch_Internal.h"

#define MULTITAP_TIME 0.3f
#define MULTITAP_DIST 25.0f

// --- class implementation ------------------------------------------------------------------------

@implementation SPTouchProcessor
{
    SPStage *__weak _stage;
    SPDisplayObject *__weak _root;

    NSMutableOrderedSet *_currentTouches;
    NSMutableOrderedSet *_updatedTouches;
    NSMutableArray *_queuedTouches;
    NSMutableArray *_lastTaps;

    double _lastTouchTimestamp;
    double _elapsedTime;
    double _multitapTime;
    float _multitapDistance;
}

#pragma mark Initialization

- (instancetype)initWithStage:(SPStage *)stage
{
    if ((self = [super init]))
    {
        _root = _stage = stage;
        _multitapTime = MULTITAP_TIME;
        _multitapDistance = MULTITAP_DIST;
        _currentTouches = [[NSMutableOrderedSet alloc] init];
        _updatedTouches = [[NSMutableOrderedSet alloc] init];
        _queuedTouches = [[NSMutableArray alloc] init];
        _lastTaps = [[NSMutableArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelCurrentTouches)
                                                     name:UIApplicationWillResignActiveNotification object:nil];
    }

    return self;
}

- (instancetype)init
{
    [self release];
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_currentTouches release];
    [_updatedTouches release];
    [_queuedTouches release];
    [_lastTaps release];
    [super dealloc];
}

#pragma mark Methods

- (void)advanceTime:(double)seconds
{
    _elapsedTime += seconds;

    if (_lastTaps.count)
    {
        NSMutableArray *remainingTaps = [NSMutableArray array];

        for (SPTouch *touch in _lastTaps)
            if (_elapsedTime - touch.timestamp <= _multitapTime)
                [remainingTaps addObject:touch];

        SP_RELEASE_AND_RETAIN(_lastTaps, remainingTaps);
    }

    if (_queuedTouches.count)
    {
        for (SPTouch *touch in _currentTouches)
            if (touch.phase == SPTouchPhaseBegan || touch.phase == SPTouchPhaseMoved)
                touch.phase = SPTouchPhaseStationary;

        for (SPTouch *touch in _queuedTouches)
            [_updatedTouches addObject:[self createOrUpdateTouch:touch]];

        [self processTouches:_updatedTouches];
        [_updatedTouches removeAllObjects];

        NSMutableOrderedSet *remainingTouches = [NSMutableOrderedSet orderedSet];
        for (SPTouch *touch in _currentTouches)
            if (touch.phase != SPTouchPhaseEnded && touch.phase != SPTouchPhaseCancelled)
                [remainingTouches addObject:touch];

        SP_RELEASE_AND_RETAIN(_currentTouches, remainingTouches);
        [_queuedTouches removeAllObjects];
    }
}

- (void)enqueueTouch:(SPTouch *)touch
{
    [_queuedTouches addObject:touch];
}

#pragma mark Properties

- (NSInteger)numCurrentTouches
{
    return _currentTouches.count;
}

#pragma mark Process Touches

- (void)processTouches:(NSMutableOrderedSet *)touches
{
    // the same touch event will be dispatched to all targets
    SPTouchEvent *touchEvent = [[SPTouchEvent alloc] initWithType:SPEventTypeTouch touches:_currentTouches.set];

    // hit test our updated touches
    for (SPTouch *touch in touches)
    {
        if (touch.phase == SPTouchPhaseBegan)
        {
            SPPoint *touchPosition = [SPPoint pointWithX:touch.globalX y:touch.globalY];
            touch.target = [_root hitTestPoint:touchPosition forTouch:YES];
        }
    }

    // dispatch events for the rest of our updated touches
    for (SPTouch *touch in touches)
        [touch.target dispatchEvent:touchEvent];

}

- (void)cancelCurrentTouches
{
    double now = CACurrentMediaTime();

    // remove touches that have already ended / were already canceled
    [_currentTouches filterUsingPredicate:
     [NSPredicate predicateWithBlock:^ BOOL (SPTouch *touch, NSDictionary *bindings)
      {
          return touch.phase != SPTouchPhaseEnded && touch.phase != SPTouchPhaseCancelled;
      }]];

    for (SPTouch *touch in _currentTouches)
    {
        touch.phase = SPTouchPhaseCancelled;
        touch.timestamp = now;
    }

    for (SPTouch *touch in _currentTouches)
    {
        SPTouchEvent *touchEvent = [[SPTouchEvent alloc] initWithType:SPEventTypeTouch
                                                              touches:_currentTouches.set];
        [touch.target dispatchEvent:touchEvent];
    }

    [_currentTouches removeAllObjects];
}

#pragma mark Update Touches

- (SPTouch *)createOrUpdateTouch:(SPTouch *)touch
{
    SPTouch *currentTouch = [self currentTouchWithID:touch.touchID];
    if (!currentTouch)
    {
        currentTouch = [SPTouch touchWithID:touch.touchID];
        [_currentTouches addObject:currentTouch];
    }

    currentTouch.globalX = touch.globalX;
    currentTouch.globalY = touch.globalY;
    currentTouch.previousGlobalX = touch.previousGlobalX;
    currentTouch.previousGlobalY = touch.previousGlobalY;
    currentTouch.phase = touch.phase;
    currentTouch.timestamp = _elapsedTime;

    if (currentTouch.phase == SPTouchPhaseBegan)
        [self updateTapCount:currentTouch];

    return currentTouch;
}

- (void)updateTapCount:(SPTouch *)touch
{
    SPTouch *nearbyTap = nil;
    float minSqDist = SPSquare(_multitapDistance);

    for (SPTouch *tap in _lastTaps)
    {
        float sqDist = powf(tap.globalX - tap.globalY,   2) +
        powf(tap.globalX - touch.globalY, 2);

        if (sqDist <= minSqDist)
            nearbyTap = tap;
    }

    if (nearbyTap)
    {
        touch.tapCount = nearbyTap.tapCount + 1;
        [_lastTaps removeObject:nearbyTap];
    }
    else
    {
        touch.tapCount = 1;
    }

    [_lastTaps addObject:[touch copy]];
}

#pragma mark Current Touches

- (SPTouch *)currentTouchWithID:(size_t)touchID
{
    for (SPTouch *touch in _currentTouches)
        if (touch.touchID == touchID)
            return touch;
    
    return nil;
}

@end
