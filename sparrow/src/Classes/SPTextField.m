//
//  SPTextField.m
//  Sparrow
//
//  Created by Daniel Sperl on 29.06.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPBitmapFont.h"
#import "SPEnterFrameEvent.h"
#import "SPGLTexture.h"
#import "SPImage.h"
#import "SPQuad.h"
#import "SPQuadBatch.h"
#import "SPRectangle.h"
#import "SPStage.h"
#import "SPSprite.h"
#import "SPSubTexture.h"
#import "SPTextField.h"
#import "SPTexture.h"

#import <UIKit/UIKit.h>

// --- public constants ----------------------------------------------------------------------------

NSString *const   SPDefaultFontName   = @"Helvetica";
const float       SPDefaultFontSize   = 14.0f;
const uint        SPDefaultFontColor  = 0x0;
const float       SPNativeFontSize    = -1;

// --- bitmap font cache ---------------------------------------------------------------------------

static NSMutableDictionary *bitmapFonts = nil;

// --- helpers -------------------------------------------------------------------------------------

static NSTextAlignment hAlignToTextAlignment[] = {
    NSTextAlignmentLeft,
    NSTextAlignmentCenter,
    NSTextAlignmentRight
};

@interface SPTextField ()

@property (nonatomic, readonly) BOOL isHorizontalAutoSize;
@property (nonatomic, readonly) BOOL isVerticalAutoSize;

@end

// --- class implementation ------------------------------------------------------------------------

@implementation SPTextField
{
    float _fontSize;
    uint _color;
    NSString *_text;
    NSString *_fontName;
    SPHAlign _hAlign;
    SPVAlign _vAlign;
    BOOL _bold;
    BOOL _italic;
    BOOL _underline;
    BOOL _autoScale;
    SPTextFieldAutoSize _autoSize;
    BOOL _batchable;
    BOOL _kerning;
    float _leading;
    BOOL _requiresRedraw;
    BOOL _isRenderedText;
    
    SPRectangle *_textBounds;
    SPRectangle *_hitArea;
    SPDisplayObjectContainer *_border;
    
    SPImage *_image;
    SPQuadBatch *_quadBatch;
}

#pragma mark Initialization

- (instancetype)initWithWidth:(float)width height:(float)height text:(NSString *)text fontName:(NSString *)name 
                     fontSize:(float)size color:(uint)color
{
    if ((self = [super init]))
    {        
        _text = [text copy];
        _fontSize = size;
        _color = color;
        _hAlign = SPHAlignCenter;
        _vAlign = SPVAlignCenter;
        _autoScale = NO;
        _requiresRedraw = YES;
        _kerning = YES;
        _leading = 0.0f;
        _autoSize = SPTextFieldAutoSizeNone;
        _hitArea = [[SPRectangle alloc] initWithX:0 y:0 width:width height:height];
        self.fontName = name;
        
        [self addEventListener:@selector(onFlatten:) atObject:self forType:SPEventTypeFlatten];
    }
    return self;
} 

- (instancetype)initWithWidth:(float)width height:(float)height text:(NSString *)text
{
    return [self initWithWidth:width height:height text:text fontName:SPDefaultFontName
                     fontSize:SPDefaultFontSize color:SPDefaultFontColor];   
}

- (instancetype)initWithWidth:(float)width height:(float)height
{
    return [self initWithWidth:width height:height text:@""];
}

- (instancetype)initWithText:(NSString *)text
{
    return [self initWithWidth:128 height:128 text:text];
}

- (instancetype)init
{
    return [self initWithText:@""];
}

- (void)dealloc
{
    [_text release];
    [_fontName release];
    [_textBounds release];
    [_hitArea release];
    [_border release];
    [_image release];
    [_quadBatch release];
    [super dealloc];
}

+ (instancetype)textFieldWithWidth:(float)width height:(float)height text:(NSString *)text
                          fontName:(NSString *)name fontSize:(float)size color:(uint)color
{
    return [[[self alloc] initWithWidth:width height:height text:text fontName:name
                               fontSize:size color:color] autorelease];
}

+ (instancetype)textFieldWithWidth:(float)width height:(float)height text:(NSString *)text
{
    return [[[self alloc] initWithWidth:width height:height text:text] autorelease];
}

+ (instancetype)textFieldWithText:(NSString *)text
{
    return [[[self alloc] initWithText:text] autorelease];
}

#pragma mark Methods

+ (NSString *)registerBitmapFont:(SPBitmapFont *)font name:(NSString *)fontName
{
    if (!bitmapFonts) bitmapFonts = [[NSMutableDictionary alloc] init];
    if (!fontName) fontName = font.name;
    bitmapFonts[fontName] = font;
    return [[fontName copy] autorelease];
}

