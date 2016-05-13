//
//  Uniforms.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/13/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ShaderTypes.h"
#import "MetalRenderer.h"

@interface Uniforms : NSObject

- (nullable instancetype) init NS_UNAVAILABLE;
- (nullable instancetype) initWithDevice:(nonnull id<MTLDevice>) device NS_DESIGNATED_INITIALIZER;

@property (nonatomic) CGSize drawableSize;
@property (nonatomic) NSTimeInterval timeSinceLastDraw;

- (void) update;
- (void) upload;
- (void) encode:(nonnull id<MTLRenderCommandEncoder>) encoder;

@end
