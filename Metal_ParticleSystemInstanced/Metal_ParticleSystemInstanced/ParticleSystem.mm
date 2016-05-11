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
static const size_t kGPUParticleSize = sizeof(particleGPU_t);
static const size_t kParticleBufferSize = kGPUParticleSize * kMaximumNumberOfParticles * kInFlightCommandBuffers;

@implementation ParticleSystem
{
    NSUInteger _currentBufferIndex;
    id<MTLBuffer> _particleBuffer;
    
    particle_t _particles[kMaximumNumberOfParticles];
    simd::float4x4 _modelMatrices[kMaximumNumberOfParticles];
    
    NSTimer *_timer;
    NSUInteger _particleCount;
    
    dispatch_group_t _dispatchGroup;
    dispatch_queue_t _bgQueue;
    dispatch_semaphore_t _particleSystemUpdateSemaphore;
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
        [self initializeModelMatrices];
        [self createParticleBufferOnDevice:device];
        
        _dispatchGroup = dispatch_group_create();
        _bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    }
    
    return self;
}

static inline float particleScale() {
    return 0.05f;
}

- (void) initializeAllParticles
{
    for (uint32_t i = 0; i < kMaximumNumberOfParticles; ++i) {
        
        _particles[i].position = 0.f;
        _particles[i].scale = particleScale();
        _particles[i].vec = MathUtils::ballRandomVector3(0.5f);
        _particles[i].vec.y += 2.f;
    }
}

- (void) initializeModelMatrices
{
    /**
     * Pri startu programu nastavim vsem maticim vychozi scale,
     * ktery modifikuje pouze diagonalu matice
     */
    for (uint32_t i = 0; i < kMaximumNumberOfParticles; ++i) {
        _modelMatrices[i] = AAPL::scale(particleScale());
    }
}

- (void) createParticleBufferOnDevice:(id<MTLDevice>) device
{
    _particleBuffer = [device newBufferWithLength:kParticleBufferSize options:MTLResourceCPUCacheModeDefaultCache];
    _particleBuffer.label = @"ParticleBuffer";
}

- (void) increaseParticleCount:(NSTimer *) timer
{
    if ((_particleCount + kBatchSize) <= kMaximumNumberOfParticles) {
        _particleCount += kBatchSize;
    } else {
        [_timer invalidate];
    }
}

- (NSUInteger) upload
{
    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
    NSUInteger particleCount = _particleCount;
    
    size_t offset = _currentBufferIndex * kGPUParticleSize * kMaximumNumberOfParticles;
    simd::float4x4 *ptrData = (simd::float4x4 *) ((uintptr_t) [_particleBuffer contents] + offset);
    
    memcpy(ptrData, &_modelMatrices[0], particleCount * sizeof(simd::float4x4));
    
    return particleCount;
}

- (void) encode:(id<MTLRenderCommandEncoder>)encoder
{
    size_t offset = _currentBufferIndex * kGPUParticleSize * kMaximumNumberOfParticles;
    [encoder setVertexBuffer:_particleBuffer offset:offset atIndex:PSParticleBuffer];
    
    _currentBufferIndex = (_currentBufferIndex + 1) % kInFlightCommandBuffers;
}

- (void) _update
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

        /**
         * Diky tomu ze je scale nastaveny v dobe inicializace muzu ted upravit
         * pouze jeden ze sloupcu matice a nastavit tak pozici modelu  
         * Proc? usetreni nasobeni matic
         */
        _modelMatrices[i].columns[3].xyz = _particles[i].position;
    }
}

- (void) update
{
    /**
     * Update dat se provede ve fronte na pozadi
     * I kdyz je objekt dostane zpravu upload, tak ceka na dokonceni operace upload
     */
    __block ParticleSystem *blockSelf = self;

    dispatch_group_async(_dispatchGroup, _bgQueue, ^{
        [blockSelf _update];
    });

}


@end
