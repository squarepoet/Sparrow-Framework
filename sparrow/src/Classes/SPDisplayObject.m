//
//  SPDisplayObject.m
//  Sparrow
//
//  Created by Daniel Sperl on 15.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"
#import "SPBlendMode.h"
#import "SPDisplayObject_Internal.h"
#import "SPDisplayObjectContainer.h"
#import "SPEnterFrameEvent.h"
#import "SPEventDispatcher_Internal.h"
#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPMatrix3D.h"
#import "SPPoint.h"
#import "SPRectangle.h"
#import "SPStage_Internal.h"
#import "SPTouchEvent.h"
#import "SPVector3D.h"

// --- class implementation ------------------------------------------------------------------------

@implementation SPDisplayObject
{
    float _x;
    float _y;
    float _pivotX;
    float _pivotY;
    float _scaleX;
    float _scaleY;
    float _skewX;
    float _skewY;
    float _rotation;
    float _alpha;
    uint _blendMode;
    BOOL _visible;
    BOOL _touchable;
    BOOL _orientationChanged;
    BOOL _is3D;
    
    SPDisplayObjectContainer *__weak _parent;
    SPMatrix *_transformationMatrix;
    double _lastTouchTimestamp;
    NSString *_name;
    SPFragmentFilter *_filter;
    id _physicsBody;
    
    SPDisplayObject *_mask;
    BOOL _isMask;
}

// --- helpers -------------------------------------------------------------------------------------

static SPDisplayObject *findCommonParent(SPDisplayObject *object1, SPDisplayObject *object2)
{
    // This method is used very often during touch testing, so we optimized the code.
    // Instead of using an NSSet or NSArray (which would make the code much cleaner), we
    // use a C array here to save the ancestors.
    
    SPDisplayObject *ancestors[SP_MAX_DISPLAY_TREE_DEPTH];
    
    int count = 0;
    SPDisplayObject *commonParent = nil;
    SPDisplayObject *currentObject = object1;
    while (currentObject && count < SP_MAX_DISPLAY_TREE_DEPTH)
    {
        ancestors[count++] = currentObject;
        currentObject = currentObject->_parent;
    }
    
    currentObject = object2;
    while (currentObject && !commonParent)
    {
        for (int i=0; i<count; ++i)
        {
            if (currentObject == ancestors[i])
            {
                commonParent = ancestors[i];
                break;
            }
        }
        currentObject = currentObject->_parent;
    }
    
    if (!commonParent)
        [NSException raise:SPExceptionNotRelated format:@"Object not connected to target"];
    
    return commonParent;
}

#pragma mark Initialization