+ (NSString *)registerBitmapFont:(SPBitmapFont *)font
{
    return [self registerBitmapFont:font name:nil];
}

+ (NSString *)registerBitmapFontFromFile:(NSString *)path texture:(SPTexture *)texture
                                    name:(NSString *)fontName
{
    SPBitmapFont *font = [[[SPBitmapFont alloc] initWithContentsOfFile:path texture:texture] autorelease];
    return [self registerBitmapFont:font name:fontName];
}

+ (NSString *)registerBitmapFontFromFile:(NSString *)path texture:(SPTexture *)texture
{
    SPBitmapFont *font = [[[SPBitmapFont alloc] initWithContentsOfFile:path texture:texture] autorelease];
    return [self registerBitmapFont:font];
}

+ (NSString *)registerBitmapFontFromFile:(NSString *)path
{
    SPBitmapFont *font = [[[SPBitmapFont alloc] initWithContentsOfFile:path] autorelease];
    return [self registerBitmapFont:font];
}

+ (void)unregisterBitmapFont:(NSString *)name
{
    [bitmapFonts removeObjectForKey:name];
}

+ (SPBitmapFont *)registeredBitmapFont:(NSString *)name
{
    return bitmapFonts[name];
}

#pragma mark SPDisplayObject

- (void)render:(SPRenderSupport *)support
{
    if (_requiresRedraw) [self redraw];
    [super render:support];
}

- (SPRectangle *)boundsInSpace:(SPDisplayObject *)targetSpace
{
    if (_requiresRedraw) [self redraw];
    SPMatrix *matrix = [self transformationMatrixToSpace:targetSpace];
    return [_hitArea boundsAfterTransformation:matrix];
}

- (void)setWidth:(float)width
{
    // other than in SPDisplayObject, changing the size of the object should not change the scaling;
    // changing the size should just make the texture bigger/smaller,
    // keeping the size of the text/font unchanged. (this applies to setHeight:, as well.)

    _hitArea.width = width;
    _requiresRedraw = YES;
}

- (void)setHeight:(float)height
{
    _hitArea.height = height;
    _requiresRedraw = YES;
}

#pragma mark Events

- (void)onFlatten:(SPEvent *)event
{
    if (_requiresRedraw) [self redraw];
}

#pragma mark NSCopying

- (instancetype)copy
{
    SPTextField *textField = [super copy];
    
    [textField->_hitArea copyFromRectangle:_hitArea];
    textField.text = self.text;
    textField.fontName = self.fontName;
    textField.fontSize = self.fontSize;
    textField.color = self.color;
    textField.hAlign = self.hAlign;
    textField.vAlign = self.vAlign;
    textField.border = self.border;
    textField.bold = self.bold;
    textField.italic = self.italic;
    textField.underline = self.underline;
    textField.kerning = self.kerning;
    textField.autoScale = self.autoScale;
    textField.autoSize = self.autoSize;
    textField.batchable = self.batchable;
    textField.leading = self.leading;
    
    return textField;
}

#pragma mark Properties

- (void)setText:(NSString *)text
{
    if (![text isEqualToString:_text])
    {
        SP_RELEASE_AND_COPY(_text, text);
        _requiresRedraw = YES;
    }
}

- (void)setFontName:(NSString *)fontName
{
    if (![fontName isEqualToString:_fontName])
    {
        if ([fontName isEqualToString:SPBitmapFontMiniName] && ![bitmapFonts objectForKey:fontName])
            [SPTextField registerBitmapFont:[[[SPBitmapFont alloc] initWithMiniFont] autorelease]];

        SP_RELEASE_AND_COPY(_fontName, fontName);
        _requiresRedraw = YES;        
        _isRenderedText = !bitmapFonts[_fontName];
    }
}

- (void)setFontSize:(float)fontSize
{
    if (fontSize != _fontSize)
    {
        _fontSize = fontSize;
        _requiresRedraw = YES;
    }
}

- (void)setColor:(uint)color
{
    if (color != _color)
    {
        _color = color;
        _requiresRedraw = YES;
    }
}
 
- (void)setHAlign:(SPHAlign)hAlign
{
    if (hAlign != _hAlign)
    {
        _hAlign = hAlign;
        _requiresRedraw = YES;
    }
}

- (void)setVAlign:(SPVAlign)vAlign
{
    if (vAlign != _vAlign)
    {
        _vAlign = vAlign;
        _requiresRedraw = YES;
    }
}

- (BOOL)border
{
    return _border != nil;
}

