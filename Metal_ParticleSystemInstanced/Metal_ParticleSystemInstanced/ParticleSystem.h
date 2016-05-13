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

NS_ASSUME_NONNULL_BEGIN

@interface ParticleSystem : NSObject

- (nullable instancetype) init NS_UNAVAILABLE;
- (nullable instancetype) initWithDevice:(id<MTLDevice>) device NS_DESIGNATED_INITIALIZER;

- (void) update;

// @return Number of particles uploaded into structure bound to shaders
- (NSUInteger) upload;

- (void) encode:(id<MTLRenderCommandEncoder>) encoder;

@end

NS_ASSUME_NONNULL_END
