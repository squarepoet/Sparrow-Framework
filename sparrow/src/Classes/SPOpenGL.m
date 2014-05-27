//
//  SPOpenGL.m
//  Sparrow
//
//  Created by Robert Carone on 10/8/13.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SPOpenGL.h>

const GLchar* sglGetErrorString(GLenum error)
{
	switch (error)
    {
        case GL_NO_ERROR:                       return "GL_NO_ERROR";
		case GL_INVALID_ENUM:                   return "GL_INVALID_ENUM";
		case GL_INVALID_OPERATION:              return "GL_INVALID_OPERATION";
		case GL_INVALID_VALUE:                  return "GL_INVALID_VALUE";
		case GL_INVALID_FRAMEBUFFER_OPERATION:  return "GL_INVALID_FRAMEBUFFER_OPERATION";
		case GL_OUT_OF_MEMORY:                  return "GL_OUT_OF_MEMORY";
	}

	return "UNKNOWN_ERROR";
}

/** --------------------------------------------------------------------------------------------- */
#pragma mark - OpenGL State Cache
/** --------------------------------------------------------------------------------------------- */

#if SP_ENABLE_GL_STATE_CACHE

// undefine previous 'shims'

#undef glActiveTexture
#undef glBindBuffer
#undef glBindFramebuffer
#undef glBindRenderbuffer
#undef glBindTexture
#undef glBindVertexArray
#undef glBlendFunc
#undef glClearColor
#undef glCreateProgram
#undef glDeleteBuffers
#undef glDeleteFramebuffers
#undef glDeleteProgram
#undef glDeleteRenderbuffers
#undef glDeleteTextures
#undef glDeleteVertexArrays
#undef glDisable
#undef glEnable
#undef glGetIntegerv
#undef glLinkProgram
#undef glScissor
#undef glUseProgram
#undef glViewport

// redefine extension mappings

#define glBindVertexArray       glBindVertexArrayOES
#define glDeleteVertexArrays    glDeleteVertexArraysOES

// state definition

#define MAX_TEXTURE_UNITS   32
#define INVALID_STATE      -1

struct SGLState
{
    GLint   textureUnit;
    GLint   texture[MAX_TEXTURE_UNITS];
    GLint   program;
    GLint   framebuffer;
    GLint   renderbuffer;
    GLint   viewport[4];
    GLint   scissor[4];
    GLint   buffer[2];
    GLint   vertexArray;
    GLchar  enabledCaps[10];
    GLint   blendSrc;
    GLint   blendDst;
};

static SGLStateRef currentState = NULL;

/** --------------------------------------------------------------------------------------------- */
#pragma mark Internal
/** --------------------------------------------------------------------------------------------- */

SP_INLINE GLuint __sglGetIndexForCapability(GLuint cap)
{
    switch (cap)
    {
        case GL_BLEND:                      return 0;
        case GL_CULL_FACE:                  return 1;
        case GL_DEPTH_TEST:                 return 2;
        case GL_DITHER:                     return 3;
        case GL_POLYGON_OFFSET_FILL:        return 4;
        case GL_SAMPLE_ALPHA_TO_COVERAGE:   return 5;
        case GL_SAMPLE_COVERAGE:            return 6;
        case GL_SCISSOR_TEST:               return 7;
        case GL_STENCIL_TEST:               return 8;
        case GL_TEXTURE_2D:                 return 9;
    }
    return INVALID_STATE;
}

SP_INLINE GLenum __sglGetCapabilityForIndex(GLuint index)
{
    switch (index)
    {
        case 0: return GL_BLEND;
        case 1: return GL_CULL_FACE;
        case 2: return GL_DEPTH_TEST;
        case 3: return GL_DITHER;
        case 4: return GL_POLYGON_OFFSET_FILL;
        case 5: return GL_SAMPLE_ALPHA_TO_COVERAGE;
        case 6: return GL_SAMPLE_COVERAGE;
        case 7: return GL_SCISSOR_TEST;
        case 8: return GL_STENCIL_TEST;
        case 9: return GL_TEXTURE_2D;
    }
    return INVALID_STATE;
}

SP_INLINE void __sglGetChar(GLenum pname, GLchar* state, GLint* outParam)
{
    if (*state == INVALID_STATE)
    {
        GLint i;
        glGetIntegerv(pname, &i);
        *state = (GLchar)i;
    }

    *outParam = *state;
}