- (instancetype)init
{
    SP_ABSTRACT_CLASS_INITIALIZER(SPDisplayObject);
    
    if ((self = [super init]))
    {
        _alpha = 1.0f;
        _scaleX = 1.0f;
        _scaleY = 1.0f;
        _visible = YES;
        _touchable = YES;
        _transformationMatrix = [[SPMatrix alloc] init];
        _orientationChanged = NO;
        _blendMode = SPBlendModeAuto;
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [_filter release];
    [_physicsBody release];
    [_transformationMatrix release];
    [_mask release];
    [super dealloc];
}

#pragma mark Methods

- (void)render:(SPRenderSupport *)support
{
    // override in subclass
}

- (void)removeFromParent
{
    [_parent removeChild:self];
}

- (void)alignPivotToCenter
{
    [self alignPivotX:SPHAlignCenter pivotY:SPVAlignCenter];
}

- (void)alignPivotX:(SPHAlign)hAlign pivotY:(SPVAlign)vAlign
{
    SPRectangle* bounds = [self boundsInSpace:self];
    _orientationChanged = YES;

    switch (hAlign)
    {
        case SPHAlignLeft:   _pivotX = bounds.x;                      break;
        case SPHAlignCenter: _pivotX = bounds.x + bounds.width / 2.0; break;
        case SPHAlignRight:  _pivotX = bounds.x + bounds.width;       break;
        default:
            [NSException raise:SPExceptionInvalidOperation
                        format:@"Invalid horizontal alignment"];
    }

    switch (vAlign)
    {
        case SPVAlignTop:    _pivotY = bounds.y;                       break;
        case SPVAlignCenter: _pivotY = bounds.y + bounds.height / 2.0; break;
        case SPVAlignBottom: _pivotY = bounds.y + bounds.height;       break;
        default:
            [NSException raise:SPExceptionInvalidOperation
                        format:@"Invalid vertical alignment"];
    }
}

- (SPMatrix *)transformationMatrixToSpace:(SPDisplayObject *)targetSpace
{           
    if (targetSpace == self)
    {
        return [SPMatrix matrixWithIdentity];
    }
    else if (targetSpace == _parent || (!targetSpace && !_parent))
    {
        return [[self.transformationMatrix copy] autorelease];
    }
    else if (!targetSpace || targetSpace == self.base)
    {
        // targetSpace 'nil' represents the target coordinate of the base object.
        // -> move up from self to base
        SPMatrix *selfMatrix = [SPMatrix matrixWithIdentity];
        SPDisplayObject *currentObject = self;
        while (currentObject != targetSpace)
        {
            [selfMatrix appendMatrix:currentObject.transformationMatrix];
            currentObject = currentObject->_parent;
        }        
        return selfMatrix; 
    }
    else if (targetSpace->_parent == self)
    {
        SPMatrix *targetMatrix = [[targetSpace.transformationMatrix copy] autorelease];
        [targetMatrix invert];
        return targetMatrix;
    }
    
    // 1.: Find a common parent of self and the target coordinate space.
    SPDisplayObject *commonParent = findCommonParent(self, targetSpace);
    
    // 2.: Move up from self to common parent
    SPMatrix *selfMatrix = [SPMatrix matrixWithIdentity];
    SPDisplayObject *currentObject = self;
    while (currentObject != commonParent)
    {
        [selfMatrix appendMatrix:currentObject.transformationMatrix];
        currentObject = currentObject->_parent;
    }
    
    // 3.: Now move up from target until we reach the common parent
    SPMatrix *targetMatrix = [SPMatrix matrixWithIdentity];
    currentObject = targetSpace;
    while (currentObject && currentObject != commonParent)
    {
        [targetMatrix appendMatrix:currentObject.transformationMatrix];
        currentObject = currentObject->_parent;
    }    
    
    // 4.: Combine the two matrices
    [targetMatrix invert];
    [selfMatrix appendMatrix:targetMatrix];
    
    return selfMatrix;
}

- (SPMatrix3D *)transformationMatrix3DToSpace:(nullable SPDisplayObject *)targetSpace
{
    if (targetSpace == self)
    {
        return [SPMatrix3D matrix3DWithIdentity];
    }
    else if (targetSpace == _parent || (!targetSpace && !_parent))
    {
        return [[self.transformationMatrix3D copy] autorelease];
    }
    else if (!targetSpace || targetSpace == self.base)
    {
        // targetSpace 'nil' represents the target coordinate of the base object.
        // -> move up from self to base
        SPMatrix3D *selfMatrix = [SPMatrix3D matrix3DWithIdentity];
        SPDisplayObject *currentObject = self;
        while (currentObject != targetSpace)
        {
            [selfMatrix appendMatrix:currentObject.transformationMatrix3D];
            currentObject = currentObject->_parent;
        }
        return selfMatrix;
    }
    else if (targetSpace->_parent == self)
    {
        SPMatrix3D *targetMatrix = [[targetSpace.transformationMatrix3D copy] autorelease];
        [targetMatrix invert];
        return targetMatrix;
    }
    
    // 1.: Find a common parent of self and the target coordinate space.
    SPDisplayObject *commonParent = findCommonParent(self, targetSpace);
    
    // 2.: Move up from self to common parent
    SPMatrix3D *selfMatrix = [SPMatrix3D matrix3DWithIdentity];
    SPDisplayObject *currentObject = self;
    while (currentObject != commonParent)
    {
        [selfMatrix appendMatrix:currentObject.transformationMatrix3D];
        currentObject = currentObject->_parent;
    }
    
    // 3.: Now move up from target until we reach the common parent
    SPMatrix3D *targetMatrix = [SPMatrix3D matrix3DWithIdentity];
    currentObject = targetSpace;
    while (currentObject && currentObject != commonParent)
    {
        [targetMatrix appendMatrix:currentObject.transformationMatrix3D];
        currentObject = currentObject->_parent;
    }
    
    // 4.: Combine the two matrices
    [targetMatrix invert];
    [selfMatrix appendMatrix:targetMatrix];
    
    return selfMatrix;
}

- (SPRectangle *)boundsInSpace:(SPDisplayObject *)targetSpace
{
    [NSException raise:SPExceptionAbstractMethod 
                format:@"Method 'boundsInSpace:' needs to be implemented in subclasses"];
    return nil;
}

- (SPDisplayObject *)hitTestPoint:(SPPoint *)localPoint
{
    return [self hitTestPoint:localPoint forTouch:NO];
}

- (SPDisplayObject *)hitTestPoint:(SPPoint *)localPoint forTouch:(BOOL)forTouch
{
    // invisible or untouchable objects cause the test to fail
    if (forTouch && (!_visible || !_touchable)) return nil;
    
    // if we've got a mask and the hit occurs outside, fail
    if (_mask && ![self hitTestMask:localPoint]) return nil;
    
    // otherwise, check bounding box
    if ([[self boundsInSpace:self] containsPoint:localPoint]) return self; 
    else return nil;
}

- (BOOL)hitTestMask:(SPPoint *)localPoint
{
    if (_mask)
    {
        SPMatrix *transformMatrix = nil;
        if (_mask.stage) transformMatrix = [self transformationMatrixToSpace:_mask];
        else
        {
            transformMatrix = [[_mask.transformationMatrix copy] autorelease];
            [transformMatrix invert];
        }
        
        SPPoint *transformedPoint = [transformMatrix transformPoint:localPoint];
        return [_mask hitTestPoint:transformedPoint forTouch:YES] != nil;
    }
    else return YES;
}

- (BOOL)hitTestObject:(SPDisplayObject *)object
{
    return [[self boundsInSpace:nil] intersectsRectangle:[object boundsInSpace:nil]];
}

- (SPPoint *)localToGlobal:(SPPoint *)localPoint
{
    if (_is3D)
    {
        return [self local3DToGlobal:[SPVector3D vector3DWithX:localPoint.x y:localPoint.y z:0.0f]];
    }
    else
    {
        SPMatrix *matrix = [self transformationMatrixToSpace:self.base];
        return [matrix transformPoint:localPoint];
    }
}

- (SPPoint *)globalToLocal:(SPPoint *)globalPoint
{
    if (_is3D)
    {
        SPVector3D *localVector = [self globalToLocal3D:globalPoint];
        return [localVector intersectWithXYPlane:self.stage.cameraPosition];
    }
    else
    {
        
        SPMatrix *matrix = [self transformationMatrixToSpace:self.base];
        [matrix invert];
        return [matrix transformPoint:globalPoint];
    }
}

- (SPPoint *)local3DToGlobal:(SPVector3D *)localPoint
{
    SPStage *stage = self.stage;
    if (stage == nil) [NSException raise:SPExceptionInvalidOperation format:@"object not connected to stage"];
    
    SPMatrix3D *matrix = [self transformationMatrix3DToSpace:stage];
    return [[matrix transformVector:localPoint] intersectWithXYPlane:stage.cameraPosition];
}

- (SPVector3D *)globalToLocal3D:(SPPoint *)globalPoint
{
    SPStage *stage = self.stage;
    if (stage == nil) [NSException raise:SPExceptionInvalidOperation format:@"object not connected to stage"];
    
    SPMatrix3D *matrix = [self transformationMatrix3DToSpace:stage];
    [matrix invert];
    return [matrix transformVectorWithX:globalPoint.x y:globalPoint.y z:0];
}

- (void)broadcastEvent:(SPEvent *)event
{
    if (event.bubbles)
        [NSException raise:SPExceptionInvalidOperation
                    format:@"Broadcast of bubbling events is prohibited"];

    [self dispatchEvent:event];
}

- (void)broadcastEventWithType:(NSString *)type
{
    [self dispatchEventWithType:type];
}

#pragma mark NSCopying

- (instancetype)copy
{
    SPDisplayObject *object = [[[self class] alloc] init];
    
    object->_is3D = _is3D;
    object->_isMask = _isMask;
    object.x = self.x;
    object.y = self.y;
    object.pivotX = self.pivotX;
    object.pivotY = self.pivotY;
    object.scaleX = self.scaleX;
    object.scaleY = self.scaleY;
    
    if (!_is3D)
    {
        object.skewX = self.skewX;
        object.skewY = self.skewY;
    }
    
    object.rotation = self.rotation;
    object.alpha = self.alpha;
    object.visible = self.visible;
    object.touchable = self.touchable;
    object.name = self.name;
    object.filter = self.filter;
    object.mask = self.mask;
    object.blendMode = self.blendMode;
    object.physicsBody = self.physicsBody;
    
    return object;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self copy];
}

