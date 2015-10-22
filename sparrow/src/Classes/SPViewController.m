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
#import "SPPoint.h"
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
    BOOL _supportHighResolutions;
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
    _contentScaleFactor = 1.0f;
    _stage = [[SPStage alloc] init];
    _juggler = [[SPJuggler alloc] init];
    _touchProcessor = [[SPTouchProcessor alloc] initWithStage:_stage];
    _programs = [[NSMutableDictionary alloc] init];
    _support = [[SPRenderSupport alloc] init];
    _viewPort = [[SPRectangle alloc] init];
    _previousViewPort = [[SPRectangle alloc] init];
    
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
    // the last set viewport is stored in a variable; that way, people can modify the
    // viewPort directly (without a copy) and we still know if it has changed.
    
    if (forceUpdate || ![_previousViewPort isEqualToRectangle:_viewPort])
    {
        [_previousViewPort copyFromRectangle:_viewPort];
        [_context configureBackBufferForDrawable:_internalView.layer antiAlias:_antiAliasing
                           enableDepthAndStencil:YES wantsBestResolution:_supportHighResolutions];
    }
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

    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    
    _rootClass = rootClass;
    _supportHighResolutions = hd;
    _doubleOnPad = doubleOnPad;
    _viewScaleFactor = _supportHighResolutions ? [[UIScreen mainScreen] scale] : 1.0f;
    _contentScaleFactor = (_doubleOnPad && isPad) ? _viewScaleFactor * 2.0f : _viewScaleFactor;
    
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
            [self updateViewPort:NO];
            if (!_root) [self createRoot];
            
            [_context setRenderToBackBuffer];
            
            SPExecuteWithDebugMarker("Sparrow")
            {
                [_stage dispatchEventWithType:SPEventTypeRender];
                
                glDisable(GL_CULL_FACE);
                glDepthMask(GL_FALSE);
                glDepthFunc(GL_ALWAYS);
                
                [_support nextFrame];
                [_support setStencilReferenceValue:0];
                [_support setRenderTarget:nil];
                [_stage render:_support];
                [_support finishQuadBatch];
                
                if (_statsDisplay)
                    _statsDisplay.numDrawCalls = _support.numDrawCalls - 2; // stats display requires 2 itself
            }
            
          #if DEBUG
            [SPRenderSupport checkForOpenGLError];
          #endif
            
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
    _internalView.multipleTouchEnabled = YES;
    
    [_viewPort setEmpty]; // reset viewport
}

- (void)didReceiveMemoryWarning
{
    [self purgePools];
    [_support purgeBuffers];
    
    [super didReceiveMemoryWarning];
}

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
            float xConversion = _stage.width / viewSize.width;
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
    
    float newWidth  = isPortrait ? MIN(_stage.width, _stage.height) :
                                   MAX(_stage.width, _stage.height);
    float newHeight = isPortrait ? MAX(_stage.width, _stage.height) :
                                   MIN(_stage.width, _stage.height);
    
    [self viewDidResize:CGRectMake(0, 0, newWidth, newHeight)];
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

- (void)setMultitouchEnabled:(BOOL)multitouchEnabled
{
    _internalView.multipleTouchEnabled = multitouchEnabled;
}

- (BOOL)multitouchEnabled
{
    return _internalView.multipleTouchEnabled;
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

@end

@implementation SPViewController (Internal)

- (void)viewDidResize:(CGRect)bounds
{
    float newWidth  = bounds.size.width;
    float newHeight = bounds.size.height;
    
    if (newWidth  != _stage.width ||
        newHeight != _stage.height)
    {
        _stage.width  = newWidth  * _viewScaleFactor / _contentScaleFactor;
        _stage.height = newHeight * _viewScaleFactor / _contentScaleFactor;
        
        SPEvent *resizeEvent = [[SPResizeEvent alloc] initWithType:SPEventTypeResize width:newWidth height:newHeight];
        [_stage broadcastEvent:resizeEvent];
        [resizeEvent release];
    }
    
    [_viewPort copyFromRectangle:[SPRectangle rectangleWithCGRect:_internalView.bounds]];
}

@end
