//
//  SPTouchEvent.m
//  Sparrow
//
//  Created by Daniel Sperl on 02.05.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPDisplayObject.h"
#import "SPDisplayObjectContainer.h"
#import "SPEvent_Internal.h"
#import "SPMacros.h"
#import "SPTouchEvent.h"

#define ANY_PHASE ((SPTouchPhase)-1)
#define ANY_TOUCH ((size_t)-1)

NSString *const SPEventTypeTouch = @"SPEventTypeTouch";

// --- class implementation ------------------------------------------------------------------------

@implementation SPTouchEvent
{
    SP_GENERIC(NSSet, SPTouch*) *_touches;
}

#pragma mark Initialization

- (instancetype)initWithType:(NSString *)type bubbles:(BOOL)bubbles touches:(SP_GENERIC(NSSet, SPTouch*) *)touches
{
    if ((self = [super initWithType:type bubbles:bubbles]))
    {        
        _touches = [touches retain];
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type touches:(SP_GENERIC(NSSet, SPTouch*) *)touches
{
    return [self initWithType:type bubbles:YES touches:touches];
}

- (instancetype)initWithType:(NSString *)type bubbles:(BOOL)bubbles
{
    return [self initWithType:type bubbles:bubbles touches:[NSSet set]];
}

- (void)dealloc
{
    [_touches release];
    [super dealloc];
}

+ (instancetype)eventWithType:(NSString *)type touches:(SP_GENERIC(NSSet, SPTouch*) *)touches
{
    return [[[self alloc] initWithType:type touches:touches] autorelease];
}

#pragma mark Methods

- (SP_GENERIC(NSSet, SPTouch*) *)touchesWithTarget:(SPDisplayObject *)target
{
    return [self touchesWithTarget:target andPhase:ANY_PHASE];
}

- (SP_GENERIC(NSSet, SPTouch*) *)touchesWithTarget:(SPDisplayObject *)target andPhase:(SPTouchPhase)phase
{
    SP_GENERIC(NSMutableSet, SPTouch*) *touchesFound = [NSMutableSet set];
    for (SPTouch *touch in _touches)
    {
        BOOL correctPhase = phase == ANY_PHASE || touch.phase == phase;
        if (correctPhase && [touch isTouchingTarget:target])
            [touchesFound addObject:touch];
    }
    return touchesFound;
}

- (SPTouch *)touchWithTarget:(SPDisplayObject *)target
{
    return [self touchWithTarget:target andPhase:ANY_PHASE touchID:ANY_TOUCH];
}

- (SPTouch *)touchWithTarget:(SPDisplayObject *)target andPhase:(SPTouchPhase)phase
{
    return [self touchWithTarget:target andPhase:phase touchID:ANY_TOUCH];
}

- (SPTouch *)touchWithTarget:(SPDisplayObject *)target andPhase:(SPTouchPhase)phase touchID:(size_t)touchID
{
    NSSet *touches = [self touchesWithTarget:target andPhase:phase];
    if (touches.count > 0)
    {
        if (touchID == ANY_TOUCH) return [touches anyObject];
        else
        {
            for (SPTouch *touch in touches)
                if (touch.touchID == touchID)
                    return touch;
        }
    }
    
    return nil;
}

- (BOOL)interactsWithTarget:(SPDisplayObject *)target
{
    NSSet *touches = [self touchesWithTarget:target andPhase:ANY_PHASE];
    for (SPTouch *touch in touches)
        if (touch.phase != SPTouchPhaseEnded)
            return YES;
    
    return NO;
}

#pragma mark Properties

- (double)timestamp
{
    return [[_touches anyObject] timestamp];
}

@end
