//
//  SPTextureCache.m
//  Sparrow
//
//  Created by Daniel Sperl on 25.03.14.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPCache.h"

#import <libkern/OSAtomic.h>

@implementation SPCache
{
    NSMapTable *_cache;
    OSSpinLock _lock;
}

#pragma mark Initialization

- (instancetype)initWithMapTable:(NSMapTable *)mapTable
{
    if (self = [super init])
    {
        _cache = [mapTable retain];
    }
    return self;
}

- (instancetype)initWithWeakValues
{
    return [self initWithMapTable:[NSMapTable strongToWeakObjectsMapTable]];
}

- (instancetype)init
{
    return [self initWithMapTable:[NSMapTable strongToStrongObjectsMapTable]];
}

- (void)dealloc
{
    [_cache release];
    [super dealloc];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPCache *cache = [[[self class] alloc] init];
    
    OSSpinLockLock(&_lock);
    SP_RELEASE_AND_COPY(cache->_cache, _cache);
    OSSpinLockUnlock(&_lock);
    
    return cache;
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)len
{
    OSSpinLockLock(&_lock);
    NSInteger count = [_cache countByEnumeratingWithState:state objects:buffer count:len];
    OSSpinLockUnlock(&_lock);
    
    return count;
}

#pragma mark Methods

- (id)objectForKey:(id)key
{
    OSSpinLockLock(&_lock);
    id object = [[_cache objectForKey:key] retain];
    OSSpinLockUnlock(&_lock);
    
    return [object autorelease];
}

- (void)setObject:(id)obj forKey:(id)key
{
    OSSpinLockLock(&_lock);
    [_cache setObject:obj forKey:key];
    OSSpinLockUnlock(&_lock);
}

- (void)removeObjectForKey:(id)key
{
    OSSpinLockLock(&_lock);
    [_cache removeObjectForKey:key];
    OSSpinLockUnlock(&_lock);
}

- (void)purge
{
    OSSpinLockLock(&_lock);
    [_cache removeAllObjects];
    OSSpinLockUnlock(&_lock);
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    [self setObject:obj forKey:key];
}

- (NSInteger)count
{
    OSSpinLockLock(&_lock);
    NSInteger count = _cache.count;
    OSSpinLockUnlock(&_lock);
    
    return count;
}

@end
