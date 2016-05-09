//
//  Shaders.metal
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>

#include "ShaderTypes.h"

using namespace metal;

struct VertexInput {
    float3 position [[attribute(AAPLVertexAttributePosition)]];
    float3 normal   [[attribute(AAPLVertexAttributeNormal)]];
};

typedef struct {
    float4 position [[position]];
} ShaderInOut;

vertex ShaderInOut vertexFunction(VertexInput in [[stage_in]],
                                  constant uniforms_t *uniforms[[buffer(AAPLFrameUniformBuffer)]])
{
    float4x4 mvpMatrix = uniforms->projectionMatrix * uniforms->viewMatrix * uniforms->modelMatrix;
    
    ShaderInOut out;
    out.position = mvpMatrix * float4(in.position, 1.0);
    return out;
}

fragment float4 fragmentFunction(void)
{
    return float4(1.0);
}
