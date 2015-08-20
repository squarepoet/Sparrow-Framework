//
//  SPTouchProcessor.h
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>

NS_ASSUME_NONNULL_BEGIN

@class SPDisplayObjectContainer;
@class SPStage;
@class SPTouch;

/** ------------------------------------------------------------------------------------------------
 The SPTouchProcesser processes raw touch information and dispatches it on display objects.
 _This is an internal class. You do not have to use it manually._
 ------------------------------------------------------------------------------------------------- */

@interface SPTouchProcessor : NSObject

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a touch processor with a certain root object.
- (instancetype)initWithStage:(SPStage *)stage;

/// -------------
/// @name Methods
/// -------------

/// Analyzes the current touch queue and processes the list of current touches, emptying
/// the queue while doing so. This method is called by Sparrow once per frame.
- (void)advanceTime:(double)seconds;

/// Dispatches SPTouchEvents to the display objects that are affected by the list of given touches.
/// Called internally by "advanceTime:". To calculate updated targets, the method will call
/// "hitTestPoint:" on the "root" object.
///
/// @param touches  A list of all touches that have changed just now.
- (void)processTouches:(NSMutableOrderedSet *)touches;

/// Enqueues a new touch.
- (void)enqueueTouch:(SPTouch *)touch;

/// Force-end all current touches. Changes the phase of all touches to '.Ended' and immediately
/// dispatches a new TouchEvent (if touches are present). Called automatically when the app
/// receives a 'UIApplicationWillResignActiveNotification' notification.
- (void)cancelCurrentTouches;

/// ----------------
/// @name Properties
/// ----------------

/// The root display container to check for touched targets.
@property (nonatomic, readonly) SPStage *stage;

/// The base object that will be used for hit testing. Per default, this reference points
/// to the stage; however, you can limit touch processing to certain parts of your game
/// by assigning a different object.
@property (nonatomic, weak) SPDisplayObject *root;

/// The time period (in seconds) in which two touches must occur to be recognized as a
/// multitap gesture.
@property (nonatomic, assign) double multitapTime;

/// The distance (in points) describing how close two touches must be to each other to be
/// recognized as a multitap gesture.
@property (nonatomic, assign) float multitapDistance;

/// Returns the number of fingers or touch points that are currently on the stage.
@property (nonatomic, readonly) NSInteger numCurrentTouches;

@end

NS_ASSUME_NONNULL_END
