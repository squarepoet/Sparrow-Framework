//
//  SPViewController.m
//  Sparrow
//
//  Created by Daniel Sperl on 26.01.13.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass_Internal.h"
#import "SPContext_Internal.h"
#import "SPEnterFrameEvent.h"
#import "SPMatrix.h"
#import "SPOpenGL.h"
#import "SPJuggler.h"
#import "SPOverlayView.h"
#import "SPPoint.h"
#import "SPPress_Internal.h"
#import "SPPressEvent.h"
#import "SPProgram.h"
#import "SPRectangle.h"
#import "SPRenderSupport.h"
#import "SPResizeEvent.h"
#import "SPStage_Internal.h"
#import "SPStatsDisplay.h"
#import "SPTexture.h"
#import "SPTouchProcessor.h"
#import "SPTouch_Internal.h"
#import "SPView_Internal.h"
#import "SPViewController_Internal.h"

// --- private interface ---------------------------------------------------------------------------

@interface SPViewController()
@property (nonatomic, strong) SPContext *context;
@end

// --- class implementation ------------------------------------------------------------------------

@implementation SPViewController
{
    SPView *_internalView;
    SPContext *_context;
    Class _rootClass;
    SPStage *_stage;
    SPSprite *_root;
    SPJuggler *_juggler;
    SPTouchProcessor *_touchProcessor;
    SPRenderSupport *_support;
    SPRootCreatedBlock _onRootCreated;
    SPStatsDisplay *_statsDisplay;
    NSMutableDictionary *_programs;
    
    SPRectangle *_viewPort;
    SPRectangle *_previousViewPort;
    SPRectangle *_clippedViewPort;
    SPResizeEvent *_resizeEvent;
    SPOverlayView *_overlayView;
    
    CADisplayLink *_displayLink;
    dispatch_queue_t _resourceQueue;
    SPContext *_resourceContext;
    
    NSInteger _antiAliasing;
    NSInteger _preferredFramesPerSecond;
    NSInteger _frameInterval;
    double _lastFrameTimestamp;
    double _lastTouchTimestamp;
    float _contentScaleFactor;
    float _viewScaleFactor;
    BOOL _hasRenderedOnce;
    BOOL _supportHighResolutions;
    BOOL _isPad;
    BOOL _doubleOnPad;
    BOOL _showStats;
    BOOL _paused;
    BOOL _rendering;
}

@dynamic view;