SP_INLINE void __sglGetInt(GLenum pname, GLint* state, GLint* outParam)
{
    if (*state == INVALID_STATE)
        glGetIntegerv(pname, state);

    *outParam = *state;
}

SP_INLINE void __sglGetIntv(GLenum pname, GLint count, GLint statev[], GLint* outParams)
{
    if (*statev == INVALID_STATE)
        glGetIntegerv(pname, statev);

    memcpy(outParams, statev, sizeof(GLint)*count);
}

SP_INLINE SGLStateRef __sglGetDefaultState(void)
{
    static SGLStateRef defaultState;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        defaultState = malloc(sizeof(struct SGLState));
        memset(defaultState, INVALID_STATE, sizeof(struct SGLState));
    });

    return defaultState;
}

SP_INLINE SGLStateRef __sglGetCurrentState(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentState = __sglGetDefaultState();
    });

    return currentState;
}

/** --------------------------------------------------------------------------------------------- */
#pragma mark State
/** --------------------------------------------------------------------------------------------- */

SGLStateRef sglCreateState(void)
{
    SGLStateRef newState = malloc(sizeof(struct SGLState));
    memset(newState, INVALID_STATE, sizeof(struct SGLState));
    return newState;
}

void sglDestroyState(SGLStateRef state)
{
    if (state == __sglGetCurrentState())
        return;

    if (!state || state == __sglGetDefaultState())
        return sglSetCurrentState(__sglGetDefaultState());

    free(state);
}

SGLStateRef sglCopyState(SGLStateRef state)
{
    SGLStateRef copyState = malloc(sizeof(struct SGLState));
    memcpy(copyState, state, sizeof(struct SGLState));
    return copyState;
}

void sglResetState(void)
{
    SGLStateRef currentState = __sglGetCurrentState();
    memset(currentState, INVALID_STATE, sizeof(*currentState));
}

void sglSetCurrentState(SGLStateRef state)
{
    if (!state)
        state = __sglGetDefaultState();

    if (state == __sglGetCurrentState())
        return;

    // don't alter the current state
    struct SGLState tempState = *currentState;
    currentState = &tempState;

    if (state->framebuffer != INVALID_STATE)
        sglBindFramebuffer(GL_FRAMEBUFFER, state->framebuffer);

    if (state->renderbuffer != INVALID_STATE)
        sglBindRenderbuffer(GL_RENDERBUFFER, state->renderbuffer);

    if (state->buffer[0] != INVALID_STATE)
        sglBindBuffer(GL_ARRAY_BUFFER, state->buffer[0]);

    if (state->buffer[1] != INVALID_STATE)
        sglBindBuffer(GL_ELEMENT_ARRAY_BUFFER, state->buffer[1]);

    if (state->vertexArray != INVALID_STATE)
        sglBindVertexArray(state->vertexArray);

    if (state->blendSrc != INVALID_STATE && state->blendDst != INVALID_STATE)
        sglBlendFunc(state->blendSrc, state->blendDst);

    if (state->program != INVALID_STATE)
        sglUseProgram(state->program);

    if (state->viewport[0] != INVALID_STATE &&
        state->viewport[1] != INVALID_STATE &&
        state->viewport[2] != INVALID_STATE &&
        state->viewport[3] != INVALID_STATE)
        sglViewport(state->viewport[0], state->viewport[1],
                    state->viewport[2], state->viewport[3]);

    if (state->scissor[0] != INVALID_STATE &&
        state->scissor[1] != INVALID_STATE &&
        state->scissor[2] != INVALID_STATE &&
        state->scissor[3] != INVALID_STATE)
        sglScissor(state->scissor[0], state->scissor[1],
                   state->scissor[2], state->scissor[3]);

    for (int i=0; i<32; ++i)
    {
        if (state->texture[i] != INVALID_STATE)
        {
            sglActiveTexture(GL_TEXTURE0 + i);
            sglBindTexture(GL_TEXTURE_2D, state->texture[i]);
        }
    }

    for (int i=0; i<10; ++i)
    {
        if (state->enabledCaps[i] == GL_TRUE)
            sglEnable(__sglGetCapabilityForIndex(i));
        else if (state->enabledCaps[i] == GL_FALSE)
            sglDisable(__sglGetCapabilityForIndex(i));
    }

    currentState = state;
}

