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
    SPTexture *_renderTarget;
    SGLStateCacheRef _glStateCache;
    NSMutableDictionary *_framebufferCache;
}

#pragma mark Initialization

- (instancetype)initWithSharegroup:(id)sharegroup
{
    if ((self = [super init]))
    {
        _nativeContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];
        _nativeContext.spContext = self;
        _framebufferCache = [[NSMutableDictionary alloc] init];
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
    [_renderTarget release];
    [_framebufferCache release];

    [super dealloc];
}

#pragma mark Methods

- (void)renderToBackBuffer
{
    [self setRenderTarget:nil];
}

- (void)presentBufferForDisplay
{
    [_nativeContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (UIImage *)snapshot
{
    UIImage *uiImage = nil;
    float scale = _renderTarget ? _renderTarget.scale : Sparrow.currentController.contentScaleFactor;
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;

    if (_renderTarget)
    {
        if ([_renderTarget isKindOfClass:[SPSubTexture class]])
        {
            SPRectangle *region = [(SPSubTexture *)_renderTarget region];
            x = region.x;
            y = region.y;
            width  = region.width;
            height = region.height;
        }
        else
        {
            width  = _renderTarget.nativeWidth;
            height = _renderTarget.nativeHeight;
        }
    }
    else
    {
        width  = (int)Sparrow.currentController.view.drawableWidth;
        height = (int)Sparrow.currentController.view.drawableHeight;
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
                        CGContextScaleCTM(context, scale, -scale);
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

- (UIImage *)snapshotOfTexture:(SPTexture *)texture
{
    SPTexture *previousRenderTarget = [_renderTarget retain];
    self.renderTarget = texture;

    UIImage *image = [self snapshot];

    self.renderTarget = previousRenderTarget;
    return image;
}

- (UIImage *)snapshotOfDisplayObject:(SPDisplayObject *)object
{
    SPRenderTexture *renderTexture = [SPRenderTexture textureWithWidth:object.width height:object.height];
    [renderTexture drawObject:object];
    return [self snapshotOfTexture:renderTexture];
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

+ (BOOL)deviceSupportsOpenGLExtension:(NSString *)extensionName
{
    static dispatch_once_t once;
    static NSArray *extensions = nil;

    dispatch_once(&once, ^{
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensions = [[extensionsString componentsSeparatedByString:@" "] retain];
    });

    return [extensions containsObject:extensionName];
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

- (SPRectangle *)viewport
{
    struct { int x, y, w, h; } viewport;
    glGetIntegerv(GL_VIEWPORT, (int *)&viewport);
    return [SPRectangle rectangleWithX:viewport.x y:viewport.y width:viewport.w height:viewport.h];
}

- (void)setViewport:(SPRectangle *)viewport
{
    if (viewport)
        glViewport(viewport.x, viewport.y, viewport.width, viewport.height);
    else
        glViewport(0, 0, (int)Sparrow.currentController.view.drawableWidth, (int)Sparrow.currentController.view.drawableHeight);
}

- (SPRectangle *)scissorBox
{
    struct { int x, y, w, h; } scissorBox;
    glGetIntegerv(GL_SCISSOR_BOX, (int *)&scissorBox);
    return [SPRectangle rectangleWithX:scissorBox.x y:scissorBox.y width:scissorBox.w height:scissorBox.h];
}

- (void)setScissorBox:(SPRectangle *)scissorBox
{
    if (scissorBox)
    {
        glEnable(GL_SCISSOR_TEST);
        glScissor(scissorBox.x, scissorBox.y, scissorBox.width, scissorBox.height);
    }
    else
    {
        glDisable(GL_SCISSOR_TEST);
    }
}

- (void)setRenderTarget:(SPTexture *)renderTarget
{
    if (renderTarget)
    {
        uint framebuffer = [_framebufferCache[@(renderTarget.name)] unsignedIntValue];
        if (!framebuffer)
        {
            // create and cache the framebuffer
            framebuffer = [self createFramebufferForTexture:renderTarget];
            _framebufferCache[@(renderTarget.name)] = @(framebuffer);
        }

        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        glViewport(0, 0, renderTarget.nativeWidth, renderTarget.nativeHeight);
    }
    else
    {
        // HACK: GLKView does not use the OpenGL state cache, so we have to 'reset' these values
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glViewport(0, 0, 0, 0);

        [Sparrow.currentController.view bindDrawable];
    }

  #if DEBUG
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"Currently bound framebuffer is invalid");
  #endif

    SP_RELEASE_AND_RETAIN(_renderTarget, renderTarget);
}

@end

// -------------------------------------------------------------------------------------------------

@implementation SPContext (Internal)

- (uint)createFramebufferForTexture:(SPTexture *)texture
{
    uint framebuffer = -1;

    // create framebuffer
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

    // attach renderbuffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture.name, 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"failed to create frame buffer for render texture");

    return framebuffer;
}

- (void)destroyFramebufferForTexture:(SPTexture *)texture
{
    uint framebuffer = [_framebufferCache[@(texture.name)] unsignedIntValue];
    if (framebuffer)
    {
        glDeleteFramebuffers(1, &framebuffer);
        [_framebufferCache removeObjectForKey:@(texture.name)];
    }
}

@end
