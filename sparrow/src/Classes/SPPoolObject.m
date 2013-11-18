//
//  SPPoolObject.m
//  Sparrow
//
//  Created by Daniel Sperl on 17.09.09.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPPoolObject.h"
#import "SPMacros.h"

#import <libkern/OSAtomic.h>
#import <malloc/malloc.h>
#import <objc/runtime.h>

#ifndef DISABLE_MEMORY_POOLING

// --- hash table ----------------------------------------------------------------------------------

#define HASH_MASK (SP_POOL_OBJECT_MAX_CLASSES - 1)

typedef struct
{
    Class key;
    OSQueueHead value;
}
Pair;

typedef struct
{
    Pair table[SP_POOL_OBJECT_MAX_CLASSES];
}
PoolCache;

SP_INLINE PoolCache *poolCache(void)
{
    static PoolCache instance = (PoolCache){{ nil, OS_ATOMIC_QUEUE_INIT }};
    return &instance;
}

SP_INLINE unsigned hashPtr(void* ptr)
{
#ifdef __LP64__
    return (unsigned)(((uintptr_t)ptr) >> 3);
#else
    return ((uintptr_t)ptr) >> 2;
#endif
}

SP_INLINE Pair *getPairWith(PoolCache *cache, unsigned key)
{
    unsigned h = key & HASH_MASK;
    return &(cache->table[h]);
}

SP_INLINE void initPoolWith(PoolCache *cache, Class class)
{
    unsigned key = hashPtr(class);
    Pair *pair = getPairWith(cache, key);
    pair->key = class;
    pair->value = (OSQueueHead)OS_ATOMIC_QUEUE_INIT;
}

SP_INLINE OSQueueHead *getPoolWith(PoolCache *cache, Class class)
{
    unsigned key = hashPtr(class);
    Pair *pair = getPairWith(cache, key);
    assert(pair->key == class);
    return &pair->value;
}

// --- queue ---------------------------------------------------------------------------------------

#define QUEUE_OFFSET sizeof(Class)

#if SP_POOL_OBJECT_IS_ATOMIC
    #define DEQUEUE(pool)       OSAtomicDequeue(pool, QUEUE_OFFSET)
    #define ENQUEUE(pool, obj)  OSAtomicEnqueue(pool, obj, QUEUE_OFFSET)
#else
    #define DEQUEUE(pool)       dequeue(pool)
    #define ENQUEUE(pool, obj)  enqueue(pool, obj)

    SP_INLINE void enqueue(OSQueueHead *list, void *new)
    {
        *((void **)((char *)new + QUEUE_OFFSET)) = list->opaque1;
        list->opaque1 = new;
    }

    SP_INLINE void* dequeue(OSQueueHead *list)
    {
        void *head;

        head = list->opaque1;
        if (head != NULL) {
            void **next = (void **)((char *)head + QUEUE_OFFSET);
            list->opaque1 = *next;
        }

        return head;
    }
#endif

// --- class implementation ------------------------------------------------------------------------

#if SP_POOL_OBJECT_IS_ATOMIC
    typedef volatile int32_t RCint;
    #define INCREMENT_32(var) OSAtomicIncrement32(&var)
    #define DECREMENT_32(var) OSAtomicDecrement32(&var)
#else
    typedef int32_t RCint;
    #define INCREMENT_32(var) (++ var)
    #define DECREMENT_32(var) (-- var)
#endif

@implementation SPPoolObject
{
    RCint _rc;
#ifdef __LP64__
    uint8_t _extra[4];
#endif
}

+ (void)initialize
{ 
    if (self == [SPPoolObject class])
        return;

    initPoolWith(poolCache(), self);
}

+ (id)allocWithZone:(NSZone *)zone
{
  #if DEBUG && !SP_POOL_OBJECT_IS_ATOMIC
    // make sure that people don't use pooling from multiple threads
    static id thread = nil;
    if (thread) NSAssert(thread == [NSThread currentThread], @"SPPoolObject is NOT thread safe! "
                                                             @"Set SP_POOL_OBJECT_IS_ATOMIC to 1.");
    else thread = [NSThread currentThread];
  #endif

    OSQueueHead *poolQueue = getPoolWith(poolCache(), self);
    SPPoolObject *object = DEQUEUE(poolQueue);

    if (object)
    {
        // zero out memory. (do not overwrite isa, thus the offset)
        static size_t offset = sizeof(Class);
        memset((char *)object + offset, 0, malloc_size(object) - offset);
        object->_rc = 1;
    }
    else
    {
        // pool is empty -> allocate
        object = NSAllocateObject(self, 0, NULL);
        object->_rc = 1;
    }

    return object;
}

- (NSUInteger)retainCount
{
    return _rc;
}

- (instancetype)retain
{
    INCREMENT_32(_rc);
    return self;
}

- (oneway void)release
{
    if (DECREMENT_32(_rc))
        return;

    OSQueueHead *poolQueue = getPoolWith(poolCache(), object_getClass(self));
    ENQUEUE(poolQueue, self);
}

- (void)purge
{
    // will call 'dealloc' internally -- which should not be called directly.
    [super release];
}

+ (NSUInteger)purgePool
{
    OSQueueHead *poolQueue = getPoolWith(poolCache(), self);
    SPPoolObject *lastElement;

    NSUInteger count = 0;
    while ((lastElement = DEQUEUE(poolQueue)))
    {
        ++count;
        [lastElement purge];
    }

    return count;
}

@end

#else // DISABLE_MEMORY_POOLING

@implementation SPPoolObject

+ (NSUInteger)purgePool
{
    return 0;
}

@end

#endif
