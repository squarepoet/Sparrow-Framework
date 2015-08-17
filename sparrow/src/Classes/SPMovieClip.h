//
//  SPMovieClip.h
//  Sparrow
//
//  Created by Daniel Sperl on 01.05.10.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPAnimatable.h>
#import <Sparrow/SPImage.h>

NS_ASSUME_NONNULL_BEGIN

@class SPSoundChannel;

/** ------------------------------------------------------------------------------------------------

 An SPMovieClip is a simple way to display an animation depicted by a list of textures.

 You can add the frames one by one or pass them all at once (in an array) at initialization time.
 The movie clip will have the width and height of the first frame.
 
 At initialization, you can specify the desired framerate. You can, however, manually give each
 frame a custom duration. You can also play a sound whenever a certain frame appears.
 
 The methods `play` and `pause` control playback of the movie. You will receive an event of type
 `SPEventTypeCompleted` when the movie finished playback. When the movie is looping,
 the event is dispatched once per loop.
 
 As any animated object, a movie clip has to be added to a juggler (or have its `advanceTime:` 
 method called regularly) to run.
 
------------------------------------------------------------------------------------------------- */
 
@interface SPMovieClip : SPImage <SPAnimatable>

/// --------------------
/// @name Initialization
/// --------------------

/// Initializes a movie with the first frame and the default number of frames per second. _Designated initializer_.
- (instancetype)initWithFrame:(SPTexture *)texture fps:(float)fps;

/// Initializes a movie with an array of textures and the default number of frames per second.
- (instancetype)initWithFrames:(NSArray<SPTexture*> *)textures fps:(float)fps;

/// Factory method.
+ (instancetype)movieWithFrame:(SPTexture *)texture fps:(float)fps;

/// Factory method.
+ (instancetype)movieWithFrames:(NSArray<SPTexture*> *)textures fps:(float)fps;

/// --------------------------------
/// @name Frame Manipulation Methods
/// --------------------------------

/// Adds a frame with a certain texture, using the default duration.
- (void)addFrameWithTexture:(SPTexture *)texture;

/// Adds a frame with a certain texture and duration.
- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration;

/// Adds a frame with a certain texture, duration and sound.
- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration sound:(nullable SPSoundChannel *)sound;

/// Inserts a frame at the specified index. The successors will move down.
- (void)addFrameWithTexture:(SPTexture *)texture atIndex:(NSInteger)frameID;

/// Adds a frame with a certain texture and duration.
- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration atIndex:(NSInteger)frameID;

/// Adds a frame with a certain texture, duration and sound.
- (void)addFrameWithTexture:(SPTexture *)texture duration:(double)duration
                      sound:(nullable SPSoundChannel *)sound atIndex:(NSInteger)frameID;

/// Removes the frame at the specified index. The successors will move up.
- (void)removeFrameAtIndex:(NSInteger)frameID;

/// Returns the texture of a frame at a certain index.
- (SPTexture *)textureAtIndex:(NSInteger)frameID;

/// Sets the texture of a certain frame.
- (void)setTexture:(SPTexture *)texture atIndex:(NSInteger)frameID;

/// Returns the sound of a frame at a certain index.
- (nullable SPSoundChannel *)soundAtIndex:(NSInteger)frameID;

/// Sets the sound that will be played back when a certain frame is active.
- (void)setSound:(nullable SPSoundChannel *)sound atIndex:(NSInteger)frameID;

/// Returns the duration (in seconds) of a frame at a certain index.
- (double)durationAtIndex:(NSInteger)frameID;

/// Sets the duration of a certain frame in seconds.
- (void)setDuration:(double)duration atIndex:(NSInteger)frameID;

/// Reverses the order of all frames, making the clip run from end to start. Makes sure that the
/// currently visible frame stays the same.
- (void)reverseFrames;

/// ----------------------
/// @name Playback Methods
/// ----------------------

/// Start playback. Beware that the clip has to be added to a juggler, too!
- (void)play;

/// Pause playback.
- (void)pause;

/// Stop playback. Resets currentFrame to beginning.
- (void)stop;

/// ----------------
/// @name Properties
/// ----------------

/// The number of frames of the clip.
@property (nonatomic, readonly) NSInteger numFrames;

/// The total duration of the clip in seconds.
@property (nonatomic, readonly) double totalTime;

/// The time that has passed since the clip was started (each loop starts at zero).
@property (nonatomic, readonly) double currentTime;

/// Indicates if the movie is looping.
@property (nonatomic, assign) BOOL loop;

/// If enabled, no new sounds will be started during playback. Sounds that are already
/// playing are not affected.
@property (nonatomic, assign) BOOL muted;

/// The ID of the frame that is currently displayed.
@property (nonatomic, assign) NSInteger currentFrame;

/// The default frames per second. Used when you add a frame without specifying a duration.
@property (nonatomic, assign) float fps;

/// Indicates if the movie is currently playing. Returns `NO` when the end has been reached.
@property (nonatomic, readonly) BOOL isPlaying;

/// Indicates if a (non-looping) movie has come to its end.
@property (nonatomic, readonly) BOOL isComplete;

@end

NS_ASSUME_NONNULL_END
