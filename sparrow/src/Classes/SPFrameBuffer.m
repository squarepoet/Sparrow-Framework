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

#import "SPContext.h"
#import "SPFrameBuffer.h"
#import "SPGLTexture.h"
#import "SPOpenGL.h"

@implementation SPFrameBuffer
{
  @package
    SPContext *__weak _context;
    SPGLTexture *__weak _texture;
    id<EAGLDrawable> _drawable;
    
    int _width;
    int _height;
    
    uint _frameBuffer;
    uint _colorRenderBuffer;
    uint _depthStencilRenderBuffer;
    uint _msaaFrameBuffer;
    uint _msaaColorRenderBuffer;
}

- (instancetype)initWithContext:(SPContext *)context texture:(SPGLTexture *)texture
{
    if (self = [super init])
    {
        _context = context;
        _texture = texture;
        _width = texture.nativeWidth;
        _height = texture.nativeHeight;
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
    [(id)_drawable release];
    [super dealloc];
}

- (void)reset
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindFramebuffer(GL_RENDERBUFFER, 0);
    
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
}

- (void)bind
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _width, _height);
}

- (void)present
{
    if (_drawable)
    {
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
        [_context.nativeContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (void)affirmWithAntiAliasing:(NSInteger)antiAlias enableDepthAndStencil:(BOOL)enableDepthAndStencil
{
    if (!_frameBuffer || (enableDepthAndStencil && !_depthStencilRenderBuffer))
    {
        if (!_frameBuffer)
        {
            glGenFramebuffers(1, &_frameBuffer);
            glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
            if (_texture)
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture.name, 0);
        }
        else
        {
            glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        }
        
        if (_drawable && !_colorRenderBuffer)
        {
            glGenRenderbuffers(1, &_colorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
            
            if (![_context.nativeContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_drawable])
            {
                SPLog(@"Could not create storage for drawable %@", _drawable);
                return [self reset];
            }
            
            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_width);
            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
        }
        
        if (_drawable && antiAlias && !_msaaFrameBuffer)
        {
            glGenFramebuffers(1, &_msaaFrameBuffer);
            glBindFramebuffer(GL_FRAMEBUFFER, _msaaFrameBuffer);
            
            glGenRenderbuffers(1, &_msaaColorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, _msaaColorRenderBuffer);
            
            glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, (int)antiAlias, GL_RGBA8_OES, _width, _height);
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
                glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, (int)antiAlias, GL_DEPTH24_STENCIL8_OES, _width, _height);
            else
                glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _width, _height);
        }
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            SPLog(@"failed to create a framebuffer for texture.");
            return [self reset];
        }
    }
}

- (uint)name
{
    return _frameBuffer;
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
