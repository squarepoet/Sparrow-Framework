//
//  SPMacrosTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 13.02.12.
//  Copyright 2012 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPMacrosTest : SPTestCase

@end

@implementation SPMacrosTest

- (void)testClamp
{
    XCTAssertEqual( 4, SP_CLAMP(1, 4, 6), @"wrong clamp result");
    XCTAssertEqual(-3, SP_CLAMP(-3, -10, -1), @"wrong clamp result");
    XCTAssertEqual( 5, SP_CLAMP(10, 0, 5), @"wrong clamp result");
}

- (void)testSwap
{
    float x = 4.0f;
    float y = 5.0f;
    
    SP_SWAP(x, y, float);
    XCTAssertEqual(5.0f, x, @"float swap did not work");
    XCTAssertEqual(4.0f, y, @"float swap did not work");
    
    int a = 4;
    int b = 5;
    
    SP_SWAP(a, b, int);
    XCTAssertEqual(5, a, @"int swap did not work");
    XCTAssertEqual(4, b, @"int swap did not work");
    
    NSString *u = @"u";
    NSString *v = @"v";
    
    SP_SWAP(u, v, id);
    XCTAssertEqualObjects(@"v", u, @"string swap did not work");
    XCTAssertEqualObjects(@"u", v, @"string swap did not work");
}

@end