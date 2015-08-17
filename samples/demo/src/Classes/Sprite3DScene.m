//
//  Sprite3DScene.m
//  Demo
//
//  Created by Robert Carone on 7/31/15.
//
//

#import "Sprite3DScene.h"

@implementation Sprite3DScene
{
    SPSprite3D *_cube;
}

- (instancetype)init
{
    if (self = [super init])
    {
        SPTexture *texture = [SPTexture textureWithContentsOfFile:@"gamua_logo.png"];
        _cube = [self createCubeWithTexture:texture];
        _cube.name = @"cube";
        _cube.x = CENTER_X;
        _cube.y = CENTER_Y;
        _cube.z = 100;
        
        [self addChild:_cube];
        
        [self addEventListener:@selector(start) atObject:self forType:SPEventTypeAddedToStage];
        [self addEventListener:@selector(stop) atObject:self forType:SPEventTypeRemovedFromStage];
    }
    
    return self;
}

- (void)start
{
    [Sparrow.juggler tweenWithTarget:_cube time:6 properties:@{ @"rotationX" : @(TWO_PI), @"repeatCount": @0 }];
    [Sparrow.juggler tweenWithTarget:_cube time:7 properties:@{ @"rotationY" : @(TWO_PI), @"repeatCount": @0 }];
    [Sparrow.juggler tweenWithTarget:_cube time:8 properties:@{ @"rotationZ" : @(TWO_PI), @"repeatCount": @0 }];
}

- (void)stop
{
    [Sparrow.juggler removeObjectsWithTarget:_cube];
}

- (SPSprite3D *)createCubeWithTexture:(SPTexture *)texture
{
    float offset = texture.width / 2.0f;
    
    SPSprite3D *front = [self createSideWallWithTexture:texture color:0xff0000];
    front.z = -offset;
    
    SPSprite3D *back = [self createSideWallWithTexture:texture color:0x00ff00];
    back.rotationX = PI;
    back.z = offset;
    
    SPSprite3D *top = [self createSideWallWithTexture:texture color:0x0000ff];
    top.y = - offset;
    top.rotationX = PI / -2.0f;
    
    SPSprite3D *bottom = [self createSideWallWithTexture:texture color:0xffff00];
    bottom.y = offset;
    bottom.rotationX = PI / 2.0f;
    
    SPSprite3D *left = [self createSideWallWithTexture:texture color:0xff00ff];
    left.x = -offset;
    left.rotationY = PI / 2.0f;
    
    SPSprite3D *right = [self createSideWallWithTexture:texture color:0x00ffff];
    right.x = offset;
    right.rotationY = PI / -2.0f;
    
    SPSprite3D *cube = [[SPSprite3D alloc] init];
    [cube addChild:front];
    [cube addChild:back];
    [cube addChild:top];
    [cube addChild:bottom];
    [cube addChild:left];
    [cube addChild:right];
    return cube;
}

- (SPSprite3D *)createSideWallWithTexture:(SPTexture *)texture color:(uint)color
{
    SPImage *image = [SPImage imageWithTexture:texture];
    image.color = color;
    [image alignPivotToCenter];
    
    SPSprite3D *sprite = [[SPSprite3D alloc] init];
    [sprite addChild:image];
    
    return sprite;
}

- (void)render:(SPRenderSupport *)support
{
    // Sparrow does not make any depth-tests, so we use a trick in order to only show
    // the front quads: we're activating backface culling, i.e. we hide triangles at which
    // we look from behind.
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_FRONT);
    [super render:support];
    glDisable(GL_CULL_FACE);
}

@end
