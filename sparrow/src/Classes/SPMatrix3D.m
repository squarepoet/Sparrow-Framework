//
//  SPMatrix3D.m
//  Sparrow
//
//  Created by Robert Carone on 7/31/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPMatrix3D.h"
#import "SPPoint.h"
#import "SPPoint3D.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
static __SIMD_BOOLEAN_TYPE__ __SIMD_ATTRIBUTES__ matrix_almost_equal_elements(matrix_float4x4 __x, matrix_float4x4 __y, float __tol)
{
    return vector_all((__tg_fabs(__x.columns[0] - __y.columns[0]) <= __tol) &
                      (__tg_fabs(__x.columns[1] - __y.columns[1]) <= __tol) &
                      (__tg_fabs(__x.columns[2] - __y.columns[2]) <= __tol) &
                      (__tg_fabs(__x.columns[3] - __y.columns[3]) <= __tol));
}
#endif

@implementation SPMatrix3D

// --- c functions ---

static matrix_float4x4 makeRotation(float angle, vector_float3 r)
{
    float a = angle;
    float c = cosf(a);
    float s = sinf(a);
    float k = 1.0f - c;
    
    vector_float3 u = vector_normalize(r);
    vector_float3 v = s * u;
    vector_float3 w = k * u;
    
    vector_float4 P;
    vector_float4 Q;
    vector_float4 R;
    vector_float4 S;
    
    P.x = w.x * u.x + c;
    P.y = w.x * u.y + v.z;
    P.z = w.x * u.z - v.y;
    P.w = 0.0f;
    
    Q.x = w.x * u.y - v.z;
    Q.y = w.y * u.y + c;
    Q.z = w.y * u.z + v.x;
    Q.w = 0.0f;
    
    R.x = w.x * u.z + v.y;
    R.y = w.y * u.z - v.x;
    R.z = w.z * u.z + c;
    R.w = 0.0f;
    
    S.x = 0.0f;
    S.y = 0.0f;
    S.z = 0.0f;
    S.w = 1.0f;
    
    return matrix_from_columns(P, Q, R, S);
}

static matrix_float4x4 makeXRotation(float angle)
{
    float cos = cosf(angle);
    float sin = sinf(angle);
    
    vector_float4 P = { 1.0f, 0.0f, 0.0f, 0.0f };
    vector_float4 Q = { 0.0f, cos,  sin,  0.0f };
    vector_float4 R = { 0.0f, -sin, cos,  0.0f };
    vector_float4 S = { 0.0f, 0.0f, 0.0f, 1.0f };
    
    return matrix_from_columns(P, Q, R, S);
}

static matrix_float4x4 makeYRotation(float angle)
{
    float cos = cosf(angle);
    float sin = sinf(angle);
    
    vector_float4 P = { cos,  0.0f, -sin, 0.0f, };
    vector_float4 Q = { 0.0f, 1.0f, 0.0f, 0.0f };
    vector_float4 R = { sin,  0.0f, cos,  0.0f };
    vector_float4 S = { 0.0f, 0.0f, 0.0f, 1.0f };
    
    return matrix_from_columns(P, Q, R, S);
}

static matrix_float4x4 makeZRotation(float angle)
{
    float cos = cosf(angle);
    float sin = sinf(angle);
    
    vector_float4 P = { cos,  sin,  0.0f, 0.0f };
    vector_float4 Q = { -sin, cos,  0.0f, 0.0f };
    vector_float4 R = { 0.0f, 0.0f, 1.0f, 0.0f };
    vector_float4 S = { 0.0f, 0.0f, 0.0f, 1.0f };
    
    return matrix_from_columns(P, Q, R, S);
}

static matrix_float4x4 makeScale(float x, float y, float z)
{
    vector_float4 diagonal = { x, y, z, 1.0f };
    return matrix_from_diagonal(diagonal);
}

static matrix_float4x4 makeTranslation(float x, float y, float z)
{
    matrix_float4x4 matrix = matrix_identity_float4x4;
    matrix.columns[3].xyz = (vector_float3){ x, y, z };
    return matrix;
}