- (void)setBorder:(BOOL)value
{
    if (value && !_border)
    {
        _border = [[SPSprite alloc] init];

        for (int i=0; i<4; ++i)
            [_border addChild:[SPQuad quadWithWidth:1.0f height:1.0f]];

        [self addChild:_border];
        [self updateBorder];
    }
    else if (!value && _border)
    {
        [_border removeFromParent];
        SP_RELEASE_AND_NIL(_border);
    }
}

- (void)setBold:(BOOL)bold
{
    if (bold != _bold)
    {
        _bold = bold;
        _requiresRedraw = YES;
    }
}

- (void)setItalic:(BOOL)italic
{
    if (italic != _italic)
    {
        _italic = italic;
        _requiresRedraw = YES;
    }
}

- (void)setUnderline:(BOOL)underline
{
    if (underline != _underline)
    {
        _underline = underline;
        _requiresRedraw = YES;
    }
}

- (void)setKerning:(BOOL)kerning
{
	if (kerning != _kerning)
	{
		_kerning = kerning;
		_requiresRedraw = YES;
	}
}

- (void)setAutoScale:(BOOL)autoScale
{
    if (autoScale != _autoScale)
    {
        _autoScale = autoScale;
        _requiresRedraw = YES;
    }
}

- (void)setAutoSize:(SPTextFieldAutoSize)autoSize
{
    if (autoSize != _autoSize)
    {
        _autoSize = autoSize;
        _requiresRedraw = YES;
    }
}

- (void)setBatchable:(BOOL)batchable
{
    _batchable = batchable;
    if (_quadBatch) _quadBatch.batchable = batchable;
}

- (void)setLeading:(float)leading
{
    if (leading != _leading)
    {
        _leading = leading;
        _requiresRedraw = YES;
    }
}

- (SPRectangle *)textBounds
{
    if (_requiresRedraw) [self redraw];
    if (!_textBounds) _textBounds = [[_quadBatch boundsInSpace:_quadBatch] retain];
    return [[_textBounds copy] autorelease];
}

#pragma mark Private

- (BOOL)isVerticalAutoSize
{
    return (_autoSize & SPTextFieldAutoSizeVertical) != 0;
}

- (BOOL)isHorizontalAutoSize
{
    return (_autoSize & SPTextFieldAutoSizeHorizontal) != 0;
}

- (void)redraw
{
    if (_requiresRedraw)
    {
        if (_isRenderedText) [self createRenderedContents];
        else                 [self createComposedContents];
        
        [self updateBorder];
        _requiresRedraw = NO;
    }
}

