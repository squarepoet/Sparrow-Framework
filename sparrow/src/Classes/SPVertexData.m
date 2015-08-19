//
//  SPVertexData.m
//  Sparrow
//
//  Created by Daniel Sperl on 18.02.13.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPMatrix3D.h"
#import "SPPoint.h"
#import "SPRectangle.h"
#import "SPVertexData.h"
#import "SPVector3D.h"

#define MIN_ALPHA (5.0f / 255.0f)

/// --- C methods ----------------------------------------------------------------------------------

SPVertexColor SPVertexColorMake(uchar r, uchar g, uchar b, uchar a)
{
    SPVertexColor vertexColor = { .r = r, .g = g, .b = b, .a = a };
    return vertexColor;
}

SPVertexColor SPVertexColorMakeWithColorAndAlpha(uint rgb, float alpha)
{
    SPVertexColor vertexColor = {
        .r = SPColorGetRed(rgb),
        .g = SPColorGetGreen(rgb),
        .b = SPColorGetBlue(rgb),
        .a = (uchar)(alpha * 255.0f)
    };
    return vertexColor;
}

static SPVertexColor premultiplyAlpha(SPVertexColor color)
{
    float alpha = color.a / 255.0f;
    
    if (alpha == 1.0f) return color;
    else return SPVertexColorMake(color.r * alpha,
                                  color.g * alpha,
                                  color.b * alpha,
                                  color.a);
}

static SPVertexColor unmultiplyAlpha(SPVertexColor color)
{
    float alpha = color.a / 255.0f;

    if (alpha == 0.0f || alpha == 1.0f) return color;
    else return SPVertexColorMake(color.r / alpha,
                                  color.g / alpha,
                                  color.b / alpha,
                                  color.a);
}

static BOOL isOpaqueWhite(SPVertexColor color)
{
    return color.a == 255 && color.r == 255 && color.g == 255 && color.b == 255;
}

/// --- class implementation -----------------------------------------------------------------------

@implementation SPVertexData
{
    SPVertex *_vertices;
    NSInteger _numVertices;
    BOOL _premultipliedAlpha;
}

#pragma mark Initialization

- (instancetype)initWithSize:(NSInteger)numVertices premultipliedAlpha:(BOOL)pma
{
    if ((self = [super init]))
    {
        _premultipliedAlpha = pma;
        self.numVertices = numVertices;
    }
    
    return self;
}

- (instancetype)initWithSize:(NSInteger)numVertices
{
    return [self initWithSize:numVertices premultipliedAlpha:NO];
}

- (instancetype)init
{
    return [self initWithSize:0];
}

- (void)dealloc
{
    free(_vertices);
    [super dealloc];
}

#pragma mark Methods

- (void)copyToVertexData:(SPVertexData *)target
{
    [self copyTransformedToVertexData:target atIndex:0 matrix:nil fromIndex:0 numVertices:_numVertices];
}

- (void)copyToVertexData:(SPVertexData *)target atIndex:(NSInteger)targetIndex
{
    [self copyTransformedToVertexData:target atIndex:targetIndex matrix:nil fromIndex:0 numVertices:_numVertices];
}

- (void)copyToVertexData:(SPVertexData *)target atIndex:(NSInteger)targetIndex numVertices:(NSInteger)count
{
    [self copyTransformedToVertexData:target atIndex:targetIndex matrix:nil fromIndex:0 numVertices:count];
}

- (void)copyTransformedToVertexData:(SPVertexData *)target
{
    [self copyTransformedToVertexData:target atIndex:0 matrix:nil fromIndex:0 numVertices:_numVertices];
}

- (void)copyTransformedToVertexData:(SPVertexData *)target atIndex:(NSInteger)targetIndex matrix:(SPMatrix *)matrix
{
    [self copyTransformedToVertexData:target atIndex:targetIndex matrix:matrix fromIndex:0 numVertices:_numVertices];
}

