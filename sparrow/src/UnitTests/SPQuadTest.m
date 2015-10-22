//
//  SPQuadTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 23.04.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPQuadTest : SPTestCase

@end

@implementation SPQuadTest

- (void)testProperties
{
    float width = 30.0f;
    float height = 20.0f;
    float x = 3;
    float y = 2;
    
    SPQuad *quad = [[SPQuad alloc] initWithWidth:width height:height];
    quad.x = x; 
    quad.y = y;
    
    XCTAssertTrue(SPIsFloatEqual(x, quad.x), @"wrong x");
    XCTAssertTrue(SPIsFloatEqual(y, quad.y), @"wrong y");
    XCTAssertTrue(SPIsFloatEqual(width, quad.width), @"wrong width");
    XCTAssertTrue(SPIsFloatEqual(height, quad.height), @"wrong height");
}

- (void)testWidthAfterRotation
{
    float width = 30;
    float height = 40;
    float angle = SPDeg2Rad(45.0f);
    SPQuad *quad = [[SPQuad alloc] initWithWidth:width height:height];
    quad.rotation = angle;

    float expectedWidth = cosf(angle) * (width + height);
    XCTAssertTrue(SPIsFloatEqual(expectedWidth, quad.width), @"wrong width: %f vs %f", expectedWidth, quad.width);
}

- (void)testVertexColorAndAlpha
{
    SPQuad *quad = [[SPQuad alloc] initWithWidth:100 height:100 color:SPColorWhite premultipliedAlpha:NO];
    
    [quad setColor:0xff0000 ofVertex:0];
    [quad setColor:0x00ff00 ofVertex:1];
    [quad setColor:0x0000ff ofVertex:2];
    [quad setColor:0xff00ff ofVertex:3];
    
    XCTAssertEqual((uint)0xff0000, [quad colorOfVertex:0], @"wrong vertex color");
    XCTAssertEqual((uint)0x00ff00, [quad colorOfVertex:1], @"wrong vertex color");
    XCTAssertEqual((uint)0x0000ff, [quad colorOfVertex:2], @"wrong vertex color");
    XCTAssertEqual((uint)0xff00ff, [quad colorOfVertex:3], @"wrong vertex color");
    
    XCTAssertEqual(1.0f, [quad alphaOfVertex:0], @"wrong vertex alpha");
    XCTAssertEqual(1.0f, [quad alphaOfVertex:1], @"wrong vertex alpha");
    XCTAssertEqual(1.0f, [quad alphaOfVertex:2], @"wrong vertex alpha");
    XCTAssertEqual(1.0f, [quad alphaOfVertex:3], @"wrong vertex alpha");
    
    [quad setAlpha:0.2 ofVertex:0];
    [quad setAlpha:0.4 ofVertex:1];
    [quad setAlpha:0.6 ofVertex:2];
    [quad setAlpha:0.8 ofVertex:3];
    
    XCTAssertEqual((uint)0xff0000, [quad colorOfVertex:0], @"wrong vertex color");
    XCTAssertEqual((uint)0x00ff00, [quad colorOfVertex:1], @"wrong vertex color");
    XCTAssertEqual((uint)0x0000ff, [quad colorOfVertex:2], @"wrong vertex color");
    XCTAssertEqual((uint)0xff00ff, [quad colorOfVertex:3], @"wrong vertex color");
    
    XCTAssertEqual(0.2f, [quad alphaOfVertex:0], @"wrong vertex alpha");
    XCTAssertEqual(0.4f, [quad alphaOfVertex:1], @"wrong vertex alpha");
    XCTAssertEqual(0.6f, [quad alphaOfVertex:2], @"wrong vertex alpha");
    XCTAssertEqual(0.8f, [quad alphaOfVertex:3], @"wrong vertex alpha");
}

- (void)testTinted
{
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    XCTAssertFalse(quad.tinted, @"default quad shouldn't be tinted");
    
    quad.alpha = 0.99f;
    XCTAssertTrue(quad.tinted, @"non-opaque quad should be tinted");
    
    quad.alpha = 1.0f;
    [quad setColor:0xff0000 ofVertex:0];
    XCTAssertTrue(quad.tinted, @"partially colored quad should be tinted");
    
    [quad setColor:SPColorWhite ofVertex:0];
    XCTAssertFalse(quad.tinted, @"reset quad shouldn't be tinted");
    
    [quad setAlpha:0.99f ofVertex:0];
    XCTAssertTrue(quad.tinted, @"partially non-opaque quad should be tinted");
}

@end