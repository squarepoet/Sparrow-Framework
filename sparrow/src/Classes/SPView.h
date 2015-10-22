//
//  SPView.h
//  Sparrow
//
//  Created by Robert Carone on 8/11/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>

NS_ASSUME_NONNULL_BEGIN

@class SPContext;
@class SPViewController;

/** A view to render Sparrow's content to. */

@interface SPView : UIView

/// The OpenGL render target layer.
@property (nonatomic, readonly) CAEAGLLayer *layer;

/// The parent view controller of this view.
@property (nonatomic, readonly) SPViewController *viewController;

@end

NS_ASSUME_NONNULL_END
