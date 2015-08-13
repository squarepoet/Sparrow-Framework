//
//  SparrowBase.h
//  Sparrow
//
//  Created by Robert Carone on 8/13/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Availability.h>
#import <TargetConditionals.h>
#import <CoreGraphics/CGGeometry.h>
#import <Sparrow/SparrowBase.h>
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#define SP_DEPRECATED __attribute__((deprecated))
#define SP_INLINE     static __inline__

#ifdef __cplusplus
    #define SP_EXTERN extern "C" __attribute__((visibility ("default")))
#else
    #define SP_EXTERN extern __attribute__((visibility ("default")))
#endif