#pragma mark Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (void)dealloc
{
    [self setRendering:NO];
    [self purgePools];

    [(id)_resourceQueue release];
    [_internalView release];
    [_context release];
    [_resourceContext release];
    [_stage release];
    [_root release];
    [_juggler release];
    [_touchProcessor release];
    [_support release];
    [_onRootCreated release];
    [_statsDisplay release];
    [_programs release];
    [_viewPort release];
    [_previousViewPort release];

    [SPContext setCurrentContext:nil];
    [Sparrow setCurrentController:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

- (void)setup
{
    _contentScaleFactor = 1.0;
    _viewScaleFactor = 1.0;
    _isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    _stage = [[SPStage alloc] init];
    _juggler = [[SPJuggler alloc] init];
    _touchProcessor = [[SPTouchProcessor alloc] initWithStage:_stage];
    _programs = [[NSMutableDictionary alloc] init];
    _support = [[SPRenderSupport alloc] init];
    _viewPort = [[SPRectangle alloc] init];
    _previousViewPort = [[SPRectangle alloc] init];
    _clippedViewPort = [[SPRectangle alloc] init];
    
    [self setPreferredFramesPerSecond:60];
    [self makeCurrent];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResign:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)setupContext
{
    if (!_context)
    {
        _context = [[SPContext alloc] init];
        
        if (_context && [SPContext setCurrentContext:_context])
        {
            // if the global share context has not been set, set it to this instance's context
            SPContext *globalShareContext = [SPContext globalShareContext];
            if (!globalShareContext) [SPContext setGlobalShareContext:_context];
            
            // the stats display could not be shown before now, since it requires a context.
            self.showStats = _showStats;
        }
        else SPLog(@"Could not create render context.");
    }
}

- (void)setupRenderCallback
{
    if (_displayLink)
    {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderingCallback)];
    [_displayLink setFrameInterval:_frameInterval];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)renderingCallback
{
    if (!_paused) [self nextFrame];
    else          [self render];
}

- (void)updateViewPort:(BOOL)forceUpdate
{
    if (_viewPort.isEmpty) // just in case
        SP_RELEASE_AND_RETAIN(_viewPort, [SPRectangle rectangleWithCGRect:_internalView.bounds]);
    
    // the last set viewport is stored in a variable; that way, people can modify the
    // viewPort directly (without a copy) and we still know if it has changed.
    
    if (forceUpdate || ![_previousViewPort isEqualToRectangle:_viewPort])
    {
        [_previousViewPort copyFromRectangle:_viewPort];
        
        [_context configureBackBufferForDrawable:_internalView.layer antiAlias:_antiAliasing
                           enableDepthAndStencil:YES wantsBestResolution:_supportHighResolutions];
        
        [_clippedViewPort release];
        _clippedViewPort = [[_viewPort intersectionWithRectangle:
                            [SPRectangle rectangleWithCGRect:_internalView.bounds]] retain];
        
        _viewScaleFactor = _supportHighResolutions ? _internalView.contentScaleFactor : 1.0f;
        _contentScaleFactor = (_doubleOnPad && _isPad) ? _viewScaleFactor * 2.0f : _viewScaleFactor;
        
        if (_hasRenderedOnce && !_resizeEvent)
        {
            float newWidth  = _viewPort.width  * _viewScaleFactor / _contentScaleFactor;
            float newHeight = _viewPort.height * _viewScaleFactor / _contentScaleFactor;
            _resizeEvent = [[SPResizeEvent alloc] initWithType:SPEventTypeResize width:newWidth height:newHeight];
        }
        
        _hasRenderedOnce = NO;
    }
    
    [self readjustStageSize];
    
    if (_resizeEvent)
    {
        // we delay the resize events so they're insync with the update loop
        [_stage broadcastEvent:_resizeEvent];
        SP_RELEASE_AND_NIL(_resizeEvent);
    }
}

- (void)readjustStageSize
{
    CGSize viewSize = self.view.bounds.size;
    _stage.width  = viewSize.width  * _viewScaleFactor / _contentScaleFactor;
    _stage.height = viewSize.height * _viewScaleFactor / _contentScaleFactor;
}

#pragma mark Notifications

- (void)onActive:(NSNotification *)notification
{
    self.rendering = YES;
}

- (void)onResign:(NSNotification *)notification
{
    self.rendering = NO;
}

#pragma mark Methods

- (void)makeCurrent
{
    [Sparrow setCurrentController:self];
}

- (void)startWithRoot:(Class)rootClass
{
    [self startWithRoot:rootClass supportHighResolutions:YES];
}

- (void)startWithRoot:(Class)rootClass supportHighResolutions:(BOOL)hd
{
    [self startWithRoot:rootClass supportHighResolutions:hd doubleOnPad:NO];
}

- (void)startWithRoot:(Class)rootClass supportHighResolutions:(BOOL)hd doubleOnPad:(BOOL)doubleOnPad
{
    if (_rootClass)
        [NSException raise:SPExceptionInvalidOperation
                    format:@"Sparrow has already been started"];
    
    _rootClass = rootClass;
    _supportHighResolutions = hd;
    _doubleOnPad = doubleOnPad;
    
    self.paused = NO;
    self.rendering = YES;
}

- (void)nextFrame
{
    double now = _displayLink.timestamp;
    double passedTime = now - _lastFrameTimestamp;
    _lastFrameTimestamp = now;
    
    // to avoid overloading time-based animations, the maximum delta is truncated.
    if (passedTime > 1.0) passedTime = 1.0;
    if (passedTime < 0.0) passedTime = 1.0 / self.framesPerSecond;
    
    [self advanceTime:passedTime];
    [self render];
}

- (void)advanceTime:(double)passedTime
{
    @autoreleasepool
    {
        [self makeCurrent];
        
        [_touchProcessor advanceTime:passedTime];
        [_stage advanceTime:passedTime];
        [_juggler advanceTime:passedTime];
    }
}

- (void)render
{
    if (!_rendering) return;
    if (!_context) [self setupContext];
    if (!_context) return;
    
    @autoreleasepool
    {
        if ([_context makeCurrentContext])
        {
            [self makeCurrent];
            [self updateViewPort:!_hasRenderedOnce];
            
            if (!_root)
                [self createRoot];
            
            [_context setRenderToBackBuffer];
            
            SPExecuteWithDebugMarker("Sparrow")
            {
                [_stage dispatchEventWithType:SPEventTypeRender];
                
                float scaleX = _viewPort.width  / _stage.width;
                float scaleY = _viewPort.height / _stage.height;
                
                glDisable(GL_CULL_FACE);
                glDepthMask(GL_FALSE);
                glDepthFunc(GL_ALWAYS);
                
                [_support nextFrame];
                [_support setStencilReferenceValue:0];
                [_support setRenderTarget:nil];
                [_support setProjectionMatrixWithX:_viewPort.x < 0 ? -_viewPort.x / scaleX : 0.0
                                                 y:_viewPort.y < 0 ? -_viewPort.y / scaleX : 0.0
                                             width:_clippedViewPort.width  / scaleX
                                            height:_clippedViewPort.height / scaleY
                                        stageWidth:_stage.width
                                       stageHeight:_stage.height
                                         cameraPos:_stage.cameraPosition];
                [_support clearWithColor:_stage.color alpha:1.0];
                
                [_stage render:_support];
                [_support finishQuadBatch];
                
                if (_statsDisplay)
                    _statsDisplay.numDrawCalls = _support.numDrawCalls - 2; // stats display requires 2 itself
            }
            
          #if DEBUG
            [SPRenderSupport checkForOpenGLError];
          #endif
            
            if (!_hasRenderedOnce) glFinish();
            _hasRenderedOnce = YES;
            
            [_context present];
        }
        else SPLog(@"WARNING: Unable to set the current rendering context.");
    }
}

#pragma mark Program Management

- (void)registerProgram:(SPProgram *)program name:(NSString *)name
{
    _programs[name] = program;
}

- (void)unregisterProgram:(NSString *)name
{
    [_programs removeObjectForKey:name];
}

- (SPProgram *)programByName:(NSString *)name
{
    return _programs[name];
}

#pragma mark Other Methods

- (void)executeInResourceQueue:(dispatch_block_t)block
{
    [self executeInResourceQueueAsynchronously:YES block:block];
}

- (void)executeInResourceQueueAsynchronously:(BOOL)async block:(dispatch_block_t)block
{
    if (!_resourceContext)
         _resourceContext = [[SPContext alloc] init];
    
    if (!_resourceQueue)
         _resourceQueue = dispatch_queue_create("com.Sparrow.ResourceQueue", NULL);
    
    (async ? dispatch_async : dispatch_sync)(_resourceQueue, ^
    {
        [_resourceContext makeCurrentContext];
        block();
    });
}

#pragma mark UIViewController

- (void)setView:(SPView *)view
{
    if (view != _internalView)
    {
        SP_RELEASE_AND_RETAIN(_internalView, view);
        super.view = view;
    }
}

- (void)loadView
{
    if (self.nibName && self.nibBundle)
    {
        [super loadView];
        
        if (![_internalView isKindOfClass:[SPView class]])
            [NSException raise:SPExceptionInvalidOperation
                        format:@"Loaded view nib, but it wasn't an SPView class"];
    }
    else
    {
        CGRect viewFrame = _internalView ? _internalView.frame : [[UIScreen mainScreen] bounds];
        SPView *view = [[[SPView alloc] initWithFrame:viewFrame] autorelease];
        [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self setView:view];
    }
    
    _internalView.viewController = self;
    _internalView.opaque = YES;
    _internalView.clearsContextBeforeDrawing = NO;
  #if !TARGET_OS_TV
    _internalView.multipleTouchEnabled = YES;
  #endif
    
    [_viewPort setEmpty]; // reset viewport
}

- (void)didReceiveMemoryWarning
{
    [self purgePools];
    [_support purgeBuffers];
    
    [super didReceiveMemoryWarning];
}

#pragma mark Presses

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (void)pressesBegan:(NSSet<UIPress*> *)presses withEvent:(UIPressesEvent *)event
{
    [self proccessPressEvent:event];
}

- (void)pressesChanged:(NSSet<UIPress*> *)presses withEvent:(UIPressesEvent *)event
{
    [self proccessPressEvent:event];
}

- (void)pressesCancelled:(NSSet<UIPress*> *)presses withEvent:(UIPressesEvent *)event
{
    [self proccessPressEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress*> *)presses withEvent:(UIPressesEvent *)event
{
    [self proccessPressEvent:event];
}

- (void)proccessPressEvent:(UIPressesEvent *)event
{
    if (!_paused)
    {
        // convert to SPPresses and forward to stage
        double now = CACurrentMediaTime();
        for (UIPress *uiPress in [event allPresses])
        {
            SPPress *press = [SPPress press];
            press.pressID = (size_t)uiPress;
            press.timestamp = now;
            press.type = (SPPressType)uiPress.type;
            press.phase = (SPPressPhase)uiPress.phase;
            press.force = (float)uiPress.force;
            [_stage enqueuePress:press];
        }
    }
}
#endif

#pragma mark Touch Processing

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouchEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouchEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouchEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _lastTouchTimestamp -= 0.0001f; // cancelled touch events have an old timestamp -> workaround
    [self processTouchEvent:event];
}

- (void)processTouchEvent:(UIEvent *)event
{
    if (!_paused && _lastTouchTimestamp != event.timestamp)
    {
        @autoreleasepool
        {
            CGSize viewSize = _internalView.bounds.size;
            float xConversion = _stage.width  / viewSize.width;
            float yConversion = _stage.height / viewSize.height;
            
            // convert to SPTouches and forward to stage
            double now = CACurrentMediaTime();
            for (UITouch *uiTouch in [event touchesForView:_internalView])
            {
                CGPoint location = [uiTouch locationInView:_internalView];
                CGPoint previousLocation = [uiTouch previousLocationInView:_internalView];

                SPTouch *touch = [SPTouch touch];
                touch.timestamp = now; // timestamp of uiTouch not compatible to Sparrow timestamp
                touch.globalX = location.x * xConversion;
                touch.globalY = location.y * yConversion;
                touch.previousGlobalX = previousLocation.x * xConversion;
                touch.previousGlobalY = previousLocation.y * yConversion;
                touch.tapCount = (int)uiTouch.tapCount;
                touch.phase = (SPTouchPhase)uiTouch.phase;
                touch.touchID = (size_t)uiTouch;
                [_touchProcessor enqueueTouch:touch];
            }

            _lastTouchTimestamp = event.timestamp;
        }
    }
}

#pragma mark Auto Rotation

// The following methods implement what I would expect to be the default behaviour of iOS:
// The orientations that you activated in the application plist file are automatically rotated to.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    NSArray *supportedOrientations =
    [[NSBundle mainBundle] infoDictionary][@"UISupportedInterfaceOrientations"];
    
    UIInterfaceOrientationMask returnOrientations = 0;
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"])
        returnOrientations |= UIInterfaceOrientationMaskPortrait;
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"])
        returnOrientations |= UIInterfaceOrientationMaskLandscapeLeft;
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"])
        returnOrientations |= UIInterfaceOrientationMaskPortraitUpsideDown;
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"])
        returnOrientations |= UIInterfaceOrientationMaskLandscapeRight;
    
    return returnOrientations;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    NSArray *supportedOrientations =
    [[NSBundle mainBundle] infoDictionary][@"UISupportedInterfaceOrientations"];
    
    return ((interfaceOrientation == UIInterfaceOrientationPortrait &&
             [supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"]) ||
            (interfaceOrientation == UIInterfaceOrientationLandscapeLeft &&
             [supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"]) ||
            (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown &&
             [supportedOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"]) ||
            (interfaceOrientation == UIInterfaceOrientationLandscapeRight &&
             [supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"]));
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    // inform all display objects about the new game size
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(interfaceOrientation);
    
    CGSize viewSize = _internalView.bounds.size;
    float viewWidth  = viewSize.width;
    float viewHeight = viewSize.height;
    
    float newWidth  = isPortrait ? MIN(viewWidth, viewHeight) :
                                   MAX(viewWidth, viewHeight);
    float newHeight = isPortrait ? MAX(viewWidth, viewHeight) :
                                   MIN(viewWidth, viewHeight);
    
    [self viewDidResize:CGRectMake(0, 0, newWidth, newHeight) duration:duration];
}

#pragma mark Properties

- (void)setPaused:(BOOL)paused
{
    if (_paused != paused)
    {
        _paused = paused;
        if (!_paused) _lastFrameTimestamp = CACurrentMediaTime();
    }
}

- (void)setRendering:(BOOL)rendering
{
    if (rendering != _rendering)
    {
        _rendering = rendering;
        
        if (!_rendering)
        {
            [_displayLink invalidate]; // invalidate releases the object
            _displayLink = nil;
        }
        else
        {
            [self setupRenderCallback];
        }
    }
}

- (SPOverlayView *)overlayView
{
    if (!_overlayView)
    {
        _overlayView = [[[SPOverlayView alloc] initWithFrame:_internalView.frame] autorelease];
        _overlayView.opaque = NO;
        [_internalView addSubview:_overlayView];
    }
    
    return _overlayView;
}

- (void)setMultitouchEnabled:(BOOL)multitouchEnabled
{
  #if !TARGET_OS_TV
    _internalView.multipleTouchEnabled = multitouchEnabled;
  #endif
}

- (BOOL)multitouchEnabled
{
  #if !TARGET_OS_TV
    return _internalView.multipleTouchEnabled;
  #else
    return NO;
  #endif
}

- (void)setShowStats:(BOOL)showStats
{
    if (showStats && !_statsDisplay && _context)
    {
        _statsDisplay = [[SPStatsDisplay alloc] init];
        [_stage addChild:_statsDisplay];
    }

    _showStats = showStats;
    _statsDisplay.visible = showStats;
}

- (void)setAntiAliasing:(NSInteger)antiAliasing
{
    if (antiAliasing != _antiAliasing)
    {
        _antiAliasing = antiAliasing;
        if (_context) [self updateViewPort:YES];
    }
}

- (NSInteger)framesPerSecond
{
    return 60 / _frameInterval;
}

- (NSInteger)preferredFramesPerSecond
{
    return _preferredFramesPerSecond;
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    if (preferredFramesPerSecond < 1) preferredFramesPerSecond = 1;
    if (preferredFramesPerSecond != _preferredFramesPerSecond)
    {
        _preferredFramesPerSecond = preferredFramesPerSecond;
        _frameInterval = ceilf(60.0f / (float)preferredFramesPerSecond);
        if (_displayLink) _displayLink.frameInterval = _frameInterval;
    }
}

#pragma mark Private

- (void)purgePools
{
    [SPPoint purgePool];
    [SPRectangle purgePool];
    [SPMatrix purgePool];
}

- (void)createRoot
{
    if (!_root)
    {
        _root = [[_rootClass alloc] init];

        if ([_root isKindOfClass:[SPStage class]])
            [NSException raise:SPExceptionInvalidOperation
                        format:@"Root extends 'SPStage' but is expected to extend 'SPSprite' "
                               @"instead (different to Sparrow 1.x)"];
        else
        {
            [_stage addChild:_root atIndex:0];

            if (_onRootCreated)
            {
                _onRootCreated(_root);
                SP_RELEASE_AND_NIL(_onRootCreated);
            }
        }
    }
}

#pragma mark Internal

- (void)viewDidResize:(CGRect)bounds
{
    [self viewDidResize:bounds duration:0];
}

- (void)viewDidResize:(CGRect)bounds duration:(double)duration
{
    CGSize viewSize = bounds.size;
    float newWidth  = viewSize.width  * _viewScaleFactor / _contentScaleFactor;
    float newHeight = viewSize.height * _viewScaleFactor / _contentScaleFactor;
    
    if (_hasRenderedOnce &&
        (newWidth  != _stage.width ||
         newHeight != _stage.height))
    {
        _resizeEvent = [[SPResizeEvent alloc] initWithType:SPEventTypeResize
						width:newWidth height:newHeight animationTime:duration];
    }
    
    [_viewPort copyFromRectangle:[SPRectangle rectangleWithCGRect:bounds]];
}

@end


#pragma mark - UIKitHelpers

@implementation SPViewController (UIKitHelpers)

- (CGPoint)convertPoint:(SPPoint *)point toView:(UIView *)view
{
    float toUIKitScaleFactor = self.toUIKitConversionFactor;
    CGPoint globalPoint = CGPointMake(point.x * toUIKitScaleFactor, point.y * toUIKitScaleFactor);
    return [_internalView convertPoint:globalPoint toView:view];
}

- (SPPoint *)convertPoint:(CGPoint)point fromView:(UIView *)view
{
    float toSarrowScaleFactor = self.fromUIKitConversionFactor;
    CGPoint globalPoint = [_internalView convertPoint:point fromView:view];
    return [SPPoint pointWithX:globalPoint.x * toSarrowScaleFactor y: globalPoint.y * toSarrowScaleFactor];
}

- (CGRect)convertRectangle:(SPRectangle *)rectangle toView:(UIView *)view
{
    float toUIKitScaleFactor = self.toUIKitConversionFactor;
    CGRect globalRect = CGRectMake(rectangle.x * toUIKitScaleFactor, rectangle.y * toUIKitScaleFactor,
                                   rectangle.width * toUIKitScaleFactor, rectangle.height * toUIKitScaleFactor);
    return [_internalView convertRect:globalRect toView:view];
}

- (SPRectangle *)convertRectangle:(CGRect)rect fromView:(UIView *)view
{
    float toSarrowScaleFactor = self.fromUIKitConversionFactor;
    CGRect globalRect = [_internalView convertRect:rect fromView:view];
    return [SPRectangle rectangleWithX:globalRect.origin.x    * toSarrowScaleFactor
                                     y:globalRect.origin.y    * toSarrowScaleFactor
                                 width:globalRect.size.width  * toSarrowScaleFactor
                                height:globalRect.size.height * toSarrowScaleFactor];
}

- (float)toUIKitConversionFactor
{
    return _internalView.bounds.size.width / _stage.width;
}

- (float)fromUIKitConversionFactor
{
    return _stage.width / _internalView.bounds.size.width;
}

@end
