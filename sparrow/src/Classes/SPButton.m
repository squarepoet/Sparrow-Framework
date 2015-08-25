//
//  SPButton.m
//  Sparrow
//
//  Created by Daniel Sperl on 13.07.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPButton.h"
#import "SPGLTexture.h"
#import "SPImage.h"
#import "SPRectangle.h"
#import "SPSprite.h"
#import "SPStage.h"
#import "SPTextField.h"
#import "SPTexture.h"
#import "SPTouchEvent.h"

#define MAX_DRAG_DIST 40

// --- class implementation ------------------------------------------------------------------------

@implementation SPButton
{
    SPTexture *_upState;
    SPTexture *_downState;
    SPTexture *_disabledState;
    
    SPSprite *_contents;
    SPImage *_body;
    SPTextField *_textField;
    SPRectangle *_textBounds;
    SPSprite *_overlay;
    
    float _scaleWhenDown;
    float _alphaWhenDisabled;
    BOOL _enabled;
    SPButtonState _state;
    SPRectangle *_triggerBounds;
}

#pragma mark Initialization

- (instancetype)initWithUpState:(SPTexture *)upState downState:(SPTexture *)downState disabledState:(SPTexture *)disabledState
{
    if (!upState)
        [NSException raise:SPExceptionInvalidOperation format:@"up state cannot be nil"];
    
    if ((self = [super init]))
    {
        _upState = [upState retain];
        _downState = [downState retain];
        _disabledState = [disabledState retain];
        
        _state = SPButtonStateUp;
        _body = [[SPImage alloc] initWithTexture:upState];
        _textField = nil;
        _scaleWhenDown = _downState ? 1.0 : 0.9;
        _alphaWhenDown = 1.0;
        _alphaWhenDisabled = _disabledState ? 1.0 : 0.5;
        _enabled = YES;
        _textBounds = [[SPRectangle alloc] initWithX:0 y:0 width:_body.width height:_body.height];
        
        _contents = [[SPSprite alloc] init];
        [_contents addChild:_body];
        [self addChild:_contents];
        [self addEventListener:@selector(onTouch:) atObject:self forType:SPEventTypeTouch];
        
        self.touchGroup = YES;
    }
    return self;
}

- (instancetype)initWithUpState:(SPTexture *)upState downState:(SPTexture *)downState
{
    return [self initWithUpState:upState downState:downState disabledState:nil];
}

- (instancetype)initWithUpState:(SPTexture *)upState text:(NSString *)text
{
    self = [self initWithUpState:upState];
    self.text = text;
    return self;
}

- (instancetype)initWithUpState:(SPTexture *)upState
{
    return [self initWithUpState:upState downState:nil];
}

- (instancetype)init
{
    SPTexture *texture = [[[SPGLTexture alloc] init] autorelease];
    return [self initWithUpState:texture];
}

- (void)dealloc
{
    [self removeEventListenersAtObject:self forType:SPEventTypeTouch];
    
    [_upState release];
    [_downState release];
    [_disabledState release];
    [_contents release];
    [_body release];
    [_textField release];
    [_textBounds release];
    [_overlay release];
    [_triggerBounds release];
    
    [super dealloc];
}

+ (instancetype)buttonWithUpState:(SPTexture *)upState downState:(SPTexture *)downState
{
    return [[[self alloc] initWithUpState:upState downState:downState] autorelease];
}

+ (instancetype)buttonWithUpState:(SPTexture *)upState text:(NSString *)text
{
    return [[[self alloc] initWithUpState:upState text:text] autorelease];
}

+ (instancetype)buttonWithUpState:(SPTexture *)upState
{
    return [[[self alloc] initWithUpState:upState] autorelease];
}

#pragma mark Methods

- (void)readjustSize
{
    [self readjustSize:YES];
}

