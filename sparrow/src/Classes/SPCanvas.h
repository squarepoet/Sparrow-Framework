//
//  SPCanvas.h
//  Sparrow
//
//  Created by Robert Carone on 8/4/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPDisplayObject.h>

@class SPPolygon;

/** ------------------------------------------------------------------------------------------------
 
 A display object supporting basic vector drawing functionality. In its current state, the main use 
 of this class is to provide a range of forms that can be used as masks.
 
------------------------------------------------------------------------------------------------- */

@interface SPCanvas : SPDisplayObject

/// Draws a circle.
- (void)drawCircleWithX:(float)x y:(float)y radius:(float)radius;

/// Draws an ellipse.
- (void)drawEllipseWithX:(float)x y:(float)y radiusX:(float)radiusX radiusY:(float)radiusY;

/// Draws a rectangle.
- (void)drawRectangleWithX:(float)x y:(float)y width:(float)width height:(float)height;

/// Draws an arbitrary polygon.
- (void)drawPolygon:(SPPolygon *)polygon;

/// Specifies a simple one-color fill that subsequent calls to drawing methods
/// (such as 'drawCircleWithX:') will use.
- (void)beginFill:(uint)color;

/// Specifies a simple one-color fill and alpha that subsequent calls to drawing methods
/// (such as 'drawCircleWithX:') will use.
- (void)beginFill:(uint)color alpha:(float)alpha;

/// Resets the color to 'white' and alpha to '1'.
- (void)endFill;

/// Removes all existing vertices.
- (void)clear;

@end
