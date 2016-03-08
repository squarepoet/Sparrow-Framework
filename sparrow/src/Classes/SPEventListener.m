//
//  SPEventListener.m
//  Sparrow
//
//  Created by Daniel Sperl on 28.02.13.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPEventListener.h"
#import "SPMacros.h"
#import "SPNSExtensions.h"

#import <objc/message.h>
#import <objc/runtime.h> // weak

@implementation SPEventListener
{
    id _target;
    SPEventBlock _block;
    SEL _selector;
}

static inline id getTarget(SPEventListener *self)
{
    return objc_loadWeak(&self->_target);
}

#pragma mark Initialization

- (instancetype)initWithTarget:(id)target selector:(SEL)selector block:(SPEventBlock)block
{
    if (self = [super init])
    {
        objc_storeWeak(&_target, target);
        _block = [block copy];
        _selector = selector;
    }
    
    return self;
}

- (void)dealloc
{
    [_block release];
    [super dealloc];
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector
{
    return [self initWithTarget:target selector:selector block:^(SPEvent *event)
            {
                typedef void (*EventFunc)(id, SEL, SPEvent *);
                ((EventFunc)objc_msgSend)(getTarget(self), selector, event);
            }];
}

- (instancetype)initWithBlock:(SPEventBlock)block
{
    return [self initWithTarget:nil selector:nil block:block];
}

#pragma mark Methods

- (void)invokeWithEvent:(SPEvent *)event
{
    _block(event);
}

- (BOOL)fitsTarget:(id)target andSelector:(SEL)selector orBlock:(SPEventBlock)block
{
    BOOL fitsTargetAndSelector = (target && (target == _target)) && (!selector || (selector == _selector));
    BOOL fitsBlock = block == _block;
    return fitsTargetAndSelector || fitsBlock;
}

- (id)target
{
    return getTarget(self);
}

@end
