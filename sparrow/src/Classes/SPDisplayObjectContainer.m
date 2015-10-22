//
//  SPDisplayObjectContainer.m
//  Sparrow
//
//  Created by Daniel Sperl on 15.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPDisplayObjectContainer_Internal.h"
#import "SPDisplayObject_Internal.h"
#import "SPEnterFrameEvent.h"
#import "SPEvent_Internal.h"
#import "SPFragmentFilter.h"
#import "SPMacros.h"
#import "SPMatrix.h"
#import "SPPoint.h"
#import "SPRectangle.h"
#import "SPRenderSupport.h"

// --- class implementation ------------------------------------------------------------------------

@implementation SPDisplayObjectContainer
{
    SP_GENERIC(NSMutableArray, SPDisplayObject*) *_children;
    BOOL _touchGroup;
}

// --- c functions ---

static void getDescendantEventListeners(SPDisplayObject *object, NSString *eventType,
                                        SP_GENERIC(NSMutableArray, SPDisplayObject*) *listeners)
{
    // some events (ENTER_FRAME, ADDED_TO_STAGE, etc.) are dispatched very often and traverse
    // the entire display tree -- thus, it pays off handling them in their own c function.
    
    if ([object hasEventListenerForType:eventType])
        [listeners addObject:object];
    
    if ([object isKindOfClass:[SPDisplayObjectContainer class]])
        for (SPDisplayObject *child in ((SPDisplayObjectContainer *)object)->_children)
            getDescendantEventListeners(child, eventType, listeners);
}

#pragma mark Initialization

- (instancetype)init
{
    SP_ABSTRACT_CLASS_INITIALIZER(SPDisplayObjectContainer);
    
    if (self = [super init])
    {
        _children = [[NSMutableArray alloc] init];
    }    
    return self;
}

