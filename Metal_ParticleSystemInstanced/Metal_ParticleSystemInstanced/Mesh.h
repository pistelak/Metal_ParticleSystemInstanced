//
//  Mesh.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@interface Mesh : NSObject

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithModelName:(NSString *)modelName
                            device:(id<MTLDevice>)device
            andMTLVertexDescriptor:(MTLVertexDescriptor *) vertexDescriptor NS_DESIGNATED_INITIALIZER;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;

@property (nonatomic, copy, readonly) NSString *modelName;

@end