#pragma mark SPEventDispatcher

- (void)dispatchEvent:(SPEvent *)event
{
    // on one given moment, there is only one set of touches -- thus, 
    // we process only one touch event with a certain timestamp
    if ([event isKindOfClass:[SPTouchEvent class]])
    {
        SPTouchEvent *touchEvent = (SPTouchEvent *)event;
        if (touchEvent.timestamp == _lastTouchTimestamp) return;        
        else _lastTouchTimestamp = touchEvent.timestamp;
    }
    
    [super dispatchEvent:event];
}

// To avoid looping through the complete display tree each frame to find out who's listening to
// SPEventTypeEnterFrame events, we manage a list of them manually in the SPStage class.

- (void)addEventListener:(id)listener forType:(NSString *)eventType
{
    if ([eventType isEqualToString:SPEventTypeEnterFrame] && ![self hasEventListenerForType:SPEventTypeEnterFrame])
    {
        [self addEventListener:@selector(addEnterFrameListenerToStage) atObject:self forType:SPEventTypeAddedToStage];
        [self addEventListener:@selector(removeEnterFrameListenerFromStage) atObject:self forType:SPEventTypeRemovedFromStage];
        if (self.stage) [self addEnterFrameListenerToStage];
    }

    [super addEventListener:listener forType:eventType];
}

