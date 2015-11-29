//
//  SPEvent.m
//  Sparrow
//
//  Created by Daniel Sperl on 27.04.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPEvent.h"
#import "SPEventDispatcher.h"
#import "SPEvent_Internal.h"
#import "SPMacros.h"

// --- event types ---------------------------------------------------------------------------------

NSString *const SPEventTypeAdded                = @"SPEventTypeAdded";
NSString *const SPEventTypeAddedToStage         = @"SPEventTypeAddedToStage";
NSString *const SPEventTypeRemoved              = @"SPEventTypeRemoved";
NSString *const SPEventTypeRemovedFromStage     = @"SPEventTypeRemovedFromStage";
NSString *const SPEventTypeRemoveFromJuggler    = @"SPEventTypeRemoveFromJuggler";
NSString *const SPEventTypeCompleted            = @"SPEventTypeCompleted";
NSString *const SPEventTypeTriggered            = @"SPEventTypeTriggered";
NSString *const SPEventTypeFlatten              = @"SPEventTypeFlatten";
NSString *const SPEventTypeRender               = @"SPEventTypeRender";
NSString *const SPEventTypePress                = @"SPEventTypePress";

// --- class implementation ------------------------------------------------------------------------

@implementation SPEvent
{
    SPEventDispatcher *__weak _target;
    SPEventDispatcher *__weak _currentTarget;
    NSString *_type;
    id _data;
    BOOL _stopsImmediatePropagation;
    BOOL _stopsPropagation;
    BOOL _bubbles;
}

#pragma mark Initialization

- (instancetype)initWithType:(NSString *)type bubbles:(BOOL)bubbles data:(id)data
{
    if ((self = [super init]))
    {
        _type = [[NSString alloc] initWithString:type];
        _data = [data retain];
        _bubbles = bubbles;
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type bubbles:(BOOL)bubbles
{
    return [self initWithType:type bubbles:bubbles data:nil];
}

- (instancetype)initWithType:(NSString *)type
{
    return [self initWithType:type bubbles:NO];
}

- (instancetype)init
{
    return [self initWithType:@"undefined"];
}

- (void)dealloc
{
    [_data release];
    [_type release];
    [super dealloc];
}

+ (instancetype)eventWithType:(NSString *)type bubbles:(BOOL)bubbles data:(id)object
{
    return [[[self alloc] initWithType:type bubbles:bubbles data:object] autorelease];
}

+ (instancetype)eventWithType:(NSString *)type bubbles:(BOOL)bubbles
{
    return [[[self alloc] initWithType:type bubbles:bubbles] autorelease];
}

+ (instancetype)eventWithType:(NSString *)type
{
    return [[[self alloc] initWithType:type] autorelease];
}

#pragma mark Methods

- (void)stopImmediatePropagation
{
    _stopsImmediatePropagation = YES;
}

- (void)stopPropagation
{
    _stopsPropagation = YES;
}

#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@: type=\"%@\", bubbles=%@]",
            NSStringFromClass([self class]), _type, _bubbles ? @"YES" : @"NO"];
}

@end

// --- internal implementation ---------------------------------------------------------------------

@implementation SPEvent (Internal)

- (BOOL)stopsImmediatePropagation
{ 
    return _stopsImmediatePropagation;
}

- (BOOL)stopsPropagation
{ 
    return _stopsPropagation;
}

- (void)setTarget:(SPEventDispatcher *)target
{
    if (_target != target)
        _target = target;
}

- (void)setCurrentTarget:(SPEventDispatcher *)currentTarget
{
    if (_currentTarget != currentTarget)
        _currentTarget = currentTarget;
}

@end
