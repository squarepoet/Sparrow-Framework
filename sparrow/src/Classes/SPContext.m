//
//  SPContext.m
//  Sparrow
//
//  Created by Robert Carone on 1/11/14.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPContext_Internal.h"
#import "SPDisplayObject.h"
#import "SPGLTexture_Internal.h"
#import "SPMacros.h"
#import "SPOpenGL.h"
#import "SPRectangle.h"
#import "SPRenderTexture.h"
#import "SPSubTexture.h"
#import "SPTexture.h"

#import <objc/runtime.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>

// --- EAGLContext ---------------------------------------------------------------------------------

@interface EAGLContext (Sparrow)

@property (atomic, strong) SPContext *spContext;

@end

// ---

@implementation EAGLContext (Sparrow)

@dynamic spContext;

- (SPContext *)spContext
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSpContext:(SPContext *)spContext
{
    objc_setAssociatedObject(self, _cmd, spContext, OBJC_ASSOCIATION_ASSIGN);
}

@end

// --- class implementation ------------------------------------------------------------------------

@implementation SPContext
{
    EAGLContext *_nativeContext;
    SPGLTexture *_renderTexture;
    SGLStateCacheRef _glStateCache;
    NSMutableDictionary *_data;
    
    int _backBufferWidth;
    int _backBufferHeight;
    uint _colorRenderBuffer;
    uint _depthStencilRenderBuffer;
    uint _frameBuffer;
    uint _msaaFrameBuffer;
    uint _msaaColorRenderBuffer;
}

#pragma mark Initialization

- (instancetype)initWithSharegroup:(id)sharegroup
{
    if ((self = [super init]))
    {
        _nativeContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];
        _nativeContext.spContext = self;
        _data = [[NSMutableDictionary alloc] init];
        _glStateCache = sglStateCacheCreate();
    }
    return self;
}

- (instancetype)init
{
    return [self initWithSharegroup:nil];
}

- (void)dealloc
{
    sglStateCacheRelease(_glStateCache);
    _glStateCache = NULL;
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (_frameBuffer)
        glDeleteFramebuffers(1, &_frameBuffer);
    
    if (_colorRenderBuffer)
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
    
    if (_depthStencilRenderBuffer)
        glDeleteRenderbuffers(1, &_depthStencilRenderBuffer);
    
    if (_msaaFrameBuffer)
        glDeleteFramebuffers(1, &_msaaFrameBuffer);
    
    if (_msaaColorRenderBuffer)
        glDeleteRenderbuffers(1, &_msaaColorRenderBuffer);
    
    _nativeContext.spContext = nil;
    [_nativeContext release];
    [_renderTexture release];
    [_data release];

    [super dealloc];
}

#pragma mark Methods

- (void)clearWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
               depth:(float)depth stencil:(uint)stencil mask:(SPClearMask)mask
{
    GLboolean scissorEnabled = glIsEnabled(GL_SCISSOR_TEST);
    if (scissorEnabled)
        glDisable(GL_SCISSOR_TEST);
    
    glClearColor(red, green, blue, alpha);
    glClearDepthf(depth);
    glClearStencil(stencil);
    
    GLbitfield glMask = 0;
    if ((mask & SPClearMaskColor) != 0)
        glMask |= GL_COLOR_BUFFER_BIT;
    if ((mask & SPClearMaskDepth) != 0)
        glMask |= GL_DEPTH_BUFFER_BIT;
    if ((mask & SPClearMaskStencil) != 0)
        glMask |= GL_STENCIL_BUFFER_BIT;
    
    glClear(glMask);
    
    if (scissorEnabled)
        glEnable(GL_SCISSOR_TEST);
}

- (void)clearWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    [self clearWithRed:red green:green blue:blue alpha:alpha depth:1 stencil:0 mask:SPClearMaskAll];
}

- (void)configureBackBufferForDrawable:(id<EAGLDrawable>)drawable antiAlias:(NSInteger)antiAlias
                 enableDepthAndStencil:(BOOL)enableDepthAndStencil
                   wantsBestResolution:(BOOL)wantsBestResolution
{
    [self makeCurrentContext];
    
    if ([(id)drawable isKindOfClass:[CALayer class]])
    {
        CALayer *layer = (CALayer *)drawable;
        layer.contentsScale = wantsBestResolution ? [UIScreen mainScreen].scale : 1.0f;
    }
    
    if (!_frameBuffer)
    {
        glGenFramebuffers(1, &_frameBuffer);
        glGenRenderbuffers(1, &_colorRenderBuffer);
        
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    [_nativeContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backBufferHeight);
    
    if (antiAlias && !_msaaFrameBuffer)
    {
        glGenFramebuffers(1, &_msaaFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _msaaFrameBuffer);
        
        glGenRenderbuffers(1, &_msaaColorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _msaaColorRenderBuffer);
        
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, (int)antiAlias, GL_RGBA8_OES, _backBufferWidth, _backBufferHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _msaaColorRenderBuffer);
    }
    else if (!antiAlias && _msaaFrameBuffer)
    {
        glDeleteFramebuffers(1, &_msaaFrameBuffer);
        _msaaFrameBuffer = 0;
        
        glDeleteRenderbuffers(1, &_msaaColorRenderBuffer);
        _msaaColorRenderBuffer = 0;
    }
    
    if (enableDepthAndStencil && !_depthStencilRenderBuffer)
    {
        glGenRenderbuffers(1, &_depthStencilRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _depthStencilRenderBuffer);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthStencilRenderBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _depthStencilRenderBuffer);
        
        if (_msaaFrameBuffer)
            glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, (int)antiAlias, GL_DEPTH24_STENCIL8_OES, _backBufferWidth, _backBufferHeight);
        else
            glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _backBufferWidth, _backBufferHeight);
    }
    else if (!enableDepthAndStencil && _depthStencilRenderBuffer)
    {
        glDeleteRenderbuffers(1, &_depthStencilRenderBuffer);
        _depthStencilRenderBuffer = 0;
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        SPLog(@"Failed to create default framebuffer");
}

