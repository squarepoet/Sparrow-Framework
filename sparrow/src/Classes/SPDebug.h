//
//  SPDebug.h
//  Sparrow
//
//  Created by Robert Carone on 8/13/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPDisplayObject.h>
#import <Sparrow/SPSubTexture.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPDisplayObject (Debug)

- (UIImage *)debugQuickLookObject;

@end

@interface SPTexture (Debug)

- (UIImage *)debugQuickLookObject;

@end

@interface SPSubTexture (Debug)

- (UIImage *)debugQuickLookObject;

@end

NS_ASSUME_NONNULL_END
