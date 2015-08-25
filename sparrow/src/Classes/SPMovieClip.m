//
//  SPMovieClip.m
//  Sparrow
//
//  Created by Daniel Sperl on 01.05.10.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPMovieClip.h"
#import "SPSoundChannel.h"

static SPSoundChannel *nullSound = nil;

@implementation SPMovieClip
{
    SP_GENERIC(NSMutableArray, SPTexture*) *_textures;
    SP_GENERIC(NSMutableArray, SPSoundChannel*) *_sounds;
    SP_GENERIC(NSMutableArray, NSNumber*) *_durations;
    SP_GENERIC(NSMutableArray, NSNumber*) *_startTimes;
    
    double _defaultFrameDuration;
    double _currentTime;
    double _totalTime;
    NSInteger _currentFrame;
    BOOL _loop;
    BOOL _playing;
    BOOL _muted;
    BOOL _wasStopped;
}

+ (void)initialize
{
    nullSound = (SPSoundChannel *)[NSNull null];
}

#pragma mark Initialization

- (instancetype)initWithFrames:(SP_GENERIC(NSArray, SPTexture*) *)textures fps:(float)fps
{
    if (textures.count == 0)
        [NSException raise:SPExceptionInvalidOperation format:@"empty texture array"];
    
    if (fps < 0)
        [NSException raise:SPExceptionInvalidOperation format:@"Invalid fps: %f", fps];
    
    if (self = [super initWithTexture:textures[0]])
    {
        NSInteger numFrames = textures.count;
        
        _defaultFrameDuration = 1.0f / fps;
        _loop = YES;
        _playing = YES;
        _currentTime = 0.0;
        _currentFrame = 0;
        _wasStopped = YES;
        _textures = [textures mutableCopy];
        _sounds = [[NSMutableArray alloc] initWithCapacity:numFrames];
        _durations = [[NSMutableArray alloc] initWithCapacity:numFrames];
        _startTimes = [[NSMutableArray alloc] initWithCapacity:numFrames];
        _totalTime = _defaultFrameDuration * numFrames;
        
        for (int i=0; i<numFrames; ++i)
        {
            _sounds[i] = nullSound;
            _durations[i] = @(_defaultFrameDuration);
            _startTimes[i] = @(i * _defaultFrameDuration);
        }
    }
    
    return self;
}

- (instancetype)initWithFrame:(SPTexture *)texture fps:(float)fps
{
    return [self initWithFrames:@[texture] fps:fps];
}

- (instancetype)initWithTexture:(SPTexture *)texture
{
    return [self initWithFrame:texture fps:10];
}

- (void)dealloc
{
    [_textures release];
    [_sounds release];
    [_durations release];
    [_startTimes release];
    [super dealloc];
}

+ (instancetype)movieWithFrame:(SPTexture *)texture fps:(float)fps
{
    return [[[self alloc] initWithFrame:texture fps:fps] autorelease];
}

+ (instancetype)movieWithFrames:(SP_GENERIC(NSArray, SPTexture*)*)textures fps:(float)fps
{
    return [[[self alloc] initWithFrames:textures fps:fps] autorelease];
}

#pragma mark Frame Manipulation Methods

- (void)addFrameWithTexture:(SPTexture *)texture
{
    [self addFrameWithTexture:texture atIndex:self.numFrames];
}

- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration
{
    [self addFrameWithTexture:texture duration:duration atIndex:self.numFrames];
}

- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration sound:(SPSoundChannel *)sound
{
    [self addFrameWithTexture:texture duration:duration sound:sound atIndex:self.numFrames];
}

- (void)addFrameWithTexture:(SPTexture *)texture atIndex:(NSInteger)frameID
{
    [self addFrameWithTexture:texture duration:_defaultFrameDuration atIndex:frameID];
}

- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration atIndex:(NSInteger)frameID
{
    [self addFrameWithTexture:texture duration:duration sound:nil atIndex:frameID];
}

- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration
                      sound:(SPSoundChannel *)sound atIndex:(NSInteger)frameID
{
    [_textures insertObject:texture atIndex:frameID];
    [_durations insertObject:@(duration) atIndex:frameID];
    [_sounds insertObject:sound ?: nullSound atIndex:frameID];
    
    if (frameID > 0 && frameID == self.numFrames)
        [_startTimes addObject:@([_startTimes[frameID-1] doubleValue] + [_durations[frameID-1] doubleValue])];
    else
        [self updateStartTimes];
}

- (void)removeFrameAtIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    if (self.numFrames == 1)
        [NSException raise:SPExceptionInvalidOperation format:@"Movie clip must not be empty"];
    
    [_textures removeObjectAtIndex:frameID];
    [_durations removeObjectAtIndex:frameID];
    [_sounds removeObjectAtIndex:frameID];
    
    [self updateStartTimes];
}

- (SPTexture *)textureAtIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    return _textures[frameID];
}

- (void)setTexture:(SPTexture *)texture atIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    _textures[frameID] = texture;
}

- (SPSoundChannel *)soundAtIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    id sound = _sounds[frameID];
    if (nullSound != sound) return sound;
    else return nil;
}

- (void)setSound:(SPSoundChannel *)sound atIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    _sounds[frameID] = sound ?: nullSound;
}

- (double)durationAtIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    return [_durations[frameID] doubleValue];
}

- (void)setDuration:(double)duration atIndex:(NSInteger)frameID
{
    if (frameID < 0 || frameID >= self.numFrames)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid frame id"];
    
    _durations[frameID] = @(duration);
    [self updateStartTimes];
}

