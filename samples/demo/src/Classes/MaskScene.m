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
    SPSprite *_contents;
    SPCanvas *_mask;
    SPCanvas *_maskDisplay;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
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

        _maskDisplay = [self createCircle];
        _maskDisplay.alpha = 0.3;
        _maskDisplay.touchable = NO;
        [self addChild:_maskDisplay];
        
        _mask = [self createCircle];
        _contents.mask = _mask;

        [self addEventListener:@selector(onTouch:) atObject:self forType:SPEventTypeTouch];
    }
    return self;
}

- (void)onTouch:(SPTouchEvent *)event
{
    SPTouch *touch = [[event touches] anyObject];

    if (touch && (touch.phase == SPTouchPhaseBegan || touch.phase == SPTouchPhaseMoved))
    {
        SPPoint* localPos = [touch locationInSpace:self];
        _mask.x = _maskDisplay.x = localPos.x;
        _mask.y = _maskDisplay.y = localPos.y;
    }
}

- (SPCanvas *)createCircle
{
    SPCanvas *circle = [SPCanvas new];
    [circle beginFillWithColor:SPColorRed];
    [circle drawCircleWithX:0 y:0 radius:100];
    [circle endFill];
    return circle;
}

@end