static matrix_float4x4 lookAt(vector_float3 eye, vector_float3 center, vector_float3 up)
{
    vector_float3 zAxis = vector_normalize(center - eye);
    vector_float3 xAxis = vector_normalize(vector_cross(up, zAxis));
    vector_float3 yAxis = vector_cross(zAxis, xAxis);
    
    vector_float4 P;
    vector_float4 Q;
    vector_float4 R;
    vector_float4 S;
    
    P.x = xAxis.x;
    P.y = yAxis.x;
    P.z = zAxis.x;
    P.w = 0.0f;
    
    Q.x = xAxis.y;
    Q.y = yAxis.y;
    Q.z = zAxis.y;
    Q.w = 0.0f;
    
    R.x = xAxis.z;
    R.y = yAxis.z;
    R.z = zAxis.z;
    R.w = 0.0f;
    
    S.x = -vector_dot(xAxis, eye);
    S.y = -vector_dot(yAxis, eye);
    S.z = -vector_dot(zAxis, eye);
    S.w =  1.0f;
    
    return matrix_from_columns(P, Q, R, S);
}

#pragma mark Initialization

- (instancetype)initWithMatrix4x4:(matrix_float4x4)matrix
{
    if (self)
    {
        _m = matrix;
    }
    return self;
}

- (instancetype)initWithGLKMatrix4:(GLKMatrix4)matrix
{
    return [self initWithMatrix4x4:*(matrix_float4x4 *)&matrix];
}

- (instancetype)initWithValues:(float [16])values
{
    return [self initWithMatrix4x4:*(matrix_float4x4 *)values];
}

- (instancetype)init
{
    return [self initWithMatrix4x4:matrix_identity_float4x4];
}

+ (instancetype)matrix3DWithMatrix4x4:(matrix_float4x4)matrix
{
    return [[[self alloc] initWithMatrix4x4:matrix] autorelease];
}

+ (instancetype)matrix3DWithIdentity
{
    return [[[self alloc] init] autorelease];
}

+ (instancetype)matrix3DWithRotation:(float)rotation x:(float)x y:(float)y z:(float)z
{
    return [[[self alloc] initWithMatrix4x4:makeRotation(rotation, (vector_float3){ x, y, z })] autorelease];
}

+ (instancetype)matrix3DWithRotationX:(float)angle
{
    return [[[self alloc] initWithMatrix4x4:makeXRotation(angle)] autorelease];
}

+ (instancetype)matrix3DWithRotationY:(float)angle
{
    return [[[self alloc] initWithMatrix4x4:makeYRotation(angle)] autorelease];
}

+ (instancetype)matrix3DWithRotationZ:(float)angle
{
    return [[[self alloc] initWithMatrix4x4:makeZRotation(angle)] autorelease];
}

+ (instancetype)matrix3DWithScaleX:(float)sx y:(float)sy z:(float)sz
{
    return [[[self alloc] initWithMatrix4x4:makeScale(sx, sy, sz)] autorelease];
}

+ (instancetype)matrix3DWithTranslationX:(float)tx y:(float)ty z:(float)tz
{
    return [[[self alloc] initWithMatrix4x4:makeTranslation(tx, ty, tz)] autorelease];
}

#pragma mark Methods

- (void)appendMatrix:(SPMatrix3D *)lhs
{
    _m = matrix_multiply(lhs->_m, _m);
}

- (void)appendRotation:(float)angle axis:(SPPoint3D *)axis
{
    _m = matrix_multiply(makeRotation(angle, axis.convertToVector3), _m);
}

- (void)appendScaleX:(float)sx y:(float)sy z:(float)sz
{
    _m = matrix_multiply(makeScale(sx, sy, sz), _m);
}

- (void)appendTranslationX:(float)tx y:(float)ty z:(float)tz
{
    _m = matrix_multiply(makeTranslation(tx, ty, tz), _m);
}

- (void)prependMatrix:(SPMatrix3D *)rhs
{
    _m = matrix_multiply(_m, rhs->_m);
}

- (void)prependRotation:(float)angle axis:(SPPoint3D *)axis
{
    _m = matrix_multiply(_m, makeRotation(angle, axis.convertToVector3));
}

