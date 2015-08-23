//
//  SPDisplayObjectContainer.h
//  Sparrow
//
//  Created by Daniel Sperl on 15.03.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPDisplayObject.h>

NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------
 
 An SPDisplayObjectContainer represents a collection of display objects.
 
 It is the base class of all display objects that act as a container for other objects. By 
 maintaining an ordered list of children, it defines the back-to-front positioning of the children
 within the display tree.
 
 A container does not have size in itself. The width and height properties represent the extents
 of its children. Changing those properties will scale all children accordingly.
 
 As this is an abstract class, you can't instantiate it directly, but have to 
 use a subclass instead. The most lightweight container class is SPSprite.
 
 **Adding and removing children**
 
 The class defines methods that allow you to add or remove children. When you add a child, it will
 be added at the foremost position, possibly occluding a child that was added before. You can access
 the children via an index. The first child will have index 0, the second child index 1, etc. 
 
 Adding and removing objects from a container triggers non-bubbling events.
 
 - `SPEventTypeAdded`: the object was added to a parent.
 - `SPEventTypeAddedToStage`: the object was added to a parent that is connected to the stage,
                                   thus becoming visible now.
 - `SPEventTypeRemoved`: the object was removed from a parent.
 - `SPEventTypeRemovedFromStage`: the object was removed from a parent that is connected to 
                                       the stage, thus becoming invisible now.
 
 Especially the `ADDED_TO_STAGE` event is very helpful, as it allows you to automatically execute
 some logic (e.g. start an animation) when an object is rendered the first time.
 
 **Sorting children**
 
 The `sortChildren:` method allows you to sort the children of a container by a custom criteria. 
 Below is an example how to depth-sort children by their y-coordinate; this will put objects that
 are lower on the screen in front of those higher on the screen.
 
	[container sortChildren:^(SPDisplayObject *child1, SPDisplayObject *child2) 
	{
	    if (child1.y < child2.y) return NSOrderedAscending;
	    else if (child1.y > child2.y) return NSOrderedDescending;
	    else return NSOrderedSame;
	}];
 
------------------------------------------------------------------------------------------------- */

@interface SPDisplayObjectContainer : SPDisplayObject <NSFastEnumeration>

/// -------------
/// @name Methods
/// -------------

/// Adds a child to the container. It will be at the topmost position.
- (void)addChild:(SPDisplayObject *)child;

/// Inserts a child to the container at a certain index.
- (void)addChild:(SPDisplayObject *)child atIndex:(NSInteger)index;

/// Determines if a certain object is a child of the container (recursively).
- (BOOL)containsChild:(SPDisplayObject *)child;

/// Returns a child object at a certain index. If you pass a negative index, '-1' will return the
/// last child, '-2' the second to last child, etc.
- (SPDisplayObject *)childAtIndex:(NSInteger)index;

/// Returns a child object with a certain name (non-recursively).
- (nullable SPDisplayObject *)childByName:(NSString *)name;

/// Returns the index of a child within the container.
- (NSInteger)childIndex:(SPDisplayObject *)child;

/// Moves a child to a certain index. Children at and after the replaced position move up.
- (void)setIndex:(NSInteger)index ofChild:(SPDisplayObject *)child;

/// Removes a child from the container. If the object is not a child, nothing happens.
- (void)removeChild:(SPDisplayObject *)child;

/// Removes a child at a certain index. Children above the child will move down.
- (void)removeChildAtIndex:(NSInteger)index;

/// Removes all children from the container.
- (void)removeAllChildren;

/// Swaps the indexes of two children.
- (void)swapChild:(SPDisplayObject *)child1 withChild:(SPDisplayObject *)child2;

/// Swaps the indexes of two children.
- (void)swapChildAtIndex:(NSInteger)index1 withChildAtIndex:(NSInteger)index2;

/// Sorts the children using the given NSComparator block.
- (void)sortChildren:(NSComparator)comparator;

/// Returns a child object at the subscript index.
- (SPDisplayObject *)objectAtIndexedSubscript:(NSInteger)index;

/// Assigns a child object at the subscript index. If a child object already exists at the index
/// it is removed first.
- (void)setObject:(SPDisplayObject *)child atIndexedSubscript:(NSInteger)index;

/// ----------------
/// @name Properties
/// ----------------

/// The number of children of this container.
@property (nonatomic, readonly) NSInteger numChildren;

/// The array of children. You can also assign the children of this contianer using this
/// property; the previous children will be removed first.
/// CAUTION: Use with care! Each call returns the internal instance.
@property (nonatomic, copy) NSArray<SPDisplayObject*> *children;

/// If a container is a 'touchGroup', it will act as a single touchable object.
/// Touch events will have the container as target, not the touched child (similar to
/// 'mouseChildren' in Flash, but with inverted logic). Default: `NO`
@property (nonatomic, assign) BOOL touchGroup;

@end

NS_ASSUME_NONNULL_END
