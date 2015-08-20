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
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKMath.h>

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#endif

// defines

#define SP_DEPRECATED __attribute__((deprecated))

#ifdef CF_INLINE
#   define SP_INLINE CF_INLINE
#else
#   define SP_INLINE static __inline__
#endif

#ifdef CF_EXPORT
#   define SP_EXTERN CF_EXPORT
#else
#   ifdef __cplusplus
#       define SP_EXTERN extern "C" __attribute__((visibility ("default")))
#   else
#       define SP_EXTERN extern __attribute__((visibility ("default")))
#   endif
#endif

// Xcode 6.x support

#if __has_feature(objc_generics)
#   define NS_ARRAY(a)                 NSArray<a>
#   define NS_DICTIONARY(a, b)         NSDictionary<a, b>
#   define NS_ORDERED_SET(a)           NSOrderedSet<a>
#   define NS_MAP_TABLE(a, b)          NSMapTable<a, b>
#   define NS_MUTABLE_ARRAY(a)         NSMutableArray<a>
#   define NS_MUTABLE_DICTIONARY(a, b) NSMutableDictionary<a, b>
#   define NS_MUTABLE_ORDERED_SET(a)   NSMutableOrderedSet<a>
#   define NS_MUTABLE_SET(a)           NSMutableSet<a>
#   define NS_SET(a)                   NSSet<a>
#   define SP_CACHE(a, b)              SPCache<a, b>
#else
#   define NS_ARRAY(a)                 NSArray
#   define NS_DICTIONARY(a, b)         NSDictionary
#   define NS_ORDERED_SET(a)           NSOrderedSet
#   define NS_MAP_TABLE(a, b)          NSMapTable
#   define NS_MUTABLE_ARRAY(a)         NSMutableArray
#   define NS_MUTABLE_DICTIONARY(a, b) NSMutableDictionary
#   define NS_MUTABLE_ORDERED_SET(a)   NSMutableOrderedSet
#   define NS_MUTABLE_SET(a)           NSMutableSet
#   define NS_SET(a)                   NSSet
#   define SP_CACHE(a, b)              SPCache
#endif

// enums

enum { SPNotFound = -1 };

/// Horizontal alignment.
typedef NS_ENUM(NSInteger, SPHAlign)
{
    SPHAlignLeft,
    SPHAlignCenter,
    SPHAlignRight
};

/// Vertical alignment.
typedef NS_ENUM(NSInteger, SPVAlign)
{
    SPVAlignTop,
    SPVAlignCenter,
    SPVAlignBottom
};

// exceptions

SP_EXTERN NSString *const SPExceptionAbstractClass;
SP_EXTERN NSString *const SPExceptionAbstractMethod;
SP_EXTERN NSString *const SPExceptionNotRelated;
SP_EXTERN NSString *const SPExceptionIndexOutOfBounds;
SP_EXTERN NSString *const SPExceptionInvalidOperation;
SP_EXTERN NSString *const SPExceptionFileNotFound;
SP_EXTERN NSString *const SPExceptionFileInvalid;
SP_EXTERN NSString *const SPExceptionDataInvalid;
SP_EXTERN NSString *const SPExceptionOperationFailed;
