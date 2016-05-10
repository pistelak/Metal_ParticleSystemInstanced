//
//  MetalRenderer.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "ViewController.h"
#import "Mesh.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalRenderer : NSObject <ViewDelegate, ViewControllerDelegate>

- (nullable instancetype) init NS_UNAVAILABLE;

- (nullable instancetype) initWithVertexShader:(NSString *) vertexShaderName
                             andFragmentShader:(NSString *) fragmentShaderName NS_DESIGNATED_INITIALIZER;

@property (nonatomic) id<MTLDevice> device;
@property (nonatomic) MTLPixelFormat depthPixelFormat;

@end

NS_ASSUME_NONNULL_END