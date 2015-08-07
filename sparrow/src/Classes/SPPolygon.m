//
//  SPPolygon.m
//  Sparrow
//
//  Created by Robert Carone on 3/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPIndexData.h"
#import "SPMacros.h"
#import "SPPoint.h"
#import "SPPolygon.h"
#import "SPVertexData.h"

/// --- immutable polygon interfaces ---------------------------------------------------------------

@interface SPImmutablePolygon : SPPolygon
@end

@interface SPElipsePolygon : SPImmutablePolygon
- (instancetype)initWithX:(float)x y:(float)y radiusX:(float)radiusX radiusY:(float)radiusY numSides:(NSInteger)numSides;
@end

@interface SPRectanglePolygon : SPImmutablePolygon
- (instancetype)initWithX:(float)x y:(float)y width:(float)width height:(float)height;
@end

/// --- class implementation -----------------------------------------------------------------------

@implementation SPPolygon
{
  @package
    GLKVector2 *_vertices;
    NSInteger _numVertices;
}

// --- c functions ---

SP_INLINE BOOL isConvexTriangle(float ax, float ay,
                                float bx, float by,
                                float cx, float cy)
{
    // dot product of [the normal of (a->b)] and (b->c) must be positive
    return (ay - by) * (cx - bx) + (bx - ax) * (cy - by) >= 0;
}

static BOOL isPointInTriangle(float px, float py,
                              float ax, float ay,
                              float bx, float by,
                              float cx, float cy)
{
    // This algorithm is described well in this article:
    // http://www.blackpawn.com/texts/pointinpoly/default.html

    float v0x = cx - ax;
    float v0y = cy - ay;
    float v1x = bx - ax;
    float v1y = by - ay;
    float v2x = px - ax;
    float v2y = py - ay;

    float dot00 = v0x * v0x + v0y * v0y;
    float dot01 = v0x * v1x + v0y * v1y;
    float dot02 = v0x * v2x + v0y * v2y;
    float dot11 = v1x * v1x + v1y * v1y;
    float dot12 = v1x * v2x + v1y * v2y;

    float invDen = 1.0 / (dot00 * dot11 - dot01 * dot01);
    float u = (dot11 * dot02 - dot01 * dot12) * invDen;
    float v = (dot00 * dot12 - dot01 * dot02) * invDen;

    return (u >= 0) && (v >= 0) && (u + v < 1);
}

static BOOL areVectorsIntersecting(float ax, float ay, float bx, float by,
                                   float cx, float cy, float dx, float dy)
{
    if ((ax == bx && ay == by) || (cx == dx && cy == dy)) return false; // length = 0

    float abx = bx - ax;
    float aby = by - ay;
    float cdx = dx - cx;
    float cdy = dy - cy;
    float tDen = cdy * abx - cdx * aby;

    if (tDen == 0.0) return false; // parallel or identical

    float t = (aby * (cx - ax) - abx * (cy - ay)) / tDen;

    if (t < 0 || t > 1) return false; // outside c->d

    float s = aby ? (cy - ay + t * cdy) / aby :
    (cx - ax + t * cdx) / abx;

    return s >= 0.0 && s <= 1.0; // inside a->b
}

#pragma mark Initialization

- (instancetype)initWithVertices:(GLKVector2 *)vertices count:(NSInteger)count
{
    if (self = [super init])
    {
        if (vertices)
            [self addVertices:vertices count:count];
    }
    return self;
}

- (instancetype)init
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    return [self initWithVertices:nil count:0];
#pragma clang diagnostic pop
}

- (void)dealloc
{
    free(_vertices);
    [super dealloc];
}

+ (instancetype)circleWithX:(float)x y:(float)y radius:(float)radius
{
    return [[[SPElipsePolygon alloc] initWithX:x y:y radiusX:radius radiusY:radius numSides:-1] autorelease];
}

+ (instancetype)elipseWithX:(float)x y:(float)y radiusX:(float)radiusX radiusY:(float)radiusY
{
    return [[[SPElipsePolygon alloc] initWithX:x y:y radiusX:radiusX radiusY:radiusY numSides:-1] autorelease];
}

+ (instancetype)rectangleWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    return [[[SPRectanglePolygon alloc] initWithX:x y:y width:width height:height] autorelease];
}

#pragma mark Methods

