//
//  SPVector3D.m
//  Sparrow
//
//  Created by Robert Carone on 7/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPPoint.h"
#import "SPVector3D.h"

@implementation SPVector3D

#pragma mark Initialization

- (instancetype)initWithVectorFloat4:(vector_float4)vector
{
    if (self)
    {
        _v = vector;
    }
    return self;
}

- (instancetype)initWithVectorFloat3:(vector_float3)vector
{
    return [self initWithVectorFloat4:(vector_float4){ vector.x, vector.y, vector.z, 0 }];
}

- (instancetype)initWithX:(float)x y:(float)y z:(float)z
{
    return [self initWithVectorFloat4:(vector_float4){ x, y, z, 0 }];
}

- (instancetype)init
{
    return [self initWithVectorFloat4:(vector_float4){ 0 }];
}

+ (instancetype)vector3DWithVectorFloat3:(vector_float3)vector
{
    return [[[self alloc] initWithVectorFloat3:vector] autorelease];
}

+ (instancetype)vector3DWithVectorFloat4:(vector_float4)vector
{
    return [[[self alloc] initWithVectorFloat4:vector] autorelease];
}

+ (instancetype)vector3DWithX:(float)x y:(float)y z:(float)z
{
    return [[[self alloc] initWithX:x y:y z:z] autorelease];
}

+ (instancetype)vector3D
{
    return [[[self alloc] init] autorelease];
}

+ (instancetype)xAxis
{
    return [[[self alloc] initWithVectorFloat4:(vector_float4){ 1, 0, 0, 0 }] autorelease];
}

+ (instancetype)yAxis
{
    return [[[self alloc] initWithVectorFloat4:(vector_float4){ 0, 1, 0, 0 }] autorelease];
}

+ (instancetype)zAxis
{
    return [[[self alloc] initWithVectorFloat4:(vector_float4){ 0, 0, 1, 0 }] autorelease];
}

#pragma mark Methods

- (SPVector3D *)add:(SPVector3D *)vector
{
    return [SPVector3D vector3DWithVectorFloat3:_v.xyz + vector->_v.xyz];
}

- (SPVector3D *)subtract:(SPVector3D *)vector
{
    return [SPVector3D vector3DWithVectorFloat3:_v.xyz - vector->_v.xyz];
}

- (SPVector3D *)crossProduct:(SPVector3D *)vector
{
    return [SPVector3D vector3DWithVectorFloat3:vector_cross(_v.xyz, _v.xyz)];
}

- (float)dot:(SPVector3D *)vector
{
    return vector_dot(_v.xyz, _v.xyz);
}

- (void)negate
{
    _v.xyz = -_v.xyz;
}

- (void)normalize
{
    _v.xyz = vector_normalize(_v.xyz);
}

- (void)scaleBy:(float)scale
{
    _v.xyz *= scale;
}

- (void)project
{
    _v.xyz /= _v.w;
}

- (void)incrementBy:(SPVector3D *)vector
{
    _v.xyz += vector->_v.xyz;
}

- (void)decrementBy:(SPVector3D *)vector
{
    _v.xyz -= vector->_v.xyz;
}

- (void)setX:(float)x y:(float)y z:(float)z
{
    _v.x = x;
    _v.y = y;
    _v.z = z;
}

- (BOOL)isEqualToVector3D:(SPVector3D *)other
{
    if (other == self) return YES;
    else if (!other) return NO;
    else
    {
        return SPIsFloatEqual(_v.x, other->_v.x) &&
               SPIsFloatEqual(_v.y, other->_v.y) &&
               SPIsFloatEqual(_v.z, other->_v.z);
    }
}

- (void)copyFromVector3D:(SPVector3D *)other
{
    _v = other->_v;
}

- (SPPoint *)intersectWithXYPlane:(SPVector3D *)plane
{
    vector_float3 vector = plane->_v.xyz - _v.xyz;
    float lamda = -_v.z / vector.z;
    
    return [SPPoint pointWithX:_v.x + lamda + vector.x
                             y:_v.y + lamda + vector.y];
}

- (GLKVector4)convertToGLKVector
{
    return *(GLKVector4 *)&_v;
}

- (vector_float3)convertToVector3
{
    return _v.xyz;
}

- (vector_float4)convertToVector4
{
    return _v;
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if (!object)
        return NO;
    else if (object == self)
        return YES;
    else if (![object isKindOfClass:[SPPoint class]])
        return NO;
    else
        return [self isEqualToVector3D:object];
}

- (NSUInteger)hash
{
    return SPHashFloat(_v.x) ^
           SPShiftAndRotate(SPHashFloat(_v.y), 1) ^
           SPShiftAndRotate(SPHashFloat(_v.z), 1);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[SPVector3D: x=%f, y=%f, z=%f, w=%f]",
            _v.x, _v.y, _v.z, _v.w];
}

#pragma mark NSCopying

- (instancetype)copy
{
    return [[[self class] alloc] initWithVectorFloat4:_v];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [self copy];
}

#pragma mark Properties

- (float)x
{
    return _v.x;
}

- (void)setX:(float)x
{
    _v.x = x;
}

- (float)y
{
    return _v.y;
}

- (void)setY:(float)y
{
    _v.y = y;
}

- (float)z
{
    return _v.z;
}

- (void)setZ:(float)z
{
    _v.z = z;
}

- (float)w
{
    return _v.w;
}

- (void)setW:(float)w
{
    _v.w = w;
}

- (float)length
{
    return vector_length(_v.xyz);
}

- (float)lengthSquared
{
    return vector_length_squared(_v.xyz);
}

@end