- (void)removeEventListenersForType:(NSString *)eventType withTarget:(id)object andSelector:(SEL)selector orBlock:(SPEventBlock)block
{
    [super removeEventListenersForType:eventType withTarget:object andSelector:selector orBlock:block];

    if ([eventType isEqualToString:SPEventTypeEnterFrame] && ![self hasEventListenerForType:SPEventTypeEnterFrame])
    {
        [self removeEventListener:@selector(addEnterFrameListenerToStage) atObject:self forType:SPEventTypeAddedToStage];
        [self removeEventListener:@selector(removeEnterFrameListenerFromStage) atObject:self forType:SPEventTypeRemovedFromStage];
        [self removeEnterFrameListenerFromStage];
    }
}

- (void)addEnterFrameListenerToStage
{
    [Sparrow.currentController.stage addEnterFrameListener:self];
}

- (void)removeEnterFrameListenerFromStage
{
    [Sparrow.currentController.stage removeEnterFrameListener:self];
}

#pragma mark Properties

- (void)setX:(float)value
{
    if (value != _x)
    {
        _x = value;
        _orientationChanged = YES;
    }
}

- (void)setY:(float)value
{
    if (value != _y)
    {
        _y = value;
        _orientationChanged = YES;
    }
}

- (float)scale
{
    if (!SPIsFloatEqual(_scaleX, _scaleY))
        SPLog(@"WARNING: Scale is not uniform. Use the approriate scaleX and scaleY properties.");

    return _scaleX;
}

