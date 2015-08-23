//
//  SPMacros.h
//  Sparrow
//
//  Created by Daniel Sperl on 15.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <math.h>

// typedefs

typedef void (^SPCallbackBlock)();
typedef unsigned char uchar;

// constants

#define PI                          3.14159265359f
#define PI_HALF                     1.57079632679f
#define TWO_PI                      6.28318530718f

#define SP_FLOAT_EPSILON            0.0001f
#define SP_MAX_DISPLAY_TREE_DEPTH   32

// colors

SP_EXTERN const uint SPColorWhite;
SP_EXTERN const uint SPColorSilver;
SP_EXTERN const uint SPColorGray;
SP_EXTERN const uint SPColorBlack;
SP_EXTERN const uint SPColorRed;
SP_EXTERN const uint SPColorMaroon;
SP_EXTERN const uint SPColorYellow;
SP_EXTERN const uint SPColorOlive;
SP_EXTERN const uint SPColorLime;
SP_EXTERN const uint SPColorGreen;
SP_EXTERN const uint SPColorAqua;
SP_EXTERN const uint SPColorTeal;
SP_EXTERN const uint SPColorBlue;
SP_EXTERN const uint SPColorNavy;
SP_EXTERN const uint SPColorFuchsia;
SP_EXTERN const uint SPColorPurple;

// helpers

SP_INLINE uint SPHashInt(uint value)
{
    value = (value+0x7ed55d16) + (value<<12);
    value = (value^0xc761c23c) ^ (value>>19);
    value = (value+0x165667b1) + (value<<5);
    value = (value+0xd3a2646c) ^ (value<<9);
    value = (value+0xfd7046c5) + (value<<3);
    value = (value^0xb55a4f09) ^ (value>>16);
    return value;
}

SP_INLINE uint SPHashFloat(float value)
{
    union { float f; int i; } converter = { .f = value };
    return converter.i & 0xffffff00; // mask for epsilon
}

SP_INLINE uint SPHashPointer(void *ptr)
{
  #ifdef __LP64__
    return (uint)(((uintptr_t)ptr) >> 3);
  #else
    return ((uintptr_t)ptr) >> 2;
  #endif
}

SP_INLINE uint SPShiftAndRotate(uint value, int shift)
{
    return (value << 1) | (value >> ((sizeof(uint) * CHAR_BIT) - shift));
}

SP_INLINE int SPSign(int value)
{
    if (value > 0)      return  1;
    else if (value < 0) return -1;
    else                return  0;
}

// macros

#define SP_CLAMP(value, min, max)   MIN((max), MAX((value), (min)))
#define SP_SWAP(x, y, T)            do { T temp##x##y = x; x = y; y = temp##x##y; } while (0)
#define SP_SQUARE(x)                ((x)*(x))

SP_INLINE float SPRandomFloat()
{
    return (float) arc4random() / UINT_MAX;
}

SP_INLINE float SPRad2Deg(float rad)
{
    return rad / PI * 180.0f;
}

SP_INLINE float SPDeg2Rad(float deg)
{
    return deg / 180.0f * PI;
}

SP_INLINE uint SPColorMake(uchar r, uchar g, uchar b)
{
    return ((int)(r) << 16) | ((int)(g) << 8) | (int)(b);
}

SP_INLINE uint SPColorMakeARGB(uchar a, uchar r, uchar g, uchar b)
{
    return ((int)(a) << 24) | ((int)(r) << 16) | ((int)(g) << 8) | (int)(b);
}

SP_INLINE uchar SPColorGetAlpha(uint color)
{
    return ((color) >> 24) & 0xff;
}

SP_INLINE uchar SPColorGetRed(uint color)
{
    return ((color) >> 16) & 0xff;
}

SP_INLINE uchar SPColorGetGreen(uint color)
{
    return ((color) >>  8) & 0xff;
}

SP_INLINE uchar SPColorGetBlue(uint color)
{
    return  (color)        & 0xff;
}

