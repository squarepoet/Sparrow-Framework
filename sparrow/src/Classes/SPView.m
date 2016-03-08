//
//  SPView.m
//  Sparrow
//
//  Created by Robert Carone on 8/11/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPRectangle.h"
#import "SPView_Internal.h"
#import "SPViewController_Internal.h"

@implementation SPView
{
    SPViewController __weak *_viewController;
}

@dynamic layer;

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
        [self initCommon];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
        [self initCommon];
    
    return self;
}

- (void)initCommon
{
    self.opaque = YES;
    self.clearsContextBeforeDrawing = NO;
  #if !TARGET_OS_TV
    self.multipleTouchEnabled = YES;
  #endif
}

- (void)displayLayer:(CALayer *)layer
{
    [_viewController render];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [_viewController viewDidResize:self.frame];
    [_viewController render];
}

- (void)setFrame:(CGRect)frame
{
    if (!CGRectEqualToRect(frame, super.frame))
    {
        super.frame = frame;
        [_viewController viewDidResize:self.frame];
    }
}

@end

@implementation SPView (Internal)

- (void)setViewController:(SPViewController *)viewController
{
    _viewController = viewController;
}

@end
