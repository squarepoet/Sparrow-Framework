//
//  SPTweenerTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 15.05.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

#define E 0.0001f

@interface SPTweenTest : SPTestCase

@property (nonatomic, assign) int intProperty;

@end

@implementation SPTweenTest
{
    int _startedCount;
    int _updatedCount;
    int _completedCount;
    int _repeatedCount;
}

- (void) setUp
{
    _startedCount = _updatedCount = _completedCount = _repeatedCount = 0;
}

- (SPTween *)tweenWithTarget:(id)target time:(double)time
{
    SPTween *tween = [SPTween tweenWithTarget:target time:time];
    tween.onStart = ^{ _startedCount++; };
    tween.onUpdate = ^{ _updatedCount++; };
    tween.onRepeat = ^{ _repeatedCount++; };
    tween.onComplete = ^{ _completedCount++; };
    return tween;
}

- (void)testBasicTween
{    
    float startX = 10.0f;
    float startY = 20.0f;
    float endX = 100.0f;
    float endY = 200.0f;
    float startAlpha = 1.0f;
    float endAlpha = 0.0f;
    double totalTime = 2.0;
    
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.x = startX;
    quad.y = startY;
    quad.alpha = startAlpha;
    
    SPTween *tween = [self tweenWithTarget:quad time:totalTime];
    [tween animateProperty:@"x" targetValue:endX];
    [tween animateProperty:@"y" targetValue:endY];
    [tween animateProperty:@"alpha" targetValue:endAlpha];    
    
    XCTAssertEqualWithAccuracy(startX, quad.x, E, @"wrong x");
    XCTAssertEqualWithAccuracy(startY, quad.y, E, @"wrong y");
    XCTAssertEqualWithAccuracy(startAlpha, quad.alpha, E, @"wrong alpha");        
    XCTAssertEqual(0, _startedCount, @"start event dispatched too soon");
    
    [tween advanceTime: totalTime/3.0];   
    XCTAssertEqualWithAccuracy(startX + (endX-startX)/3.0f, quad.x, E, @"wrong x: %f", quad.x);
    XCTAssertEqualWithAccuracy(startY + (endY-startY)/3.0f, quad.y, E, @"wrong y");
    XCTAssertEqualWithAccuracy(startAlpha + (endAlpha-startAlpha)/3.0f, quad.alpha, E, @"wrong alpha");
    XCTAssertEqualWithAccuracy(totalTime/3.0, tween.currentTime, E, @"wrong current time");
    XCTAssertEqual(1, _startedCount, @"missing start event");
    XCTAssertEqual(1, _updatedCount, @"missing update event");
    XCTAssertEqual(0, _completedCount, @"completed event dispatched too soon");
    
    [tween advanceTime: totalTime/3.0];   
    XCTAssertEqualWithAccuracy(startX + 2.0f*(endX-startX)/3.0f, quad.x, E, @"wrong x: %f", quad.x);
    XCTAssertEqualWithAccuracy(startY + 2.0f*(endY-startY)/3.0f, quad.y, E, @"wrong y");
    XCTAssertEqualWithAccuracy(startAlpha + 2.0f*(endAlpha-startAlpha)/3.0f, quad.alpha, E, @"wrong alpha");
    XCTAssertEqualWithAccuracy(2*totalTime/3.0, tween.currentTime, E, @"wrong current time");
    XCTAssertEqual(1, _startedCount, @"too many start events dipatched");
    XCTAssertEqual(2, _updatedCount, @"missing update event");
    XCTAssertEqual(0, _completedCount, @"completed event dispatched too soon");
    
    [tween advanceTime: totalTime/3.0];
    XCTAssertEqualWithAccuracy(endX, quad.x, E, @"wrong x: %f", quad.x);
    XCTAssertEqualWithAccuracy(endY, quad.y, E, @"wrong y");
    XCTAssertEqualWithAccuracy(endAlpha, quad.alpha, E, @"wrong alpha");
    XCTAssertEqualWithAccuracy(totalTime, tween.currentTime, E, @"wrong current time");
    XCTAssertEqual(1, _startedCount, @"too many start events dispatched");
    XCTAssertEqual(3, _updatedCount, @"missing update event");
    XCTAssertEqual(1, _completedCount, @"missing completed event");
}

