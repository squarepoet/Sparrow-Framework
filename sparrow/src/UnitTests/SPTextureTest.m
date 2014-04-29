//
//  SPTextureTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 31.01.14.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPTextureTest : SPTestCase

@end

@implementation SPTextureTest

- (void)testTextureCoordinates
{
    int rootWidth  = 256;
    int rootHeight = 128;

    SPPoint *texCoords;
    SPSubTexture *subTexture, *subSubTexture;
    SPVertexData *vertexData = [self standardVertexData];
    SPVertexData *adjustedVertexData;
    SPGLTexture *texture = [self GLTextureWithWidth:rootWidth height:rootHeight scale:1.0f];
    SPRectangle *region = [SPRectangle rectangle];

    // test subtexture filling the whole base texture
    [region setX:0 y:0 width:rootWidth height:rootHeight];
    subTexture = [[SPSubTexture alloc] initWithRegion:region ofTexture:texture];
    adjustedVertexData = [vertexData copy];
    [subTexture adjustVertexData:adjustedVertexData atIndex:0 numVertices:4];
    [self compareVertexData:vertexData withVertexData:adjustedVertexData];

    // test subtexture with 50% of the size of the base texture
    [region setX:rootWidth/4 y:rootHeight/4 width:rootWidth/2 height:rootHeight/2];
    subTexture = [[SPSubTexture alloc] initWithRegion:region ofTexture:texture];
    adjustedVertexData = [vertexData copy];
    [subTexture adjustVertexData:adjustedVertexData atIndex:0 numVertices:4];

    texCoords = [adjustedVertexData texCoordsAtIndex:0];
    [self comparePoint:[SPPoint pointWithX:0.25f y:0.25f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:1];
    [self comparePoint:[SPPoint pointWithX:0.75f y:0.25f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:2];
    [self comparePoint:[SPPoint pointWithX:0.25f y:0.75f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:3];
    [self comparePoint:[SPPoint pointWithX:0.75f y:0.75f] withPoint:texCoords];

    // test subtexture of subtexture
    [region setX:subTexture.width/4.0f y:subTexture.height/4.0f
           width:subTexture.width/2.0f height:subTexture.height/2.0f];
    subSubTexture = [[SPSubTexture alloc] initWithRegion:region ofTexture:subTexture];
    adjustedVertexData = [vertexData copy];
    [subSubTexture adjustVertexData:adjustedVertexData atIndex:0 numVertices:4];

    texCoords = [adjustedVertexData texCoordsAtIndex:0];
    [self comparePoint:[SPPoint pointWithX:0.375f y:0.375f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:1];
    [self comparePoint:[SPPoint pointWithX:0.625f y:0.375f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:2];
    [self comparePoint:[SPPoint pointWithX:0.375f y:0.625f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:3];
    [self comparePoint:[SPPoint pointWithX:0.625f y:0.625f] withPoint:texCoords];

    // test subtexture over moved texture coords (same effect as above)
    vertexData = [self regionVertexData];
    adjustedVertexData = [vertexData copy];
    [subTexture adjustVertexData:adjustedVertexData atIndex:0 numVertices:4];

    texCoords = [adjustedVertexData texCoordsAtIndex:0];
    [self comparePoint:[SPPoint pointWithX:0.375f y:0.375f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:1];
    [self comparePoint:[SPPoint pointWithX:0.625f y:0.375f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:2];
    [self comparePoint:[SPPoint pointWithX:0.375f y:0.625f] withPoint:texCoords];
    texCoords = [adjustedVertexData texCoordsAtIndex:3];
    [self comparePoint:[SPPoint pointWithX:0.625f y:0.625f] withPoint:texCoords];
}

- (void)testRotation
{
    int rootWidth  = 256;
    int rootHeight = 128;

    SPPoint *texCoords;
    SPRectangle *region;
    SPSubTexture *subTexture, *subSubTexture;
    SPGLTexture *texture = [self GLTextureWithWidth:rootWidth height:rootHeight scale:1.0f];
    SPVertexData *vertexData = [self standardVertexData];

    // rotate full region once

    subTexture = [[SPSubTexture alloc] initWithRegion:nil frame:nil rotated:YES ofTexture:texture];
    [subTexture adjustVertexData:vertexData atIndex:0 numVertices:4];

    texCoords = [vertexData texCoordsAtIndex:0];
    [self comparePoint:[SPPoint pointWithX:1 y:0] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:1];
    [self comparePoint:[SPPoint pointWithX:1 y:1] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:2];
    [self comparePoint:[SPPoint pointWithX:0 y:0] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:3];
    [self comparePoint:[SPPoint pointWithX:0 y:1] withPoint:texCoords];

    // rotate again

    subSubTexture = [[SPSubTexture alloc] initWithRegion:nil frame:nil rotated:YES ofTexture:subTexture];
    vertexData = [self standardVertexData];
    [subSubTexture adjustVertexData:vertexData atIndex:0 numVertices:4];

    texCoords = [vertexData texCoordsAtIndex:0];
    [self comparePoint:[SPPoint pointWithX:1 y:1] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:1];
    [self comparePoint:[SPPoint pointWithX:0 y:1] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:2];
    [self comparePoint:[SPPoint pointWithX:1 y:0] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:3];
    [self comparePoint:[SPPoint pointWithX:0 y:0] withPoint:texCoords];

    // now get rotated region

    region = [SPRectangle rectangleWithX:rootWidth/4 y:rootHeight/2 width:rootWidth/2 height:rootHeight/4];
    subTexture = [[SPSubTexture alloc] initWithRegion:region frame:nil rotated:YES ofTexture:texture];
    vertexData = [self standardVertexData];
    [subTexture adjustVertexData:vertexData atIndex:0 numVertices:4];

    texCoords = [vertexData texCoordsAtIndex:0];
    [self comparePoint:[SPPoint pointWithX:0.75f y:0.5f] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:1];
    [self comparePoint:[SPPoint pointWithX:0.75f y:0.75f] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:2];
    [self comparePoint:[SPPoint pointWithX:0.25f y:0.5f] withPoint:texCoords];
    texCoords = [vertexData texCoordsAtIndex:3];
    [self comparePoint:[SPPoint pointWithX:0.25f y:0.75f] withPoint:texCoords];
}

- (void)testRoot
{
    SPRectangle *subRegion = [SPRectangle rectangleWithX:0 y:0 width:16 height:16];
    SPRectangle *subSubRegion = [SPRectangle rectangleWithX:0 y:0 width:8 height:8];

    SPGLTexture *texture = [self GLTextureWithWidth:32 height:32 scale:1.0f];
    SPTexture *subTexture = [[SPSubTexture alloc] initWithRegion:subRegion ofTexture:texture];
    SPTexture *subSubTexture = [[SPSubTexture alloc] initWithRegion:subSubRegion ofTexture:subTexture];

    XCTAssertEqual(texture, texture.root, @"wrong root texture");
    XCTAssertEqual(texture, subTexture.root, @"wrong root texture");
    XCTAssertEqual(texture, subSubTexture.root, @"wrong root texture");
    XCTAssertEqual(texture.name, subSubTexture.name, @"wrong texture name of SubTexture");
}

- (void)testSize
{
    SPTexture *texture = [self GLTextureWithWidth:32 height:16 scale:2.0f];
    SPRectangle *region = [SPRectangle rectangleWithX:0 y:0 width:12 height:8];
    SPSubTexture *subTexture = [[SPSubTexture alloc] initWithRegion:region ofTexture:texture];

    XCTAssertEqualWithAccuracy(texture.width, 16.0f, E, @"wrong texture width");
    XCTAssertEqualWithAccuracy(texture.height, 8.0f, E, @"wrong texture height");
    XCTAssertEqualWithAccuracy(texture.nativeWidth,  32.0f, E, @"wrong texture native width");
    XCTAssertEqualWithAccuracy(texture.nativeHeight, 16.0f, E, @"wrong texture native height");

    XCTAssertEqualWithAccuracy(subTexture.width, 12.0f, E, @"wrong subTexture width");
    XCTAssertEqualWithAccuracy(subTexture.height, 8.0f, E, @"wrong subTexture height");
    XCTAssertEqualWithAccuracy(subTexture.nativeWidth,  24.0f, E, @"wrong subTexture native width");
    XCTAssertEqualWithAccuracy(subTexture.nativeHeight, 16.0f, E, @"wrong subTexture native height");
}

- (void)testClipping
{
    SPTexture *texture = [self GLTextureWithWidth:8 height:4 scale:1.0f];
    SPRectangle *region = [SPRectangle rectangleWithX:4 y:2 width:2 height:2];
    SPSubTexture *subTexture = [[SPSubTexture alloc] initWithRegion:region ofTexture:texture];
    SPRectangle *clipping = subTexture.clipping;

    XCTAssertEqualWithAccuracy(clipping.x, 0.5f, E, @"wrong clipping.x");
    XCTAssertEqualWithAccuracy(clipping.y, 0.5f, E, @"wrong clipping.x");
    XCTAssertEqualWithAccuracy(clipping.width, 0.25f, E, @"wrong clipping.x");
    XCTAssertEqualWithAccuracy(clipping.height, 0.5f, E, @"wrong clipping.x");
}

- (SPGLTexture *)GLTextureWithWidth:(float)width height:(float)height scale:(float)scale
{
    return [[SPGLTexture alloc] initWithName:1 format:SPTextureFormat4444 width:width height:height
                             containsMipmaps:NO scale:scale premultipliedAlpha:NO];
}

- (SPVertexData *)standardVertexData
{
    SPVertexData *vertexData = [[SPVertexData alloc] initWithSize:4];
    [vertexData setTexCoordsWithX:0 y:0 atIndex:0];
    [vertexData setTexCoordsWithX:1 y:0 atIndex:1];
    [vertexData setTexCoordsWithX:0 y:1 atIndex:2];
    [vertexData setTexCoordsWithX:1 y:1 atIndex:3];
    return vertexData;
}

- (SPVertexData *)regionVertexData
{
    SPVertexData *vertexData = [[SPVertexData alloc] initWithSize:4];
    [vertexData setTexCoordsWithX:0.25f y:0.25f atIndex:0];
    [vertexData setTexCoordsWithX:0.75f y:0.25f atIndex:1];
    [vertexData setTexCoordsWithX:0.25f y:0.75f atIndex:2];
    [vertexData setTexCoordsWithX:0.75f y:0.75f atIndex:3];
    return vertexData;
}

@end