SP_INLINE BOOL SPIsFloatEqual(float a, float b)
{
    return fabsf(a-b) < SP_FLOAT_EPSILON;
}

SP_INLINE float SPClamp(float value, float min, float max)
{
    return MIN(max, MAX(value, min));
}

SP_INLINE float SPSquare(float x)
{
    return x*x;
}

// logging

#define SPLog(...) \
    _SPLog(__PRETTY_FUNCTION__, __VA_ARGS__)

SP_INLINE void _SPLog(const char *function, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSLogv([NSString stringWithFormat:@"[Sparrow] '%s' %@", function, format], args);
    va_end(args);
}

// checks

#define SP_USE_DESIGNATED_INITIALIZER(DESIGNATED_INITIALIZER) \
    @throw [NSException exceptionWithName:SPExceptionInvalidOperation \
                                   reason:[NSString stringWithFormat:@"[%p %@] Use the designated initializer.", \
                                          self, \
                                          NSStringFromSelector(@selector(DESIGNATED_INITIALIZER))] \
                                          userInfo:nil]

#if DEBUG
    #define SP_ABSTRACT_CLASS_INITIALIZER(aClass) \
        if ([self isMemberOfClass:[aClass class]]) \
        { \
            @throw [NSException exceptionWithName:SPExceptionInvalidOperation \
                                           reason:[NSString stringWithFormat:@"[%p %@] Attempting to initialize abstract class.", \
                                                  self, \
                                                  NSStringFromClass([aClass class])] \
                                                  userInfo:nil]; \
            return nil; \
        }
#else
    #define SP_ABSTRACT_CLASS_INITIALIZER(aClass)
#endif

#define SP_STATIC_CLASS_INITIALIZER() \
    @throw [NSException exceptionWithName:SPExceptionInvalidOperation \
                                   reason:[NSString stringWithFormat:@"[%p %@] Static class - do not initialize!", \
                                          self, \
                                          NSStringFromClass([self class])] \
                                          userInfo:nil]

// release and set value to nil

#if __has_feature(objc_arc)
    #define SP_RELEASE_AND_NIL(_var)            \
        _var = nil                              \

#else
    #define SP_RELEASE_AND_NIL(_var)            \
        do {                                    \
            [_var release];                     \
            _var = nil;                         \
        }                                       \
        while (0)                               \

#endif

// release old and retain new

#if __has_feature(objc_arc)
    #define SP_RELEASE_AND_RETAIN(_old, _new)   \
        _old = _new                             \

#else
    #define SP_RELEASE_AND_RETAIN(_old, _new)   \
        do {                                    \
            if (_old == _new) break;            \
            id tmp = _old;                      \
            _old = [_new retain];               \
            [tmp release];                      \
        }                                       \
        while (0)                               \

#endif

// release old and copy new

#if __has_feature(objc_arc)
    #define SP_RELEASE_AND_COPY(_old, _new)     \
        _old = [_new copy]                      \

#else
    #define SP_RELEASE_AND_COPY(_old, _new)     \
        do {                                    \
            id tmp = _old;                      \
            _old = [_new copy];                 \
            [tmp release];                      \
        }                                       \
        while (0)                               \

#endif

#if __has_feature(objc_arc)
    #define SP_RELEASE_AND_COPY_MUTABLE(_old, _new)     \
        _old = [_new mutableCopy]                       \

#else
    #define SP_RELEASE_AND_COPY_MUTABLE(_old, _new)     \
        do {                                            \
            id tmp = _old;                              \
            _old = [_new mutableCopy];                  \
            [tmp release];                              \
        }                                               \
        while (0)                                       \

#endif

// autorelase value

#if __has_feature(objc_arc)
    #define SP_AUTORELEASE(_value)              \
        _value                                  \

#else
    #define SP_AUTORELEASE(_value)              \
        [_value autorelease]                    \

#endif
