//
//  SPTweenedProperty.m
//  Sparrow
//
//  Created by Daniel Sperl on 17.10.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPMacros.h"
#import "SPTweenedProperty.h"

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

@implementation SPTweenedProperty
{
    id  _target;
    
    SEL _getter;
    IMP _getterFunc;
    SEL _setter;
    IMP _setterFunc;
    
    float _startValue;
    float _endValue;
    char  _numericType;
}

- (instancetype)initWithTarget:(id)target name:(NSString *)name endValue:(float)endValue
{
    if ((self = [super init]))
    {
        _target = [target retain];
        _endValue = endValue;
        
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
    [super dealloc];
}

- (void)setCurrentValue:(float)value
{
    if (_numericType == 'f')
    {
        FnPtrSetterF func = (FnPtrSetterF)_setterFunc;
        func(_target, _setter, value);
    }        
    else if (_numericType == 'd')
    {
        FnPtrSetterD func = (FnPtrSetterD)_setterFunc;
        func(_target, _setter, (double)value);
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

- (float)currentValue
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

- (float)delta
{
    return _endValue - _startValue;
}

@end
