//
//  SPDisplayObjectContainer_Internal.h
//  Sparrow
//
//  Created by Robert Carone on 10/7/13.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPDisplayObjectContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPDisplayObjectContainer (Internal)

- (void)appendDescendantEventListenersOfObject:(SPDisplayObject *)object
                                 withEventType:(NSString *)type
                                       toArray:(SP_GENERIC(NSMutableArray, SPDisplayObject*) *)listeners;

@end

NS_ASSUME_NONNULL_END