- (void)reverse
{
    for (NSInteger i=0; i<_numVertices; ++i)
    {
        GLKVector2 tmp = _vertices[i];
        _vertices[i] = _vertices[_numVertices - i];
        _vertices[_numVertices - i] = tmp;
    }
}

- (void)addVertices:(GLKVector2 *)vertices count:(NSInteger)count
{
    if (!vertices || !count) return;

    NSInteger numVertices = _numVertices;
    self.numVertices = _numVertices + count;

    memcpy(_vertices + numVertices, vertices, sizeof(GLKVector2) * count);
}

- (void)setVertexWithX:(float)x y:(float)y atIndex:(NSInteger)index
{
    if (index < 0 && index > _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index: %ld", (long)index];

    if (index == _numVertices) self.numVertices = _numVertices + 1;
    assert(_vertices);
    _vertices[index] = GLKVector2Make(x, y);
}

- (GLKVector2)vertexAtIndex:(NSInteger)index
{
    if (index < 0 && index >= _numVertices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index: %ld", (long)index];

    return _vertices[index];
}

- (BOOL)containsPointWithX:(float)x y:(float)y
{
    // Algorithm & implementation thankfully taken from:
    // -> http://alienryderflex.com/polygon/

    uint oddNodes = 0;

    for (NSInteger i=0, j=_numVertices-1; i<_numVertices; ++i)
    {
        float ix = _vertices[i].x;
        float iy = _vertices[i].y;
        float jx = _vertices[j].x;
        float jy = _vertices[j].y;

        if (((iy < y && jy >= y) || (jy < y && iy >= y)) && (ix <= x || jx <= x))
            oddNodes ^= (uint)(ix + (y - iy) / (jy - iy) * (jx - ix) < x);

        j = i;
    }

    return oddNodes != 0;
}

- (BOOL)containsPoint:(SPPoint *)point
{
    return [self containsPointWithX:point.x y:point.y];
}

- (SPIndexData *)triangulate:(SPIndexData *)result
{
    // Algorithm "Ear clipping method" described here:
    // -> https://en.wikipedia.org/wiki/Polygon_triangulation
    //
    // Implementation inspired by:
    // -> http://polyk.ivank.net

    if (result == nil) result = [[[SPIndexData alloc] init] autorelease];
    if (_numVertices < 3) return result;

    ushort restIndices[_numVertices];
    for (int i=0; i<_numVertices; ++i)
        restIndices[i] = i;

    int restIndexPos = 0;
    int numRestIndices = (int)_numVertices;

    while (numRestIndices > 3)
    {
        // In each step, we look at 3 subsequent vertices. If those vertices spawn up
        // a triangle that is convex and does not contain any other vertices, it is an 'ear'.
        // We remove those ears until only one remains -> each ear is one of our wanted
        // triangles.

        int i0 = restIndices[ restIndexPos      % numRestIndices];
        int i1 = restIndices[(restIndexPos + 1) % numRestIndices];
        int i2 = restIndices[(restIndexPos + 2) % numRestIndices];

        float ax = _vertices[i0].x;
        float ay = _vertices[i0].y;
        float bx = _vertices[i1].x;
        float by = _vertices[i1].y;
        float cx = _vertices[i2].x;
        float cy = _vertices[i2].y;
        BOOL earFound = false;

        if (isConvexTriangle(ax, ay, bx, by, cx, cy))
        {
            earFound = true;
            for (NSInteger i=3; i<numRestIndices; ++i)
            {
                NSInteger otherIndex = restIndices[(restIndexPos + i) % numRestIndices];
                if (isPointInTriangle(_vertices[otherIndex].x, _vertices[otherIndex].y,
                                      ax, ay, bx, by, cx, cy))
                {
                    earFound = false;
                    break;
                }
            }
        }

        if (earFound)
        {
            [result appendTriangleWithA:i0 b:i1 c:i2];
            
            // shift rest indices
            for (int i=(restIndexPos + 1) % numRestIndices; i<numRestIndices-1; ++i)
                restIndices[i] = restIndices[i+1];

            numRestIndices--;
            restIndexPos = 0;
        }
        else
        {
            restIndexPos++;
            if (restIndexPos == numRestIndices) break; // no more ears
        }
    }

    [result appendTriangleWithA:restIndices[0] b:restIndices[1] c:restIndices[2]];
    return result;
}

- (void)copyToVertexData:(SPVertexData *)target atIndex:(NSInteger)targetIndex
{
    NSInteger requiredTargetLength = targetIndex + _numVertices;
    if (target.numVertices < requiredTargetLength)
        target.numVertices = requiredTargetLength;

    [self copyToVertices:(float *)target.vertices atIndex:targetIndex withStride:sizeof(SPVertex) - sizeof(GLKVector2)];
}

- (void)copyToVertices:(float *)target atIndex:(NSInteger)targetIndex withStride:(NSInteger)stride
{
    const size_t step = sizeof(GLKVector2) + stride;
    unsigned char *data = (unsigned char *)(target) + targetIndex * step;

    for (int i=0; i<_numVertices; ++i)
    {
        GLKVector2 *current = (GLKVector2 *)(data);
        *current = _vertices[i];
        data += step;
    }
}

#pragma mark NSObject

- (NSString *)description
{
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"[SPPolygon \n"];
    int numPoints = (int)self.numVertices;
    
    for (int i=0; i<numPoints; ++i)
    {
        [result appendFormat:@"  [Vertex %d: ", i];
        [result appendFormat:@"x=%f", _vertices[i].x];
        [result appendFormat:@"y=%f", _vertices[i].y];
        [result appendString:i == numPoints-1 ? @"\n" : @",\n"];
    }
    
    [result appendString:@"]"];
    return result;
}

#pragma mark NSCopying

- (id)copy
{
    return [[[self class] alloc] initWithVertices:_vertices count:_numVertices];;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self copy];
}

