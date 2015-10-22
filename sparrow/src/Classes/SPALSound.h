//
//  SPALSound.h
//  Sparrow
//
//  Created by Daniel Sperl on 28.05.10.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPSound.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
#import <OpenAL/al.h>
#else
#import <OpenAL/OpenAL.h>
#endif
NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------ 

 The SPALSound class is a concrete implementation of SPSound that uses OpenAL internally. 
 
 Don't create instances of this class manually. Use `[SPSound initWithContentsOfFile:]` instead.
 
------------------------------------------------------------------------------------------------- */

@interface SPALSound : SPSound

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a sound with its known properties.
- (instancetype)initWithData:(const void *)data size:(NSInteger)size channels:(NSInteger)channels
                   frequency:(NSInteger)frequency duration:(double)duration;

/// ----------------
/// @name Properties
/// ----------------

/// The OpenAL buffer ID of the sound.
@property (nonatomic, readonly) ALuint bufferID;

@end

NS_ASSUME_NONNULL_END
