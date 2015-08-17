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

@implementation SPCache
{
    NSMapTable *_cache;
    dispatch_queue_t _queue;
}

#pragma mark Initialization

- (instancetype)initWithMapTable:(NSMapTable *)mapTable
{
    if (self = [super init])
    {
        _cache = [mapTable retain];
        
        NSString *label = [NSString stringWithFormat:@"com.gamua.Sparrow.CacheQueue:%zx", (size_t)self];
        _queue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_CONCURRENT);
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
    [(id)_queue release];
    [_cache release];
    [super dealloc];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SPCache *cache = [[[self class] alloc] init];
    SP_RELEASE_AND_COPY(cache->_cache, _cache);
    return cache;
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nonnull *)buffer count:(NSUInteger)len
{
    __block NSInteger count = 0;
    
    dispatch_sync(_queue, ^
    {
        count = [_cache countByEnumeratingWithState:state objects:buffer count:len];
    });
    
    return count;
}

#pragma mark Methods

- (id)objectForKey:(id)key
{
    __block id texture;
    
    dispatch_sync(_queue, ^
    {
        texture = [[_cache objectForKey:key] retain];
    });

    return [texture autorelease];
}

- (void)setObject:(id)obj forKey:(id)key
{
    dispatch_barrier_async(_queue, ^
    {
        [_cache setObject:obj forKey:key];
    });
}

- (void)removeObjectForKey:(id)key
{
    dispatch_barrier_async(_queue, ^
    {
        [_cache removeObjectForKey:key];
    });
}

- (void)purge
{
    dispatch_barrier_async(_queue, ^
    {
        [_cache removeAllObjects];
    });
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
    __block NSInteger count = 0;
    
    dispatch_sync(_queue, ^
    {
        count = _cache.count;
    });
    
    return count;
}

@end
