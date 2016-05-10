//
//  ParticleSystem.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/10/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//
//  Particle movement
//  https://github.com/floooh/oryol/blob/master/code/Samples/Instancing/Instancing.cc
//

#import "ParticleSystem.h"
#import "Math.h"

#import <simd/simd.h>

typedef struct {
    simd::float3 position;
    simd::float3 vec;
    float scale;
} particle_t;

static const uint32_t kMaximumNumberOfParticles = 10000;
static const uint32_t kBatchSize = 100;
static const uint32_t kParticleBufferSize = kMaximumNumberOfParticles * sizeof(particle_t);

@implementation ParticleSystem
{
    NSUInteger _currentBufferIndex;
    id<MTLBuffer> _particleBuffer[kInFlightCommandBuffers];
    
    particle_t _particles[kMaximumNumberOfParticles];
    simd::float4x4 _modelMatrices[kMaximumNumberOfParticles];
    
    NSTimer *_timer;
    NSUInteger _particleCount;
}

- (instancetype) initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if (self) {
        
        _particleCount = kBatchSize;
        
        const NSTimeInterval timeInterval = 1.0; // in seconds
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                  target:self
                                                selector:@selector(increaseParticleCount:)
                                                userInfo:nil
                                                 repeats:YES];
        
        [self initializeAllParticles];
        [self createParticleBufferOnDevice:device];
    }
    
    return self;
}

- (void) initializeAllParticles
{
    for (uint32_t i = 0; i < kMaximumNumberOfParticles; ++i) {
        
        _particles[i].position = 0.f;
        _particles[i].scale = 0.05f;
        _particles[i].vec = MathUtils::ballRandomVector3(0.5f);
        _particles[i].vec.y += 2.f;
    }
}

- (void) createParticleBufferOnDevice:(id<MTLDevice>) device
{
    for (unsigned i = 0; i < kInFlightCommandBuffers; ++i) {
        
        _particleBuffer[i] = [device newBufferWithLength:kParticleBufferSize options:MTLResourceCPUCacheModeDefaultCache];
        _particleBuffer[i].label = [NSString stringWithFormat:@"ParticleBuffer%i", i];
    }
}

- (void) increaseParticleCount:(NSTimer *) timer
{
    if ((_particleCount + kBatchSize) <= kMaximumNumberOfParticles) {
        _particleCount += kBatchSize;
    } else {
        [_timer invalidate];
    }
}

- (NSUInteger)upload
{
    NSUInteger particleCount = _particleCount;
    
    id<MTLBuffer> currentParticleBuffer = _particleBuffer[_currentBufferIndex];
    
    memcpy([currentParticleBuffer contents] , &_modelMatrices[0], particleCount * sizeof(simd::float4x4));
    
    return particleCount;
}

- (void)encode:(id<MTLRenderCommandEncoder>)encoder
{
    [encoder setVertexBuffer:_particleBuffer[_currentBufferIndex] offset:0 atIndex:PSParticleBuffer];
    
    _currentBufferIndex = (_currentBufferIndex + 1) % kInFlightCommandBuffers;
}

- (void)update
{
    NSUInteger particleCount = _particleCount;
    
    for (uint32_t i = 0; i < particleCount; ++i) {
        
        const GLfloat kFrameTime = 1.0f / 60.0f;
        
        _particles[i].vec.y -= 1 * kFrameTime;
        _particles[i].position = _particles[i].position + _particles[i].vec * kFrameTime;
        
        if (_particles[i].position.y < - 2.0f) {
            _particles[i].position.y = - 1.8f;
            _particles[i].vec.y = -_particles[i].vec.y;
            _particles[i].vec = _particles[i].vec * 0.8;
        }

        _modelMatrices[i] = AAPL::translate(_particles[i].position) * AAPL::scale(_particles[i].scale);
    }
}

@end