- (void)createRenderedContents
{
    if (_quadBatch)
    {
        [_quadBatch removeFromParent];
        SP_RELEASE_AND_NIL(_quadBatch);
    }
    
    float width  = _hitArea.width;
    float height = _hitArea.height;
    float fontSize = _fontSize == SPNativeFontSize ? SPDefaultFontSize : _fontSize;
    SPHAlign hAlign = _hAlign;
    SPVAlign vAlign = _vAlign;
    
    if (self.isHorizontalAutoSize)
    {
        width = FLT_MAX;
        hAlign = SPHAlignLeft;
    }
    
    if (self.isVerticalAutoSize)
    {
        height = FLT_MAX;
        vAlign = SPVAlignTop;
    }
    
    NSRange textRange = (NSRange){ 0, _text.length };
    NSMutableAttributedString *attributedText = [[[NSMutableAttributedString alloc] initWithString:_text] autorelease];
    
    // paragraph style
    
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    if (_leading > 0.0f) paragraphStyle.lineSpacing = _leading;
    paragraphStyle.alignment = hAlignToTextAlignment[_hAlign];
    [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:textRange];
    
    // traits
    
    UIFontDescriptorSymbolicTraits traits = 0;
    if (_bold)   traits |= UIFontDescriptorTraitBold;
    if (_italic) traits |= UIFontDescriptorTraitItalic;
    
    UIFontDescriptor *fontDescriptor = [[UIFontDescriptor fontDescriptorWithName:_fontName size:_fontSize]
                                        fontDescriptorWithSymbolicTraits:traits];
    
    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:_fontSize];
    [attributedText addAttribute:NSFontAttributeName value:font range:textRange];
    
    // attributes
    
    if (_underline) {
        [attributedText addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:textRange];
    }
    
    UIColor *color = [UIColor colorWithRed:SPColorGetRed(_color)   / 255.0f
                                     green:SPColorGetGreen(_color) / 255.0f
                                      blue:SPColorGetBlue(_color)  / 255.0f
                                     alpha:1.0f];
    
    [attributedText addAttribute:NSForegroundColorAttributeName value:color range:textRange];
    
    CGSize textSize;
    
    if (_autoScale)
    {
        CGSize maxSize = CGSizeMake(width, FLT_MAX);
        fontSize += 1.0f;
        
        do
        {
            fontSize -= 1.0f;
            
            font = [UIFont fontWithDescriptor:fontDescriptor size:fontSize];
            [attributedText addAttribute:NSFontAttributeName value:font range:textRange];
            textSize = [attributedText boundingRectWithSize:maxSize
						options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
            
        } while (textSize.height > height);
    }
    else
    {
        textSize = [attributedText boundingRectWithSize:CGSizeMake(width, height)
					options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    }
    
    float xOffset = 0;
    if (hAlign == SPHAlignCenter)      xOffset = (width - textSize.width) / 2.0f;
    else if (hAlign == SPHAlignRight)  xOffset =  width - textSize.width;
    
    float yOffset = 0;
    if (vAlign == SPVAlignCenter)      yOffset = (height - textSize.height) / 2.0f;
    else if (vAlign == SPVAlignBottom) yOffset =  height - textSize.height;
    
    if (!_textBounds) _textBounds = [[SPRectangle alloc] init];
    [_textBounds setX:xOffset y:yOffset width:textSize.width height:textSize.height];
    
    SPTexture *texture = [[SPTexture alloc] initWithWidth:width height:height generateMipmaps:NO
                                                     draw:^(CGContextRef context)
    {
        [attributedText drawWithRect:CGRectMake(0, yOffset, width, height)
                             options:NSStringDrawingUsesLineFragmentOrigin
                             context:nil];
    }];
    
    [texture autorelease];
    
    if (!_image)
    {
        _image = [[SPImage alloc] initWithTexture:texture];
        _image.touchable = false;
        [self addChild:_image];
    }
    else
    {
        _image.texture = texture;
        [_image readjustSize];
    }
}

- (void)createComposedContents
{
    SPBitmapFont *bitmapFont = bitmapFonts[_fontName];
    if (!bitmapFont)
        [NSException raise:SPExceptionInvalidOperation 
                    format:@"bitmap font %@ not registered!", _fontName];
    
    if (_image)
    {
        [_image removeFromParent];
        SP_RELEASE_AND_NIL(_image);
    }
    
    if (!_quadBatch)
    {
        _quadBatch = [[SPQuadBatch alloc] init];
        _quadBatch.touchable = false;
        [self addChild:_quadBatch];
    }
    else
    {
        [_quadBatch reset];
    }
    
    float width  = _hitArea.width;
    float height = _hitArea.height;
    SPHAlign hAlign = _hAlign;
    SPVAlign vAlign = _vAlign;
    
    if (self.isHorizontalAutoSize)
    {
        width = FLT_MAX;
        hAlign = SPHAlignLeft;
    }
    
    if (self.isVerticalAutoSize)
    {
        height = FLT_MAX;
        vAlign = SPVAlignTop;
    }
    
    [bitmapFont fillQuadBatch:_quadBatch withWidth:width height:height
                         text:_text fontSize:_fontSize color:_color hAlign:hAlign vAlign:vAlign
                    autoScale:_autoScale kerning:_kerning leading:_leading];
    
    _quadBatch.batchable = _batchable;
    
    if (_autoSize != SPTextFieldAutoSizeNone)
    {
        _textBounds = [_quadBatch boundsInSpace:_quadBatch];
        
        if (self.isHorizontalAutoSize)
            _hitArea.width  = _textBounds.x + _textBounds.width;
        
        if (self.isVerticalAutoSize)
            _hitArea.height = _textBounds.y + _textBounds.height;
    }
    else
    {
        // hit area doesn't change, text bounds can be created on demand
        SP_RELEASE_AND_NIL(_textBounds);
    }
}

- (void)updateBorder
{
    if (!_border) return;
    
    float width  = _hitArea.width;
    float height = _hitArea.height;
    
    SPQuad *topLine    = (SPQuad *)[_border childAtIndex:0];
    SPQuad *rightLine  = (SPQuad *)[_border childAtIndex:1];
    SPQuad *bottomLine = (SPQuad *)[_border childAtIndex:2];
    SPQuad *leftLine   = (SPQuad *)[_border childAtIndex:3];
    
    topLine.width = width; topLine.height = 1;
    bottomLine.width = width; bottomLine.height = 1;
    leftLine.width = 1; leftLine.height = height;
    rightLine.width = 1; rightLine.height = height;
    rightLine.x = width - 1;
    bottomLine.y = height - 1;
    topLine.color = rightLine.color = bottomLine.color = leftLine.color = _color;
}

@end
