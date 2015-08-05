//
//  SPPolygon.h
//  Sparrow
//
//  Created by Robert Carone on 3/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

NS_ASSUME_NONNULL_BEGIN

@class SPIndexData;
@class SPPoint;
@class SPVertexData;

/** ------------------------------------------------------------------------------------------------

 A polygon describes a closed two-dimensional shape bounded by a number of straight line segments.
 
 The vertices of a polygon form a closed path (i.e. the last vertex will be connected to the first). 
 It is recommended to provide the vertices in clockwise order. Self-intersecting paths are not 
 supported and will give wrong results on triangulation, area calculation, etc.

------------------------------------------------------------------------------------------------- */

@interface SPPolygon : NSObject <NSCopying>

/// --------------------
/// @name Initialization
/// --------------------

/// Creates a Polygon with the given coordinates.
- (instancetype)initWithVertices:(GLKVector2 *)vertices count:(NSInteger)count;

/// Factory method.
+ (instancetype)circleWithX:(float)x y:(float)y radius:(float)radius;

/// Factory method.
+ (instancetype)elipseWithX:(float)x y:(float)y radiusX:(float)radiusX radiusY:(float)radiusY;

/// Factory method.
+ (instancetype)rectangleWithX:(float)x y:(float)y width:(float)width height:(float)height;

/// -------------
/// @name Methods
/// -------------

/// Reverses the order of the vertices. Note that some methods of the Polygon class require the
/// vertices in clockwise order.
- (void)reverse;

/// Adds vertices to the polygon. Pass either a list of 'Point' instances or alternating
/// 'x' and 'y' coordinates.
- (void)addVertices:(GLKVector2 *)vertices count:(NSInteger)count;

/// Moves a given vertex to a certain position or adds a new vertex at the end.
- (void)setVertexWithX:(float)x y:(float)y atIndex:(NSInteger)index;

/// Returns the coordinates of a certain vertex.
- (GLKVector2)vertexAtIndex:(NSInteger)index;

/// Figures out if the given point lies within the polygon.
- (BOOL)containsPoint:(SPPoint *)point;

/// Figures out if the given coordinates lie within the polygon.
- (BOOL)containsPointWithX:(float)x y:(float)y;

/// Calculates a possible representation of the polygon via triangles. The resulting vector
/// contains a list of vertex indices, where every three indices describe a triangle referencing
/// the vertices of the polygon.
- (SPIndexData *)triangulate:(nullable SPIndexData *)result;

/// Copies all vertices to a 'VertexData' instance, beginning at a certain target index.
- (void)copyToVertexData:(SPVertexData *)targetData atIndex:(NSInteger)targetIndex;

/// Copies all vertices to a 'Vector', beginning at a certain target index and skipping 'stride'
/// coordinates between each 'x, y' pair.
- (void)copyToVertices:(float *)vertices atIndex:(NSInteger)index withStride:(NSInteger)stride;

/// ----------------
/// @name Properties
/// ----------------

/// Indicates if the polygon's line segments are not self-intersecting. Beware: this is a
/// brute-force implementation with <code>O(n^2)</code>.
@property (nonatomic, readonly) BOOL isSimple;

/// Indicates if the polygon is convex. In a convex polygon, the vector between any two points
/// inside the polygon lies inside it, as well.
@property (nonatomic, readonly) BOOL isConvex;

/// Calculates the total area of the polygon.
@property (nonatomic, readonly) float area;

/// Returns the total number of vertices spawning up the polygon. Assigning a value that's smaller
/// than the current number of vertices will crop the path; a bigger value will fill up the path
/// with zeros.
@property (nonatomic, assign) NSInteger numVertices;

@end

NS_ASSUME_NONNULL_END