- (void)copyTransformedToVertexData:(SPVertexData *)target atIndex:(NSInteger)targetIndex matrix:(SPMatrix *)matrix
                          fromIndex:(NSInteger)fromIndex numVertices:(NSInteger)count
{
    if (count < 0 || fromIndex + count > _numVertices)
        count = _numVertices - fromIndex;
    
    if (targetIndex + count > target->_numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Target too small"];
    
    SPVertex *targetVertices = &target->_vertices[targetIndex];
    SPVertex *fromVertices   = &_vertices[fromIndex];
    
    if (matrix)
    {
        GLKMatrix3 glkMatrix = [matrix convertToGLKMatrix3];
        
        for (NSInteger i=0; i<count; ++i)
        {
            GLKVector2 pos = fromVertices[i].position;
            targetVertices[i].position.x = glkMatrix.m00 * pos.x + glkMatrix.m10 * pos.y + glkMatrix.m20;
            targetVertices[i].position.y = glkMatrix.m11 * pos.y + glkMatrix.m01 * pos.x + glkMatrix.m21;
            targetVertices[i].texCoords = fromVertices[i].texCoords;
            targetVertices[i].color = fromVertices[i].color;
        }
    }
    else
    {
        memcpy(&target->_vertices[targetIndex], _vertices, sizeof(SPVertex) * count);
    }
}

- (SPVertex)vertexAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];

    return _vertices[index];
}

- (void)setVertex:(SPVertex)vertex atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];

    _vertices[index] = vertex;
    
    if (_premultipliedAlpha)
        _vertices[index].color = premultiplyAlpha(vertex.color);
}

- (SPPoint *)positionAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    GLKVector2 position = _vertices[index].position;
    return [SPPoint pointWithX:position.x y:position.y];
}

- (void)setPosition:(SPPoint *)position atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    _vertices[index].position = GLKVector2Make(position.x, position.y);
}

- (void)setPositionWithX:(float)x y:(float)y atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    _vertices[index].position = GLKVector2Make(x, y);
}

- (SPPoint *)texCoordsAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    GLKVector2 texCoords = _vertices[index].texCoords;
    return [SPPoint pointWithX:texCoords.x y:texCoords.y];
}

- (void)setTexCoords:(SPPoint *)texCoords atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    _vertices[index].texCoords = GLKVector2Make(texCoords.x, texCoords.y);
}

- (void)setTexCoordsWithX:(float)x y:(float)y atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    _vertices[index].texCoords = GLKVector2Make(x, y);
}

- (void)setColor:(uint)color alpha:(float)alpha atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    alpha = SPClamp(alpha, _premultipliedAlpha ? MIN_ALPHA : 0.0f, 1.0f);
    
    SPVertexColor vertexColor = SPVertexColorMakeWithColorAndAlpha(color, alpha);
    _vertices[index].color = _premultipliedAlpha ? premultiplyAlpha(vertexColor) : vertexColor;
}

- (void)setColor:(uint)color alpha:(float)alpha
{
    for (NSInteger i=0; i<_numVertices; ++i)
        [self setColor:color alpha:alpha atIndex:i];
}

- (uint)colorAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];

    SPVertexColor vertexColor = _vertices[index].color;
    if (_premultipliedAlpha) vertexColor = unmultiplyAlpha(vertexColor);
    return SPColorMake(vertexColor.r, vertexColor.g, vertexColor.b);
}

- (void)setColor:(uint)color atIndex:(NSInteger)index
{
    float alpha = [self alphaAtIndex:index];
    [self setColor:color alpha:alpha atIndex:index];
}

- (void)setColor:(uint)color
{
    for (NSInteger i=0; i<_numVertices; ++i)
        [self setColor:color atIndex:i];
}

- (void)setAlpha:(float)alpha atIndex:(NSInteger)index
{
    uint color = [self colorAtIndex:index];
    [self setColor:color alpha:alpha atIndex:index];
}

- (void)setAlpha:(float)alpha
{
    for (NSInteger i=0; i<_numVertices; ++i)
        [self setAlpha:alpha atIndex:i];
}

- (float)alphaAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid vertex index"];
    
    return _vertices[index].color.a / 255.0f;
}

- (void)scaleAlphaBy:(float)factor
{
    [self scaleAlphaBy:factor atIndex:0 numVertices:_numVertices];
}