- (void)readjustSize:(BOOL)resetTextBounds
{
    [_body readjustSize];
    
    if (resetTextBounds && _textField)
    {
        SPRectangle* bounds = [SPRectangle rectangleWithX:0 y:0 width:_body.width height:_body.height];
        SP_RELEASE_AND_RETAIN(_textBounds, bounds);
    }
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPButton *button = [super copyWithZone:zone];
    
    button.upState = self.upState;
    button.downState = self.downState;
    button.disabledState = self.disabledState;
    button.scaleWhenDown = self.scaleWhenDown;
    button.alphaWhenDown = self.alphaWhenDown;
    button.alphaWhenDisabled = self.alphaWhenDisabled;
    button.enabled = self.enabled;
    button.text = self.text;
    button.fontName = self.fontName;
    button.fontSize = self.fontSize;
    button.fontColor = self.fontColor;
    button.fontBold = self.fontBold;
    button.textHAlign = self.textHAlign;
    button.textVAlign = self.textVAlign;
    button.textBounds = self.textBounds;
    button.color = self.color;
    button.state = self.state;
    button->_overlay = [_overlay copy];
    
    return button;
}

#pragma mark Events

- (void)onTouch:(SPTouchEvent *)touchEvent
{
    SPTouch *touch = [touchEvent touchWithTarget:self];
    BOOL isWithinBounds = NO;
    
    if (!_enabled)
    {
        return;
    }
    else if (!touch || touch.phase == SPTouchPhaseCancelled)
    {
        self.state = SPButtonStateUp;
    }
    else if (touch.phase == SPTouchPhaseBegan && _state != SPButtonStateDown)
    {
        SP_RELEASE_AND_RETAIN(_triggerBounds, [self boundsInSpace:self.stage]);
        [_triggerBounds inflateXBy:MAX_DRAG_DIST yBy:MAX_DRAG_DIST];
        
        self.state = SPButtonStateDown;
    }
    else if (touch.phase == SPTouchPhaseMoved)
    {
        isWithinBounds = [_triggerBounds containsX:touch.globalX y:touch.globalY];
        
        if (_state == SPButtonStateDown && !isWithinBounds)
        {
            // reset button when finger is moved too far away ...
            self.state = SPButtonStateUp;
        }
        else if (_state == SPButtonStateUp && isWithinBounds)
        {
            // ... and reactivate when the finger moves back into the bounds.
            self.state = SPButtonStateDown;
        }
    }
    else if (touch.phase == SPTouchPhaseEnded && _state == SPButtonStateDown)
    {
        self.state = SPButtonStateUp;
        [self dispatchEventWithType:SPEventTypeTriggered bubbles:YES];
    }
}

#pragma mark Private

- (void)setStateTexture:(SPTexture *)texture
{
    _body.texture = texture ?: _upState;
}

- (void)createTextField
{
    if (!_textField)
    {
        _textField = [[SPTextField alloc] initWithWidth:_textBounds.width height:_textBounds.height];
        _textField.vAlign = SPVAlignCenter;
        _textField.hAlign = SPHAlignCenter;
        _textField.touchable = NO;
        _textField.autoScale = YES;
        _textField.batchable = YES;
    }
    
    _textField.width  = _textBounds.width;
    _textField.height = _textBounds.height;
    _textField.x = _textBounds.x;
    _textField.y = _textBounds.y;
}

- (void)refreshState
{
    _contents.x = _contents.y = 0.0f;
    _contents.scaleX = _contents.scaleY = _contents.alpha = 1.0f;
    
    switch (_state)
    {
        case SPButtonStateDown:
            [self setStateTexture:_downState];
            _contents.alpha = _alphaWhenDown;
            _contents.scaleX = _contents.scaleY = _scaleWhenDown;
            _contents.x = (1.0f - _scaleWhenDown) / 2.0f * _body.width;
            _contents.y = (1.0f - _scaleWhenDown) / 2.0f * _body.height;
            break;
            
        case SPButtonStateUp:
            [self setStateTexture:_upState];
            break;
            
        case SPButtonStateDisabled:
            [self setStateTexture:_disabledState];
            _contents.alpha = _alphaWhenDisabled;
            break;
            
        default:
            [NSException raise:SPExceptionInvalidOperation format:@"invalid button state"];
    }
}

#pragma mark SPDisplayObject

- (void)setWidth:(float)width
{
    // a button behaves just like a textfield: when changing width & height,
    // the textfield is not stretched, but will have more room for its chars.
    
    _body.width = width;
    [self createTextField];
}

