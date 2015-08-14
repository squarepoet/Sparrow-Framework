//
//  SPTextureCache.h
//  Sparrow
//
//  Created by Daniel Sperl on 25.03.14.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>

NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------

 The cache keeps weak references to all loaded objects. It is essentially thread-safe wrapper 
 around NSMapTable.

 The SPTexture class uses this class in order to cache texture objects. When you try to instantiate 
 a texture that is already in memory, it is taken from the cache instead of loading it again.

 _This is an internal class. You do not have to use it manually._
 
 @see NSMapTable

------------------------------------------------------------------------------------------------- */

@interface SPCache<KeyType, ObjectType> : NSObject <NSCopying, NSFastEnumeration>

/// Initializes a cache with a map table object used as the underlying storage object.
- (instancetype)initWithMapTable:(NSMapTable *)mapTable;

/// Initializes a cache which has strong references to the keys and weak references to the values.
- (instancetype)initWithWeakValues;

/// Initializes a cache which has strong references to the keys and values.
- (instancetype)init;

/// Returns the object stored with the given key, or `nil` if that object is not available.
- (nullable ObjectType)objectForKey:(KeyType)key;

/// Stores a weak reference to the given object. The object is not retained;
/// when it is deallocated, it is automatically removed from the cache.
- (void)setObject:(ObjectType)obj forKey:(KeyType)key;

/// Removes a given key and its associated value from the cache.
- (void)removeObjectForKey:(KeyType)key;

/// Removes all references.
- (void)purge;

/// Returns the object at the keyed subscript.
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

/// Set an object for the keyed subscript.
- (void)setObject:(ObjectType)obj forKeyedSubscript:(KeyType)key;

/// The number of key-value pairs in the cache.
@property (nonatomic, readonly) NSInteger count;

@end

NS_ASSUME_NONNULL_END
