//
//  SPStageTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 25.04.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPStageTest : SPTestCase 

@end

@implementation SPStageTest

- (void)testForbiddenProperties
{
    SPStage *stage = [[SPStage alloc] init];
    XCTAssertThrows([stage setX:10], @"allowed to set x coordinate of stage");
    XCTAssertThrows([stage setY:10], @"allowed to set y coordinate of stage");
    XCTAssertThrows([stage setScaleX:2.0], @"allowed to scale stage");
    XCTAssertThrows([stage setScaleY:2.0], @"allowed to scale stage");
    XCTAssertThrows([stage setRotation:PI], @"allowed to rotate stage");
}

@end