/** --------------------------------------------------------------------------------------------- */
#pragma mark OpenGL
/** --------------------------------------------------------------------------------------------- */

void sglActiveTexture(GLenum texture)
{
    GLuint textureUnit = texture-GL_TEXTURE0;
    SGLStateRef currentState = __sglGetCurrentState();

    if (textureUnit != currentState->textureUnit)
    {
        currentState->textureUnit = textureUnit;
        glActiveTexture(texture);
    }
}

void sglBindBuffer(GLenum target, GLuint buffer)
{
    GLuint index = target-GL_ARRAY_BUFFER;
    SGLStateRef currentState = __sglGetCurrentState();

    if (buffer != currentState->buffer[index])
    {
        currentState->buffer[index] = buffer;
        glBindBuffer(target, buffer);
    }
}

void sglBindFramebuffer(GLenum target, GLuint framebuffer)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (framebuffer != currentState->framebuffer)
    {
        currentState->framebuffer = framebuffer;
        glBindFramebuffer(target, framebuffer);
    }
}

void sglBindRenderbuffer(GLenum target, GLuint renderbuffer)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (renderbuffer != currentState->renderbuffer)
    {
        currentState->renderbuffer = renderbuffer;
        glBindRenderbuffer(target, renderbuffer);
    }
}

void sglBindTexture(GLenum target, GLuint texture)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (currentState->textureUnit == INVALID_STATE)
        sglActiveTexture(GL_TEXTURE0);

    if (texture != currentState->texture[currentState->textureUnit])
    {
        currentState->texture[currentState->textureUnit] = texture;
        glBindTexture(target, texture);
    }
}

void sglBindVertexArray(GLuint array)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (array != currentState->vertexArray)
    {
        currentState->vertexArray = array;
        glBindVertexArray(array);
    }
}

void sglBlendFunc(GLenum sfactor, GLenum dfactor)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (sfactor != currentState->blendSrc || dfactor != currentState->blendDst)
    {
        currentState->blendSrc = sfactor;
        currentState->blendDst = dfactor;
        glBlendFunc(sfactor, dfactor);
    }
}

void sglDeleteBuffers(GLsizei n, const GLuint* buffers)
{
    SGLStateRef currentState = __sglGetCurrentState();
    for (int i=0; i<n; i++)
    {
        if (currentState->buffer[0] == buffers[i]) currentState->buffer[0] = INVALID_STATE;
        if (currentState->buffer[1] == buffers[i]) currentState->buffer[1] = INVALID_STATE;
    }

    glDeleteBuffers(n, buffers);
}

void sglDeleteFramebuffers(GLsizei n, const GLuint* framebuffers)
{
    SGLStateRef currentState = __sglGetCurrentState();
    for (int i=0; i<n; i++)
    {
        if (currentState->framebuffer == framebuffers[i])
            currentState->framebuffer = INVALID_STATE;
    }

    glDeleteFramebuffers(n, framebuffers);
}

void sglDeleteProgram(GLuint program)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (currentState->program == program)
        currentState->program = INVALID_STATE;

    glDeleteProgram(program);
}

void sglDeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers)
{
    SGLStateRef currentState = __sglGetCurrentState();
    for (int i=0; i<n; i++)
    {
        if (currentState->renderbuffer == renderbuffers[i])
            currentState->renderbuffer = INVALID_STATE;
    }

    glDeleteRenderbuffers(n, renderbuffers);
}

void sglDeleteTextures(GLsizei n, const GLuint* textures)
{
    SGLStateRef currentState = __sglGetCurrentState();
    for (int i=0; i<n; i++)
    {
        for (int j=0; j<32; j++)
        {
            if (currentState->texture[j] == textures[i])
                currentState->texture[j] = INVALID_STATE;
        }
    }

    glDeleteTextures(n, textures);
}

void sglDeleteVertexArrays(GLsizei n, const GLuint* arrays)
{
    SGLStateRef currentState = __sglGetCurrentState();
    for (int i=0; i<n; i++)
    {
        if (currentState->vertexArray == arrays[i])
            currentState->vertexArray = INVALID_STATE;
    }

    glDeleteVertexArrays(n, arrays);
}

