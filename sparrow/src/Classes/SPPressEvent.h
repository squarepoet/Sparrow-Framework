//
//  SPPressEvent.h
//  Sparrow
//
//  Created by Robert Carone on 10/24/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPEvent.h>

NS_ASSUME_NONNULL_BEGIN

@class SPPress;

/** ------------------------------------------------------------------------------------------------
 
 An SPPressEvent object is an event that describes the state of a set of physical buttons that are 
 available to the device, such as those on an associated remote or game controller. You can listen
 for these events by adding an event listener to the stage. 
 
 The stage dispatches an SPPressEventType event type when a button is pressed.
 
------------------------------------------------------------------------------------------------- */

NS_CLASS_AVAILABLE_IOS(9_0)
@interface SPPressEvent : SPEvent

/// --------------------
/// @name Initialization
/// --------------------

/// Creates a press event with a set of presses. _Designated Initializer_.
- (instancetype)initWithType:(NSString *)type bubbles:(BOOL)bubbles presses:(SP_GENERIC(NSSet, SPPress*) *)presses;

/// Creates a press event with a set of presses.
- (instancetype)initWithType:(NSString *)type presses:(SP_GENERIC(NSSet, SPPress*) *)presses;

/// Factory method.
+ (instancetype)eventWithType:(NSString *)type presses:(SP_GENERIC(NSSet, SPPress*) *)presses;

/// ----------------
/// @name Properties
/// ----------------

/// All presses that are currently available.
@property (nonatomic, readonly) SP_GENERIC(NSSet, SPPress*) *presses;

/// The time the event occurred (in seconds since application launch).
@property (nonatomic, readonly) double timestamp;

@end

NS_ASSUME_NONNULL_END
