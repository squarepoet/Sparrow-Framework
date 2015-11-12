//
//  SPContext.m
//  Sparrow
//
//  Created by Robert Carone on 1/11/14.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPCache.h"
#import "SPContext_Internal.h"
#import "SPDisplayObject.h"
#import "SPFrameBuffer.h"
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

// --- static helpers ------------------------------------------------------------------------------

static SP_GENERIC(SPCache, EAGLContext*, SPContext*) *contexts = nil;
static SPContext *globalShareContext = nil;

static EAGLRenderingAPI toEAGLRenderingAPI[] = {
    0,
    kEAGLRenderingAPIOpenGLES2,
    kEAGLRenderingAPIOpenGLES3
};

static SPRenderingAPI toSPRenderingAPI[] = {
    0,
    SPRenderingAPIOpenGLES2,
    SPRenderingAPIOpenGLES2,
    SPRenderingAPIOpenGLES3,
};

// --- class implementation ------------------------------------------------------------------------

@implementation SPContext
{
    EAGLContext *_nativeContext;
    SPGLTexture *_renderTexture;
    SPRenderingAPI _API;
    SGLStateCacheRef _glStateCache;
    NSMutableDictionary *_data;
    
    SP_GENERIC(NSMapTable, SPTexture*, SPFrameBuffer*) *_frameBuffers;
    SPFrameBuffer *_backBuffer;
}

+ (void)initialize
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        // strong key ref and hash by pointer, weak values
        NSPointerFunctionsOptions keyOptions = NSMapTableStrongMemory | NSMapTableObjectPointerPersonality;
        NSMapTable *table = [[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:NSMapTableWeakMemory capacity:4];
        contexts = [[SPCache alloc] initWithMapTable:[table autorelease]];
    });
}

#pragma mark Initialization

- (instancetype)initWithNativeContext:(EAGLContext *)nativeContext
{
    if (!nativeContext)
        [NSException raise:SPExceptionOperationFailed format:@"native context cannot be nil"];
    
    if (self = [super init])
    {
        if (nativeContext)
        {
            contexts[nativeContext] = self;
            _nativeContext = [nativeContext retain];
            
            // BUG: if this enabled IOAccelerator leaks!
            // if ([nativeContext respondsToSelector:@selector(setMultiThreaded:)])
            //    _nativeContext.multiThreaded = YES;
        }
        else
        {
            [self release];
            return nil;
        }
        
        _glStateCache = sglStateCacheCreate();
        _API = toSPRenderingAPI[nativeContext.API];
        
        // framebuffer are stored strong via weak SPGLTexture keys (hashed via pointer)
        // note however that values are not removed automatically when an SPGLTexture object is freed
        NSPointerFunctionsOptions keyOptions = NSMapTableWeakMemory | NSMapTableObjectPointerPersonality;
        _frameBuffers = [[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:NSMapTableStrongMemory capacity:8];
        _data = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (instancetype)initWithShareContext:(SPContext *)shareContext
{
    EAGLRenderingAPI api = toEAGLRenderingAPI[shareContext ? shareContext.API : SPRenderingAPIOpenGLES3];
    EAGLSharegroup *sharegroup = shareContext.sharegroup;
    
    EAGLContext *nativeContext = [[EAGLContext alloc] initWithAPI:api sharegroup:sharegroup];
    if (!nativeContext)
        nativeContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];
    
    return [self initWithNativeContext:[nativeContext autorelease]];
}

- (instancetype)init
{
    return [self initWithShareContext:globalShareContext];
}

+ (instancetype)globalShareContext
{
    return globalShareContext;
}

- (void)dealloc
{
    sglStateCacheRelease(_glStateCache);
    
    [_backBuffer release];
    [_frameBuffers release];
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
        
        CGFloat prevScaleFactor = layer.contentsScale;
        layer.contentsScale = wantsBestResolution ? [UIScreen mainScreen].scale : 1.0f;
        
        if (prevScaleFactor != layer.contentsScale)
            [_backBuffer reset];
    }
    
    if (!_backBuffer || _backBuffer.drawable != drawable)
        SP_RELEASE_AND_RETAIN(_backBuffer, [[[SPFrameBuffer alloc] initWithContext:self drawable:drawable] autorelease]);
    
    _backBuffer.antiAlias = antiAlias;
    _backBuffer.enableDepthAndStencil = enableDepthAndStencil;
}

- (UIImage *)drawToImage
{
    return [self drawToImageInRegion:nil];
}

- (UIImage *)drawToImageInRegion:(SPRectangle *)region
{
    [self makeCurrentContext];
    
    if (_renderTexture)
        return [[_frameBuffers objectForKey:_renderTexture] drawToImageInRegion:region];
    else
        return [_backBuffer drawToImageInRegion:region];
}

- (void)present
{
    [self makeCurrentContext];
    [_backBuffer present];
}

- (void)setRenderToBackBuffer
{
    [self setRenderToTexture:nil enableDepthAndStencil:_backBuffer.enableDepthAndStencil];
}

- (void)setRenderToTexture:(SPGLTexture *)texture
{
    [self setRenderToTexture:texture enableDepthAndStencil:NO];
}

- (void)setRenderToTexture:(SPGLTexture *)texture enableDepthAndStencil:(BOOL)enableDepthAndStencil
{
    SPFrameBuffer *frameBuffer = nil;
    
    if (texture)
    {
        frameBuffer = [_frameBuffers objectForKey:texture];
        if (!frameBuffer)
        {
            frameBuffer = [[[SPFrameBuffer alloc] initWithContext:self texture:texture] autorelease];
            [_frameBuffers setObject:frameBuffer forKey:texture];
            texture.usedAsRenderTexture = YES;
        }
        
        frameBuffer.enableDepthAndStencil = enableDepthAndStencil;
    }
    else
    {
        frameBuffer = _backBuffer;
    }
    
    if (!enableDepthAndStencil)
    {
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_STENCIL_TEST);
    }
    
    if (frameBuffer)
    {
        [frameBuffer bind];
    }
    else
    {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glBindRenderbuffer(GL_FRAMEBUFFER, 0);
    }
    
    if (enableDepthAndStencil)
    {
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_STENCIL_TEST);
    }
    
    SP_RELEASE_AND_RETAIN(_renderTexture, texture);
    
  #if DEBUG
    if (frameBuffer && glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
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

+ (SPContext *)currentContext
{
    EAGLContext *context = [EAGLContext currentContext];
    if (context) return contexts[context];
    else         return nil;
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
    return _backBuffer.width;
}

- (NSInteger)backBufferHeight
{
    return _backBuffer.height;
}

- (BOOL)isMultiThreaded
{
    return _nativeContext.multiThreaded;
}

- (void)setIsMultiThreaded:(BOOL)isMultiThreaded
{
    _nativeContext.multiThreaded = isMultiThreaded;
}

@end

@implementation SPContext (Internal)

+ (void)clearFrameBuffersForTexture:(SPGLTexture *)texture
{
    for (EAGLContext *key in contexts)
        [((SPContext *)contexts[key])->_frameBuffers removeObjectForKey:texture];
}

+ (void)setGlobalShareContext:(SPContext *)newGlobalShareContext
{
    SP_RELEASE_AND_RETAIN(globalShareContext, newGlobalShareContext);
}

@end
