//
//  SPUtilsTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 04.01.11.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPUtilsTest : SPTestCase

@end

@implementation SPUtilsTest

- (void)testGetNextPowerOfTwo
{   
    XCTAssertEqual(1, [SPUtils nextPowerOfTwo:0], @"wrong power of two");
    XCTAssertEqual(1, [SPUtils nextPowerOfTwo:1], @"wrong power of two");
    XCTAssertEqual(2, [SPUtils nextPowerOfTwo:2], @"wrong power of two");
    XCTAssertEqual(4, [SPUtils nextPowerOfTwo:3], @"wrong power of two");
    XCTAssertEqual(4, [SPUtils nextPowerOfTwo:4], @"wrong power of two");
    XCTAssertEqual(8, [SPUtils nextPowerOfTwo:5], @"wrong power of two");
    XCTAssertEqual(8, [SPUtils nextPowerOfTwo:6], @"wrong power of two");
    XCTAssertEqual(256, [SPUtils nextPowerOfTwo:129], @"wrong power of two");
    XCTAssertEqual(256, [SPUtils nextPowerOfTwo:255], @"wrong power of two");
    XCTAssertEqual(256, [SPUtils nextPowerOfTwo:256], @"wrong power of two");    
}

- (void)testGetRandomFloat
{
    for (int i=0; i<20; ++i)
    {
        float rnd = [SPUtils randomFloat];
        XCTAssertTrue(rnd >= 0.0f, @"random number too small");
        XCTAssertTrue(rnd < 1.0f,  @"random number too big");        
    }    
}

- (void)testGetRandomInt
{
    for (int i=0; i<20; ++i)
    {
        int rnd = [SPUtils randomIntBetweenMin:5 andMax:10];
        XCTAssertTrue(rnd >= 5, @"random number too small");
        XCTAssertTrue(rnd < 10, @"random number too big");        
    }    
}

- (void)testFileExistsAtPath_Absolute
{
    NSString *absolutePath = [[NSBundle appBundle] pathForResource:@"pvrtc_image.pvr"];
    
    BOOL fileExists = [SPUtils fileExistsAtPath:absolutePath];
    XCTAssertTrue(fileExists, @"resource file not found");
    
    fileExists = [SPUtils fileExistsAtPath:@"/tmp/some_non_existing_file.foo"];
    XCTAssertFalse(fileExists, @"found non-existing file");
    
    NSString *folder = [absolutePath stringByDeletingLastPathComponent];
    BOOL folderExists = [SPUtils fileExistsAtPath:folder];
    XCTAssertTrue(folderExists, @"folder not found");
}

- (void)testFileExistsAtPath_Relative
{
    BOOL fileExists = [SPUtils fileExistsAtPath:@"pvrtc_image@2x.pvr"];
    XCTAssertTrue(fileExists, @"resource file not found");

    fileExists = [SPUtils fileExistsAtPath:@"pvrtc_image.pvr"];
    XCTAssertTrue(fileExists, @"resource file not found");

    fileExists = [SPUtils fileExistsAtPath:@"some_non_existing_file.foo"];
    XCTAssertFalse(fileExists, @"found non-existing file");
}

- (void)testFileExistsAtPath_Null
{
    BOOL fileExists = [SPUtils fileExistsAtPath:nil];
    XCTAssertFalse(fileExists, @"nil path mistakenly accepted");
}

- (void)testAbsolutePathToFile
{
    NSString *absolutePath1x = [SPUtils absolutePathToFile:@"pvrtc_image.pvr" withScaleFactor:1.0f];
    NSString *absolutePath2x = [SPUtils absolutePathToFile:@"pvrtc_image.pvr" withScaleFactor:2.0f];
    
    XCTAssertNotNil(absolutePath1x, @"resource not found (1x)");
    XCTAssertNotNil(absolutePath2x, @"resource not found (2x)");
    
    NSUInteger suffixLoc = [absolutePath2x rangeOfString:@"@2x.pvr"].location;
    XCTAssertEqual((int)suffixLoc, (int)absolutePath2x.length - 7, @"did not find correct resource (2x)");
    
    NSString *nonexistingPath = [SPUtils absolutePathToFile:@"does_not_exist.foo"];
    XCTAssertNil(nonexistingPath, @"found non-existing file");
    
    nonexistingPath = [SPUtils absolutePathToFile:@"does_not_exist@2x.foo"];
    XCTAssertNil(nonexistingPath, @"found non-existing file");
    
    NSString *nilPath = [SPUtils absolutePathToFile:nil];
    XCTAssertNil(nilPath, @"found nil-path");
    
    nilPath = [SPUtils absolutePathToFile:nil withScaleFactor:2.0f];
    XCTAssertNil(nilPath, @"found nil-path (2x)");
}

- (void)testIdiom
{
    NSString *filename = @"image_idiom.png";
    
    NSString *absolutePath = [SPUtils absolutePathToFile:filename withScaleFactor:1.0f 
                                                   idiom:UIUserInterfaceIdiomPhone];
    XCTAssertTrue([absolutePath hasSuffix:@"image_idiom~iphone.png"], @"idiom image not found");
}

- (void)testScaledIdiom
{
    NSString *filename = @"image_idiom.png";
    
    NSString *absolutePath = [SPUtils absolutePathToFile:filename withScaleFactor:2.0f 
                                                   idiom:UIUserInterfaceIdiomPhone];
    XCTAssertTrue([absolutePath hasSuffix:@"image_idiom@2x~iphone.png"], @"idiom image not found");
}

- (void)testGetSdTextureFallback
{
    NSString *filename = @"image_only_sd.png";
    
    NSString *absolutePath = [SPUtils absolutePathToFile:filename withScaleFactor:2.0f];
    XCTAssertTrue([absolutePath hasSuffix:filename], @"1x fallback resource not found");
}

- (void)testGetHdTextureFallback
{
    NSString *filename = @"image_only_hd.png";
    
    // @4x is not available -> @2x should be returned as a fallback
    NSString *absolutePath = [SPUtils absolutePathToFile:filename withScaleFactor:4.0f];
    XCTAssertEqual(2.0f, [absolutePath contentScaleFactor], @"2x fallback not found");
}

- (void)testOnlyHdTextureAvailable
{
    NSString *filename = @"image_only_hd.png";
    NSString *fullFilename = [filename stringByAppendingSuffixToFilename:@"@2x"];
    
    NSString *absolutePath = [SPUtils absolutePathToFile:filename withScaleFactor:2.0f];
    XCTAssertTrue([absolutePath hasSuffix:fullFilename], @"2x resource not found");
}

@end