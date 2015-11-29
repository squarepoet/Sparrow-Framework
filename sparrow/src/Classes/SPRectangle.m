//
//  SPRectangle.m
//  Sparrow
//
//  Created by Daniel Sperl on 21.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPPoint.h"
#import "SPRectangle.h"

static GLKVector2 positions[] = {
    (GLKVector2){{ 0.0f, 0.0f }},
    (GLKVector2){{ 1.0f, 0.0f }},
    (GLKVector2){{ 0.0f, 1.0f }},
    (GLKVector2){{ 1.0f, 1.0f }}
};

/// Calculates the next whole-number multiplier or divisor, moving either up or down.
static float nextSuitableScaleFactor(float factor, BOOL up)
{
    float divisor = 1.0f;
    
    if (up)
    {
        if (factor >= 0.5f) return ceilf(factor);
        else
        {
            while (1.0f / (divisor + 1.0f) > factor)
                ++divisor;
        }
    }
    else
    {
        if (factor >= 1.0) return floorf(factor);
        else
        {
            while (1.0f / divisor > factor)
                ++divisor;
        }
    }
    
    return 1.0f / divisor;
}

@implementation SPRectangle

#pragma mark Initialization

- (instancetype)initWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    if (self)
    {
        _x = x;
        _y = y;
        _width = width;
        _height = height;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithX:0.0f y:0.0f width:0.0f height:0.0f];
}

+ (instancetype)rectangleWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    return [[[self alloc] initWithX:x y:y width:width height:height] autorelease];
}

+ (instancetype)rectangle
{
    return [[[self alloc] init] autorelease];
}

+ (instancetype)rectangleWithCGRect:(CGRect)rect
{
    return [[[self alloc] initWithX:rect.origin.x y:rect.origin.y
                              width:rect.size.width height:rect.size.height] autorelease];
}

#pragma mark Methods

- (BOOL)containsX:(float)x y:(float)y
{
    return x >= _x && y >= _y && x <= _x + _width && y <= _y + _height;
}

- (BOOL)containsPoint:(SPPoint *)point
{
    return [self containsX:point.x y:point.y];
}

- (BOOL)containsRectangle:(SPRectangle *)rectangle
{
    if (!rectangle) return NO;
    
    float rX = rectangle->_x;
    float rY = rectangle->_y;
    float rWidth = rectangle->_width;
    float rHeight = rectangle->_height;

    return rX >= _x && rX + rWidth <= _x + _width &&
           rY >= _y && rY + rHeight <= _y + _height;
}

- (BOOL)intersectsRectangle:(SPRectangle *)rectangle
{
    if (!rectangle) return NO;
    
    float rX = rectangle->_x;
    float rY = rectangle->_y;
    float rWidth = rectangle->_width;
    float rHeight = rectangle->_height;
    
    BOOL outside = 
        (rX <= _x && rX + rWidth <= _x)  || (rX >= _x + _width && rX + rWidth >= _x + _width) ||
        (rY <= _y && rY + rHeight <= _y) || (rY >= _y + _height && rY + rHeight >= _y + _height);
    return !outside;
}

- (SPRectangle *)intersectionWithRectangle:(SPRectangle *)rectangle
{
    if (!rectangle) return nil;
    
    float left   = MAX(_x, rectangle->_x);
    float right  = MIN(_x + _width, rectangle->_x + rectangle->_width);
    float top    = MAX(_y, rectangle->_y);
    float bottom = MIN(_y + _height, rectangle->_y + rectangle->_height);
    
    if (left > right || top > bottom)
        return [SPRectangle rectangleWithX:0 y:0 width:0 height:0];
    else
        return [SPRectangle rectangleWithX:left y:top width:right-left height:bottom-top];
}

- (SPRectangle *)uniteWithRectangle:(SPRectangle *)rectangle
{
    if (!rectangle) return [[self copy] autorelease];
    
    float left   = MIN(_x, rectangle->_x);
    float right  = MAX(_x + _width, rectangle->_x + rectangle->_width);
    float top    = MIN(_y, rectangle->_y);
    float bottom = MAX(_y + _height, rectangle->_y + rectangle->_height);
    return [SPRectangle rectangleWithX:left y:top width:right-left height:bottom-top];
}

- (SPRectangle *)boundsAfterTransformation:(SPMatrix *)matrix
{
    float minX = FLT_MAX, maxX = FLT_MIN;
    float minY = FLT_MAX, maxY = FLT_MIN;
    
    for (int i=0; i<4; ++i)
    {
        SPPoint *transformedPoint = [matrix transformPointWithX:_width  * positions[i].x
                                                              y:_height * positions[i].y];
        
        if (minX > transformedPoint.x) minX = transformedPoint.x;
        if (maxX < transformedPoint.x) maxX = transformedPoint.x;
        if (minY > transformedPoint.y) minY = transformedPoint.y;
        if (maxY < transformedPoint.y) maxY = transformedPoint.y;
    }
    
    return [SPRectangle rectangleWithX:minX y:minY width:maxX-minX height:maxY-minY];
}

