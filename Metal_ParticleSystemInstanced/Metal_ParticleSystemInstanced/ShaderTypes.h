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

/// Indices of vertex attribute in descriptor.
enum AAPLVertexAttributes {
    AAPLVertexAttributePosition = 0,
    AAPLVertexAttributeNormal   = 1,
};

/// Indices for buffer bind points.
enum AAPLBufferIndex  {
    AAPLMeshVertexBuffer      = 0,
    AAPLFrameUniformBuffer    = 1,
};

#endif /* ShaderTypes_h */