- (void)dealloc
{
    // 'self' is becoming invalid; thus, we have to remove any references to it.
    [_children makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
    [_children release];
    [super dealloc];
}

#pragma mark Methods

- (void)addChild:(SPDisplayObject *)child
{
    [self addChild:child atIndex:_children.count];
}

- (void)addChild:(SPDisplayObject *)child atIndex:(NSInteger)index
{
    if (index >= 0 && index <= _children.count)
    {
        if (child.parent == self)
        {
            [self setIndex:index ofChild:child]; // avoids dispatching events
        }
        else
        {
            [child retain];
            [child removeFromParent];
            [_children insertObject:child atIndex:MIN(_children.count, index)];
            child.parent = self;
            
            [child dispatchEventWithType:SPEventTypeAdded];
            
            if (self.stage)
                [child broadcastEventWithType:SPEventTypeAddedToStage];
            
            [child release];
        }
    }
    else [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid child index"]; 
}

- (BOOL)containsChild:(SPDisplayObject *)child
{
    while (child)
    {
        if (child == self) return YES;
        else child = child.parent;
    }
    
    return NO;
}

- (SPDisplayObject *)childAtIndex:(NSInteger)index
{
    if (index < 0) index = _children.count + index;
    return _children[index];
}

- (SPDisplayObject *)childByName:(NSString *)name
{
    for (SPDisplayObject *currentChild in _children)
        if ([currentChild.name isEqualToString:name]) return currentChild;
    
    return nil;
}

- (NSInteger)childIndex:(SPDisplayObject *)child
{
    NSInteger index = [_children indexOfObject:child];
    if (index == NSNotFound) return SPNotFound;
    else                     return index;
}

- (void)setIndex:(NSInteger)index ofChild:(SPDisplayObject *)child
{
    NSInteger oldIndex = [_children indexOfObject:child];
    if (oldIndex == index) return;
    if (oldIndex == NSNotFound) 
        [NSException raise:SPExceptionInvalidOperation format:@"Not a child of this container"];
    else
    {
        [child retain];
        [_children removeObjectAtIndex:oldIndex];
        [_children insertObject:child atIndex:MIN(_children.count, index)];
        [child release];
    }
}

- (void)removeChild:(SPDisplayObject *)child
{
    NSInteger childIndex = [self childIndex:child];
    if (childIndex != SPNotFound)
        [self removeChildAtIndex:childIndex];
}

- (void)removeChildAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _children.count)
    {
        SPDisplayObject *child = _children[index];
        [child dispatchEventWithType:SPEventTypeRemoved];

        if (self.stage)
            [child broadcastEventWithType:SPEventTypeRemovedFromStage];
        
        child.parent = nil; 
        NSUInteger newIndex = [_children indexOfObject:child]; // index might have changed in event handler
        if (newIndex != NSNotFound) [_children removeObjectAtIndex:newIndex];
    }
    else [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid child index"];        
}

- (void)swapChild:(SPDisplayObject *)child1 withChild:(SPDisplayObject *)child2
{
    NSInteger index1 = [self childIndex:child1];
    NSInteger index2 = [self childIndex:child2];
    [self swapChildAtIndex:index1 withChildAtIndex:index2];
}

- (void)swapChildAtIndex:(NSInteger)index1 withChildAtIndex:(NSInteger)index2
{    
    NSInteger numChildren = _children.count;
    if (index1 < 0 || index1 >= numChildren || index2 < 0 || index2 >= numChildren)
        [NSException raise:SPExceptionInvalidOperation format:@"invalid child indices"];
    
    [_children exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)sortChildren:(NSComparator)comparator
{
    if ([_children respondsToSelector:@selector(sortWithOptions:usingComparator:)])
        [_children sortWithOptions:NSSortStable usingComparator:comparator];
    else
        [NSException raise:SPExceptionInvalidOperation 
                    format:@"sortChildren is only available in iOS 4 and above"];
}

- (void)removeAllChildren
{
    for (NSInteger i=_children.count-1; i>=0; --i)
        [self removeChildAtIndex:i];
}

- (SPDisplayObject *)objectAtIndexedSubscript:(NSInteger)index
{
    return [self childAtIndex:index];
}

- (void)setObject:(SPDisplayObject *)child atIndexedSubscript:(NSInteger)index
{
    if (index != _children.count)
        [self removeChildAtIndex:index];

    [self addChild:child atIndex:index];
}

- (NSInteger)numChildren
{
    return [_children count];
}

- (SP_GENERIC(NSArray, SPDisplayObject *) *)children
{
    return _children;
}

- (void)setChildren:(NSArray *)children
{
    [self removeAllChildren];

    for (SPDisplayObject *child in children)
        [self addChild:child];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    SPDisplayObjectContainer *container = [super copyWithZone:zone];
    
    container->_touchGroup = _touchGroup;
    [container->_children release];
    
    container->_children = [[NSMutableArray alloc] initWithArray:_children copyItems:YES];
    [container->_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
    
    return container;
}

#pragma mark SPDisplayObject

- (void)render:(SPRenderSupport *)support
{
    for (SPDisplayObject *child in _children)
    {
        if (child.hasVisibleArea)
        {
            SPDisplayObject *mask = child.mask;
            SPFragmentFilter *filter = child.filter;
            
            [support pushStateWithMatrix:child.transformationMatrix
                                   alpha:child.alpha
                               blendMode:child.blendMode];
            
            if (mask) [support pushMask:mask];

            if (filter) [filter renderObject:child support:support];
            else        [child render:support];
            
            if (mask) [support popMask];

            [support popState];
        }
    }
}

- (SPRectangle *)boundsInSpace:(SPDisplayObject *)targetSpace
{
    NSInteger numChildren = _children.count;

    if (numChildren == 0)
    {
        SPMatrix *transformationMatrix = [self transformationMatrixToSpace:targetSpace];
        SPPoint *transformedPoint = [transformationMatrix transformPointWithX:self.x y:self.y];
        return [SPRectangle rectangleWithX:transformedPoint.x y:transformedPoint.y
                                     width:0.0f height:0.0f];
    }
    else if (numChildren == 1)
    {
        return [_children[0] boundsInSpace:targetSpace];
    }
    else
    {
        float minX = FLT_MAX, maxX = -FLT_MAX, minY = FLT_MAX, maxY = -FLT_MAX;
        for (SPDisplayObject *child in _children)
        {
            SPRectangle *childBounds = [child boundsInSpace:targetSpace];
            minX = MIN(minX, childBounds.x);
            maxX = MAX(maxX, childBounds.x + childBounds.width);
            minY = MIN(minY, childBounds.y);
            maxY = MAX(maxY, childBounds.y + childBounds.height);
        }
        return [SPRectangle rectangleWithX:minX y:minY width:maxX-minX height:maxY-minY];
    }
}

- (SPDisplayObject *)hitTestPoint:(SPPoint *)localPoint forTouch:(BOOL)forTouch
{
    if (forTouch && (!self.visible || !self.touchable))
        return nil;

    for (NSInteger i=_children.count-1; i>=0; --i) // front to back!
    {
        SPDisplayObject *child = _children[i];
        SPMatrix *transformationMatrix = [self transformationMatrixToSpace:child];
        SPPoint  *transformedPoint = [transformationMatrix transformPoint:localPoint];
        SPDisplayObject *target = [child hitTestPoint:transformedPoint forTouch:forTouch];

        if (target)
            return _touchGroup ? self : target;
    }

    return nil;
}

- (void)broadcastEvent:(SPEvent *)event
{
    if (event.bubbles)
        [NSException raise:SPExceptionInvalidOperation
                    format:@"Broadcast of bubbling events is prohibited"];

    // the event listeners might modify the display tree, which could make the loop crash.
    // thus, we collect them in a list and iterate over that list instead.
    NSMutableArray *listeners = [[NSMutableArray alloc] init];
    [self appendDescendantEventListenersOfObject:self withEventType:event.type toArray:listeners];
    
    event.target = self;
    for (SPEventDispatcher *listener in listeners)
        [listener dispatchEvent:event];
    
    [listeners release];
}

- (void)broadcastEventWithType:(NSString *)type
{
    SPEvent *event = [[SPEvent alloc] initWithType:type bubbles:NO];
    [self broadcastEvent:event];
    [event release];
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained *)stackbuf
                                    count:(NSUInteger)len
{
    return [_children countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end

// -------------------------------------------------------------------------------------------------

@implementation SPDisplayObjectContainer (Internal)

- (void)appendDescendantEventListenersOfObject:(SPDisplayObject *)object withEventType:(NSString *)type
                                       toArray:(SP_GENERIC(NSMutableArray, SPDisplayObject*) *)listeners
{
    getDescendantEventListeners(object, type, listeners);
}

@end
