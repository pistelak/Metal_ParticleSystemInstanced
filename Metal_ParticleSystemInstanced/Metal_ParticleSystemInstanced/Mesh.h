//
//  Mesh.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Mesh : NSObject


- (nullable instancetype) init NS_UNAVAILABLE;
- (nullable instancetype) initWithModelName:(NSString *)modelName
                            device:(id<MTLDevice>)device
            andMTLVertexDescriptor:(MTLVertexDescriptor *) vertexDescriptor NS_DESIGNATED_INITIALIZER;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder instanceCount:(NSUInteger) instanceCount;

@property (nonatomic, copy, readonly) NSString *modelName;

@end

NS_ASSUME_NONNULL_END