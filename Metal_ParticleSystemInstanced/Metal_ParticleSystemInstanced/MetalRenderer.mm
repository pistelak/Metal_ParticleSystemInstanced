//
//  MetalRenderer.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "MetalRenderer.h"
#import "ShaderTypes.h"
#import "Math.h"
#import "ParticleSystem.h"
#import "Uniforms.h"
#import "Utils.h"

@implementation MetalRenderer
{
    id<MTLLibrary> _defaultLibrary;
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLDepthStencilState> _depthState;
    id<MTLRenderPipelineState> _pipelineStateObject;
    MTLVertexDescriptor *_mtlVertexDescriptor;
    
    dispatch_semaphore_t _inflight_semaphore;
    
    Mesh *_mesh;
    
    Uniforms *_uniforms;
    ParticleSystem *_particleSystem;
}

#pragma mark -
#pragma mark Init

- (instancetype) initWithVertexShader:(NSString *) vertexShaderName
                    andFragmentShader:(NSString *) fragmentShaderName
{
    self = [super init];
    if (self) {
        
        _depthPixelFormat = MTLPixelFormatDepth32Float;
        _stencilPixelFormat = MTLPixelFormatInvalid;
        _sampleCount = 1;
        
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _defaultLibrary = [_device newDefaultLibrary];
        
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
        
        [self initializePipelineStateWithVertexShader:vertexShaderName andFragmentShader:fragmentShaderName];
        
        _particleSystem = [[ParticleSystem alloc] initWithDevice:_device];
        _uniforms = [[Uniforms alloc] initWithDevice:_device];
        
        _mesh = [[Mesh alloc] initWithModelName:@"sphere" device:_device andMTLVertexDescriptor:_mtlVertexDescriptor];
    }

    return self;
}

- (void)initializePipelineStateWithVertexShader:(NSString*)vertexShaderName andFragmentShader:(NSString*)fragmentShaderName
{
    id <MTLFunction> vertexProgram = _newFunctionFromLibrary(_defaultLibrary, vertexShaderName);
    id <MTLFunction> fragmentProgram = _newFunctionFromLibrary(_defaultLibrary, fragmentShaderName);
    
    _depthState = _createDepthStateObject(_device, [self depthStateDescriptor]);
    _mtlVertexDescriptor = [self vertexDescriptor];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    
    pipelineStateDescriptor.depthAttachmentPixelFormat = _depthPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    _pipelineStateObject = _createPipelineStateObject(_device, pipelineStateDescriptor);
}

- (MTLDepthStencilDescriptor *) depthStateDescriptor
{
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    
    return depthStateDesc;
}

- (MTLVertexDescriptor *) vertexDescriptor
{
    MTLVertexDescriptor *mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    mtlVertexDescriptor.attributes[PSVertexAttributePosition].format = MTLVertexFormatFloat3;
    mtlVertexDescriptor.attributes[PSVertexAttributePosition].offset = 0;
    mtlVertexDescriptor.attributes[PSVertexAttributePosition].bufferIndex = PSMeshVertexBuffer;
    
    mtlVertexDescriptor.attributes[PSVertexAttributeNormal].format = MTLVertexFormatFloat3;
    mtlVertexDescriptor.attributes[PSVertexAttributeNormal].offset = 12;
    mtlVertexDescriptor.attributes[PSVertexAttributeNormal].bufferIndex = PSMeshVertexBuffer;
    
    mtlVertexDescriptor.layouts[PSMeshVertexBuffer].stride = 24;
    mtlVertexDescriptor.layouts[PSMeshVertexBuffer].stepRate = 1;
    mtlVertexDescriptor.layouts[PSMeshVertexBuffer].stepFunction = MTLVertexStepFunctionPerVertex;
    
    mtlVertexDescriptor.layouts[PSFrameUniformBuffer].stepFunction = MTLVertexStepFunctionConstant;
    mtlVertexDescriptor.layouts[PSParticleBuffer].stepFunction = MTLVertexStepFunctionPerInstance;
    
    return mtlVertexDescriptor;
}

#pragma mark -
#pragma mark View controller and view delegates

- (void)render:(AAPLView *)view
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    [_uniforms upload];
    
    // upload updated particles to CPU/GPU buffer
    NSUInteger instanceCount = [_particleSystem upload];
    
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // descriptor for current render pass
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor) {
        
        // render encoder with current descriptor
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        // set pipeline state
        [renderEncoder setRenderPipelineState:_pipelineStateObject];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setCullMode:MTLCullModeBack];
        
        [renderEncoder pushDebugGroup:@"Setting buffers"];
        {
            [_uniforms encode:renderEncoder];
            [_particleSystem encode:renderEncoder];
        }
        [renderEncoder popDebugGroup];
        
        [renderEncoder pushDebugGroup:@"Rendering model mesh"];
        {
            [_mesh renderWithEncoder:renderEncoder instanceCount:instanceCount];
        }
        [renderEncoder popDebugGroup];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    __block dispatch_semaphore_t block_semaphore = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_semaphore);
    }];
    
    [commandBuffer commit];
}

- (void)update:(ViewController *)controller
{
    _uniforms.timeSinceLastDraw = [controller timeSinceLastDraw];
    
    [_uniforms update];
    [_particleSystem update];
}

- (void)reshape:(AAPLView *)view
{
    _uniforms.drawableSize = view.drawableSize;
}

@end
