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

static __SP_GENERICS(SPCache,EAGLContext*,SPContext*) *contexts = nil;
static SPContext *globalShareContext = nil;

static EAGLRenderingAPI toEAGLRenderingAPI[] = {
    kEAGLRenderingAPIOpenGLES2,
    kEAGLRenderingAPIOpenGLES3
};

static SPRenderingAPI toSPRenderingAPI[] = {
    SPRenderingAPIOpenGLES3,
    SPRenderingAPIOpenGLES2
};

// --- class implementation ------------------------------------------------------------------------

@implementation SPContext
{
    EAGLContext *_nativeContext;
    SPGLTexture *_renderTexture;
    SGLStateCacheRef _glStateCache;
    
    SPRenderingAPI _API;
    BOOL _depthAndStencilEnabled;
    
    NSMutableDictionary *_data;
    __SP_GENERICS(NSMapTable,SPTexture*,SPFrameBuffer*) *_frameBuffers;
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
        contexts = [[[SPCache class] alloc] initWithMapTable:table];
    });
}

#pragma mark Initialization

- (instancetype)initWithNativeContext:(EAGLContext *)nativeContext
{
    if (self = [super init])
    {
        if (nativeContext)
        {
            contexts[nativeContext] = self;
            _nativeContext = [nativeContext retain];
            
            if ([nativeContext respondsToSelector:@selector(setMultiThreaded:)])
                _nativeContext.multiThreaded = YES;
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
            SP_RELEASE_AND_NIL(_backBuffer);
    }
    
    if (!_backBuffer || _backBuffer.drawable != drawable)
        SP_RELEASE_AND_RETAIN(_backBuffer, [[[SPFrameBuffer alloc] initWithContext:self drawable:drawable] autorelease]);
    
    [_backBuffer affirmWithAntiAliasing:antiAlias enableDepthAndStencil:enableDepthAndStencil];
    
    _depthAndStencilEnabled = enableDepthAndStencil;
}

- (UIImage *)drawToImage
{
    return [self drawToImageInRegion:nil];
}

- (UIImage *)drawToImageInRegion:(SPRectangle *)region
{
    [self makeCurrentContext];
    
    UIImage *uiImage = nil;
    float scale = _renderTexture ? _renderTexture.scale : Sparrow.currentController.contentScaleFactor;
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    
    if (region)
    {
        x = region.x * scale;
        y = region.y * scale;
        width = region.width * scale;
        height = region.height * scale;
    }
    else
    {
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
    }
    
    width  = MAX(width,  1);
    height = MAX(height, 1);
    
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
                    CGSize sizeInPoints = CGSizeMake(width / scale, height / scale);
                    UIGraphicsBeginImageContextWithOptions(sizeInPoints, NO, scale);
                    {
                        CGRect rect = CGRectMake(0, 0, sizeInPoints.width, sizeInPoints.height);
                        CGContextRef context = UIGraphicsGetCurrentContext();
                        
                        CGContextClearRect(context, rect);
                        CGContextSetBlendMode(context, kCGBlendModeCopy);
                        
                        if (_renderTexture)
                        {
                            CGContextTranslateCTM(context, 0.0f, sizeInPoints.height);
                            CGContextScaleCTM(context, 1, -1);
                        }
                        
                        CGContextDrawImage(context, rect, cgImage);
                        
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
    [self setRenderToBackBuffer];
    
    [_backBuffer present];
}

- (void)setRenderToBackBuffer
{
    [self setRenderToTexture:nil enableDepthAndStencil:_depthAndStencilEnabled];
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
        
        [frameBuffer affirmWithAntiAliasing:0 enableDepthAndStencil:enableDepthAndStencil];
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
    
    [frameBuffer bind];
    
    if (enableDepthAndStencil)
    {
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_STENCIL_TEST);
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