- (void)reverseFrames
{
    SP_RELEASE_AND_COPY_MUTABLE(_textures,  [[_textures  reverseObjectEnumerator] allObjects]);
    SP_RELEASE_AND_COPY_MUTABLE(_sounds,    [[_sounds    reverseObjectEnumerator] allObjects]);
    SP_RELEASE_AND_COPY_MUTABLE(_durations, [[_durations reverseObjectEnumerator] allObjects]);
    
    [self updateStartTimes];
    
    _currentTime = _totalTime - _currentTime;
    _currentFrame = self.numFrames - _currentFrame - 1;
}

#pragma mark Playback Methods

- (void)play
{
    _playing = YES;    
}

- (void)pause
{
    _playing = NO;
}

- (void)stop
{
    _playing = NO;
    _wasStopped = YES;
    self.currentFrame = 0;
}

#pragma mark Private

- (void)updateStartTimes
{
    NSInteger numFrames = self.numFrames;
    
    [_startTimes removeAllObjects];
    _startTimes[0] = @0;
    
    for (int i=1; i<numFrames; ++i)
        _startTimes[i] = @([_startTimes[i-1] doubleValue] + [_durations[i-1] doubleValue]);
    
    _totalTime = [_startTimes[numFrames-1] doubleValue] + [_durations[numFrames-1] doubleValue];
}

- (void)updateCurrentFrame
{
    self.texture = _textures[_currentFrame];
}

- (void)playSound:(NSInteger)frame
{
    if (_muted) return;
    
    SPSoundChannel *sound = _sounds[frame];
    if (nullSound != sound)
        [sound play];
}

#pragma mark SPAnimatable

- (void)advanceTime:(double)passedTime
{
    if (!_playing || passedTime <= 0.0) return;
    
    NSInteger finalFrame;
    NSInteger previousFrame = _currentFrame;
    double restTime = 0.0;
    BOOL dispatchCompleteEvent = NO;
    
    if (_wasStopped)
    {
        // if the clip was stopped and started again,
        // we need to play the frame's sound manually.
        
        _wasStopped = NO;
        [self playSound:_currentFrame];
    }
    
    if (_loop && _currentTime >= _totalTime)
    {
        _currentTime = 0.0;
        _currentFrame = 0;
    }
    
    if (_currentTime < _totalTime)
    {
        _currentTime += passedTime;
        finalFrame = _textures.count - 1;
        
        while (_currentTime > ([_startTimes[_currentFrame] doubleValue] + [_durations[_currentFrame] doubleValue]))
        {
            if (_currentFrame == finalFrame)
            {
                if (_loop && ![self hasEventListenerForType:SPEventTypeCompleted])
                {
                    _currentTime -= _totalTime;
                    _currentFrame = 0;
                }
                else
                {
                    restTime = _currentTime - _totalTime;
                    dispatchCompleteEvent = true;
                    _currentFrame = finalFrame;
                    _currentTime = _totalTime;
                    break;
                }
            }
            else
            {
                _currentFrame++;
            }
            
            [self playSound:_currentFrame];
        }
        
        // special case when we reach *exactly* the total time.
        if (_currentFrame == finalFrame && _currentTime == _totalTime)
            dispatchCompleteEvent = true;
    }
    
    if (_currentFrame != previousFrame)
        self.texture = _textures[_currentFrame];
    
    if (dispatchCompleteEvent)
        [self dispatchEventWithType:SPEventTypeCompleted];
    
    if (_loop && restTime > 0.0)
        [self advanceTime:restTime];
}

#pragma mark Properties

- (NSInteger)numFrames
{
    return _textures.count;
}

- (void)setCurrentFrame:(NSInteger)value
{
    _currentFrame = value;
    _currentTime = 0.0;
    
    for (int i=0; i<value; ++i)
        _currentTime += [self durationAtIndex:i];
    
    self.texture = _textures[_currentFrame];
    if (_playing && !_wasStopped) [self playSound:_currentFrame];
}

- (float)fps
{
	return (float)(1.0 / _defaultFrameDuration);
}

- (void)setFps:(float)fps
{
    float newFrameDuration = (fps == 0.0f ? INT_MAX : 1.0 / fps);
	float acceleration = newFrameDuration / _defaultFrameDuration;
    _currentTime *= acceleration;
    _defaultFrameDuration = newFrameDuration;

	for (NSInteger i=0; i<self.numFrames; ++i)
		[self setDuration:[self durationAtIndex:i] * acceleration atIndex:i];
}

- (BOOL)isPlaying
{
    if (_playing)
        return _loop || _currentTime < _totalTime;
    else
        return NO;
}

- (BOOL)isComplete
{
    return !_loop && _currentTime >= _totalTime;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPMovieClip *movie = [super copyWithZone:zone];
    
    SP_RELEASE_AND_COPY_MUTABLE(movie->_textures, _textures);
    SP_RELEASE_AND_COPY_MUTABLE(movie->_durations, _durations);
    SP_RELEASE_AND_COPY_MUTABLE(movie->_sounds, _sounds);
    
    movie->_defaultFrameDuration = _defaultFrameDuration;
    movie->_currentTime = _currentTime;
    movie->_totalTime = _totalTime;
    movie->_loop = _loop;
    movie->_playing = _playing;
    movie->_muted = _muted;
    movie->_currentFrame = _currentFrame;
    
    [movie updateCurrentFrame];
    
    return movie;
}

@end
