//
//  Math.h
//  OpenGLES_ParticleSystem
//
//  Created by Radek Pistelak on 5/8/16.
//  Copyright © 2016 ran. All rights reserved.
//

#ifndef Math_h
#define Math_h

#import "AAPLTransforms.h"

#ifdef __cplusplus

namespace MathUtils
{
    #pragma mark -
    #pragma mark MVP matrices
    
    static inline simd::float4x4 projectionMatrix(const float width, const float height)
    {
        static const float fov = 45.f;
        static const float nearZ = 0.1f;
        static const float farZ = 100.f;
        
        return AAPL::perspective_fov(fov, width, height, nearZ, farZ);
    }
    
    static inline simd::float4x4 lookAt(simd::float3 cameraPosition)
    {
        static const simd::float3 center = { 0.f, 0.f, 0.f };
        static const simd::float3 up = { 0.f, 1.f, 0.f };
        
        return AAPL::lookAt(cameraPosition, center, up);
    }
    
    #pragma mark -
    #pragma mark Random numbers
    
    static inline float randomNumber(float min, float max, float offset)
    {
        float pseudoRandomNumber = min + (float) (rand()) / ( (float) (RAND_MAX/(max-min)));
        return pseudoRandomNumber + offset;
    }
    
    static inline simd::float3 randomVector3(float min, float max, float offset)
    {
        return (simd::float3) { randomNumber(min, max, offset),
                                randomNumber(min, max, offset),
                                randomNumber(min, max, offset) };
    }
    
    static inline simd::float3 ballRandomVector3(float radius)
    {
        // inspired by openGL math
        simd::float3 result;
        float length;
        
        do {
            result = randomVector3(0, radius, -radius/2);
            length = vector_length(result);
            
        } while (length > radius);
        
        return result;
    }
}

#endif  // cplusplus

#endif /* Math_h */