- (float)width
{
    return _body.width;
}

- (void)setHeight:(float)height
{
    _body.height = height;
    [self createTextField];
}

- (float)height
{
    return _body.height;
}

#pragma mark Properties

- (void)setState:(SPButtonState)state
{
    _state = state;
    [self refreshState];
}

- (void)setScaleWhenDown:(float)scaleWhenDown
{
    _scaleWhenDown = scaleWhenDown;
    if (_state == SPButtonStateDown) [self refreshState];
}

- (void)setAlphaWhenDown:(float)alphaWhenDown
{
    _alphaWhenDown = alphaWhenDown;
    if (_state == SPButtonStateDown) [self refreshState];
}

- (void)setAlphaWhenDisabled:(float)alphaWhenDisabled
{
    _alphaWhenDisabled = alphaWhenDisabled;
    if (_state == SPButtonStateDisabled) [self refreshState];
}

- (void)setEnabled:(BOOL)value
{
    if (_enabled != value)
    {
        _enabled = value;
        self.state = value ? SPButtonStateUp : SPButtonStateDisabled;
    }
}

- (NSString *)text
{
    if (_textField) return _textField.text;
    else return @"";
}

- (void)setText:(NSString *)value
{
    if (value.length == 0)
    {
        [_textField removeFromParent];
    }
    else
    {
        [self createTextField];
        if (!_textField.parent) [_contents addChild:_textField];
    }
    
    _textField.text = value;
}

- (NSString *)fontName
{
    if (_textField) return _textField.fontName;
    else return SPDefaultFontName;
}

- (void)setFontName:(NSString *)value
{
    [self createTextField];
    _textField.fontName = value;
}

- (float)fontSize
{
    if (_textField) return _textField.fontSize;
    else return SPDefaultFontSize;
}

- (void)setFontSize:(float)value
{
    [self createTextField];
    _textField.fontSize = value;
}

- (uint)fontColor
{
    if (_textField) return _textField.color;
    else return SPDefaultFontColor;
}

- (void)setFontColor:(uint)value
{
    [self createTextField];
    _textField.color = value;
}

- (SPHAlign)textHAlign
{
    return _textField ? _textField.hAlign : SPHAlignCenter;
}

- (void)setTextHAlign:(SPHAlign)textHAlign
{
    [self createTextField];
    _textField.hAlign = textHAlign;
}

- (SPVAlign)textVAlign
{
    return _textField ? _textField.vAlign : SPVAlignCenter;
}

- (void)setTextVAlign:(SPVAlign)textVAlign
{
    [self createTextField];
    _textField.vAlign = textVAlign;
}

- (uint)color
{
    return _body.color;
}

- (void)setColor:(uint)color
{
    _body.color = color;
}

- (void)setUpState:(SPTexture *)upState
{
    if (upState != _upState)
    {
        SP_RELEASE_AND_RETAIN(_upState, upState);
        
        if ( _state == SPButtonStateUp ||
            (_state == SPButtonStateDisabled && !_disabledState) ||
            (_state == SPButtonStateDown && !_downState))
        {
            [self setStateTexture:_upState];
        }
    }
}

- (void)setDownState:(SPTexture *)downState
{
    if (downState != _downState)
    {
        SP_RELEASE_AND_RETAIN(_downState, downState);
        if (_state == SPButtonStateDown) [self setStateTexture:_downState];
    }
}

- (void)setDisabledState:(SPTexture *)disabledState
{
    if (disabledState != _disabledState)
    {
        SP_RELEASE_AND_RETAIN(_disabledState, disabledState);
        if (_state == SPButtonStateDisabled) [self setStateTexture:_disabledState];
    }
}

- (SPRectangle *)textBounds
{
    return [[_textBounds copy] autorelease];
}

- (void)setTextBounds:(SPRectangle *)value
{
    SP_RELEASE_AND_COPY(_textBounds, value);
    [self createTextField];
}

- (SPSprite *)overlay
{
    if (!_overlay) _overlay = [[SPSprite alloc] init];
    [_contents addChild:_overlay]; // make sure it's always on top
    return _overlay;
}

@end
