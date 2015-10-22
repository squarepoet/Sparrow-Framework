//
//  SPContext_Internal.h
//  Sparrow
//
//  Created by Robert Carone on 1/11/14.
//  Copyright 2011-2015 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPContext.h"

@interface SPContext (Internal)

+ (void)clearFrameBuffersForTexture:(SPGLTexture *)texture;
+ (void)setGlobalShareContext:(SPContext *)globalShareContext;

@end
