//
//  SPSparrow.h
//  Sparrow
//
//  Created by Daniel Sperl on 27.01.13.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPViewController.h>
#import <Sparrow/SPJuggler.h>

NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------
 
 The Sparrow class provides static convenience methods to access certain properties of the current
 SPViewController.
 
------------------------------------------------------------------------------------------------- */

@interface Sparrow : NSObject

/// The currently active SPViewController.
+ (nullable SPViewController *)currentController;

/// The currently active OpenGL context.
+ (nullable SPContext *)context;

/// A juggler that is advanced once per frame by the current view controller.
+ (nullable SPJuggler *)juggler;

/// The stage that is managed by the current view controller.
+ (nullable SPStage *)stage;

/// The root object of your game, i.e. an instance of the class you passed to the 'startWithRoot:'
/// method of SPViewController.
+ (nullable SPDisplayObject *)root;

/// The content scale factor of the current view controller.
+ (float)contentScaleFactor;

@end

NS_ASSUME_NONNULL_END
