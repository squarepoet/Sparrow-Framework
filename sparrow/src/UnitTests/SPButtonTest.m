//
//  SPButtonTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 21.05.11.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

#define E 0.0001f

@interface SPButtonTest : SPTestCase

@end

@implementation SPButtonTest

- (void)testTextBounds
{
    SPTexture *texture = [[SPGLTexture alloc] init];
    SPButton *button = [SPButton buttonWithUpState:texture text:@"x"];
    
    XCTAssertEqual(0.0f, button.textBounds.x, @"wrong initial textBounds.x");
    XCTAssertEqual(0.0f, button.textBounds.y, @"wrong initial textBounds.y");
    XCTAssertEqual(texture.width, button.textBounds.width, @"wrong initial textBounds.width");
    XCTAssertEqual(texture.height, button.textBounds.height, @"wrong initial textBounds.height");
    
    SPRectangle *textBounds = [SPRectangle rectangleWithX:5 y:6 width:22 height:20];
    button.textBounds = textBounds;
    
    XCTAssertEqual(textBounds.x, button.textBounds.x, @"wrong modified textBounds.x");
    XCTAssertEqual(textBounds.y, button.textBounds.y, @"wrong modified textBounds.y");
    XCTAssertEqual(textBounds.width, button.textBounds.width, @"wrong modified textBounds.width");
    XCTAssertEqual(textBounds.height, button.textBounds.height, @"wrong modified textBounds.height");
    
    // when changing scaleX, scaleY, textBounds must not change
    button.scaleX = 1.2f;
    button.scaleY = 1.5f;
    
    XCTAssertEqual(textBounds.x, button.textBounds.x, @"wrong modified textBounds.x with scale");
    XCTAssertEqual(textBounds.y, button.textBounds.y, @"wrong modified textBounds.y with scale");
    XCTAssertEqual(textBounds.width, button.textBounds.width, @"wrong modified textBounds.width with scale");
    XCTAssertEqual(textBounds.height, button.textBounds.height, @"wrong modified textBounds.height with scale");
    
    // but when changing width or height, they should -- thus, it behaves just like a textfield.
    button.scaleX = button.scaleY = 1.0f;
    
    float scaleX = 1.2f;
    float scaleY = 1.5f;

    button.width *= scaleX;
    button.height *= scaleY;
    
    XCTAssertEqualWithAccuracy(textBounds.x * scaleX, button.textBounds.x, E, @"wrong modified textBounds.x with changed size");
    XCTAssertEqualWithAccuracy(textBounds.y * scaleY, button.textBounds.y, E, @"wrong modified textBounds.y changed size");
    XCTAssertEqualWithAccuracy(textBounds.width * scaleX, button.textBounds.width, E, @"wrong modified textBounds.width changed size");
    XCTAssertEqualWithAccuracy(textBounds.height * scaleY, button.textBounds.height, E, @"wrong modified textBounds.height changed size");
}

@end