- (UIImage *)drawToImage
{
    UIImage *uiImage = nil;
    float scale = _renderTexture ? _renderTexture.scale : Sparrow.currentController.contentScaleFactor;
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    
    if (_renderTexture)
    {
        width  = _renderTexture.nativeWidth;
        height = _renderTexture.nativeHeight;
    }
    else
    {
        width  = (int)self.backBufferWidth;
        height = (int)self.backBufferHeight;
    }
    
    GLubyte *pixels = malloc(4 * width * height);
    if (pixels)
    {
        GLint prevPackAlignment;
        GLint bytesPerRow = 4 * width;
        
        glGetIntegerv(GL_PACK_ALIGNMENT, &prevPackAlignment);
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        glPixelStorei(GL_PACK_ALIGNMENT, prevPackAlignment);
        
        CFDataRef data = CFDataCreate(kCFAllocatorDefault, pixels, bytesPerRow * height);
        if (data)
        {
            CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
            if (provider)
            {
                CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
                CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, space, 1, provider, nil, NO, 0);
                if (cgImage)
                {
                    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, scale);
                    {
                        CGContextRef context = UIGraphicsGetCurrentContext();
                        CGContextSetBlendMode(context, kCGBlendModeCopy);
                        CGContextTranslateCTM(context, 0.0f, height);
                        CGContextScaleCTM(context, 1, -1);
                        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
                        uiImage = UIGraphicsGetImageFromCurrentImageContext();
                    }
                    UIGraphicsEndImageContext();
                    
                    CGImageRelease(cgImage);
                }
                
                CGColorSpaceRelease(space);
                CGDataProviderRelease(provider);
            }
            
            CFRelease(data);
        }
        
        free(pixels);
    }
    
    return [[uiImage retain] autorelease];
}

- (void)present
{
    [self makeCurrentContext];
    
    if (_msaaFrameBuffer)
    {
        if (_depthStencilRenderBuffer)
        {
            GLenum attachments[] = { GL_COLOR_ATTACHMENT0, GL_STENCIL_ATTACHMENT, GL_DEPTH_ATTACHMENT };
            glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 3, attachments);
        }
        else
        {
            GLenum attachments[] = { GL_COLOR_ATTACHMENT0 };
            glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
        }
    }
    else if (_depthStencilRenderBuffer)
    {
        GLenum attachments[] = { GL_STENCIL_ATTACHMENT, GL_DEPTH_ATTACHMENT };
        glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, attachments);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_nativeContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setRenderToBackBuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _backBufferWidth, _backBufferHeight);
    
    if (_depthStencilRenderBuffer)
    {
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_STENCIL_TEST);
    }
    else
    {
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_STENCIL_TEST);
    }
}

- (void)setRenderToTexture:(SPGLTexture *)texture
{
    [self setRenderToTexture:texture enableDepthAndStencil:NO];
}

- (void)setRenderToTexture:(SPGLTexture *)texture enableDepthAndStencil:(BOOL)enableDepthAndStencil
{
    if (texture)
    {
        uint framebuffer = [texture framebufferWithDepthAndStencil:enableDepthAndStencil];
        
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        glViewport(0, 0, texture.nativeWidth, texture.nativeHeight);
        
        if (enableDepthAndStencil)
        {
            glEnable(GL_DEPTH_TEST);
            glEnable(GL_SCISSOR_TEST);
        }
        else
        {
            glDisable(GL_DEPTH_TEST);
            glDisable(GL_SCISSOR_TEST);
        }
    }
    else
    {
        [self setRenderToBackBuffer];
    }
    
    SP_RELEASE_AND_RETAIN(_renderTexture, texture);
    
  #if DEBUG
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        SPLog(@"Currently bound framebuffer is invalid");
  #endif
}

- (void)setScissorRectangle:(SPRectangle *)rectangle
{
    if (rectangle)
    {
        glEnable(GL_SCISSOR_TEST);
        glScissor(rectangle.x, rectangle.y, rectangle.width, rectangle.height);
    }
    else
    {
        glDisable(GL_SCISSOR_TEST);
    }
}


- (void)setViewportRectangle:(SPRectangle *)rectangle
{
    if (rectangle)
    {
        glViewport(rectangle.x, rectangle.y, rectangle.width, rectangle.height);
    }
}

#pragma mark EAGLContext

- (BOOL)makeCurrentContext
{
    return [[self class] setCurrentContext:self];
}

+ (BOOL)setCurrentContext:(SPContext *)context
{
    if (context)
    {
        sglStateCacheSetCurrent(context->_glStateCache);
        
        if ([EAGLContext currentContext] != context->_nativeContext)
            return [EAGLContext setCurrentContext:context->_nativeContext];
        
        return YES;
    }
    
    sglStateCacheSetCurrent(NULL);
    return [EAGLContext setCurrentContext:nil];
}

+ (SPContext *)currentContext
{
    return [EAGLContext currentContext].spContext;
}

#pragma mark Properties

- (id)sharegroup
{
    return _nativeContext.sharegroup;
}

- (id)nativeContext
{
    return _nativeContext;
}

- (NSInteger)backBufferWidth
{
    return _backBufferWidth;
}

- (NSInteger)backBufferHeight
{
    return _backBufferHeight;
}

@end
