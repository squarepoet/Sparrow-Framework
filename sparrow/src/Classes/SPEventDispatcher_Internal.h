//
//  SPEventDispatcher_Internal.h
//  Sparrow
//
//  Created by Robert Carone on 10/7/13.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SPEventDispatcher.h>

NS_ASSUME_NONNULL_BEGIN

@class SPEventListener;

@interface SPEventDispatcher (Internal)

- (void)addEventListener:(SPEventListener *)listener forType:(NSString *)eventType;
- (void)removeEventListenersForType:(NSString *)eventType withTarget:(nullable id)object
                        andSelector:(nullable SEL)selector orBlock:(nullable SPEventBlock)block;

@end

NS_ASSUME_NONNULL_END