- (void)setScale:(float)value
{
    if (value != _scaleX || value != _scaleY)
    {
        _scaleX = _scaleY = value;
        _orientationChanged = YES;
    }
}

- (void)setScaleX:(float)value
{
    if (value != _scaleX)
    {
        _scaleX = value;
        _orientationChanged = YES;
    }
}

- (void)setScaleY:(float)value
{
    if (value != _scaleY)
    {
        _scaleY = value;
        _orientationChanged = YES;
    }
}

- (void)setSkewX:(float)value
{
    if (value != _skewX)
    {
        _skewX = value;
        _orientationChanged = YES;
    }
}

- (void)setSkewY:(float)value
{
    if (value != _skewY)
    {
        _skewY = value;
        _orientationChanged = YES;
    }
}

- (void)setPivotX:(float)value
{
    if (value != _pivotX)
    {
        _pivotX = value;
        _orientationChanged = YES;
    }
}

- (void)setPivotY:(float)value
{
    if (value != _pivotY)
    {
        _pivotY = value;
        _orientationChanged = YES;
    }
}

- (float)width
{
    return [self boundsInSpace:_parent].width;
}

- (void)setWidth:(float)value
{
    // this method calls 'self.scaleX' instead of changing _scaleX directly.
    // that way, subclasses reacting on size changes need to override only the scaleX method.

    self.scaleX = 1.0f;
    float actualWidth = self.width;
    if (actualWidth != 0.0f) self.scaleX = value / actualWidth;
}

- (float)height
{
    return [self boundsInSpace:_parent].height;
}

- (void)setHeight:(float)value
{
    self.scaleY = 1.0f;
    float actualHeight = self.height;
    if (actualHeight != 0.0f) self.scaleY = value / actualHeight;
}

- (void)setRotation:(float)value
{
    // move to equivalent value in range [0 deg, 360 deg] without a loop
    value = fmod(value, TWO_PI);
    
    // move to [-180 deg, +180 deg]
    if (value < -PI) value += TWO_PI;
    if (value >  PI) value -= TWO_PI;
    
    _rotation = value;
    _orientationChanged = YES;
}

- (void)setAlpha:(float)value
{
    _alpha = SP_CLAMP(value, 0.0f, 1.0f);
}

- (SPRectangle *)bounds
{
    return [self boundsInSpace:_parent];
}

- (SPDisplayObject *)root
{
    Class stageClass = [SPStage class];
    SPDisplayObject *currentObject = self;
    while (currentObject->_parent)
    {
        if ([currentObject->_parent isMemberOfClass:stageClass]) return currentObject;
        else currentObject = currentObject->_parent;
    }
    return nil;
}

- (SPDisplayObject *)base
{
    SPDisplayObject *currentObject = self;
    while (currentObject->_parent) currentObject = currentObject->_parent;
    return currentObject;
}

- (SPStage *)stage
{
    SPDisplayObject *base = self.base;
    if ([base isKindOfClass:[SPStage class]]) return (SPStage *) base;
    else return nil;
}

