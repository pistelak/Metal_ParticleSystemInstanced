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

enum AAPLVertexAttributes {
    AAPLVertexAttributePosition = 0,
    AAPLVertexAttributeNormal   = 1,
};

enum AAPLBufferIndex  {
    AAPLMeshVertexBuffer      = 0,
    AAPLFrameUniformBuffer    = 1,
};

#ifdef __cplusplus

/**
 * @brief Shared data types between CPU code and metal shader code
 */
typedef struct {
    simd::float4x4 modelMatrix;
    simd::float4x4 viewMatrix;
    simd::float4x4 projectionMatrix;
} uniforms_t;

#endif

#endif /* ShaderTypes_h */
