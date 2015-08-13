//
//  SPBlendMode.h
//  Sparrow
//
//  Created by Daniel Sperl on 29.03.13.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowBase.h>
#import <Sparrow/SPMacros.h>

NS_ASSUME_NONNULL_BEGIN

/// Inherits the blend mode from this display object's parent.
SP_EXTERN const uint SPBlendModeAuto;

/// Deactivates blending, i.e. disabling any transparency.
/// one, zero -- one, zero
SP_EXTERN const uint SPBlendModeNone;

/// The display object appears in front of the background.
// src_alpha, one_minus_src_alpha -- one, one_minus_src_alpha
SP_EXTERN const uint SPBlendModeNormal;

/// Adds the values of the colors of the display object to the colors of its background.
/// src_alpha, dst_alpha -- one, one
SP_EXTERN const uint SPBlendModeAdd;

/// Multiplies the values of the display object colors with the the background color.
/// dst_color, one_minus_src_alpha -- dst_color, one_minus_src_alpha
SP_EXTERN const uint SPBlendModeMultiply;

/// Multiplies the complement (inverse) of the display object color with the complement of the
/// background color, resulting in a bleaching effect.
/// src_alpha, one -- one, one_minus_src_color
SP_EXTERN const uint SPBlendModeScreen;

/// Erases the background when drawn on a RenderTexture.
/// zero, one_minus_src_alpha -- zero, one_minus_src_alpha
SP_EXTERN const uint SPBlendModeErase;

/// When used on a RenderTexture, the drawn object will act as a mask for the current content,
/// i.e. the source alpha overwrites the destination alpha.
/// zero, src_alpha -- zero, src_alpha
SP_EXTERN const uint SPBlendModeMask;

/// Draws under/below existing objects; useful especially on RenderTextures.
/// one_minus_dst_alpha, dst_alpha -- one_minus_dst_alpha, dst_alpha
SP_EXTERN const uint SPBlendModeBelow;

/** ------------------------------------------------------------------------------------------------

 A helper class for working with Sparrow's blend modes.
 
 A blend mode is always defined by two OpenGL blend factors. A blend factor represents a particular
 value that is multiplied with the source or destination color in the blending formula. The 
 blending formula is:
 
     result = source × sourceFactor + destination × destinationFactor
 
 In the formula, the source color is the output color of the pixel shader program. The destination
 color is the color that currently exists in the color buffer, as set by previous clear and draw
 operations.
 
 Beware that blending factors produce different output depending on the texture type. Textures may
 contain 'premultiplied alpha' (pma), which means that their RGB values were multiplied with their
 alpha value. (Typically, Xcode will convert your PNGs to use PMA; other texture types remain 
 unmodified.) For this reason, a blending mode may have different factors depending on the pma 
 value.

------------------------------------------------------------------------------------------------- */

@interface SPBlendMode : NSObject

/// Encodes a set of blend factors into a single unsigned integer, using the same factors regardless
/// of the premultiplied alpha state active on rendering.
+ (uint)encodeBlendModeWithSourceFactor:(uint)sFactor destFactor:(uint)dFactor;

/// Encodes a set of blend factors into a single unsigned integer, using different factors depending
/// on the premultiplied alpha state active on rendering.
+ (uint)encodeBlendModeWithSourceFactor:(uint)sFactor destFactor:(uint)dFactor
                        sourceFactorPMA:(uint)sFactorPMA destFactorPMA:(uint)dFactorPMA;

/// Decodes a blend mode into its source and destination factors.
+ (void)decodeBlendMode:(uint)blendMode premultipliedAlpha:(BOOL)pma
       intoSourceFactor:(uint *)sFactor destFactor:(uint *)destFactor;

/// Makes OpenGL use the blend factors that correspond with a certain blend mode.
+ (void)applyBlendFactorsForBlendMode:(uint)blendMode premultipliedAlpha:(BOOL)pma;

/// Returns a string that describes a blend mode.
+ (NSString *)describeBlendMode:(uint)blendMode;

@end

NS_ASSUME_NONNULL_END