#pragma mark Properties

- (BOOL)isSimple
{
    if (_numVertices <= 3) return true;

    for (int i=0; i<_numVertices; ++i)
    {
        float ax = _vertices[ i ].x;
        float ay = _vertices[ i ].y;
        float bx = _vertices[(i + 1) % _numVertices].x;
        float by = _vertices[(i + 1) % _numVertices].y;
        float endJ = i + _numVertices;

        for (int j=i+2; j<endJ; ++j)
        {
            float cx = _vertices[ j      % _numVertices].x;
            float cy = _vertices[ j      % _numVertices].y;
            float dx = _vertices[(j + 1) % _numVertices].x;
            float dy = _vertices[(j + 1) % _numVertices].y;

            if (areVectorsIntersecting(ax, ay, bx, by, cx, cy, dx, dy))
                return false;
        }
    }

    return true;
}

- (BOOL)isConvex
{
    if (_numVertices < 3) return true;
    else
    {
        for (int i=0; i<_numVertices; ++i)
        {
            if (!isConvexTriangle(_vertices[i].x, _vertices[i].y,
                                  _vertices[(i+1) % _numVertices].x, _vertices[(i+1) % _numVertices].y,
                                  _vertices[(i+2) % _numVertices].x, _vertices[(i+2) % _numVertices].y))
            {
                return false;
            }
        }
    }

    return true;
}

- (float)area
{
    float area = 0;

    if (_numVertices >= 3)
    {
        for (int i=0; i<_numVertices; ++i)
        {
            area += _vertices[i].x * _vertices[(i+1) % _numVertices].y;
            area -= _vertices[i].y * _vertices[(i+1) % _numVertices].x;
        }
    }

    return area / 2.0;
}

- (void)setNumVertices:(NSInteger)numVertices
{
    if (numVertices != _numVertices)
    {
        if (numVertices)
        {
            if (!_vertices) _vertices = malloc(sizeof(GLKVector2) * numVertices);
            else            _vertices = realloc(_vertices, sizeof(GLKVector2) * numVertices);

            if (numVertices > _numVertices)
                memset(_vertices + _numVertices, 0, sizeof(GLKVector2) * (numVertices - _numVertices));
        }
        else
        {
            free(_vertices);
            _vertices = NULL;
        }

        _numVertices = numVertices;
    }
}

@end

#pragma mark - SPImmutablePolygon

@implementation SPImmutablePolygon
{
    BOOL _frozen;
}

- (instancetype)initWithVertices:(GLKVector2 *)vertices count:(NSInteger)count
{
    if (self = [super initWithVertices:vertices count:count])
    {
        _frozen = YES;
    }
    return self;
}

- (void)reverse
{
    if (_frozen) [self raiseImutableException];
    else [super reverse];
}

