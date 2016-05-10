//
//  ParticleSystem.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/10/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ShaderTypes.h"
#import "MetalRenderer.h"

@interface ParticleSystem : NSObject

- (nullable instancetype) init NS_UNAVAILABLE;
- (nullable instancetype) initWithDevice:(nonnull id<MTLDevice>) device NS_DESIGNATED_INITIALIZER;

// @return Number of particles uploaded into structure bound to shaders
- (NSUInteger) upload;

- (void) encode:(nonnull id<MTLRenderCommandEncoder>) encoder;

- (void) update;

@end
