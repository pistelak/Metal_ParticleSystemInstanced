//
//  Particles.h
//  OpenGLES_ParticleSystem
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 ran. All rights reserved.
//

#ifndef Particles_h
#define Particles_h

#ifdef __cplusplus

#import <vector>
#import "Math.h"

typedef struct {
    simd::float3 position;
    simd::float3 vec;
    float scale;
} particle_t;

const uint32_t kMaximumNumberOfParticles = 10000;
const uint32_t kBatchSize = 100;

static inline simd::float4x4 particleModelMatrix(particle_t *particle)
{
    simd::float4x4 modelMatrix = matrix_identity_float4x4;
    modelMatrix = AAPL::scale(particle->scale, particle->scale, particle->scale) * modelMatrix;
    modelMatrix = AAPL::translate(particle->position) * modelMatrix;
    
    return modelMatrix;
}

static inline particle_t particleWithInitialPosition(void)
{
    particle_t newParticle;
    
    newParticle.position = { 0.f, 0.f, 0.f };
    newParticle.scale = 0.05f;
    
    // inspired by https://github.com/floooh/oryol/blob/master/code/Samples/Instancing/Instancing.cc
    newParticle.vec = MathUtils::ballRandomVector3(0.5f);
    newParticle.vec.y += 2.f;
    
    return newParticle;
}

static inline std::vector<simd::float4x4> updateParticles(std::vector<particle_t> *particles, uint32_t newParticleCount)
{
    std::vector<simd::float4x4> modelMatrices;
    
    // new particles
    uint32_t currentNumberOfParticles = (uint32_t) particles->size();
    uint32_t diff = newParticleCount - currentNumberOfParticles;
    
    for (uint32_t i = 0; i < diff; ++i) {
        particles->push_back(particleWithInitialPosition());
    }
    
    const GLfloat kFrameTime = 1.0f / 60.0f;
    currentNumberOfParticles = (uint32_t) particles->size();
    
    for (uint32_t i = 0; i < currentNumberOfParticles; ++i) {
        particle_t *particle= &particles->at(i);
        
        // insipred by https://github.com/floooh/oryol/blob/master/code/Samples/Instancing/Instancing.cc
        particle->vec.y -= 1 * kFrameTime;
        particle->position = particle->position + particle->vec * kFrameTime;
        
        if (particle->position.y < -2.0f) {
            particle->position.y = -1.8f;
            particle->vec.y = -particle->vec.y;
            particle->vec = particle->vec * 0.8;
        }
        
        modelMatrices.push_back(particleModelMatrix(particle));
    }
    
    return modelMatrices;
}

#endif // cplusplus

#endif /* Particles_h */
