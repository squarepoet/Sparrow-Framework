//
//  SPTweenedProperty.m
//  Sparrow
//
//  Created by Daniel Sperl on 17.10.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPTweenedProperty.h"

#import <objc/runtime.h>
#import <objc/message.h>

#define HINT_MARKER @"#"

typedef float              (*FnPtrGetterF)   (id, SEL);
typedef double             (*FnPtrGetterD)   (id, SEL);
typedef int                (*FnPtrGetterI)   (id, SEL);
typedef uint               (*FnPtrGetterUI)  (id, SEL);
typedef long               (*FnPtrGetterL)   (id, SEL);
typedef unsigned long      (*FnPtrGetterUL)  (id, SEL);
typedef long long          (*FnPtrGetterLL)  (id, SEL);
typedef unsigned long long (*FnPtrGetterULL) (id, SEL);

typedef void (*FnPtrSetterF)   (id, SEL, float);
typedef void (*FnPtrSetterD)   (id, SEL, double);
typedef void (*FnPtrSetterI)   (id, SEL, int);
typedef void (*FnPtrSetterUI)  (id, SEL, uint);
typedef void (*FnPtrSetterL)   (id, SEL, long);
typedef void (*FnPtrSetterUL)  (id, SEL, unsigned long);
typedef void (*FnPtrSetterLL)  (id, SEL, long long);
typedef void (*FnPtrSetterULL) (id, SEL, unsigned long long);

typedef void  (*FnPtrUpdate)     (id, SEL, double);

@implementation SPTweenedProperty
{
    id  _target;
    NSString *_name;
    
    SEL _getter;
    IMP _getterFunc;
    SEL _setter;
    IMP _setterFunc;
    
    double _startValue;
    double _endValue;
    char  _numericType;
    
    BOOL _roundToInt;
    SEL _update;
    IMP _updateFunc;
}

- (instancetype)initWithTarget:(id)target name:(NSString *)name endValue:(double)endValue
{
    if ((self = [super init]))
    {
        _target = [target retain];
        _endValue = endValue;
        _name = [[self nameOfProperty:name] retain];
        
        _getter = NSSelectorFromString(name);
        _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", 
                                        [[name substringToIndex:1] uppercaseString],
                                        [name substringFromIndex:1]]);
        
        if (![_target respondsToSelector:_getter] || ![_target respondsToSelector:_setter])
            [NSException raise:SPExceptionInvalidOperation format:@"property not found or readonly: '%@'", 
             name];    
        
        // query argument type
        NSMethodSignature *sig = [_target methodSignatureForSelector:_getter];
        _numericType = *[sig methodReturnType];    
        if (_numericType != 'f' && _numericType != 'i' && _numericType != 'd' && _numericType != 'I'
             && _numericType != 'l' && _numericType != 'L' && _numericType != 'q' && _numericType != 'Q')
            [NSException raise:SPExceptionInvalidOperation format:@"property not numeric: '%@'", name];
        
        _getterFunc = [_target methodForSelector:_getter];
        _setterFunc = [_target methodForSelector:_setter];
        
        NSString *hint = [self hintOfProperty:name];
        if (!hint)
        {
            _update = @selector(updateStandard:);
            _updateFunc = class_getMethodImplementation([self class], _update);
        }
        else if ([hint isEqualToString:@"rgb"])
        {
            _update = @selector(updateRgb:);
            _updateFunc = class_getMethodImplementation([self class], _update);
        }
        else if ([hint isEqualToString:@"rad"])
        {
            _update = @selector(updateRad:);
            _updateFunc = class_getMethodImplementation([self class], _update);
        }
        else if ([hint isEqualToString:@"deg"])
        {
            _update = @selector(updateDeg:);
            _updateFunc = class_getMethodImplementation([self class], _update);
        }
        else
        {
            SPLog(@"Ignoring unknown property hint:", hint);
            _update = @selector(updateStandard:);
            _updateFunc = class_getMethodImplementation([self class], _update);
        }
    }
    return self;
}

- (instancetype)init
{
    [self release];
    return nil;
}

- (void)dealloc
{
    [_target release];
    [_name release];
    [super dealloc];
}

- (void)update:(double)progress
{
    ((FnPtrUpdate)_updateFunc)(self, _update, progress);
}

- (NSString *)hintOfProperty:(NSString *)property
{
    // colorization is special; it does not require a hint marker, just the word 'color'.
    if ([property containsString:@"color"] || [property containsString:@"Color"])
        return @"rgb";
    
    NSRange hintMarkerIndex = [property rangeOfString:HINT_MARKER];
    if (hintMarkerIndex.location != NSNotFound)
        return [property substringFromIndex:hintMarkerIndex.location+1];
    else
        return nil;
}

