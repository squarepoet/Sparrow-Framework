//
//  SPMatrix3DTest.m
//  Sparrow
//
//  Created by Robert Carone on 8/3/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPMatrix3DTest : SPTestCase

@end

@implementation SPMatrix3DTest
{
    GLKMatrix4 compareMatrix;
    SPMatrix3D *countMatrix;
    SPMatrix3D *identMatrix;
}

- (void)setUp
{
    compareMatrix = GLKMatrix4Identity;
    countMatrix = [[SPMatrix3D alloc] initWithGLKMatrix4:GLKMatrix4Make(1, 0, 0, 0,
                                                                        0, 2, 0, 0,
                                                                        0, 0, 3, 0,
                                                                        0, 0, 0, 4)];
    identMatrix = [[SPMatrix3D alloc] init];
}

- (void)testCopy
{
    SPMatrix3D *copy = [countMatrix copy];
    XCTAssertTrue([countMatrix isEqualToMatrix:copy], @"copy not equal: %@", copy);
    XCTAssertFalse(countMatrix == copy, @"copy is identical");
}

- (void)testAppendMatrix
{
    SPMatrix3D *copy = [countMatrix copy];
    [copy appendMatrix:identMatrix];
    XCTAssertTrue([countMatrix isEqualToMatrix:copy], @"multiplication with identity modified matrix");
    
    copy = [identMatrix copy];
    [copy appendMatrix:countMatrix];
    XCTAssertTrue([countMatrix isEqualToMatrix:copy], @"multiplication with identity modified matrix");
    
    SPMatrix3D *countDownMatrix = [[SPMatrix3D alloc] initWithGLKMatrix4:GLKMatrix4Make(3, 0, 0, 0,
                                                                                        0, 4, 0, 0,
                                                                                        0, 0, 5, 0,
                                                                                        0, 0, 0, 6)];
    compareMatrix = GLKMatrix4Multiply(countDownMatrix.convertToGLKMatrix, copy.convertToGLKMatrix);
    [copy appendMatrix:countDownMatrix];
    XCTAssertTrue([self checkMatrixValues:copy values:compareMatrix.m],
                  @"wrong matrix: %@", copy);
    
    compareMatrix = GLKMatrix4Multiply(countMatrix.convertToGLKMatrix, countDownMatrix.convertToGLKMatrix);
    [countDownMatrix appendMatrix:countMatrix];
    XCTAssertTrue([self checkMatrixValues:copy values:compareMatrix.m],
                  @"wrong matrix: %@", copy);
}

- (void)testInvert
{
    compareMatrix = countMatrix.convertToGLKMatrix;
    compareMatrix = GLKMatrix4Invert(compareMatrix, nil);
    
    [countMatrix invert];
    
    XCTAssertTrue([self checkMatrixValues:countMatrix values:compareMatrix.m],
                  @"invert produced wrong result: %@", countMatrix);
    
    compareMatrix = GLKMatrix4Identity;
    compareMatrix = GLKMatrix4Translate(compareMatrix, 20, 40, 0);
    compareMatrix = GLKMatrix4Invert(compareMatrix, nil);
    
    SPMatrix3D *translateMatrix = [SPMatrix3D matrix3DWithIdentity];
    [translateMatrix appendTranslationX:20 y:40 z:0];
    [translateMatrix invert];
    
    XCTAssertTrue([self checkMatrixValues:translateMatrix values:compareMatrix.m],
                  @"invert produced wrong result: %@", translateMatrix);
}

- (void)testTranslate
{
    [identMatrix appendTranslationX:5 y:6 z:7];
    SPVector3D *vector = [[SPVector3D alloc] initWithX:10 y:20 z:30];
    SPVector3D *tVector = [identMatrix transformVector:vector];
    XCTAssertTrue(SPIsFloatEqual(15, tVector.x), @"wrong x value: %f", tVector.x);
    XCTAssertTrue(SPIsFloatEqual(26, tVector.y), @"wrong y value: %f", tVector.y);
    XCTAssertTrue(SPIsFloatEqual(37, tVector.z), @"wrong z value: %f", tVector.z);
}

- (void)testRotate
{
    [identMatrix appendRotation:PI/2.0f axis:[SPVector3D zAxis]];
    SPVector3D *vector = [[SPVector3D alloc] initWithX:10 y:0 z:0];
    SPVector3D *rVector = [identMatrix transformVector:vector];
    XCTAssertTrue(SPIsFloatEqual(0, rVector.x), @"wrong x value: %f", rVector.x);
    XCTAssertTrue(SPIsFloatEqual(10, rVector.y), @"wrong y value: %f", rVector.y);
    
    [identMatrix identity];
    [identMatrix prependRotation:PI axis:[SPVector3D zAxis]];
    vector.y = 20;
    rVector = [identMatrix transformVector:vector];
    XCTAssertTrue(SPIsFloatEqual(-10, rVector.x), @"wrong x value: %f", rVector.x);
    XCTAssertTrue(SPIsFloatEqual(-20, rVector.y), @"wrong y value: %f", rVector.y);
}

- (void)testScale
{
    [identMatrix appendScaleX:2.0 y:0.5 z:0];
    SPVector3D *vector = [[SPVector3D alloc] initWithX:10 y:20 z:0];
    SPVector3D *sVector = [identMatrix transformVector:vector];
    XCTAssertTrue(SPIsFloatEqual(20.0f, sVector.x), @"wrong x value: %f", sVector.x);
    XCTAssertTrue(SPIsFloatEqual(10.0f, sVector.y), @"wrong y value: %f", sVector.y);
}

- (void)testConcatenatedTransformations
{
    [identMatrix appendRotation:PI/2.0f axis:[SPVector3D zAxis]];
    [identMatrix appendScaleX:0.5f y:0.5f z:0];
    [identMatrix appendTranslationX:0.0f y:5.0f z:0];
    SPVector3D *ctVector = [identMatrix transformVectorWithX:10.0f y:0 z:0];
    XCTAssertTrue(SPIsFloatEqual(0.0f, ctVector.x), @"wrong x value: %f", ctVector.x);
    XCTAssertTrue(SPIsFloatEqual(10.0f, ctVector.y), @"wrong y value: %f", ctVector.y);
}

- (BOOL)checkMatrixValues:(SPMatrix3D *)matrix values:(float *)values
{
    float *rawData = matrix.rawData;
    for (int i=0; i<16; ++i)
    {
        if (!SPIsFloatEqual(rawData[i], values[i]))
            return NO;
    }
    
    return YES;
}

@end
