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
    [self setRenderToBackBuffer];
    [_nativeContext presentRenderbuffer:GL_RENDERBUFFER];
}
- (void)setRenderToBackBuffer
{
    // HACK: GLKView does not use the OpenGL state cache, so we have to 'reset' these values
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, 0, 0);
    
    [Sparrow.currentController.view bindDrawable];
    
    if (Sparrow.currentController.view.drawableDepthFormat)
        glEnable(GL_DEPTH_TEST);
    else
        glDisable(GL_DEPTH_TEST);
    
    if (Sparrow.currentController.view.drawableStencilFormat)
        glEnable(GL_SCISSOR_TEST);
    else
        glDisable(GL_SCISSOR_TEST);
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
        NSLog(@"Currently bound framebuffer is invalid");
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
    return Sparrow.currentController.view.drawableWidth;
}

- (NSInteger)backBufferHeight
{
    return Sparrow.currentController.view.drawableHeight;
}

@end
