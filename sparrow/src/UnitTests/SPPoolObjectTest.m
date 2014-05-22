//
//  SPPoolObjectTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 15.01.11.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPPoolObjectTest : SPTestCase

@end

@implementation SPPoolObjectTest

- (void)testObjectPooling
{
    #ifndef DISABLE_MEMORY_POOLING
    
    [SPPoint purgePool]; // clean existing pool
    
    SPPoint *p1 = [[SPPoint alloc] initWithX:1.0f y:2.0f];
    SPPoint *p2 = [[SPPoint alloc] initWithX:3.0f y:4.0f];
    SPPoint *p3 = [[SPPoint alloc] initWithX:5.0f y:6.0f];
    
    // object should still exist after release
    [p3 release];
    XCTAssertEqual(5.0f, p3.x, @"object no longer accessible or wrong contents");
    XCTAssertEqual(6.0f, p3.y, @"object no longer accessible or wrong contents");
    
    SPPoint *p4 = [[SPPoint alloc] initWithX:15.0f y:16.0f];
    
    // p4 should be the recycled p3
    XCTAssertEqual((int)p3, (int)p4, @"object not taken from pool");
    XCTAssertEqual(15.0f, p3.x, @"object not taken from pool");
    XCTAssertEqual(16.0f, p3.y, @"object not taken from pool");

    [p4 release];
    [p2 release];
    [p1 release];
    
    SPPoint *p5 = [[SPPoint alloc] initWithX:11.0f y:22.0f];
    XCTAssertEqual((int)p5, (int)p1, @"object not taken from pool");
    
    NSUInteger numPurgedPoints = [SPPoint purgePool];
    XCTAssertEqual(2, numPurgedPoints, @"wrong number of objects released on purge"); 
    
    [p5 release];
    numPurgedPoints = [SPPoint purgePool];
    XCTAssertEqual(1, numPurgedPoints, @"wrong number of objects released on purge"); 
    
    #endif
}

@end