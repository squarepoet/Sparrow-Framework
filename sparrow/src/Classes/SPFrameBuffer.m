//
//  SPFrameBuffer.m
//  Sparrow
//
//  Created by Robert Carone on 8/24/15.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPContext.h"
#import "SPFrameBuffer.h"
#import "SPGLTexture.h"
#import "SPOpenGL.h"
#import "SPRectangle.h"

@implementation SPFrameBuffer
{
    SPContext *__weak _context;
    SPGLTexture *__weak _texture;
    id<EAGLDrawable> _drawable;
    
    int _width;
    int _height;
    int _antiAlias;
    
    BOOL _needsFinish;
    BOOL _enableDepthAndStencil;
    BOOL _shouldDestroyFrameBuffer;
    
    uint _frameBuffer;
    uint _colorRenderBuffer;
    uint _depthStencilRenderBuffer;
    uint _msaaFrameBuffer;
    uint _msaaColorRenderBuffer;
    uint _msaaDepthStencilRenderBuffer;
}

- (instancetype)initWithContext:(SPContext *)context texture:(SPGLTexture *)texture
{
    if (self = [super init])
    {
        _context = context;
        _texture = texture;
    }
    return self;
}

- (instancetype)initWithContext:(SPContext *)context drawable:(id<EAGLDrawable>)drawable
{
    if (self = [super init])
    {
        _context = context;
        _drawable = [(id)drawable retain];
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
    [(id)_drawable release];
    [super dealloc];
}

- (void)reset
{
    _shouldDestroyFrameBuffer = YES;
}

- (void)bind
{
    if (_shouldDestroyFrameBuffer)
        [self destroy];
    
    if (!_frameBuffer)
        [self create];
    
    if (_antiAlias)
        glBindFramebuffer(GL_FRAMEBUFFER, _msaaFrameBuffer);
    else
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glViewport(0, 0, _width, _height);
}

- (void)resolve
{
    if (_antiAlias)
    {
        SPExecuteWithDebugMarker("Resolve Framebuffer")
        {
            glBindFramebuffer(GL_READ_FRAMEBUFFER, _msaaFrameBuffer);
            glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _frameBuffer);
            
            if (_context.API == SPRenderingAPIOpenGLES3)
                glBlitFramebuffer(0, 0, _width, _height, 0, 0, _width, _height, GL_COLOR_BUFFER_BIT, GL_LINEAR);
            else
                glResolveMultisampleFramebufferAPPLE();
        }
    }
}

- (void)discard
{
    GLenum attachments[] = { GL_STENCIL_ATTACHMENT, GL_DEPTH_ATTACHMENT, GL_COLOR_ATTACHMENT0 };
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, _antiAlias ? 3 : 2, attachments);
}

- (void)present
{
    if (_drawable)
    {
        SPExecuteWithDebugMarker("Present Framebuffer")
        {
            [self resolve];
            [self discard];
            
            if (_needsFinish)
            {
                glFinish();
                _needsFinish = NO;
            }
            
            glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
            if (![_context.nativeContext presentRenderbuffer:GL_RENDERBUFFER])
                SPLog(@"Failed to present the renderbuffer.");
        }
    }
}

- (UIImage *)drawToImageInRegion:(SPRectangle *)region
{
    UIImage *uiImage = nil;
    float scale = _texture ? _texture.scale : Sparrow.currentController.contentScaleFactor;
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
        width  = _width;
        height = _height;
    }
    
    if (width < 1 || height < 1)
        return nil;
    
    GLubyte *pixels = malloc(4 * width * height);
    if (pixels)
    {
        SPExecuteWithDebugMarker("Read Framebuffer")
        {
            GLint prevPackAlignment;
            GLint bytesPerRow = 4 * width;
            
            GLint prevBoundFramebuffer = 0;
            glGetIntegerv(GL_FRAMEBUFFER, &prevBoundFramebuffer);
            
            if (_antiAlias) [self resolve];
            glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
            
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
                            
                            if (_texture)
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
            
            glBindFramebuffer(GL_FRAMEBUFFER, prevBoundFramebuffer);
        }
    }
    
    return [[uiImage retain] autorelease];
}

- (void)create
{
    SPExecuteWithDebugMarker("Create Framebuffer")
    {
        glGenFramebuffers(1, &_frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
        if (_texture)
        {
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture.name, 0);
            _width  = _texture.nativeWidth;
            _height = _texture.nativeHeight;
        }
        else if (_drawable)
        {
            [_drawable setDrawableProperties:@{
                                               kEAGLDrawablePropertyRetainedBacking : @NO,
                                               kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatRGBA8
                                               }];
            
            glGenRenderbuffers(1, &_colorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
            
            if (![_context.nativeContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_drawable])
            {
                SPLog(@"Could not create storage for drawable %@", _drawable);
                [self reset];
            }
            
            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,  &_width);
            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
            
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
        }
        
        if (_antiAlias)
        {
            glGenFramebuffers(1, &_msaaFrameBuffer);
            glBindFramebuffer(GL_FRAMEBUFFER, _msaaFrameBuffer);
            
            glGenRenderbuffers(1, &_msaaColorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, _msaaColorRenderBuffer);
            
            glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, _antiAlias, GL_RGBA8, _width, _height);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _msaaColorRenderBuffer);
        }
        
        if (_enableDepthAndStencil)
        {
            glGenRenderbuffers(1, &_depthStencilRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, _depthStencilRenderBuffer);
            
            if (_antiAlias)
                glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, _antiAlias, GL_DEPTH24_STENCIL8, _width, _height);
            else
                glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, _width, _height);
            
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,   GL_RENDERBUFFER, _depthStencilRenderBuffer);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _depthStencilRenderBuffer);
        }
        
        if (_antiAlias)
        {
            glBindFramebuffer(GL_FRAMEBUFFER, _msaaFrameBuffer);
            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            {
                SPLog(@"Failed to create multisample framebuffer [%d].", glCheckFramebufferStatus(GL_FRAMEBUFFER));
                [self reset];
            }
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            SPLog(@"Failed to create framebuffer [%d].", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            [self reset];
        }
    }
}

- (void)destroy
{
    _shouldDestroyFrameBuffer = NO;
    
    if (_frameBuffer)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if (_colorRenderBuffer)
    {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    
    if (_depthStencilRenderBuffer)
    {
        glDeleteRenderbuffers(1, &_depthStencilRenderBuffer);
        _depthStencilRenderBuffer = 0;
    }
    
    if (_msaaFrameBuffer)
    {
        glDeleteFramebuffers(1, &_msaaFrameBuffer);
        _msaaFrameBuffer = 0;
    }
    
    if (_msaaColorRenderBuffer)
    {
        glDeleteRenderbuffers(1, &_msaaColorRenderBuffer);
        _msaaColorRenderBuffer = 0;
    }
}

#pragma mark Properties

- (NSInteger)antiAlias
{
    return _antiAlias;
}

- (void)setAntiAlias:(NSInteger)antiAlias
{
    if (antiAlias != _antiAlias)
    {
        _antiAlias = (int)antiAlias;
        _shouldDestroyFrameBuffer = YES;
    }
}

- (void)setEnableDepthAndStencil:(BOOL)enableDepthAndStencil
{
    if (enableDepthAndStencil != _enableDepthAndStencil)
    {
        _enableDepthAndStencil = enableDepthAndStencil;
        _shouldDestroyFrameBuffer = YES;
    }
}

- (NSInteger)width
{
    return _width;
}

- (NSInteger)height
{
    return _height;
}

@end
