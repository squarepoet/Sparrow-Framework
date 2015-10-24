//
//  SPPress.h
//  Sparrow
//
//  Created by Robert Carone on 10/24/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Foundation/Foundation.h>

NS_ENUM_AVAILABLE_IOS(9_0)
typedef NS_ENUM(NSInteger, SPPressPhase)
{
    SPPressPhaseBegan,         // whenever a button press begins.
    SPPressPhaseChanged,       // whenever a button moves.
    SPPressPhaseStationary,    // whenever a buttons was pressed and is still being held down.
    SPPressPhaseEnded,         // whenever a button is releasd.
    SPPressPhaseCancelled,     // whenever a button press doesn't end but we need to stop tracking.
};

NS_ENUM_AVAILABLE_IOS(9_0)
typedef NS_ENUM(NSInteger, SPPressType)
{
    SPPressTypeUpArrow,
    SPPressTypeDownArrow,
    SPPressTypeLeftArrow,
    SPPressTypeRightArrow,
    SPPressTypeSelect,
    SPPressTypeMenu,
    SPPressTypePlayPause,
};

/** ------------------------------------------------------------------------------------------------
 
 An SPPress contains information about the presence or changes of presses on a remote. The press 
 specifically encapsulates the pressing of some physically actuated button. All of the press types 
 represent actual physical buttons on one of a variety of remotes.
 
 You receive objects of this type via an SPPressEvent. When such an event is triggered, you can
 query it for all press that are currently present on the stage. One SPPress object contains
 information about a single press.
 
------------------------------------------------------------------------------------------------- */

NS_CLASS_AVAILABLE_IOS(9_0)
@interface SPPress : NSObject

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a new touch object with the specified id. _Designated Initializer_.
- (instancetype)initWithID:(size_t)pressID;

/// Factory method.
+ (instancetype)pressWithID:(size_t)pressID;

/// Factory method.
+ (instancetype)press;

/// ----------------
/// @name Properties
/// ----------------

/// The moment the event occurred (in seconds since application start).
@property (nonatomic, readonly) NSTimeInterval timestamp;

/// The current phase the press is in.
@property (nonatomic, readonly) SPPressPhase phase;

/// The type of press that occurred.
@property (nonatomic, readonly) SPPressType type;

/// The force of the press. [0..1]
@property (nonatomic, readonly) float force;

@end
