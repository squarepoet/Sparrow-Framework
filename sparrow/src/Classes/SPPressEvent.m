//
//  SPPressEvent.m
//  Sparrow
//
//  Created by Robert Carone on 10/24/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPPress.h"
#import "SPPressEvent.h"

@implementation SPPressEvent

- (instancetype)initWithType:(NSString *)type bubbles:(BOOL)bubbles presses:(SP_GENERIC(NSSet, SPPress*) *)presses
{
    if (self = [super initWithType:type bubbles:bubbles])
    {
        _presses = [presses retain];
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type presses:(SP_GENERIC(NSSet, SPPress*) *)presses
{
    return [[self initWithType:type bubbles:NO presses:presses] autorelease];
}

+ (instancetype)eventWithType:(NSString *)type presses:(SP_GENERIC(NSSet, SPPress*) *)presses
{
    return [[[self alloc] initWithType:type bubbles:NO presses:presses] autorelease];
}

- (void)dealloc
{
    [_presses release];
    [super dealloc];
}

- (double)timestamp
{
    return _presses.anyObject.timestamp;
}

@end
