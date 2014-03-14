//
//  SPTextureAtlasTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 04.04.13.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPTextureAtlasTest : SPTestCase

@end

@implementation SPTextureAtlasTest

- (void)testBasicFunctionality
{
    SPTexture *texture = [[SPTexture alloc] initWithWidth:100 height:100];
    SPTextureAtlas *atlas = [[SPTextureAtlas alloc] initWithTexture:texture];

    XCTAssertEqual(0, atlas.numTextures, @"wrong texture count");
    
    SPRectangle *region0 = [SPRectangle rectangleWithX:50 y:25 width:50 height:75];
    [atlas addRegion:region0 withName:@"region_0"];
    
    XCTAssertEqual(1, atlas.numTextures, @"wrong texture count");
    
    SPSubTexture *subTexture = (SPSubTexture *)[atlas textureByName:@"region_0"];
    
    XCTAssertEqual(subTexture.parent, texture, @"wrong parent texture");
    
    SPRectangle *expectedClipping = [SPRectangle rectangleWithX:0.5f y:0.25f width:0.5f height:0.75f];
    SPRectangle *clipping = subTexture.clipping;
    
    XCTAssertTrue([expectedClipping isEqualToRectangle:clipping], @"wrong region");
    
    NSArray *expectedNames = @[@"region_0"];
    NSArray *names = atlas.names;
    
    XCTAssertTrue([expectedNames isEqualToArray:names], @"wrong names array");

    SPRectangle *region1 = [SPRectangle rectangleWithX:0 y:10 width:20 height:30];
    [atlas addRegion:region1 withName:@"region_1"];
    
    expectedNames = @[@"region_0", @"region_1"];
    names = atlas.names;
    
    XCTAssertTrue([expectedNames isEqualToArray:names], @"wrong names array");
    
    SPRectangle *region2 = [SPRectangle rectangleWithX:0 y:0 width:10 height:10];
    [atlas addRegion:region2 withName:@"other_name"];
    
    names = [atlas namesStartingWith:@"region"];
    XCTAssertTrue([expectedNames isEqualToArray:names], @"wrong names array");
}

@end