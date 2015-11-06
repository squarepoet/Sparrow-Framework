//
//  BenchmarkScene.m
//  Demo
//
//  Created by Daniel Sperl on 18.09.09.
//  Copyright 2011 Gamua. All rights reserved.
//

#import "BenchmarkScene.h"

static const NSInteger FRAME_TIME_WINDOW_SIZE = 10;
static const NSInteger MAX_FAIL_COUNT         = 100;

@implementation BenchmarkScene
{
    SPButton *_startButton;
    SPTextField *_resultText;
    SPTextField *_statusText;
    SPSprite *_container;
    NSMutableArray<SPDisplayObject*> *_objectPool;
    SPTexture *_objectTexture;
    
    NSInteger _frameCount;
    NSInteger _failCount;
    BOOL _started;
    NSMutableArray<NSNumber*> *_frameTimes;
    NSInteger _targetFPS;
    NSInteger _phase;
    
    double _elapsed;
    int _waitFrames;
}

- (instancetype)init
{
    if (self = [super init])
    {
        // the container will hold all test objects
        _container = [[SPSprite alloc] init];
        _container.x = CENTER_X;
        _container.y = CENTER_Y;
        _container.touchable = NO; // we do not need touch events on the test objects --
                                   // thus, it is more efficient to disable them.
        [self addChild:_container atIndex:0];
        
        _statusText = [[SPTextField alloc] initWithWidth:GAME_WIDTH - 40 height:30 text:@""
                       fontName:SPBitmapFontMiniName fontSize:SPNativeFontSize * 2 color:0x0];
        _statusText.x = 20;
        _statusText.y = 10;
        [self addChild:_statusText];
        
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_normal.png"];
        _startButton = [[SPButton alloc] initWithUpState:buttonTexture text:@"Start benchmark"];
        [_startButton addEventListener:@selector(onStartButtonTriggered:) atObject:self forType:SPEventTypeTriggered];
        _startButton.x = CENTER_X - (int)(_startButton.width / 2);
        _startButton.y = 20;
        [self addChild:_startButton];
        
        
        _started = NO;
        _frameTimes = [NSMutableArray new];
        _objectPool = [NSMutableArray new];
        _objectTexture = [SPTexture textureWithContentsOfFile:@"benchmark_object.png"];
        
        [self addEventListener:@selector(onEnterFrame:) atObject:self forType:SPEventTypeEnterFrame];
    }
    return self;
}

- (void)dealloc
{
    [self removeEventListenersAtObject:self forType:SPEventTypeEnterFrame];
    [_startButton removeEventListenersAtObject:self forType:SPEventTypeTriggered];
}

- (void)onStartButtonTriggered:(SPEvent *)event
{
    NSLog(@"Starting benchmark");
    
    _startButton.visible = NO;
    _started = YES;
    _targetFPS = Sparrow.currentController.framesPerSecond;
    _frameCount = 0;
    _failCount = 0;
    _phase = 0;
    
    for (NSInteger i=0; i<FRAME_TIME_WINDOW_SIZE; ++i)
        [_frameTimes addObject:@(1.0 / _targetFPS)];
    
    if (_resultText)
    {
        [_resultText removeFromParent];
        _resultText = nil;
    }
}

- (void)onEnterFrame:(SPEnterFrameEvent *)event
{
    if (!_started) return;
    
    double passedTime = event.passedTime;
    _frameCount++;
    _container.rotation += passedTime * 0.5;
    [_frameTimes addObject:@(0)];
    
    for (NSInteger i=0; i<FRAME_TIME_WINDOW_SIZE; ++i)
        _frameTimes[i] = @(_frameTimes[i].doubleValue + passedTime);
    
    const float measuredFps = FRAME_TIME_WINDOW_SIZE / _frameTimes.firstObject.doubleValue;
    [_frameTimes removeObjectAtIndex:0];
    
    if (_phase == 0)
    {
        if (measuredFps < 0.985 * _targetFPS)
        {
            _failCount++;
            
            if (_failCount == MAX_FAIL_COUNT)
                _phase = 1;
        }
        else
        {
            [self addTestObjects:16];
            _container.scale *= 0.99;
            _failCount = 0;
        }
    }
    
    if (_phase == 1)
    {
        if (measuredFps > 0.99 * _targetFPS)
        {
            _failCount--;
            
            if (_failCount == 0)
                [self benchmarkComplete];
        }
        else
        {
            [self removeTestObjects:1];
            _container.scale /= 0.9993720513; // 0.99 ^ (1/16)
        }
    }
    
    if (_frameCount % (int)(_targetFPS / 4) == 0)
        _statusText.text = [NSString stringWithFormat:@"%ld objects", (long)_container.numChildren];
}

- (void)addTestObjects:(NSInteger)numObjects
{
    float scale = 1.0 / _container.scale;
    
    for (NSInteger i=0; i<numObjects; ++i)
    {
        SPDisplayObject *egg = [self objectFromPool];
        float distance = (100 + [SPUtils randomFloat] * 100) * scale;
        float angle = [SPUtils randomFloat] * M_PI * 2.0;
        
        egg.x = cosf(angle) * distance;
        egg.y = sinf(angle) * distance;
        egg.rotation = angle + M_PI / 2.0;
        egg.scale = scale;
        
        [_container addChild:egg];
    }
}

- (void)removeTestObjects:(NSInteger)numObjects
{
    NSInteger numChildren = _container.numChildren;
    
    if (numObjects >= numChildren)
        numObjects = numChildren;
    
    for (NSInteger i=0; i<numObjects; ++i)
    {
        NSInteger index = _container.numChildren-1;
        
        SPDisplayObject *object = _container[index];
        [_container removeChildAtIndex:index];
        
        [self putObjectInPool:object];
    }
}

- (SPDisplayObject *)objectFromPool
{
    SPDisplayObject *image;
    
    if (_objectPool.count == 0)
    {
        image = [SPImage imageWithTexture:_objectTexture];
        [image alignPivotToCenter];
    }
    else
    {
        image = [_objectPool lastObject];
        [_objectPool removeLastObject];
    }
    
    return image;
}

- (void)putObjectInPool:(SPDisplayObject *)object
{
    [_objectPool addObject:object];
}

- (void)benchmarkComplete
{
    _started = false;
    _startButton.visible = true;
    
    NSInteger fps = Sparrow.currentController.framesPerSecond;
    NSInteger numChildren = _container.numChildren;
    NSString *resultString = [NSString stringWithFormat:
                              @"Result:\n%ld objects\nwith %ld fps", (long)numChildren, (long)fps];
    
    NSLog(@"%@", [resultString stringByReplacingOccurrencesOfString:@"\n" withString:@" "]);
    
    _resultText = [SPTextField textFieldWithWidth:240 height:200 text:resultString];
    _resultText.fontSize = 30;
    _resultText.x = CENTER_X - _resultText.width / 2;
    _resultText.y = CENTER_Y - _resultText.height / 2;
    [self addChild:_resultText];
    
    _container.scale = 1.0;
    [_frameTimes removeAllObjects];
    _statusText.text = @"";
    
    for (NSInteger i=numChildren-1; i>=0; --i)
    {
        SPDisplayObject *object = _container[i];
        [_container removeChildAtIndex:i];
        [self putObjectInPool:object];
    }
}

@end
