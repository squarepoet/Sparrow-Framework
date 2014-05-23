//
//  SPNSExtensionsTests.m
//  Sparrow
//
//  Created by Daniel Sperl on 10.07.10.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPNSExtensionsTest : SPTestCase

@end

@implementation SPNSExtensionsTest

- (void)testStringByAppendingSuffixToFilename
{    
    NSString *filename = @"path/file.ext";
    NSString *expandedFilename = [filename stringByAppendingSuffixToFilename:@"@2x"];
    XCTAssertEqualObjects(@"path/file@2x.ext", expandedFilename, @"Appending suffix did not work!");    
    
    filename = @"path/file.ext.gz";
    expandedFilename = [filename stringByAppendingSuffixToFilename:@"@2x"];
    XCTAssertEqualObjects(@"path/file@2x.ext.gz", expandedFilename, @"Appending suffix did not work!");    
}

- (void)testFullPathExtension
{
    NSString *filename = @"test.png";
    NSString *extension = [filename fullPathExtension];
    XCTAssertEqualObjects(@"png", extension, @"wrong path extension on standard filename");
    
    filename = @"test.pvr.gz";
    extension = [filename fullPathExtension];
    XCTAssertEqualObjects(@"pvr.gz", extension, @"wrong path extension on double extension");
    
    filename = @"/tmp/scratch.tiff";
    extension = [filename fullPathExtension];
    XCTAssertEqualObjects(@"tiff", extension, @"wrong path extension on path with folders");

    filename = @"/tmp/scratch";
    extension = [filename fullPathExtension];
    XCTAssertEqualObjects(@"", extension, @"wrong path extension on path without extension");
    
    filename = @"/tmp/";
    extension = [filename fullPathExtension];
    XCTAssertEqualObjects(@"", extension, @"wrong path extension on path that contains a folder");
    
    filename = @".tmp";
    extension = [filename fullPathExtension];
    XCTAssertEqualObjects(@"", extension, @"wrong path extension on hidden file");
}

- (void)testStringByDeletingFullPathExtension
{
    NSString *filename = @"/tmp/scratch.tiff";
    NSString *basename = [filename stringByDeletingFullPathExtension];
    XCTAssertEqualObjects(@"/tmp/scratch", basename, @"wrong base name on standard path");

    filename = @"/tmp/test.pvr.gz";
    basename = [filename stringByDeletingFullPathExtension];
    XCTAssertEqualObjects(@"/tmp/test", basename, @"wrong base name on double extension");
    
    filename = @"/tmp/";
    basename = [filename stringByDeletingFullPathExtension];
    XCTAssertEqualObjects(@"/tmp", basename, @"wrong base name on path that contains a folder");
    
    filename = @"scratch.bundle/";
    basename = [filename stringByDeletingFullPathExtension];
    XCTAssertEqualObjects(@"scratch", basename, @"wrong base name on standard path with terminating slash");

    filename = @".tiff";
    basename = [filename stringByDeletingFullPathExtension];
    XCTAssertEqualObjects(@".tiff", basename, @"wrong base name on hidden file");

    filename = @"/";
    basename = [filename stringByDeletingFullPathExtension];
    XCTAssertEqualObjects(@"/", basename, @"wrong base name on standard path");
}

- (void)testAppBundle
{
    NSString *absolutePath = [[NSBundle appBundle] pathForResource:@"pvrtc_image.pvr"];
    XCTAssertNotNil(absolutePath, @"path to resource not found");
}

- (void)testContentScaleFactor
{
    NSString *filename = @"/some/folders/filename@2x.png";
    XCTAssertEqual(2.0f, [filename contentScaleFactor], @"wrong scale factor");
    
    filename = @"/some/folders/filename.png";
    XCTAssertEqual(1.0f, [filename contentScaleFactor], @"wrong scale factor");
    
    filename = @"/some/folders/filename@4x~ipad.png";
    XCTAssertEqual(4.0f, [filename contentScaleFactor], @"wrong scale factor");
    
    filename = @"/some/folders/filename@x~whatever.png";
    XCTAssertEqual(1.0f, [filename contentScaleFactor], @"wrong scale factor");

    filename = @"/some/folders/filename@4x_and_more.png";
    XCTAssertEqual(4.0f, [filename contentScaleFactor], @"wrong scale factor");
    
    filename = @"not a filename";
    XCTAssertEqual(1.0f, [filename contentScaleFactor], @"wrong scale factor");
}

@end