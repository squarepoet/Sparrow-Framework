//
//  untitled.m
//  Sparrow
//
//  Created by Daniel Sperl on 19.06.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPImageTest : SPTestCase 

@end

@implementation SPImageTest

- (void)testInit
{
    SPImage *image = [[SPImage alloc] init];
    XCTAssertTrue([[SPPoint pointWithX:0 y:0] isEqualToPoint:[image texCoordsOfVertex:0]], @"wrong tex coords!");
    XCTAssertTrue([[SPPoint pointWithX:1 y:0] isEqualToPoint:[image texCoordsOfVertex:1]], @"wrong tex coords!");
    XCTAssertTrue([[SPPoint pointWithX:0 y:1] isEqualToPoint:[image texCoordsOfVertex:2]], @"wrong tex coords!");
    XCTAssertTrue([[SPPoint pointWithX:1 y:1] isEqualToPoint:[image texCoordsOfVertex:3]], @"wrong tex coords!");
}

- (void)testSetTexCoords
{
    SPImage *image = [[SPImage alloc] init];
    [image setTexCoords:[SPPoint pointWithX:1 y:2] ofVertex:0];
    [image setTexCoords:[SPPoint pointWithX:3 y:4] ofVertex:1];
    [image setTexCoordsWithX:5 y:6 ofVertex:2];
    [image setTexCoordsWithX:7 y:8 ofVertex:3];
    
    XCTAssertTrue([[SPPoint pointWithX:1 y:2] isEqualToPoint:[image texCoordsOfVertex:0]], @"wrong tex coords!");
    XCTAssertTrue([[SPPoint pointWithX:3 y:4] isEqualToPoint:[image texCoordsOfVertex:1]], @"wrong tex coords!");
    XCTAssertTrue([[SPPoint pointWithX:5 y:6] isEqualToPoint:[image texCoordsOfVertex:2]], @"wrong tex coords!");
    XCTAssertTrue([[SPPoint pointWithX:7 y:8] isEqualToPoint:[image texCoordsOfVertex:3]], @"wrong tex coords!");
}

- (void)testChangeTexture
{
    SPTexture *texture1 = [[SPTexture alloc] initWithWidth:32 height:24 draw:NULL];
    SPTexture *texture2 = [[SPTexture alloc] initWithWidth:64 height:48 draw:NULL];
    
    SPImage *image = [[SPImage alloc] initWithTexture:texture1];
    XCTAssertEqualObjects(image.texture, texture1, @"wrong texture");
    XCTAssertEqual(texture1.width, image.width, @"wrong texture width");
    XCTAssertEqual(texture1.height, image.height, @"wrong texture height");
    
    // changing the texture should NOT change the image size
    image.texture = texture2;
    XCTAssertEqualObjects(image.texture, texture2, @"wrong texture");
    XCTAssertEqual(texture1.width, image.width, @"wrong texture width");
    XCTAssertEqual(texture1.height, image.height, @"wrong texture height");
}

@end