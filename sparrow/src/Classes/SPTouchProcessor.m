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
    SPStage *_stage;
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

        [[NSNotificationCenter defaultCenter]
            addObserver:self selector:@selector(cancelCurrentTouches)
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
    
    // remove old taps
    if (_lastTaps.count)
    {
        NSMutableArray *remainingTaps = [NSMutableArray array];
        
        for (SPTouch *touch in _lastTaps)
            if (_elapsedTime - touch.timestamp <= _multitapTime)
                [remainingTaps addObject:touch];
        
        SP_RELEASE_AND_RETAIN(_lastTaps, remainingTaps);
    }
    
    while (_queuedTouches.count)
    {
        NSMutableArray *excessTouches = [NSMutableArray array];
        
        // set touches that were new or moving to phase 'SPTouchPhaseStationary'
        for (SPTouch *touch in _currentTouches)
            if (touch.phase == SPTouchPhaseBegan || touch.phase == SPTouchPhaseMoved)
                touch.phase = SPTouchPhaseStationary;
        
        // analyze new touches, but each ID only once
        for (SPTouch *touch in _queuedTouches)
        {
            if (![_updatedTouches containsObject:touch])
            {
                [self addCurrentTouch:touch];
                [_updatedTouches addObject:touch];
            }
            else
            {
                [excessTouches addObject:touch];
            }
        }
        
        // process the current set of touches (i.e. dispatch touch events)
        [self processTouches:_updatedTouches.set];
        [_updatedTouches removeAllObjects];
        
        // remove ended touches
        [self removeEndedTouches];
        
        // switch to excess touches
        SP_RELEASE_AND_RETAIN(_queuedTouches, excessTouches);
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

- (void)processTouches:(NSSet *)touches
{
    // hit test our updated touches
    for (SPTouch *touch in touches)
    {
        if (touch.phase == SPTouchPhaseBegan)
        {
            SPPoint *touchPosition = [SPPoint pointWithX:touch.globalX y:touch.globalY];
            touch.target = [_root hitTestPoint:touchPosition forTouch:YES];
        }
    }
    
    // the same touch event will be dispatched to all targets
    SPTouchEvent *touchEvent =
        [[SPTouchEvent alloc] initWithType:SPEventTypeTouch touches:_currentTouches.set];

    // dispatch events for the rest of our updated touches
    for (SPTouch *touch in touches)
        [touch.target dispatchEvent:touchEvent];
    
    [touchEvent release];
}

- (void)cancelCurrentTouches
{
    // remove touches that have already ended / were already canceled
    [self removeEndedTouches];
    
    double now = CACurrentMediaTime();
    for (SPTouch *touch in _currentTouches)
    {
        touch.phase = SPTouchPhaseCancelled;
        touch.timestamp = now;
    }
    
    SPTouchEvent *touchEvent = [[SPTouchEvent alloc]
    	initWithType:SPEventTypeTouch touches:_currentTouches.set];

    for (SPTouch *touch in _currentTouches)
        [touch.target dispatchEvent:touchEvent];
    
    [touchEvent release];
    [_currentTouches removeAllObjects];
}

#pragma mark Update Touches

- (void)addCurrentTouch:(SPTouch *)touch
{
    NSUInteger index = [_currentTouches indexOfObject:touch];
    
    // add/replace
    if (index != NSNotFound)
    {
        SPTouch *currentTouch = _currentTouches[index];
        touch.target = currentTouch.target; // save the target
        [_currentTouches replaceObjectAtIndex:index withObject:touch];
    }
    else
    {
        [_currentTouches addObject:touch];
    }
    
    // update timestamp
    touch.timestamp = _elapsedTime;
    
    // update taps
    if (touch.phase == SPTouchPhaseBegan)
        [self updateTapCount:touch];
}

- (void)updateTapCount:(SPTouch *)touch
{
    SPTouch *nearbyTap = nil;
    float minSqDist = SPSquare(_multitapDistance);

    for (SPTouch *tap in _lastTaps)
    {
        float sqDist = powf(tap.globalX - touch.globalX, 2) +
                       powf(tap.globalY - touch.globalY, 2);

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

    [_lastTaps addObject:[[touch copy] autorelease]];
}

- (void)removeEndedTouches
{
    [_currentTouches filterUsingPredicate:
     [NSPredicate predicateWithBlock:^ BOOL (SPTouch *touch, NSDictionary *bindings)
      {
          return touch.phase != SPTouchPhaseEnded &&
                 touch.phase != SPTouchPhaseCancelled;
      }]];
}

@end