- (void)prependScaleX:(float)sx y:(float)sy z:(float)sz
{
    _m = matrix_multiply(_m, makeScale(sx, sy, sz));
}

- (void)prependTranslationX:(float)tx y:(float)ty z:(float)tz
{
    _m = matrix_multiply(_m, makeTranslation(tx, ty, tz));
}

- (void)identity
{
    _m = matrix_identity_float4x4;
}

- (BOOL)invert
{
    if (matrix_determinant(_m) != 0.0f)
    {
        _m = matrix_invert(_m);
        return YES;
    }
    
    return NO;
}

- (void)pointAt:(SPPoint3D *)pos at:(SPPoint3D *)at up:(SPPoint3D *)up
{
    _m = matrix_multiply(lookAt(at.convertToVector3, pos.convertToVector3, up.convertToVector3), _m);
}

- (void)transpose
{
    _m = matrix_transpose(_m);
}

- (void)copyFromMatrix:(SPMatrix3D *)matrix
{
    _m = matrix->_m;
}

- (SPMatrix *)convertTo2D
{
    return [SPMatrix matrixWithA:_m.columns[0][0]  b:_m.columns[0][1]
                               c:_m.columns[1][0]  d:_m.columns[1][1]
                              tx:_m.columns[3][0] ty:_m.columns[3][1]];
}

- (GLKMatrix4)convertToGLKMatrix
{
    GLKMatrix4 matrix;
    
    matrix.m00 = _m.columns[0][0];
    matrix.m01 = _m.columns[0][1];
    matrix.m02 = _m.columns[0][2];
    matrix.m03 = _m.columns[0][3];
    
    matrix.m10 = _m.columns[1][0];
    matrix.m11 = _m.columns[1][1];
    matrix.m12 = _m.columns[1][2];
    matrix.m13 = _m.columns[1][3];
    
    matrix.m20 = _m.columns[2][0];
    matrix.m21 = _m.columns[2][1];
    matrix.m22 = _m.columns[2][2];
    matrix.m23 = _m.columns[2][3];
    
    matrix.m30 = _m.columns[3][0];
    matrix.m31 = _m.columns[3][1];
    matrix.m32 = _m.columns[3][2];
    matrix.m33 = _m.columns[3][3];
    
    return matrix;
}

- (matrix_float4x4)convertToMatrix4x4
{
    return _m;
}

- (BOOL)isEqualToMatrix:(SPMatrix3D *)matrix
{
    if (matrix == self) return YES;
    else if (!matrix) return NO;
    else return matrix_almost_equal_elements(_m, matrix->_m, SP_FLOAT_EPSILON);
}

- (SPPoint3D *)transformPoint3D:(SPPoint3D *)vector
{
    vector.w = 1.0f;
    return [SPPoint3D point3DWithVectorFloat4:matrix_multiply(_m, vector.convertToVector4)];
}

- (SPPoint3D *)transformPoint3DWithX:(float)x y:(float)y z:(float)z
{
    return [SPPoint3D point3DWithVectorFloat4:matrix_multiply(_m, (vector_float4){ x, y, z, 1.0f })];
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if (!object)
        return NO;
    else if (object == self)
        return YES;
    else if (![object isKindOfClass:[SPMatrix class]])
        return NO;
    else
        return [self isEqualToMatrix:object];
}

- (NSString *)description
{
    float *m = self.rawData;
    return [NSString stringWithFormat:@"[SPMatrix3D:"
            "m00=%f, m01=%f, m02=%f, m03=%f"
            "m10=%f, m11=%f, m12=%f, m13=%f"
            "m20=%f, m21=%f, m22=%f, m23=%f"
            "m30=%f, m31=%f, m32=%f, m33=%f]",
            m[0],  m[1],  m[2],  m[3],
            m[4],  m[5],  m[6],  m[7],
            m[8],  m[9],  m[10], m[11],
            m[12], m[13], m[14], m[15]];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithMatrix4x4:_m];
}

#pragma mark Properties

- (float *)rawData
{
    return (float *)&_m;
}

- (void)setRawData:(float *)rawData
{
    _m = *(matrix_float4x4 *)rawData;
}

- (float)determinant
{
    return matrix_determinant(_m);
}

@end
