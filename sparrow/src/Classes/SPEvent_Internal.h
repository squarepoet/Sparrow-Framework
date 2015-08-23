//
//  SPEvent_Internal.h
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPEvent (Internal)

- (BOOL)stopsImmediatePropagation;
- (BOOL)stopsPropagation;

@property (nonatomic, weak, nullable) SPEventDispatcher *target;
@property (nonatomic, weak, nullable) SPEventDispatcher *currentTarget;

@end

NS_ASSUME_NONNULL_END