- (void)testSequentialTweens
{
    float startPos = 0.0f;
    float targetPos = 50.0f;
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    
    // 2 tweens should move object up, then down
    SPTween *tween1 = [SPTween tweenWithTarget:quad time:1];
    [tween1 animateProperty:@"y" targetValue:targetPos];
    
    SPTween *tween2 = [SPTween tweenWithTarget:quad time:1];
    [tween2 animateProperty:@"y" targetValue:startPos];
    tween2.delay = 1;
    
    [tween1 advanceTime:1];
    XCTAssertEqual(targetPos, quad.y, @"wrong y value");
    
    [tween2 advanceTime:1];
    XCTAssertEqual(targetPos, quad.y, @"second tween changed y value on start");
                   
    [tween2 advanceTime:0.5];
    XCTAssertEqualWithAccuracy((targetPos - startPos)/2.0f, quad.y, E, 
                 @"second tween moves object the wrong way");
    
    [tween2 advanceTime:0.5];
    XCTAssertEqual(startPos, quad.y, @"second tween moved to wrong y position");
}

- (void)testTweenFromZero
{
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.scaleX = 0.0f;
    SPTween *tween = [SPTween tweenWithTarget:quad time:1.0f];
    [tween animateProperty:@"scaleX" targetValue:1.0f];
    
    [tween advanceTime:0.0f];    
    XCTAssertEqualWithAccuracy(0.0f, quad.width, E, @"wrong x value");
    
    [tween advanceTime:0.5f];
    XCTAssertEqualWithAccuracy(50.0f, quad.width, E, @"wrong x value");
    
    [tween advanceTime:0.5f];
    XCTAssertEqualWithAccuracy(100.0f, quad.width, E, @"wrong x value");
}

- (void)testRepeatingTween
{
    float startX = 100.0f;    
    float deltaX = 50.0f;
    float totalTime = 2.0f;
    
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.x = startX;
    
    SPTween *tween = [self tweenWithTarget:quad time:totalTime];
    [tween animateProperty:@"x" targetValue:startX + deltaX];
    tween.repeatCount = 5;
    
    [tween advanceTime:0.0];
    XCTAssertEqualWithAccuracy(startX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime / 2.0];
    XCTAssertEqualWithAccuracy(startX + 0.5f * deltaX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime / 2.0];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(1, _repeatedCount, @"repeated event not fired");
    
    [tween advanceTime:totalTime / 2.0];
    XCTAssertEqualWithAccuracy(startX + 0.5f * deltaX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime / 2.0];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(2, _repeatedCount, @"repeated event not fired");
    
    [tween advanceTime:totalTime * 2];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(4, _repeatedCount, @"repeated event not fired the correct number of times");
    
    [tween advanceTime:totalTime];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(4, _repeatedCount, @"repeated event not fired the correct number of times");
    XCTAssertEqual(1, _completedCount, @"completed event not fired");
}

- (void)testReversingTween
{
    float startX = 100.0f;    
    float deltaX = 50.0f;
    float totalTime = 2.0f;
    
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.x = startX;
    
    SPTween *tween = [self tweenWithTarget:quad time:totalTime];
    [tween animateProperty:@"x" targetValue:startX + deltaX];
    tween.repeatCount = 5;
    tween.reverse = YES;
    
    [tween advanceTime:0.0];
    XCTAssertEqualWithAccuracy(startX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime * 0.25];
    XCTAssertEqualWithAccuracy(startX + 0.25f * deltaX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime * 0.5];
    XCTAssertEqualWithAccuracy(startX + 0.75f * deltaX, quad.x, E, @"wrong x value");

    [tween advanceTime:totalTime * 0.25];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(1, _repeatedCount, @"repeated event not fired");

    [tween advanceTime:totalTime * 0.25];
    XCTAssertEqualWithAccuracy(startX + 0.75f * deltaX, quad.x, E, @"wrong x value");

    [tween advanceTime:totalTime * 0.5];
    XCTAssertEqualWithAccuracy(startX + 0.25f * deltaX, quad.x, E, @"wrong x value");

    [tween advanceTime:totalTime * 0.25];
    XCTAssertEqualWithAccuracy(startX, quad.x, E, @"wrong x value");
    XCTAssertEqual(2, _repeatedCount, @"repeated event not fired");
    
    [tween advanceTime:totalTime * 2];
    XCTAssertEqualWithAccuracy(startX, quad.x, E, @"wrong x value");
    XCTAssertEqual(4, _repeatedCount, @"repeated event not fired the correct number of times");
    
    [tween advanceTime:totalTime];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(4, _repeatedCount, @"repeated event not fired the correct number of times");
    XCTAssertEqual(1, _completedCount, @"completed event not fired the correct number of times");

    [tween advanceTime:totalTime];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    XCTAssertEqual(4, _repeatedCount, @"repeated event not fired the correct number of times");
    XCTAssertEqual(1, _completedCount, @"completed event not fired the correct number of times");
}

