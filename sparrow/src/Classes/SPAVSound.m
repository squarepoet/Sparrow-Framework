//
//  SPAVSound.m
//  Sparrow
//
//  Created by Daniel Sperl on 29.05.10.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPAVSound.h"
#import "SPAVSoundChannel.h"
#import "SPUtils.h"

@implementation SPAVSound
{
    NSData *_soundData;
    double _duration;
}

@synthesize duration = _duration;

#pragma mark Initialization

- (instancetype)init
{
    SP_USE_DESIGNATED_INITIALIZER(initWithContentsOfFile:duration:);
    return nil;
}

- (instancetype)initWithContentsOfFile:(NSString *)path duration:(double)duration
{
    if ((self = [super init]))
    {
        NSString *fullPath = [SPUtils absolutePathToFile:path];
        _soundData = [[NSData alloc] initWithContentsOfFile:fullPath options:NSDataReadingMappedIfSafe error:nil];
        _duration = duration;
    }
    return self;
}

- (void)dealloc
{
    [_soundData release];
    [super dealloc];
}

#pragma mark Methods

- (AVAudioPlayer *)createPlayer
{
    NSError *error = nil;    
    AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithData:_soundData error:&error] autorelease];
    if (error) SPLog(@"Could not create AVAudioPlayer: %@", [error description]);    
    return player;	
}

#pragma mark SPSound

- (SPSoundChannel *)createChannel
{
    return [[[SPAVSoundChannel alloc] initWithSound:self] autorelease];
}

@end