- (void)scaleAlphaBy:(float)factor atIndex:(NSInteger)index numVertices:(NSInteger)count
{
    if (index < 0 || index + count > _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index range"];
    
    if (factor == 1.0f) return;
    int minAlpha = _premultipliedAlpha ? (int)(MIN_ALPHA * 255.0f) : 0;
    
    for (NSInteger i=index; i<index+count; ++i)
    {
        SPVertex *vertex = &_vertices[i];
        SPVertexColor vertexColor = vertex->color;
        uchar newAlpha = SPClamp(vertexColor.a * factor, minAlpha, 255);
        
        if (_premultipliedAlpha)
        {
            vertexColor = unmultiplyAlpha(vertexColor);
            vertexColor.a = newAlpha;
            vertex->color = premultiplyAlpha(vertexColor);
        }
        else
        {
            vertex->color = SPVertexColorMake(vertexColor.r, vertexColor.g, vertexColor.b, newAlpha);
        }
    }
}

- (void)appendVertex:(SPVertex)vertex
{
    self.numVertices += 1;
    
    if (_vertices) // just to shut down an Analyzer warning ... this will never be NULL.
    {
        if (_premultipliedAlpha) vertex.color = premultiplyAlpha(vertex.color);
        _vertices[_numVertices-1] = vertex;
    }
}

- (void)transformVerticesWithMatrix:(SPMatrix *)matrix atIndex:(NSInteger)index numVertices:(NSInteger)count
{
    if (index < 0 || index + count > _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index range"];
    
    if (!matrix) return;
    
    GLKMatrix3 glkMatrix = [matrix convertToGLKMatrix3];
    
    for (NSInteger i=index, end=index+count; i<end; ++i)
    {
        GLKVector2 pos = _vertices[i].position;
        _vertices[i].position.x = glkMatrix.m00 * pos.x + glkMatrix.m10 * pos.y + glkMatrix.m20;
        _vertices[i].position.y = glkMatrix.m11 * pos.y + glkMatrix.m01 * pos.x + glkMatrix.m21;
    }
}

- (SPRectangle *)bounds
{
    return [self boundsAfterTransformation:nil atIndex:0 numVertices:_numVertices];
}

- (SPRectangle *)boundsAfterTransformation:(SPMatrix *)matrix
{
    return [self boundsAfterTransformation:matrix atIndex:0 numVertices:_numVertices];
}

- (SPRectangle *)boundsAfterTransformation:(SPMatrix *)matrix atIndex:(NSInteger)index numVertices:(NSInteger)count
{
    if (index < 0 || index + count > _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index range"];
    
    float minX = FLT_MAX, maxX = -FLT_MAX, minY = FLT_MAX, maxY = -FLT_MAX;
    NSInteger endIndex = index + count;
    
    if (count == 0)
    {
        SPPoint *point = nil;
        if (matrix) point = [matrix transformPointWithX:0 y:0];
        else        point = [SPPoint pointWithX:0 y:0];
        return [SPRectangle rectangleWithX:point.x y:point.y width:0 height:0];
    }
    else
    {
        if (matrix)
        {
            for (NSInteger i=index; i<endIndex; ++i)
            {
                GLKVector2 position = _vertices[i].position;
                SPPoint *transformedPoint = [matrix transformPointWithX:position.x y:position.y];
                float tfX = transformedPoint.x;
                float tfY = transformedPoint.y;
                minX = MIN(minX, tfX);
                maxX = MAX(maxX, tfX);
                minY = MIN(minY, tfY);
                maxY = MAX(maxY, tfY);
            }
        }
        else
        {
            for (NSInteger i=index; i<endIndex; ++i)
            {
                GLKVector2 position = _vertices[i].position;
                minX = MIN(minX, position.x);
                maxX = MAX(maxX, position.x);
                minY = MIN(minY, position.y);
                maxY = MAX(maxY, position.y);
            }
        }
    }
    
    return [SPRectangle rectangleWithX:minX y:minY width:maxX-minX height:maxY-minY];
}

- (nonnull SPRectangle *)projectedBoundsAfterTransformation:(SPMatrix3D *)matrix camPos:(SPVector3D *)camPos
{
    return [self projectedBoundsAfterTransformation:matrix camPos:camPos atIndex:0 numVertices:-1];
}

- (SPRectangle *)projectedBoundsAfterTransformation:(SPMatrix3D *)matrix camPos:(SPVector3D *)camPos
                                            atIndex:(NSInteger)index numVertices:(NSInteger)count
{
    if (camPos == nil) [NSException raise:SPExceptionInvalidOperation format:@"camPos must not be null"];
    if (count < 0 || index + count > _numVertices)
        count = _numVertices - index;
    
    if (count == 0)
    {
        SPVector3D *point3D = nil;
        if (matrix) point3D = [matrix transformVectorWithX:0 y:0 z:0];
        else        point3D = [SPVector3D vector3DWithX:0 y:0 z:0];
        
        SPPoint *point = [camPos intersectWithXYPlane:point3D];
        return [SPRectangle rectangleWithX:point.x y:point.y width:0 height:0];
    }
    else
    {
        float minX = FLT_MAX, maxX = -FLT_MAX, minY = FLT_MAX, maxY = -FLT_MAX;
        NSInteger endIndex = index + count;
        
        for (NSInteger i=index; i<endIndex; ++i)
        {
            GLKVector2 position = _vertices[i].position;
            
            SPVector3D *transformedPoint3D = nil;
            if (matrix) transformedPoint3D = [matrix transformVectorWithX:position.x y:position.y z:0];
            else        transformedPoint3D = [SPVector3D vector3DWithX:position.x y:position.y z:0];
            
            SPPoint *point = [camPos intersectWithXYPlane:transformedPoint3D];
            float tfX = point.x;
            float tfY = point.y;
            minX = MIN(minX, tfX);
            maxX = MAX(maxX, tfX);
            minY = MIN(minY, tfY);
            maxY = MAX(maxY, tfY);
        }
        
        return [SPRectangle rectangleWithX:minX y:minY width:maxX-minX height:maxY-minY];
    }
}

#pragma mark NSObject

- (NSString *)description
{
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"[SPVertexData \n"];
    
    for (NSInteger i=0; i<_numVertices; ++i)
    {
        [result appendFormat:@"[Vertex %ld: ", (long)i];
        [result appendFormat:@"x=%.1f, ", _vertices[i].position.x];
        [result appendFormat:@"y=%.1f, ", _vertices[i].position.y];
        [result appendFormat:@"rgb=%x, ", [self colorAtIndex:i]];
        [result appendFormat:@"a=%.1f, ", [self alphaAtIndex:i]];
        [result appendFormat:@"u=%.1f, ", _vertices[i].texCoords.x];
        [result appendFormat:@"v=%.1f, ", _vertices[i].texCoords.y];
        [result appendString:i == _numVertices-1 ? @"\n" : @",\n"];
    }
    
    [result appendString:@"]"];
    return result;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPVertexData *copy = [[[self class] allocWithZone:zone] initWithSize:_numVertices
                                                      premultipliedAlpha:_premultipliedAlpha];
    memcpy(copy->_vertices, _vertices, sizeof(SPVertex) *_numVertices);
    return copy;
}

#pragma mark Properties

- (SPVertex *)vertices
{
    return _vertices;
}

- (void)setNumVertices:(NSInteger)value
{
    if (value != _numVertices)
    {
        if (value)
        {
            if (_vertices)
                _vertices = realloc(_vertices, sizeof(SPVertex) * value);
            else
                _vertices = malloc(sizeof(SPVertex) * value);

            if (value > _numVertices)
            {
                memset(&_vertices[_numVertices], 0, sizeof(SPVertex) * (value - _numVertices));

                for (NSInteger i=_numVertices; i<value; ++i)
                    _vertices[i].color = SPVertexColorMakeWithColorAndAlpha(0, 1.0f);
            }
        }
        else
        {
            free(_vertices);
            _vertices = NULL;
        }

        _numVertices = value;
    }
}

- (void)setPremultipliedAlpha:(BOOL)value
{
    [self setPremultipliedAlpha:value updateVertices:YES];
}

- (void)setPremultipliedAlpha:(BOOL)value updateVertices:(BOOL)update
{
    if (value == _premultipliedAlpha) return;

    if (update)
    {
        if (value)
        {
            for (NSInteger i=0; i<_numVertices; ++i)
                _vertices[i].color = premultiplyAlpha(_vertices[i].color);
        }
        else
        {
            for (NSInteger i=0; i<_numVertices; ++i)
                _vertices[i].color = unmultiplyAlpha(_vertices[i].color);
        }
    }

    _premultipliedAlpha = value;
}

- (BOOL)tinted
{
    for (NSInteger i=0; i<_numVertices; ++i)
        if (!isOpaqueWhite(_vertices[i].color)) return YES;

    return NO;
}

@end
