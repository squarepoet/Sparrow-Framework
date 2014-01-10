//
//  SPStageTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 25.04.09.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Availability.h>
#ifdef __IPHONE_3_0

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

#import <Sparrow/SPMatrix.h>
#import <Sparrow/SPMacros.h>
#import <Sparrow/SPPoint.h>
#import <Sparrow/SPSprite.h>
#import <Sparrow/SPStage.h>

// -------------------------------------------------------------------------------------------------

@interface SPStageTest : SenTestCase 

@end

// -------------------------------------------------------------------------------------------------

@implementation SPStageTest

- (void)testForbiddenProperties
{
    SPStage *stage = [[SPStage alloc] init];
    STAssertThrows([stage setX:10], @"allowed to set x coordinate of stage");
    STAssertThrows([stage setY:10], @"allowed to set y coordinate of stage");
    STAssertThrows([stage setScaleX:2.0], @"allowed to scale stage");
    STAssertThrows([stage setScaleY:2.0], @"allowed to scale stage");
    STAssertThrows([stage setRotation:PI], @"allowed to rotate stage");
}

@end

#endif