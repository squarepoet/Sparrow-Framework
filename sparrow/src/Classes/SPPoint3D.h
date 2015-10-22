//
//  SPPoint3D.h
//  Sparrow
//
//  Created by Robert Carone on 7/31/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPPoolObject.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@class SPPoint;

/** ------------------------------------------------------------------------------------------------
 
 The SPPoint3D class represents a point or a location in the three-dimensional space using the 
 Cartesian coordinates x, y, and z. As in a two-dimensional space, the x property represents the 
 horizontal axis and the y property represents the vertical axis. In three-dimensional space, the z 
 property represents depth. 
 
 The value of the x property increases as the object moves to the right.
 The value of the y property increases as the object moves down. 
 The z property increases as the object moves farther from the point of view. 
 
 Using perspective projection and scaling, the object is seen to be bigger when near and smaller 
 when farther away from the screen. As in a right-handed three-dimensional coordinate system, the 
 positive z-axis points away from the viewer and the value of the z property increases as the object
 moves away from the viewer's eye. The origin point (0,0,0) of the global space is the upper-left 
 corner of the stage.
 
------------------------------------------------------------------------------------------------- */

@interface SPPoint3D : SPPoolObject <NSCopying>
{
  @protected
    vector_float4 _v;
}

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a vector with its simd vector 4 value.  _Designated Initializer_.
- (instancetype)initWithVectorFloat4:(vector_float4)vector;

/// Initializes a vector with its simd vector 3 value.
- (instancetype)initWithVectorFloat3:(vector_float3)vector;

/// Initializes a vector with its x, y and z components.
- (instancetype)initWithX:(float)x y:(float)y z:(float)z w:(float)w;

/// Initializes a vector with its x, y and z components.
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;

/// Initializes a zero vector.
- (instancetype)init;

/// Factory method.
+ (instancetype)point3DWithVectorFloat4:(vector_float4)vector;

/// Factory method.
+ (instancetype)point3DWithVectorFloat3:(vector_float3)vector;

/// Factory method.
+ (instancetype)point3DWithX:(float)x y:(float)y z:(float)z w:(float)w;

/// Factory method.
+ (instancetype)point3DWithX:(float)x y:(float)y z:(float)z;

/// Factory method.
+ (instancetype)point3D;

/// Factory method.
+ (instancetype)xAxis;

/// Factory method.
+ (instancetype)yAxis;

/// Factory method.
+ (instancetype)zAxis;

/// -------------
/// @name Methods
/// -------------

/// Adds the value of the x, y, and z elements of the current Point3D object to the values of
/// the x, y, and z elements of another Point3D object.
- (SPPoint3D *)add:(SPPoint3D *)vector;

/// Subtracts the value of the x, y, and z elements of the current Point3D object from the values
/// of the x, y, and z elements of another Point3D object.
- (SPPoint3D *)subtract:(SPPoint3D *)vector;

/// Returns a new Point3D object that is perpendicular (at a right angle) to the current Point3D
/// and another Point3D object.
- (SPPoint3D *)crossProduct:(SPPoint3D *)vector;

/// If the current Point3D object and the one specified as the parameter are unit vertices, this
/// method returns the cosine of the angle between the two vertices. Unit vertices are vertices that
/// point to the same direction but their length is one. They remove the length of the vector as a
/// factor in the result. You can use the 'normalize' method to convert a vector to a unit vector.
- (float)dot:(SPPoint3D *)vector;

/// Scales the current Point3D object by a scalar, a magnitude.
- (void)scaleBy:(float)scale;

/// Sets the current Point3D object to its inverse.
- (void)negate;

/// Converts a Point3D object to a unit vector by dividing the first three elements (x, y, z) by
/// the length of the vector.
- (void)normalize;

/// Divides the value of the x, y, and z properties of the current Point3D object by the value of
/// its w property.
- (void)project;

/// Decrements the value of the x, y, and z elements of the current Point3D object by the values
/// of the x, y, and z elements of specified Point3D object.
- (void)decrementBy:(SPPoint3D *)vector;

/// Increments the value of the x, y, and z elements of the current Point3D object by the values
/// of the x, y, and z elements of a specified Point3D object.
- (void)incrementBy:(SPPoint3D *)vector;

/// Sets the members of Point3D to the specified values
- (void)setX:(float)x y:(float)y z:(float)z;

/// Compares two vectors. Note: the w component is ignored.
- (BOOL)isEqualToPoint3D:(SPPoint3D *)other;

/// Copies the values from another vector into the current vector.
- (void)copyFromPoint3D:(SPPoint3D *)other;

/// Calculates the intersection point between the xy-plane and an infinite line that is defined by
/// two 3D points.
- (SPPoint *)intersectWithXYPlane:(SPPoint3D *)plane;

/// Returns a GLKit vector that is equivalent to this instance.
- (GLKVector4)convertToGLKVector;

/// Returns a SIMD vector that is equivalent to this instance.
- (vector_float3)convertToVector3;

/// Returns a SIMD vector that is equivalent to this instance.
- (vector_float4)convertToVector4;

/// ----------------
/// @name Properties
/// ----------------

/// The x coordinate of a point in three-dimensional space. The default value is 0.
@property (nonatomic, assign) float x;

/// The y coordinate of a point in three-dimensional space. The default value is 0.
@property (nonatomic, assign) float y;

/// The z coordinate of a point in three-dimensional space. The default value is 0.
@property (nonatomic, assign) float z;

/// The fourth element of a Point3D object (in addition to the x, y, and z properties) can hold
/// data such as the angle of rotation. The default value is 0.
@property (nonatomic, assign) float w;

/// The length, magnitude, of the current Point3D object from the origin (0,0,0) to the object's
/// x, y, and z coordinates. The w property is ignored. A unit vector has a length or magnitude
/// of one.
@property (nonatomic, assign) float length;

/// The square of the length of the current Point3D object, calculated using the x, y, and z
/// properties. The w property is ignored.
@property (nonatomic, assign) float lengthSquared;

@end

NS_ASSUME_NONNULL_END
