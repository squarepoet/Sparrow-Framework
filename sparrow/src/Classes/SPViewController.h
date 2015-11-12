//
//  SPViewController.h
//  Sparrow
//
//  Created by Daniel Sperl on 26.01.13.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPView.h>

NS_ASSUME_NONNULL_BEGIN

@class SPContext;
@class SPDisplayObject;
@class SPJuggler;
@class SPPoint;
@class SPProgram;
@class SPRectangle;
@class SPSprite;
@class SPStage;
@class SPTouchProcessor;

typedef void (^SPRootCreatedBlock)(SPSprite *root);

/** ------------------------------------------------------------------------------------------------
 
 An SPViewController controls and displays a Sparrow display tree. It represents the main
 link between UIKit and Sparrow.
 
 The class acts just like a conventional view controller of UIKit. It sets up an `SPView` object 
 that Sparrow can render into.
 
 To initialize the Sparrow display tree, call the 'startWithRoot:' method (or a variant)
 with the class that should act as the root object of your game. As soon as OpenGL is set up,
 an instance of that class will be created and your game will start. In this sample, `Game` is
 a subclass of `SPSprite` that sets up the display tree of your app:
 
	[viewController startWithRoot:[Game class]];
 
 If you need to pass certain information to your game, you can make use of the `onRootCreated` 
 callback:
 
	viewController.onRootCreated = ^(Game *game)
	{
	    // access your game instance here
	};
 
 **Resolution Handling**
 
 Just like in other UIKit apps, the size of the visible area (in Sparrow, the stage size) is given
 in points. Those values will always equal the non-retina resolution of the current device.
 
 Per default, Sparrow is started with support for retina displays, which means that it will 
 automatically use the optimal available screen resolution and will load retina versions of your
 textures (files with the `@2x` prefix) on a suitable device.
 
 To simplify the creation of universal apps, Sparrow can double the size of all objects on the iPad,
 effectively turning it into the retina version of an (imaginary) phone with a resolution of
 `384x512` pixels. That will be your stage size then, and iPads 1+2 will load `@2x` versions of
 your textures. Retina iPads will use a new suffix instead: `@4x`.
 
 If you want this to happen (again: only useful for universal apps), enable the `doubleOnPad`
 parameter of the `start:` method. Otherwise, Sparrow will work just like other UIKit apps, using
 a stage size of `768x1024` on the iPad.
 
 **Render Settings**
 
 * Set the desired framerate through the `preferredFramesPerSecond` property
 * Pause or restart Sparrow through the `paused` property
 * Stop or start rendering through the `rendering` property

 **Accessing the current controller**
 
 As a convenience, you can access the view controller through a static method on the `Sparrow`
 class:
 
	SPViewController *controller = Sparrow.currentController;
 
 Since the view controller contains pointers to the stage, root, and juggler, you can
 easily access those objects that way.
 
------------------------------------------------------------------------------------------------- */

@interface SPViewController : UIViewController

/// -------------
/// @name Methods
/// -------------

/// Make this SPViewController instance the 'currentController'.
- (void)makeCurrent;

/// Sets up Sparrow by instantiating the given class, which has to be a display object.
/// High resolutions are enabled, iPad content will keep its size (no doubling).
- (void)startWithRoot:(Class)rootClass;

/// Sets up Sparrow by instantiating the given class, which has to be a display object.
/// iPad content will keep its size (no doubling).
- (void)startWithRoot:(Class)rootClass supportHighResolutions:(BOOL)hd;

/// Sets up Sparrow by instantiating the given class, which has to be a display object. Optionally,
/// you can double the size of iPad content, which will give you a stage size of `384x512`. That
/// simplifies the creation of universal apps (see class documentation).
- (void)startWithRoot:(Class)rootClass supportHighResolutions:(BOOL)hd doubleOnPad:(BOOL)doubleOnPad;

/// Calls 'advanceTime:' (with the time that has passed since the last frame) and 'render'.
- (void)nextFrame;

/// Dispatches SPEventTypeEnterFrame events on the display list, advances the Juggler and processes
/// touches.
- (void)advanceTime:(double)passedTime;

/// Renders the complete display list. Before rendering, the context is cleared; afterwards, it is
/// presented. This method also dispatches an SPEventTypeRender event on the Stage instance. That's
/// the last opportunity to make changes before the display list is rendered.
- (void)render;

/// ------------------------
/// @name Program Management
/// ------------------------

/// Registers a shader program under a certain name.
- (void)registerProgram:(SPProgram *)program name:(NSString *)name;

/// Deletes the vertex- and fragment-programs of a certain name.
- (void)unregisterProgram:(NSString *)name;

/// Returns the shader program registered under a certain name.
- (SPProgram *)programByName:(NSString *)name;

