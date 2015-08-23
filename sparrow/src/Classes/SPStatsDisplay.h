//
//  SPStatsDisplay.h
//  Sparrow
//
//  Created by Daniel Sperl on 27.03.13.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPSprite.h>

NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------
 
 The statistics display is used internally by Sparrow to display statistical information.
 Use the `showStats:` method of `SPViewController` to show it.
 
 _This is an internal class. You do not have to use it manually._
 
------------------------------------------------------------------------------------------------- */

@interface SPStatsDisplay : SPSprite

/// The actual frame rate, i.e. the number of frames rendered per second.
@property (nonatomic) NSInteger framesPerSecond;

/// The number of draw calls per frame.
@property (nonatomic) NSInteger numDrawCalls;

@end

NS_ASSUME_NONNULL_END
