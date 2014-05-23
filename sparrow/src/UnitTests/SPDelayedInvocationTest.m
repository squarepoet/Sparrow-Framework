//
//  SPDelayedInvocationTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 10.07.10.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPDelayedInvocationTest : SPTestCase 

@end

@implementation SPDelayedInvocationTest
{
    int _callCount;
}

- (void)setUp
{
    _callCount = 0;
}

- (void)simpleMethod
{
    ++_callCount;
}

- (void)testSimpleDelay
{
    id delayedInv = [[SPDelayedInvocation alloc] initWithTarget:self delay:1.0f];
    [delayedInv simpleMethod];
    
    XCTAssertEqual(0, _callCount, @"Delayed Invocation triggered too soon");
    [delayedInv advanceTime:0.5f];
    
    XCTAssertEqual(0, _callCount, @"Delayed Invocation triggered too soon");
    [delayedInv advanceTime:0.49f];
    
    XCTAssertEqual(0, _callCount, @"Delayed Invocation triggered too soon");
    XCTAssertFalse([delayedInv isComplete], @"isComplete property wrong");
    
    [delayedInv advanceTime:0.1f];
    XCTAssertEqual(1, _callCount, @"Delayed Invocation did not trigger");
    XCTAssertTrue([delayedInv isComplete], @"isComplete property wrong");
    
    [delayedInv advanceTime:0.1f];
    XCTAssertEqual(1, _callCount, @"Delayed Invocation triggered too often");
}

- (void)testBlock
{
    __block int callCount = 0;
    
    SPDelayedInvocation *delayedInv = [[SPDelayedInvocation alloc] initWithDelay:1.0f block:^
    {
        ++callCount;
    }];
    
    XCTAssertEqual(0, callCount, @"Delayed block triggered too soon");

    [delayedInv advanceTime:0.5f];
    XCTAssertEqual(0, callCount, @"Delayed block triggered too soon");
    
    [delayedInv advanceTime:0.49f];
    XCTAssertEqual(0, callCount, @"Delayed block triggered too soon");
    XCTAssertFalse(delayedInv.isComplete, @"isComplete property wrong");

    [delayedInv advanceTime:0.1f];
    XCTAssertEqual(1, callCount, @"Delayed block did not trigger");
    XCTAssertTrue(delayedInv.isComplete, @"isComplete property wrong");
    
    [delayedInv advanceTime:0.1f];
    XCTAssertEqual(1, callCount, @"Delayed block triggered too often");
}

@end