//
//  SPTweenedProperty.h
//  Sparrow
//
//  Created by Daniel Sperl on 17.10.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>

NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------
 
 An SPTweenedProperty stores the information about the tweening of a single property of an object.
 Its `currentValue` property updates the specified property of the target object.
 
 _This is an internal class. You do not have to use it manually._
 
------------------------------------------------------------------------------------------------- */

@interface SPTweenedProperty : NSObject

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a tween property on a certain target. The start value will be zero.
- (instancetype)initWithTarget:(id)target name:(NSString *)name endValue:(double)endValue;

/// Updates the current value of the target to a certain value.
- (void)update:(double)progress;

/// ----------------
/// @name Properties
/// ----------------

/// The name of the property the receiver is tweening.
@property (nonatomic, readonly) NSString *name;

/// Indicates if the values should be cast to Integers.
@property (nonatomic, assign) BOOL rountToInt;

/// The start value of the tween.
@property (nonatomic, assign) double startValue;

/// The current value of the tween. Setting this property updates the target property.
@property (nonatomic, assign) double currentValue;

/// The end value of the tween.
@property (nonatomic, assign) double endValue;

/// The animation delta (endValue - startValue)
@property (nonatomic, readonly) double delta;

@end

NS_ASSUME_NONNULL_END