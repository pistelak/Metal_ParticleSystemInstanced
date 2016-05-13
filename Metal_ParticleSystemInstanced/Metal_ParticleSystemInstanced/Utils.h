//
//  Utils.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/13/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#ifndef Utils_h
#define Utils_h

static id<MTLFunction> _newFunctionFromLibrary(id<MTLLibrary> library, NSString *name)
{
    id<MTLFunction> func = [library newFunctionWithName: name];
    if (!func) {
        NSLog(@"failed to find function %@ in the library", name);
        assert(0);
    }
    return func;
}

static id<MTLRenderPipelineState> _createPipelineStateObject(id<MTLDevice> device, MTLRenderPipelineDescriptor *descriptor)
{
    NSError *error;
    id<MTLRenderPipelineState> PSO = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (!PSO || error) {
        NSLog(@"Failed to create pipeline. Error description: %@", [error description]);
        assert(0);
    }
    
    return PSO;
}

static id<MTLDepthStencilState> _createDepthStateObject(id<MTLDevice> device, MTLDepthStencilDescriptor *depthDescriptor)
{
    id<MTLDepthStencilState> depthState = [device newDepthStencilStateWithDescriptor:depthDescriptor];
    
    if (!depthState) {
        NSLog(@"Failed to create depth state object.");
        assert(0);
    }
    
    return depthState;
}

#endif /* Utils_h */
