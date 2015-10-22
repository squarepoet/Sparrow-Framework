//
//  MaskScene.m
//  Demo
//
//  Created by Robert Carone on 1/11/14.
//
//

#import "MaskScene.h"

@implementation MaskScene
{
    SPButton *_clipButton;
    SPSprite *_contents;
    SPCanvas *_mask;
    SPCanvas *_maskDisplay;
    SPRectangle *_clipRect;
    SPQuad *_clipDisplay;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_normal.png"];
        
        // we create a button that is used to start the tween.
        _clipButton = [[SPButton alloc] initWithUpState:buttonTexture text:@"Use Clip-Rect"];
        [_clipButton addEventListener:@selector(onClipButtonPressed:) atObject:self
                              forType:SPEventTypeTriggered];
        _clipButton.x = 160 - (int)_clipButton.width / 2;
        _clipButton.y = 20;
        [self addChild:_clipButton];
        
        _contents = [SPSprite sprite];
        [self addChild:_contents];

        float stageWidth  = [Sparrow stage].width;
        float stageHeight = [Sparrow stage].height;

        SPQuad *touchQuad = [SPQuad quadWithWidth:stageWidth height:stageHeight];
        touchQuad.alpha = 0; // only used to get touch events
        [self addChild:touchQuad atIndex:0];

        SPImage *image = [SPImage imageWithContentsOfFile:@"sparrow_front.png"];
        image.x = (stageWidth - image.width) / 2;
        image.y = 80;
        [_contents addChild:image];

        // just to prove it works, use a filter on the image.
        SPColorMatrixFilter *cm = [SPColorMatrixFilter colorMatrixFilter];
        [cm adjustHue:-0.5];
        image.filter = cm;

        NSString *maskString = @"Move a finger over the screen to move the clipping rectangle.";
        SPTextField *maskText = [SPTextField textFieldWithWidth:256 height:128 text:maskString];
        maskText.x = (stageWidth - maskText.width) / 2;
        maskText.y = 240;
        [_contents addChild:maskText];
        
        _clipRect = [SPRectangle rectangleWithX:0 y:0 width:150 height:150];
        _clipRect.x = (stageWidth - _clipRect.width)   / 2;
        _clipRect.y = (stageHeight - _clipRect.height) / 2 + 5;
        
        _clipDisplay = [SPQuad quadWithWidth:_clipRect.width height:_clipRect.height color:SPColorRed];
        _clipDisplay.x = _clipRect.x;
        _clipDisplay.y = _clipRect.y;
        _clipDisplay.alpha = 0.1f;
        _clipDisplay.touchable = NO;

        _maskDisplay = [self createCircle];
        _maskDisplay.alpha = 0.2f;
        _maskDisplay.touchable = NO;
        [self addChild:_maskDisplay];
        
        _mask = [self createCircle];
        _contents.mask = _mask;
        
        _mask.x = _maskDisplay.x = stageWidth  / 2;
        _mask.y = _maskDisplay.y = stageHeight / 2;
        
        [self addEventListener:@selector(onTouch:) atObject:self forType:SPEventTypeTouch];
    }
    return self;
}

- (void)onClipButtonPressed:(SPEvent *)event
{
    if (_contents.clipRect)
    {
        _contents.clipRect = nil;
        _contents.mask = _mask;
        
        [_clipDisplay removeFromParent];
        [self addChild:_maskDisplay];
        
        _clipButton.text = @"Use Clip-Rect";
    }
    else
    {
        _contents.clipRect = _clipRect;
        _contents.mask = nil;
        
        [_maskDisplay removeFromParent];
        [self addChild:_clipDisplay];
        
        _clipButton.text = @"Use Stencil Mask";
    }
}

- (void)onTouch:(SPTouchEvent *)event
{
    SPTouch *touch = [[event touches] anyObject];

    if (touch && (touch.phase == SPTouchPhaseBegan || touch.phase == SPTouchPhaseMoved))
    {
        SPPoint* localPos = [touch locationInSpace:self];
        
        _mask.x = _maskDisplay.x = localPos.x;
        _mask.y = _maskDisplay.y = localPos.y;
        
        _clipRect.x = _clipDisplay.x = localPos.x - _clipRect.width  / 2;
        _clipRect.y = _clipDisplay.y = localPos.y - _clipRect.height / 2;
        
        if (_contents.clipRect) _contents.clipRect = _clipRect;
    }
}

- (SPCanvas *)createCircle
{
    SPCanvas *circle = [SPCanvas new];
    [circle beginFill:SPColorRed];
    [circle drawCircleWithX:0 y:0 radius:100];
    [circle endFill];
    return circle;
}

@end
