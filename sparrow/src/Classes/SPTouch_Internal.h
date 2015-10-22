//
//  SPTouch_Internal.h
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTouch.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTouch (Internal)

@property (nonatomic, assign) size_t touchID;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) float globalX;
@property (nonatomic, assign) float globalY;
@property (nonatomic, assign) float previousGlobalX;
@property (nonatomic, assign) float previousGlobalY;
@property (nonatomic, assign) NSInteger tapCount;
@property (nonatomic, assign) SPTouchPhase phase;
@property (nonatomic, strong, nullable) SPDisplayObject *target;

@end

NS_ASSUME_NONNULL_END