void sglDisable(GLenum cap)
{
    SGLStateRef currentState = __sglGetCurrentState();
    GLuint index = __sglGetIndexForCapability(cap);

    if (currentState->enabledCaps[index] != GL_FALSE)
    {
        currentState->enabledCaps[index] = GL_FALSE;
        glDisable(cap);
    }
}

void sglEnable(GLenum cap)
{
    SGLStateRef currentState = __sglGetCurrentState();
    GLuint index = __sglGetIndexForCapability(cap);

    if (currentState->enabledCaps[index] != GL_TRUE)
    {
        currentState->enabledCaps[index] = GL_TRUE;
        glEnable(cap);
    }
}

void sglGetIntegerv(GLenum pname, GLint* params)
{
    SGLStateRef currentState = __sglGetCurrentState();

    switch (pname)
    {
        case GL_BLEND:
        case GL_CULL_FACE:
        case GL_DEPTH_TEST:
        case GL_DITHER:
        case GL_POLYGON_OFFSET_FILL:
        case GL_SAMPLE_ALPHA_TO_COVERAGE:
        case GL_SAMPLE_COVERAGE:
        case GL_SCISSOR_TEST:
        case GL_STENCIL_TEST:
            __sglGetChar(pname, &currentState->enabledCaps[__sglGetIndexForCapability(pname)], params);
            return;

        case GL_ACTIVE_TEXTURE:
            __sglGetInt(pname, &currentState->textureUnit, params);
            return;

        case GL_ARRAY_BUFFER_BINDING:
            __sglGetInt(pname, &currentState->buffer[0], params);
            return;

        case GL_CURRENT_PROGRAM:
            __sglGetInt(pname, &currentState->program, params);
            return;

        case GL_ELEMENT_ARRAY_BUFFER_BINDING:
            __sglGetInt(pname, &currentState->buffer[1], params);
            return;

        case GL_FRAMEBUFFER_BINDING:
            __sglGetInt(pname, &currentState->framebuffer, params);
            return;

        case GL_RENDERBUFFER_BINDING:
            __sglGetInt(pname, &currentState->renderbuffer, params);
            return;

        case GL_SCISSOR_BOX:
            __sglGetIntv(pname, 4, currentState->scissor, params);
            return;

        case GL_TEXTURE_BINDING_2D:
            __sglGetInt(pname, &currentState->textureUnit, params);
            return;

        case GL_VERTEX_ARRAY_BINDING:
            __sglGetInt(pname, &currentState->vertexArray, params);
            return;

        case GL_VIEWPORT:
            __sglGetIntv(pname, 4, currentState->viewport, params);
            return;
    }

    glGetIntegerv(pname, params);
}

void sglScissor(GLint x, GLint y, GLsizei width, GLsizei height)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (x      != currentState->scissor[0] ||
        y      != currentState->scissor[1] ||
        width  != currentState->scissor[2] ||
        height != currentState->scissor[3])
    {
        currentState->scissor[0] = x;
        currentState->scissor[1] = y;
        currentState->scissor[2] = width;
        currentState->scissor[3] = height;

        glScissor(x, y, width, height);
    }
}

void sglUseProgram(GLuint program)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (program != currentState->program)
    {
        currentState->program = program;
        glUseProgram(program);
    }
}

void sglViewport(GLint x, GLint y, GLsizei width, GLsizei height)
{
    SGLStateRef currentState = __sglGetCurrentState();
    if (width  != currentState->viewport[2] ||
        height != currentState->viewport[3] ||
        x      != currentState->viewport[0] ||
        y      != currentState->viewport[1])
    {
        currentState->viewport[0] = x;
        currentState->viewport[1] = y;
        currentState->viewport[2] = width;
        currentState->viewport[3] = height;
        
        glViewport(x, y, width, height);
    }
}

#else // !SP_ENABLE_GL_STATE_CACHE

SGLStateRef sglCreateState(void)                            { return NULL; }
void        sglDestroyState(SGLStateRef state __unused)     {}
SGLStateRef sglCopyState(SGLStateRef state __unused)        { return NULL; }
void        sglResetState(void)                             {}
void        sglSetCurrentState(SGLStateRef state __unused)  {}

#endif // SP_ENABLE_GL_STATE_CACHE
