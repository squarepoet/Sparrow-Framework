//
//  SPPress_Internal.h
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPPress.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPPress (Internal)

@property (nonatomic, assign) size_t pressID;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) SPPressPhase phase;
@property (nonatomic, assign) SPPressType type;
@property (nonatomic, assign) float force;

@end

NS_ASSUME_NONNULL_END

