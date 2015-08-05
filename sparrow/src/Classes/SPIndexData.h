//
//  SPIndexData.h
//  Sparrow
//
//  Created by Robert Carone on 3/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Foundation/Foundation.h>

/** ------------------------------------------------------------------------------------------------
 
 The SPIndexData class manages a raw list of indices. This class is best used for managing a list 
 of triangles for a SPVertexData object.
 
 ------------------------------------------------------------------------------------------------- */

@interface SPIndexData : NSObject <NSCopying>

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a IndexData instance with a certain size. _Designated Initializer_.
- (instancetype)initWithSize:(NSInteger)numIndices;

/// Initializes an empty IndexData object. Use the `appendIndex:` method and the `numIndices`
/// property to change its size later.
- (instancetype)init;

/// -------------
/// @name Methods
/// -------------

/// Copies the index data of this instance to another index data object, starting at element 0.
- (void)copyToIndexData:(SPIndexData *)target;

/// Copies the index data of this instance to another index data object, starting at a certain index.
- (void)copyToIndexData:(SPIndexData *)target atIndex:(NSInteger)targetIndex;

/// Copies a range of indices of this instance to another index data object.
- (void)copyToIndexData:(SPIndexData *)target atIndex:(NSInteger)targetIndex numIndices:(NSInteger)count;

/// Append an index.
- (void)appendIndex:(ushort)index;

/// Removes an index at the specified index.
- (void)removeIndexAtIndex:(NSInteger)index;

/// Sets an index at the specified index.
- (void)setIndex:(ushort)i atIndex:(NSInteger)index;

/// Appends 3 indices representing a triangle.
- (void)appendTriangleWithA:(ushort)a b:(ushort)b c:(ushort)c;

/// Offset all indices in the specified range by the given offset.
- (void)offsetIndicesAtIndex:(NSInteger)index numIndices:(NSInteger)count offset:(ushort)offset;

/// ----------------
/// @name Properties
/// ----------------

/// Returns a pointer to the raw index data.
@property (nonatomic, readonly) ushort *indices;

/// Indicates the size of the IndexData object. You can resize the object any time; if you
/// make it bigger, it will be filled up with indices set to zero.
@property (nonatomic, assign) NSInteger numIndices;

@end