- (void)inflateXBy:(float)dx yBy:(float)dy
{
    _x -= dx;
    _width += 2 * dx;

    _y -= dy;
    _height += 2 * dy;
}

- (SPRectangle *)fitInto:(SPRectangle *)into scaleMode:(SPScaleMode)scaleMode
            pixelPerfect:(BOOL)pixelPerfect
{
    float factorX = into->_width  / _width;
    float factorY = into->_height / _height;
    float factor  = 1.0f;
    
    if (scaleMode == SPScaleModeShowAll)
    {
        factor = factorX < factorY ? factorX : factorY;
        if (pixelPerfect) factor = nextSuitableScaleFactor(factor, false);
    }
    else if (scaleMode == SPScaleModeNoBorder)
    {
        factor = factorX > factorY ? factorX : factorY;
        if (pixelPerfect) factor = nextSuitableScaleFactor(factor, true);
    }
    
    float width  = _width  * factor;
    float height = _height * factor;
    
    return [SPRectangle rectangleWithX:into->_x + (into->_width  - width)  / 2
                                     y:into->_y + (into->_height - height) / 2
                                 width:width
                                height:height];
}

- (void)scaleBy:(float)scale
{
    _x *= scale;
    _y *= scale;
    _width *= scale;
    _height *= scale;
}

- (void)scaleSizeBy:(float)scale
{
    _width *= scale;
    _height *= scale;
}

- (void)setX:(float)x y:(float)y width:(float)width height:(float)height
{
    _x = x;
    _y = y;
    _width = width;
    _height = height;
}

- (void)setEmpty
{
    _x = _y = _width = _height = 0;
}

- (void)copyFromRectangle:(SPRectangle *)rectangle
{
    _x = rectangle->_x;
    _y = rectangle->_y;
    _width = rectangle->_width;
    _height = rectangle->_height;
}

- (BOOL)isEqualToRectangle:(SPRectangle *)other
{
    if (other == self) return YES;
    else if (!other) return NO;
    else
    {
        return SPIsFloatEqual(_x, other->_x) && SPIsFloatEqual(_y, other->_y) &&
               SPIsFloatEqual(_width, other->_width) && SPIsFloatEqual(_height, other->_height);
    }
}

- (void)normalize
{
    if (_width < 0.0f)
    {
        _width = -_width;
        _x -= _width;
    }

    if (_height < 0.0f)
    {
        _height = -_height;
        _y -= _height;
    }
}

- (CGRect)convertToCGRect
{
    return CGRectMake(_x, _y, _width, _height);
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if (!object)
        return NO;
    else if (object == self)
        return YES;
    else if (![object isKindOfClass:[SPRectangle class]])
        return NO;
    else
        return [self isEqualToRectangle:object];
}

- (NSUInteger)hash
{
    return SPHashFloat(_x) ^
           SPShiftAndRotate(SPHashFloat(_y),      1) ^
           SPShiftAndRotate(SPHashFloat(_width),  1) ^
           SPShiftAndRotate(SPHashFloat(_height), 1);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[SPRectangle: x=%f, y=%f, width=%f, height=%f]",
            _x, _y, _width, _height];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithX:_x y:_y width:_width height:_height];
}

#pragma mark Properties

- (float)top { return _y; }
- (void)setTop:(float)value { _y = value; }

- (float)bottom { return _y + _height; }
- (void)setBottom:(float)value { _height = value - _y; }

- (float)left { return _x; }
- (void)setLeft:(float)value { _x = value; }

- (float)right { return _x + _width; }
- (void)setRight:(float)value { _width = value - _x; }

- (SPPoint *)topLeft { return [SPPoint pointWithX:_x y:_y]; }
- (void)setTopLeft:(SPPoint *)value { _x = value.x; _y = value.y; }

- (SPPoint *)bottomRight { return [SPPoint pointWithX:_x+_width y:_y+_height]; }
- (void)setBottomRight:(SPPoint *)value { self.right = value.x; self.bottom = value.y; }

- (SPPoint *)size { return [SPPoint pointWithX:_width y:_height]; }
- (void)setSize:(SPPoint *)value { _width = value.x; _height = value.y; }

- (BOOL)isEmpty
{
    return _width == 0 || _height == 0;
}

@end
