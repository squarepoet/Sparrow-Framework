//
//  SPQuad.m
//  Sparrow
//
//  Created by Daniel Sperl on 15.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPPoint.h"
#import "SPQuad.h"
#import "SPRectangle.h"
#import "SPRenderSupport.h"
#import "SPStage.h"
#import "SPVertexData.h"

#define MIN_SIZE 0.01f

// --- class implementation ------------------------------------------------------------------------
#pragma mark -

@implementation SPQuad
{
    BOOL _tinted;
}

#pragma mark Initialization

- (instancetype)initWithWidth:(float)width height:(float)height color:(uint)color premultipliedAlpha:(BOOL)pma
{
    if ((self = [super init]))
    {
        if (width  <= MIN_SIZE) width  = MIN_SIZE;
        if (height <= MIN_SIZE) height = MIN_SIZE;
        
        _tinted = color != SPColorWhite;
        
        _vertexData = [[SPVertexData alloc] initWithSize:4 premultipliedAlpha:pma];
        _vertexData.vertices[1].position.x = width;
        _vertexData.vertices[2].position.y = height;
        _vertexData.vertices[3].position.x = width;
        _vertexData.vertices[3].position.y = height;
        
        for (int i=0; i<4; ++i)
            _vertexData.vertices[i].color = SPVertexColorMakeWithColorAndAlpha(color, 1.0f);
        
        [self vertexDataDidChange];
    }
    return self;
}

- (instancetype)initWithWidth:(float)width height:(float)height color:(uint)color
{
    return [self initWithWidth:width height:height color:color premultipliedAlpha:YES];
}

- (instancetype)initWithWidth:(float)width height:(float)height
{
    return [self initWithWidth:width height:height color:SPColorWhite];
}

- (instancetype)init
{    
    return [self initWithWidth:32 height:32];
}

- (void)dealloc
{
    [_vertexData release];
    [super dealloc];
}

+ (instancetype)quadWithWidth:(float)width height:(float)height
{
    return [[[self alloc] initWithWidth:width height:height] autorelease];
}

+ (instancetype)quadWithWidth:(float)width height:(float)height color:(uint)color
{
    return [[[self alloc] initWithWidth:width height:height color:color] autorelease];
}

+ (instancetype)quad
{
    return [[[self alloc] init] autorelease];
}

#pragma mark Methods

- (void)setColor:(uint)color ofVertex:(NSInteger)vertexID
{
    [_vertexData setColor:color atIndex:vertexID];
    [self vertexDataDidChange];
    
    if (color != SPColorWhite) _tinted = YES;
    else _tinted = (self.alpha != 1.0f) || _vertexData.tinted;
}

- (uint)colorOfVertex:(NSInteger)vertexID
{
    return [_vertexData colorAtIndex:vertexID];
}

- (void)setAlpha:(float)alpha ofVertex:(NSInteger)vertexID
{
    [_vertexData setAlpha:alpha atIndex:vertexID];
    [self vertexDataDidChange];
    
    if (alpha != 1.0) _tinted = true;
    else _tinted = (self.alpha != 1.0f) || _vertexData.tinted;
}

- (float)alphaOfVertex:(NSInteger)vertexID
{
    return [_vertexData alphaAtIndex:vertexID];
}

- (void)copyVertexDataTo:(SPVertexData *)targetData atIndex:(NSInteger)targetIndex
{
    [self copyTransformedVertexDataTo:targetData atIndex:targetIndex matrix:nil];
}

- (void)copyTransformedVertexDataTo:(SPVertexData *)targetData atIndex:(NSInteger)targetIndex
                             matrix:(nullable SPMatrix *)matrix
{
    [_vertexData copyTransformedToVertexData:targetData atIndex:targetIndex matrix:matrix fromIndex:0 numVertices:4];
}

- (void)vertexDataDidChange
{
    // override in subclass
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPQuad *quad = [super copyWithZone: zone];
    
    quad->_tinted = _tinted;
    SP_RELEASE_AND_COPY(quad->_vertexData, _vertexData);
    [quad vertexDataDidChange];
    
    return quad;
}

#pragma mark SPDisplayObject

- (void)render:(SPRenderSupport *)support
{
    [support batchQuad:self];
}

- (SPRectangle *)boundsInSpace:(SPDisplayObject *)targetSpace
{
    if (targetSpace == self) // optimization
    {
        SPPoint *bottomRight = [_vertexData positionAtIndex:3];
        return [SPRectangle rectangleWithX:0.0f y:0.0f width:bottomRight.x height:bottomRight.y];
    }
    else if ((id)targetSpace == (id)self.parent && self.rotation == 0.0f) // optimization
    {
        float scaleX = self.scaleX;
        float scaleY = self.scaleY;

        SPPoint *bottomRight = [_vertexData positionAtIndex:3];
        SPRectangle *resultRect = [SPRectangle rectangleWithX:self.x - self.pivotX * scaleX
                                                            y:self.y - self.pivotY * scaleY
                                                        width:bottomRight.x * scaleX
                                                       height:bottomRight.y * scaleY];

        if (scaleX < 0.0f) { resultRect.width  *= -1.0f; resultRect.x -= resultRect.width;  }
        if (scaleY < 0.0f) { resultRect.height *= -1.0f; resultRect.y -= resultRect.height; }

        return resultRect;
    }
    else if (self.is3D && self.stage)
    {
        SPPoint3D *cameraPos = self.stage.cameraPosition;
        SPMatrix3D *transform3D = [self transformationMatrix3DToSpace:targetSpace];
        return [_vertexData projectedBoundsAfterTransformation:transform3D camPos:cameraPos atIndex:0 numVertices:4];
    }
    else
    {
        SPMatrix *transformationMatrix = [self transformationMatrixToSpace:targetSpace];
        return [_vertexData boundsAfterTransformation:transformationMatrix atIndex:0 numVertices:4];
    }
}

- (void)setAlpha:(float)alpha
{
    super.alpha = alpha;

    if (self.alpha != 1.0f) _tinted = true;
    else _tinted = _vertexData.tinted;
}

#pragma mark Properties

- (uint)color
{
    return [self colorOfVertex:0];
}

- (void)setColor:(uint)color
{
    for (int i=0; i<4; ++i)
        [_vertexData setColor:color atIndex:i];

    [self vertexDataDidChange];

    if (color != SPColorWhite) _tinted = YES;
    else _tinted = (self.alpha != 1.0f) || _vertexData.tinted;
}

- (BOOL)premultipliedAlpha
{
    return _vertexData.premultipliedAlpha;
}

- (void)setPremultipliedAlpha:(BOOL)premultipliedAlpha
{
    if (premultipliedAlpha != self.premultipliedAlpha)
        _vertexData.premultipliedAlpha = premultipliedAlpha;
}

- (BOOL)tinted
{
    return _tinted;
}

- (SPTexture *)texture
{
    return nil;
}

@end