/// -------------------
/// @name Other methods
/// -------------------

/// Executes a block in a special dispatch queue that is reserved for resource loading.
/// Before executing the block, Sparrow sets up an `EAGLContext` that shares rendering resources
/// with the main context. Thus, you can use this method to load textures through a background-
/// thread (as facilitated by the asynchronous `SPTexture` loading methods).
/// Beware that you must not access any other Sparrow objects within the block, since Sparrow
/// is not thread-safe.
- (void)executeInResourceQueue:(dispatch_block_t)block;

/// Executes a block in a special dispatch queue that is reserved for resource loading.
/// Before executing the block, Sparrow sets up an `EAGLContext` that shares rendering resources
/// with the main context. Beware that you must not access any other Sparrow objects within the
/// block if when async is true, since Sparrow is not thread-safe.
- (void)executeInResourceQueueAsynchronously:(BOOL)async block:(dispatch_block_t)block;

/// ----------------
/// @name Properties
/// ----------------

/// The SPView instance used as the root view for Sparrow.
@property (nonatomic, strong) SPView *view;

/// Indicates if this SPViewController instance is paused. If YES assign Stops all logic and input
/// processing, effectively freezing the app in its current state. Rendering will continue.
@property (nonatomic, assign) BOOL paused;

/// Indicates if this SPViewController instance is rendering.
@property (nonatomic, assign) BOOL rendering;

/// The instance of the root class provided in `start:`method.
@property (nonatomic, readonly) SPDisplayObject *root;

/// The stage object, i.e. the root of the display tree.
@property (nonatomic, readonly) SPStage *stage;

/// The default juggler of this instance. It is automatically advanced once per frame.
@property (nonatomic, readonly) SPJuggler *juggler;

/// The OpenGL context used for rendering.
@property (nonatomic, readonly) SPContext *context;

/// The TouchProcessor is passed all touch input and is responsible for dispatching TouchEvents to
/// the Sparrow display tree. If you want to handle these types of input manually, pass your own
/// custom subclass to this property.
@property (nonatomic, strong) SPTouchProcessor *touchProcessor;

/// The antialiasing level. 0 - no antialasing, 16 - maximum antialiasing. Default: 0
@property (nonatomic, assign) NSInteger antiAliasing;

/// For setting the desired frames per second at which the update and drawing will take place.
@property (nonatomic, assign) NSInteger preferredFramesPerSecond;

/// The actual frames per second that was decided upon given the value for preferredFramesPerSecond.
@property (nonatomic, readonly) NSInteger framesPerSecond;

/// Indicates if multitouch input is enabled.
@property (nonatomic, assign) BOOL multitouchEnabled;

/// Indicates if a small statistics box (with FPS and draw count) is displayed.
@property (nonatomic, assign) BOOL showStats;

/// Indicates if retina display support is enabled.
@property (nonatomic, readonly) BOOL supportHighResolutions;

/// Indicates if display list contents will doubled on iPad devices (see class documentation).
@property (nonatomic, readonly) BOOL doubleOnPad;

/// The current content scale factor, i.e. the ratio between display resolution and stage size.
@property (nonatomic, readonly) float contentScaleFactor;

/// A callback block that will be executed when the root object has been created.
@property (nonatomic, copy, nullable) SPRootCreatedBlock onRootCreated;

@end


/** UIKit helpers for translating coordinate back and forth between Sparrow. */

@interface SPViewController (UIKitHelpers)

/// -------------
/// @name Methods
/// -------------

/// Converts a global Sparrow point to the specified UIKit view.
- (CGPoint)convertPoint:(SPPoint *)point toView:(UIView *)view;

/// Converts a UIKit point from the specified view to a global Sparrow point.
- (SPPoint *)convertPoint:(CGPoint)point fromView:(UIView *)view;

/// Converts a global Sparrow rectangle to the specified UIKit view.
- (CGRect)convertRectangle:(SPRectangle *)rectangle toView:(UIView *)view;

/// Converts a UIKit rectangle from the specified view to a global Sparrow rectangle.
- (SPRectangle *)convertRectangle:(CGRect)rect fromView:(UIView *)view;

/// ----------------
/// @name Properties
/// ----------------

/// The conversion ratio from Sparrow's content scale factor to current view's
/// content scale factor. Use this to convert Sparrow coordinates to UIKit coordinates.
@property (nonatomic, readonly) float toUIKitConversionFactor;

/// The conversion ratio from the current view's content scale factor to Sparrow's
/// content scale factor. Use this to convert UIKit coordinates to Sparrow coordinates.
@property (nonatomic, readonly) float fromUIKitConversionFactor;

@end

NS_ASSUME_NONNULL_END
