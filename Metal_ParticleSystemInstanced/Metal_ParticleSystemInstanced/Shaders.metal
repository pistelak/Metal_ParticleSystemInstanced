//
//  Shaders.metal
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
};

struct VertexPointOut
{
    float4 position [[position]];
    float pointSize [[point_size]];
};

struct Uniforms
{
    float4x4 projectionMatrix;
};

vertex Vertex vertexFunction(device Vertex *vertices [[buffer(0)]],
                             constant Uniforms * uniforms [[buffer(1)]],
                             uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = uniforms->projectionMatrix * vertices[vid].position;
    
    return vertexOut;
}

vertex VertexPointOut vertexFunctionForPoints(device Vertex *vertices [[buffer(0)]],
                                              constant Uniforms * uniforms [[buffer(1)]],
                                              uint vid [[vertex_id]])
{
    VertexPointOut vertexOut;
    vertexOut.position = uniforms->projectionMatrix * vertices[vid].position;
    vertexOut.pointSize = 1.0f;
    
    return vertexOut;
}

fragment half4 fragmentFunction(void)
{
    return half4(1.0, 1.0, 1.0, 1.0);
}
