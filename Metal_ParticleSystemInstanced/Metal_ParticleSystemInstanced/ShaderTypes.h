//
//  ShaderTypes.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

enum PSVertexAttributes {
    PSVertexAttributePosition = 0,
    PSVertexAttributeNormal   = 1,
};

enum PSBufferIndex  {
    PSMeshVertexBuffer      = 0,
    PSFrameUniformBuffer    = 1,
    PSParticleBuffer        = 2,
};

#ifdef __cplusplus

/**
 * @brief Shared data types between CPU code and metal shader code
 */
typedef struct {
    simd::float4x4 viewMatrix;
    simd::float4x4 projectionMatrix;
    simd::float4x4 spacing;
} uniforms_t;

#endif

#endif /* ShaderTypes_h */
