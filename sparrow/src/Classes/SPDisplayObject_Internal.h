//
//  SPDisplayObject_Internal.h
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPDisplayObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPDisplayObject (Internal)

- (void)setParent:(nullable SPDisplayObjectContainer *)parent;
- (void)setIs3D:(BOOL)is3D;

@end

NS_ASSUME_NONNULL_END
