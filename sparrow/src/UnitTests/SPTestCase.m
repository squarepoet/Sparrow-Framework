//
//  SPTestCase.m
//  Sparrow
//
//  Created by Daniel Sperl on 14.03.14.
//  Copyright 2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@implementation SPTestCase

- (void)comparePoint:(SPPoint *)p1 withPoint:(SPPoint *)p2
{
    XCTAssertEqualWithAccuracy(p1.x,  p2.x,  E, @"wrong point.x");
    XCTAssertEqualWithAccuracy(p1.y,  p2.y,  E, @"wrong point.y");
}

- (void)compareVertex:(SPVertex)v1 withVertex:(SPVertex)v2
{
    [self compareVertexColor:v1.color withVertexColor:v2.color];
    [self compareVector:v1.position withVector:v2.position];
    [self compareVector:v1.texCoords withVector:v2.texCoords];
}

- (void)compareVertexColor:(SPVertexColor)c1 withVertexColor:(SPVertexColor)c2
{
    XCTAssertEqual(c1.r, c2.r, @"wrong color.r");
    XCTAssertEqual(c1.g, c2.g, @"wrong color.g");
    XCTAssertEqual(c1.b, c2.b, @"wrong color.b");
    XCTAssertEqual(c1.a, c2.a, @"wrong color.a");
}

- (void)compareVector:(GLKVector2)v1 withVector:(GLKVector2)v2
{
    XCTAssertEqualWithAccuracy(v1.x, v2.x, E, @"wrong vector.x");
    XCTAssertEqualWithAccuracy(v1.y, v2.y, E, @"wrong vector.y");
}

- (void)compareVertexData:(SPVertexData *)v1 withVertexData:(SPVertexData *)v2
{
    NSInteger numVertices  = v1.numVertices;
    if (numVertices != v2.numVertices) XCTFail(@"vertex data size mismatch");
    else
    {
        for (int i=0; i<numVertices; ++i)
            [self compareVertex:v1.vertices[i] withVertex:v2.vertices[i]];
    }
}

@end