- (SPMatrix *)transformationMatrix
{
    if (_orientationChanged)
    {
        _orientationChanged = NO;
        
        if (_skewX == 0.0f && _skewY == 0.0f)
        {
            // optimization: no skewing / rotation simplifies the matrix math
            
            if (_rotation == 0.0f)
            {
                [_transformationMatrix setA:_scaleX b:0.0f c:0.0f d:_scaleY
                                         tx:_x - _pivotX * _scaleX
                                         ty:_y - _pivotY * _scaleY];
            }
            else
            {
                float cos = cosf(_rotation);
                float sin = sinf(_rotation);
                float a = _scaleX *  cos;
                float b = _scaleX *  sin;
                float c = _scaleY * -sin;
                float d = _scaleY *  cos;
                float tx = _x - _pivotX * a - _pivotY * c;
                float ty = _y - _pivotX * b - _pivotY * d;
                
                [_transformationMatrix setA:a b:b c:c d:d tx:tx ty:ty];
            }
        }
        else
        {
            [_transformationMatrix identity];
            [_transformationMatrix scaleXBy:_scaleX yBy:_scaleY];
            [_transformationMatrix skewXBy:_skewX yBy:_skewY];
            [_transformationMatrix rotateBy:_rotation];
            [_transformationMatrix translateXBy:_x yBy:_y];
            
            if (_pivotX != 0.0 || _pivotY != 0.0)
            {
                // prepend pivot transformation
                _transformationMatrix.tx = _x - _transformationMatrix.a * _pivotX
                                              - _transformationMatrix.c * _pivotY;
                _transformationMatrix.ty = _y - _transformationMatrix.b * _pivotX
                                              - _transformationMatrix.d * _pivotY;
            }
        }
    }
    
    return _transformationMatrix;
}

- (SPMatrix3D *)transformationMatrix3D
{
    // this method needs to be overriden in 3D-supporting subclasses (like Sprite3D).
    return [self.transformationMatrix convertTo3D];
}

- (void)setTransformationMatrix:(SPMatrix *)matrix
{
    static const float PI_Q = PI / 4.0f;

    _orientationChanged = NO;
    [_transformationMatrix copyFromMatrix:matrix];
    
    _pivotX = 0.0f;
    _pivotY = 0.0f;
    
    _x = matrix.tx;
    _y = matrix.ty;
    
    _skewX = (matrix.d == 0.0f) ? PI_HALF * SPSign(-matrix.c)
                                : atanf(-matrix.c / matrix.d);
    _skewY = (matrix.a == 0.0f) ? PI_HALF * SPSign( matrix.b)
                                : atanf( matrix.b / matrix.a);

    _scaleY = (_skewX > -PI_Q && _skewX < PI_Q) ?  matrix.d / cosf(_skewX)
                                                : -matrix.c / sinf(_skewX);
    _scaleX = (_skewY > -PI_Q && _skewY < PI_Q) ?  matrix.a / cosf(_skewY)
                                                :  matrix.b / sinf(_skewY);

    if (SPIsFloatEqual(_skewX, _skewY))
    {
        _rotation = _skewX;
        _skewX = _skewY = 0.0f;
    }
    else
    {
        _rotation = 0.0f;
    }
}

- (void)setMask:(SPDisplayObject *)value
{
    if (_mask != value)
    {
        if (_mask) _mask->_isMask = NO;
        if (value) value->_isMask = YES;
        
        SP_RELEASE_AND_RETAIN(_mask, value);
    }
}

- (BOOL)hasVisibleArea
{
    return _alpha != 0.0f && _visible && _scaleX != 0.0f && _scaleY != 0.0f;
}

@end

// -------------------------------------------------------------------------------------------------

@implementation SPDisplayObject (Internal)

- (void)setParent:(SPDisplayObjectContainer *)parent 
{ 
    SPDisplayObject *ancestor = parent;
    while (ancestor != self && ancestor != nil)
        ancestor = ancestor->_parent;
    
    if (ancestor == self)
        [NSException raise:SPExceptionInvalidOperation 
                    format:@"An object cannot be added as a child to itself or one of its children"];
    else
        _parent = parent; // only assigned, not retained (to avoid a circular reference).
}

- (void)setIs3D:(BOOL)is3D
{
    _is3D = is3D;
}

@end
