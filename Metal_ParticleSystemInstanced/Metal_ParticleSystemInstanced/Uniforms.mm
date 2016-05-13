//
//  Uniforms.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/13/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "Uniforms.h"
#import "Math.h"

static const size_t kUniformsSize = sizeof(uniforms_t);
static const size_t kUniformBufferSize = kUniformsSize * kInFlightCommandBuffers;

@implementation Uniforms
{
    simd::float4x4 _viewMatrix;
    simd::float4x4 _projectionMatrix;
    
    float _angle;
    NSInteger _currentBufferIndex;
    
    id<MTLBuffer> _uniformBuffer;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if (self) {
        
        _currentBufferIndex = 0;
        _angle = 0.f;
        
        [self createUniformBufferOnDevice:device];
    }
    
    return self;
}

- (void) createUniformBufferOnDevice:(nonnull id<MTLDevice>) device
{
    _uniformBuffer = [device newBufferWithLength:kUniformBufferSize options:MTLResourceCPUCacheModeDefaultCache];
    _uniformBuffer.label = @"UniformBuffer";
}

- (void) update
{
    _angle += _timeSinceLastDraw * 0.1;
    simd::float3 cameraPosition = { sinf(_angle) * 10.f, 2.5f, cosf(_angle) * 10.f };
    
    _viewMatrix = MathUtils::lookAt(cameraPosition);
    _projectionMatrix = MathUtils::projectionMatrix(_drawableSize.width, _drawableSize.height);
}

- (void) upload
{
    size_t offset = _currentBufferIndex * kUniformsSize;
    uniforms_t *ptrData = (uniforms_t *) ((uintptr_t) [_uniformBuffer contents] + offset);
    
    ptrData->viewMatrix = _viewMatrix;
    ptrData->projectionMatrix = _projectionMatrix;
}

- (void) encode:(id<MTLRenderCommandEncoder>)encoder
{
    size_t offset = _currentBufferIndex * kUniformsSize;
    [encoder setVertexBuffer:_uniformBuffer offset:offset atIndex:PSFrameUniformBuffer];
    
    _currentBufferIndex = (_currentBufferIndex + 1) % kInFlightCommandBuffers;
}

@end
