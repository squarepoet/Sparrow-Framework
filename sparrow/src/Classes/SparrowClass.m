//
//  SPSparrow.m
//  Sparrow
//
//  Created by Daniel Sperl on 27.01.13.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SparrowClass.h"

static __weak SPViewController *controller = nil;

@implementation Sparrow

- (instancetype)init
{
    SP_STATIC_CLASS_INITIALIZER();
    return nil;
}

+ (SPViewController *)currentController
{
    return controller;
}

+ (void)setCurrentController:(SPViewController *)value
{
    controller = value;
}

+ (SPContext *)context
{
    return controller.context;
}

+ (SPJuggler *)juggler
{
    return controller.juggler;
}

+ (SPStage *)stage
{
    return controller.stage;
}

+ (SPDisplayObject *)root
{
    return controller.root;
}

+ (float)contentScaleFactor
{
    return controller ? controller.contentScaleFactor : 1.0f;
}

@end