- (NSString *)nameOfProperty:(NSString *)property
{
    NSRange hintMarkerIndex = [property rangeOfString:HINT_MARKER];
    
    if (hintMarkerIndex.location != NSNotFound)
        return [property substringToIndex:hintMarkerIndex.location];
    else
        return property;
}

- (void)updateStandard:(double)progress
{
    double newValue = _startValue + progress * (_endValue - _startValue);
    if (_roundToInt) newValue = round(newValue);
    self.currentValue = newValue;
}

- (void)updateRgb:(double)progress
{
    uint startColor = (uint)(_startValue);
    uint endColor   = (uint)(_endValue);
    
    int startA = (startColor >> 24) & 0xff;
    int startR = (startColor >> 16) & 0xff;
    int startG = (startColor >>  8) & 0xff;
    int startB = (startColor      ) & 0xff;
    
    int endA = (endColor >> 24) & 0xff;
    int endR = (endColor >> 16) & 0xff;
    int endG = (endColor >>  8) & 0xff;
    int endB = (endColor      ) & 0xff;
    
    int newA = (int)SPClamp(startA + (endA - startA) * progress, 0, 255);
    int newR = (int)SPClamp(startR + (endR - startR) * progress, 0, 255);
    int newG = (int)SPClamp(startG + (endG - startG) * progress, 0, 255);
    int newB = (int)SPClamp(startB + (endB - startB) * progress, 0, 255);
    
    self.currentValue = (newA << 24) | (newR << 16) | (newG << 8) | newB;
}

- (void)updateRad:(double)progress
{
    [self updateAngle:progress pi:180];
}

- (void)updateDeg:(double)progress
{
    [self updateAngle:progress pi:180];
}

- (void)updateAngle:(double)progress pi:(double)pi
{
    while (fabs(_endValue - _startValue) > pi)
    {
        if (_startValue < _endValue) _endValue -= 2.0 * pi;
        else                         _endValue += 2.0 * pi;
    }
    
    [self updateStandard:progress];
}

#pragma mark Properties

- (void)setCurrentValue:(double)value
{
    if (_numericType == 'f')
    {
        FnPtrSetterF func = (FnPtrSetterF)_setterFunc;
        func(_target, _setter, (float)value);
    }        
    else if (_numericType == 'd')
    {
        FnPtrSetterD func = (FnPtrSetterD)_setterFunc;
        func(_target, _setter, value);
    }
    else if (_numericType == 'I')
    {
        FnPtrSetterUI func = (FnPtrSetterUI)_setterFunc;
        func(_target, _setter, (int)value);
    }
    else if (_numericType == 'i')
    {
        FnPtrSetterI func = (FnPtrSetterI)_setterFunc;
        func(_target, _setter, (int)(value > 0 ? value+0.5f : value-0.5f));
    }
    else if (_numericType == 'L')
    {
        FnPtrSetterUL func = (FnPtrSetterUL)_setterFunc;
        func(_target, _setter, (unsigned long)value);
    }
    else if (_numericType == 'l')
    {
        FnPtrSetterL func = (FnPtrSetterL)_setterFunc;
        func(_target, _setter, (long)(value > 0 ? value+0.5f : value-0.5f));
    }
    else if (_numericType == 'Q')
    {
        FnPtrSetterULL func = (FnPtrSetterULL)_setterFunc;
        func(_target, _setter, (unsigned long long)value);
    }
    else
    {
        FnPtrSetterLL func = (FnPtrSetterLL)_setterFunc;
        func(_target, _setter, (long long)(value > 0 ? value+0.5f : value-0.5f));
    }
}

- (double)currentValue
{
    if (_numericType == 'f')
    {
        FnPtrGetterF func = (FnPtrGetterF)_getterFunc;
        return func(_target, _getter);
    }
    else if (_numericType == 'd')
    {
        FnPtrGetterD func = (FnPtrGetterD)_getterFunc;
        return func(_target, _getter);
    }
    else if (_numericType == 'I')
    {
        FnPtrGetterUI func = (FnPtrGetterUI)_getterFunc;
        return func(_target, _getter);
    }
    else if (_numericType == 'i')
    {
        FnPtrGetterI func = (FnPtrGetterI)_getterFunc;
        return func(_target, _getter);
    }
    else if (_numericType == 'L')
    {
        FnPtrGetterUL func = (FnPtrGetterUL)_getterFunc;
        return func(_target, _getter);
    }
    else if (_numericType == 'l')
    {
        FnPtrGetterL func = (FnPtrGetterL)_getterFunc;
        return func(_target, _getter);
    }
    else if (_numericType == 'Q')
    {
        FnPtrGetterULL func = (FnPtrGetterULL)_getterFunc;
        return func(_target, _getter);
    }
    else
    {
        FnPtrGetterLL func = (FnPtrGetterLL)_getterFunc;
        return func(_target, _getter);
    }
}

- (double)delta
{
    return _endValue - _startValue;
}

@end
