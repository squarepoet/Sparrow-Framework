//
//  SPGLTexture_Internal.h
//  Sparrow
//
//  Created by Robert Carone on 8/11/15.
//
//

#import <Foundation/Foundation.h>
#import "SPGLTexture.h"

@interface SPGLTexture (Internal)

- (uint)framebufferWithDepthAndStencil:(BOOL)enableDepthAndStencil;

@end
