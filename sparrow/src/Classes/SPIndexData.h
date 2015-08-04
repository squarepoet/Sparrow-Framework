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

@interface SPIndexData : NSObject <NSCopying>

/// --------------------
/// @name Initialization
/// --------------------

///
- (instancetype)initWithSize:(int)numIndices;

///
- (instancetype)init;

/// -------------
/// @name Methods
/// -------------

/// Copies the vertex data of this instance to another vertex data object, starting at element 0.
- (void)copyToIndexData:(SPIndexData *)target;

/// Copies the vertex data of this instance to another vertex data object, starting at a certain index.
- (void)copyToIndexData:(SPIndexData *)target atIndex:(int)targetIndex;

/// Copies a range of vertices of this instance to another vertex data object.
- (void)copyToIndexData:(SPIndexData *)target atIndex:(int)targetIndex numIndices:(int)count;

///
- (void)appendIndex:(ushort)index;

///
- (void)removeIndexAtIndex:(int)index;

///
- (void)setIndex:(ushort)i atIndex:(int)index;

///
- (void)appendTriangleWithA:(ushort)a b:(ushort)b c:(ushort)c;

///
- (void)offsetIndicesAtIndex:(int)index numIndices:(int)count offset:(ushort)offset;

/// ----------------
/// @name Properties
/// ----------------

///
@property (nonatomic, readonly) ushort *indices;

///
@property (nonatomic, assign) int numIndices;

@end