- (void)testTweenWithChangingLoop
{
    float startX = 0.0f;
    float deltaX = 100.0f;
    float totalTime = 1.0f;
    
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.x = startX;
    
    SPTween *tween = [self tweenWithTarget:quad time:totalTime];
    [tween animateProperty:@"x" targetValue:startX + deltaX];
    
    [tween advanceTime:totalTime / 2.0f];
    XCTAssertEqual(0, _completedCount, @"completed event fired too soon");
    
    [tween advanceTime:totalTime / 2.0f];
    XCTAssertEqual(1, _completedCount, @"completed event not fired");
    XCTAssertEqual(0, _repeatedCount,  @"repeated event fired too often");
    
    [tween advanceTime:totalTime * 2];
    XCTAssertEqual(1, _completedCount, @"completed event fired too often");
    
    tween.repeatCount = 100;
    
    [tween advanceTime:totalTime / 2.0f];
    XCTAssertEqual(1, _completedCount, @"completed event fired too often");
    
    [tween advanceTime:totalTime / 2.0f];
    XCTAssertEqual(1, _completedCount, @"completed event fired too often");
    XCTAssertEqual(1, _repeatedCount,  @"repeated event not fired");
}

- (void)testRepeatDelay
{
    float startX = 0.0f;
    float deltaX = 100.0f;
    float totalTime = 1.0f;
    float delay = 0.5f;
    
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.x = startX;
    
    SPTween *tween = [self tweenWithTarget:quad time:totalTime];
    tween.repeatCount = 2;
    tween.repeatDelay = delay;
    [tween animateProperty:@"x" targetValue:startX + deltaX];

    [tween advanceTime:totalTime * 0.5];
    XCTAssertEqualWithAccuracy(startX + 0.5f * deltaX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime * 0.5];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:delay * 0.5];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");

    [tween advanceTime:delay * 0.5];
    XCTAssertEqualWithAccuracy(startX + deltaX, quad.x, E, @"wrong x value");
    
    [tween advanceTime:totalTime * 0.1f];
    XCTAssertEqualWithAccuracy(startX + 0.1f * deltaX, quad.x, E, @"wrong x value");
}

- (void)testInfiniteRepeat
{
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    SPTween *tween = [self tweenWithTarget:quad time:1.0];
    tween.repeatCount = 0;
    [tween advanceTime:1000];
    
    XCTAssertEqual(1000, _repeatedCount, @"wrong number of repetitions");
}

- (void)testUnsignedIntTween
{
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    quad.color = 0;
    
    SPTween *tween = [SPTween tweenWithTarget:quad time:2.0];
    [tween animateProperty:@"color" targetValue:100];
    
    XCTAssertEqual((uint)0, quad.color, @"quad starts with wrong color");
    
    [tween advanceTime:1.0];
    XCTAssertEqual((uint)50, quad.color, @"wrong intermediate color");
    
    [tween advanceTime:1.0];
    XCTAssertEqual((uint)100, quad.color, @"wrong final color");
}

- (void)testSignedIntTween
{
    // try positive value
    SPTween *tween = [SPTween tweenWithTarget:self time:1.0];
    [tween animateProperty:@"intProperty" targetValue:100];
    [tween advanceTime:1.0];
    
    XCTAssertEqual(100, self.intProperty, @"tween didn't finish although time has passed");
    
    // and negative value
    self.intProperty = 0;
    tween = [SPTween tweenWithTarget:self time:1.0];
    [tween animateProperty:@"intProperty" targetValue:-100];
    [tween advanceTime:1.0];
    
    XCTAssertEqual(-100, self.intProperty, @"tween didn't finish although time has passed");
}

- (void)makeTweenWithTime:(double)time andAdvanceBy:(double)advanceTime
{
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    SPTween *tween = [self tweenWithTarget:quad time:time];
    [tween animateProperty:@"x" targetValue:100.0f];
    [tween advanceTime:advanceTime];
    
    XCTAssertEqual(1, _updatedCount, @"short tween did not call onUpdate");
    XCTAssertEqual(1, _startedCount, @"short tween did not call onStarted");
    XCTAssertEqual(1, _completedCount, @"short tween did not call onCompleted");
}

- (void)testShortTween
{
    [self makeTweenWithTime:0.1f andAdvanceBy:0.1f];
}

- (void)testZeroTween
{
    [self makeTweenWithTime:0.0f andAdvanceBy:0.1f];
}

@end