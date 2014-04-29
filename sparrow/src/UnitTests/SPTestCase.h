//
//  SPTestCase.h
//  Sparrow
//
//  Created by Daniel Sperl on 14.03.14.
//  Copyright 2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <XCTest/XCTest.h>
#import <Sparrow/Sparrow.h>

#define E 0.0001f

@interface SPTestCase : XCTestCase

- (void)comparePoint:(SPPoint *)p1 withPoint:(SPPoint *)p2;
- (void)compareVertex:(SPVertex)v1 withVertex:(SPVertex)v2;
- (void)compareVertexColor:(SPVertexColor)c1 withVertexColor:(SPVertexColor)c2;
- (void)compareVertexData:(SPVertexData *)v1 withVertexData:(SPVertexData *)v2;
- (void)compareVector:(GLKVector2)v1 withVector:(GLKVector2)v2;

@end