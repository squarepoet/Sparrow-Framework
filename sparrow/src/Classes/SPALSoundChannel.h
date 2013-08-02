//
//  SPALSoundChannel.h
//  Sparrow
//
//  Created by Daniel Sperl on 28.05.10.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPSoundChannel.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
#import <OpenAL/alc.h>
#import <OpenAL/al.h>
#else
#import <OpenAL/OpenAL.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class SPALSound;

/** ------------------------------------------------------------------------------------------------

 The SPALSoundChannel class is a concrete implementation of SPSoundChannel that uses 
 OpenAL internally. 
 
 Don't create instances of this class manually. Use `[SPSound createChannel]` instead.
 
------------------------------------------------------------------------------------------------- */

@interface SPALSoundChannel : SPSoundChannel

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a sound channel from an SPALSound object.
- (instancetype)initWithSound:(SPALSound *)sound;

- (void)setPitch:(float)value;
- (void)setPan:(float)right;

- (void)setPitch:(float)value;
- (void)setPan:(float)right;

@end

NS_ASSUME_NONNULL_END
