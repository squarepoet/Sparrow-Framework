//
//  SPPress.m
//  Sparrow
//
//  Created by Robert Carone on 10/24/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPPress_Internal.h"

@interface SPPress ()

@property (nonatomic, assign) size_t pressID;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) SPPressPhase phase;
@property (nonatomic, assign) SPPressType type;
@property (nonatomic, assign) float force;

@end

@implementation SPPress

- (instancetype)initWithID:(size_t)pressID
{
    if (self = [super init])
    {
        _pressID = pressID;
    }
    return self;
}

+ (instancetype)pressWithID:(size_t)pressID
{
    return [[[self alloc] initWithID:pressID] autorelease];
}

+ (instancetype)press
{
    return [[[self alloc] init] autorelease];
}

#pragma mark NSObject

- (NSUInteger)hash
{
    return _pressID;
}

- (BOOL)isEqualTo:(id)object
{
    if (!object)
        return NO;
    else if (object == self)
        return YES;
    else if ([object isKindOfClass:[SPPress class]])
        return [object pressID] == _pressID;
    
    return NO;
}

@end
