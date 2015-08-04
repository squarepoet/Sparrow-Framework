//
//  SPVector3D.h
//  Sparrow
//
//  Created by Robert Carone on 7/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>
#import <Sparrow/SPPoolObject.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@class SPPoint;

/** ------------------------------------------------------------------------------------------------
 
 The SPVector3D class represents a point or a location in the three-dimensional space using the 
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

@interface SPVector3D : SPPoolObject <NSCopying>
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
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;

/// Initializes a zero vector.
- (instancetype)init;

/// Factory method.
+ (instancetype)vectorWithVectorFloat4:(vector_float4)vector;

/// Factory method.
+ (instancetype)vectorWithVectorFloat3:(vector_float3)vector;

/// Factory method.
+ (instancetype)vectorWithX:(float)x y:(float)y z:(float)z;

/// Factory method.
+ (instancetype)vector;

/// Factory method.
+ (instancetype)xAxis;

/// Factory method.
+ (instancetype)yAxis;

/// Factory method.
+ (instancetype)zAxis;

/// -------------
/// @name Methods
/// -------------

/// Adds the value of the x, y, and z elements of the current Vector3D object to the values of
/// the x, y, and z elements of another Vector3D object.
- (SPVector3D *)add:(SPVector3D *)vector;

/// Subtracts the value of the x, y, and z elements of the current Vector3D object from the values
/// of the x, y, and z elements of another Vector3D object.
- (SPVector3D *)subtract:(SPVector3D *)vector;

/// Returns a new Vector3D object that is perpendicular (at a right angle) to the current Vector3D
/// and another Vector3D object.
- (SPVector3D *)crossProduct:(SPVector3D *)vector;

/// If the current Vector3D object and the one specified as the parameter are unit vertices, this
/// method returns the cosine of the angle between the two vertices. Unit vertices are vertices that
/// point to the same direction but their length is one. They remove the length of the vector as a
/// factor in the result. You can use the 'normalize' method to convert a vector to a unit vector.
- (float)dot:(SPVector3D *)vector;

/// Scales the current Vector3D object by a scalar, a magnitude.
- (SPVector3D *)scaleBy:(float)scale;

/// Sets the current Vector3D object to its inverse.
- (SPVector3D *)negate;

/// Converts a Vector3D object to a unit vector by dividing the first three elements (x, y, z) by
/// the length of the vector.
- (SPVector3D *)normalize;

/// Divides the value of the x, y, and z properties of the current Vector3D object by the value of
/// its w property.
- (SPVector3D *)project;

/// Decrements the value of the x, y, and z elements of the current Vector3D object by the values
/// of the x, y, and z elements of specified Vector3D object.
- (void)decrementBy:(SPVector3D *)vector;

/// Increments the value of the x, y, and z elements of the current Vector3D object by the values
/// of the x, y, and z elements of a specified Vector3D object.
- (void)incrementBy:(SPVector3D *)vector;

/// Sets the members of Vector3D to the specified values
- (void)setX:(float)x y:(float)y z:(float)z;

/// Compares two vectors. Note: the w component is ignored.
- (BOOL)isEqualToVector3D:(SPVector3D *)other;

/// Copies the values from another vector into the current vector.
- (void)copyFromVector3D:(SPVector3D *)other;

/// Calculates the intersection point between the xy-plane and an infinite line that is defined by
/// two 3D points.
- (SPPoint *)intersectWithXYPlane:(SPVector3D *)plane;

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

/// The fourth element of a Vector3D object (in addition to the x, y, and z properties) can hold
/// data such as the angle of rotation. The default value is 0.
@property (nonatomic, assign) float w;

/// The length, magnitude, of the current Vector3D object from the origin (0,0,0) to the object's
/// x, y, and z coordinates. The w property is ignored. A unit vector has a length or magnitude
/// of one.
@property (nonatomic, assign) float length;

/// The square of the length of the current Vector3D object, calculated using the x, y, and z
/// properties. The w property is ignored.
@property (nonatomic, assign) float lengthSquared;

@end

NS_ASSUME_NONNULL_END
