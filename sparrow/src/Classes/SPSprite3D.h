//
//  SPSprite3D.h
//  Sparrow
//
//  Created by Robert Carone on 7/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPDisplayObjectContainer.h>

NS_ASSUME_NONNULL_BEGIN

/** ------------------------------------------------------------------------------------------------
 
 A container that allows you to position objects in three-dimensional space.
 
 Sparrow is, at its heart, a 2D engine. However, sometimes, simple 3D effects are
 useful for special effects, e.g. for screen transitions or to turn playing cards
 realistically. This class makes it possible to create such 3D effects.
 
 Positioning objects in 3D:
 
 Just like a normal sprite, you can add and remove children to this container, which
 allows you to group several display objects together. In addition to that, Sprite3D
 adds some interesting properties:
 
    z - Moves the sprite closer to / further away from the camera.
    rotationX — Rotates the sprite around the x-axis.
    rotationY — Rotates the sprite around the y-axis.
    scaleZ - Scales the sprite along the z-axis.
    pivotZ - Moves the pivot point along the z-axis.
 
 With the help of these properties, you can move a sprite and all its children in the
 3D space. By nesting several Sprite3D containers, it's even possible to construct simple
 volumetric objects (like a cube).
 
 Note that Sparrow does not make any z-tests: visibility is solely established by the
 order of the children, just as with 2D objects.
 
 Setting up the camera:
 
 The camera settings are found directly on the stage. Modify the 'focalLength' or
 'fieldOfView' properties to change the distance between stage and camera; use the
 'projectionOffset' to move it to a different position.
 
 Limitations:
 
 An SPSprite3D object cannot be flattened (although you can flatten objects within
 a SPSprite3D), and it does not work with the "clipRect" property. Furthermore, a filter
 applied to a SPSprite3D object cannot be cached.
 
 On rendering, each SPSprite3D requires its own draw call — except if the object does not
 contain any 3D transformations ('z', 'rotationX/Y' and 'pivotZ' are zero).
 
------------------------------------------------------------------------------------------------- */

@interface SPSprite3D : SPDisplayObjectContainer

/// --------------------
/// @name Initialization
/// --------------------

/// Create a new, empty 3D sprite.
+ (instancetype)sprite3D;

/// ----------------
/// @name Properties
/// ----------------

/// The z coordinate of the object relative to the local coordinates of the parent.
/// The z-axis points away from the camera, i.e. positive z-values will move the object further
/// away from the viewer.
@property (nonatomic, assign) float z;

/// The z coordinate of the object's origin in its own coordinate space (default: 0).
@property (nonatomic, assign) float pivotZ;

/// The depth scale factor. '1' means no scale, negative values flip the object.
@property (nonatomic, assign) float scaleZ;

/// The rotation of the object about the x axis, in radians.
@property (nonatomic, assign) float rotationX;

/// The rotation of the object about the y axis, in radians.
@property (nonatomic, assign) float rotationY;

/// The rotation of the object about the z axis, in radians.
@property (nonatomic, assign) float rotationZ;

@end

NS_ASSUME_NONNULL_END