- (void)addVertices:(GLKVector2 *)vertices count:(NSInteger)count
{
    if (_frozen) [self raiseImutableException];
    else [super addVertices:vertices count:count];
}

- (void)setVertexWithX:(float)x y:(float)y atIndex:(NSInteger)index
{
    if (_frozen) [self raiseImutableException];
    else [super setVertexWithX:x y:y atIndex:index];
}

- (void)setNumVertices:(NSInteger)numVertices
{
    if (_frozen) [self raiseImutableException];
    else [super setNumVertices:numVertices];
}

- (void)raiseImutableException
{
    [NSException raise:SPExceptionInvalidOperation
                format:@"%@ cannot be modified. Call 'clone' to create a mutable copy.",
                       NSStringFromClass([self class])];
}

@end

#pragma mark - SPElipsePolygon

@implementation SPElipsePolygon
{
    float _x;
    float _y;
    float _radiusX;
    float _radiusY;
}

void fillElipseVertices(GLKVector2 *vertices, float x, float y, float rx, float ry, NSInteger numSides)
{
    float angleDelta = 2 * PI / numSides;
    float angle = 0;

    for (NSInteger i=0; i<numSides; ++i)
    {
        vertices[i].x = cosf(angle) * rx + x;
        vertices[i].y = sinf(angle) * ry + y;
        angle += angleDelta;
    }
}

#pragma mark Initialization

- (instancetype)initWithX:(float)x y:(float)y radiusX:(float)radiusX radiusY:(float)radiusY numSides:(NSInteger)numSides
{
    if (numSides < 0) numSides = PI * (radiusX + radiusY) / 4.0;
    if (numSides < 6) numSides = 6;

    GLKVector2 vertices[numSides];
    fillElipseVertices(vertices, x, y, radiusX, radiusY, numSides);

    if (self = [super initWithVertices:vertices count:numSides])
    {
        _x = x;
        _y = y;
        _radiusX = radiusX;
        _radiusY = radiusY;
    }

    return self;
}

- (instancetype)initWithX:(float)x y:(float)y radiusX:(float)radiusX radiusY:(float)radiusY
{
    return [self initWithX:x y:y radiusX:radiusX radiusY:radiusY numSides:-1];
}

#pragma mark SPPolygon

- (SPIndexData *)triangulate:(SPIndexData *)result
{
    if (!result) result = [[[SPIndexData alloc] init] autorelease];

    ushort from = 1;
    ushort to = _numVertices - 1;
    
    int pos = (int)result.numIndices;
    result.numIndices += (to-from)*3;
    ushort *indices = result.indices;

    for (int i=from; i<to; ++i)
    {
        indices[pos++] = 0;
        indices[pos++] = i;
        indices[pos++] = i + 1;
    }

    return result;
}

- (BOOL)containsPointWithX:(float)x y:(float)y
{
    float vx = x - _x;
    float vy = y - _y;

    float a = vx / _radiusX;
    float b = vy / _radiusY;

    return a * a + b * b <= 1;
}

- (BOOL)isSimple
{
    return YES;
}

- (BOOL)isConvex
{
    return YES;
}

- (float)area
{
    return PI * _radiusX * _radiusY;
}

@end

#pragma mark - SPRectanglePolygon

@implementation SPRectanglePolygon
{
    float _x;
    float _y;
    float _width;
    float _height;
}

- (instancetype)initWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    GLKVector2 vertices[] = {
        { x,         y },
        { x + width, y },
        { x + width, y + height },
        { x,         y + height },
    };

    if (self = [super initWithVertices:vertices count:4])
    {
        _x = x;
        _y = y;
        _width = width;
        _height = height;
    }

    return self;
}

#pragma mark SPPolygon

- (SPIndexData *)triangulate:(SPIndexData *)result
{
    if (!result) result = [[[SPIndexData alloc] init] autorelease];
    [result appendTriangleWithA:0 b:1 c:3];
    [result appendTriangleWithA:1 b:2 c:3];
    return result;
}

- (BOOL)containsPointWithX:(float)x y:(float)y
{
    return x >= _x && x <= _x + _width &&
           y >= _y && y <= _y + _height;
}

- (BOOL)isSimple
{
    return YES;
}

- (BOOL)isConvex
{
    return YES;
}

- (float)area
{
    return _width * _height;
}

@end
