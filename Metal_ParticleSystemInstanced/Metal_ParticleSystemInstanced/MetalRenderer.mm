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

@implementation MetalRenderer
{
    id<MTLLibrary> _defaultLibrary;
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLDepthStencilState> _depthState;
    id<MTLRenderPipelineState> _pipelineState;
    MTLVertexDescriptor *_mtlVertexDescriptor;
    
    float _angle;
    
    dispatch_semaphore_t _inflight_semaphore;
    
    // Mesh
    Mesh *_mesh;
    
    NSInteger _currentBufferIndex;
    id<MTLBuffer> _uniformBuffer[kInFlightCommandBuffers];
    simd::float4x4 _modelMatrix;
    simd::float4x4 _viewMatrix;
    simd::float4x4 _projectionMatrix;

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
        
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _defaultLibrary = [_device newDefaultLibrary];
        
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
        _currentBufferIndex = 0;
        
        [self initializePipelineStateWithVertexShader:vertexShaderName andFragmentShader:fragmentShaderName];
        [self initializeDataBuffers];
        
        _particleSystem = [[ParticleSystem alloc] initWithDevice:_device];
    }

    return self;
}

- (void)initializePipelineStateWithVertexShader:(NSString*)vertexShaderName andFragmentShader:(NSString*)fragmentShaderName
{
    // shaders
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:vertexShaderName];
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:fragmentShaderName];
    
    if (!vertexProgram || !fragmentProgram) {
        assert(0);
    }
    
    _depthState = [_device newDepthStencilStateWithDescriptor:[self depthStateDescriptor]];
    
    if (!_depthState) {
        assert(0);
    }
    
    _mtlVertexDescriptor = [self vertexDescriptor];
    
    // pipeline state descriptor
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    
    pipelineStateDescriptor.depthAttachmentPixelFormat = _depthPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState || error) {
        assert(0);
    }
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
    
    return mtlVertexDescriptor;
}

- (void) initializeDataBuffers
{
    // model object
    _mesh = [[Mesh alloc] initWithModelName:@"sphere" device:_device andMTLVertexDescriptor:_mtlVertexDescriptor];
    
    for (unsigned i = 0; i < kInFlightCommandBuffers; ++i) {
        _uniformBuffer[i] = [_device newBufferWithLength:sizeof(uniforms_t) options:MTLResourceCPUCacheModeDefaultCache];
        _uniformBuffer[i].label = [NSString stringWithFormat:@"UniformBuffer%i", i];
    }
}

#pragma mark -
#pragma mark View controller and view delegates

- (void)render:(View *)view
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    NSUInteger instanceCount = [_particleSystem upload];
    
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor) {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];
        
        [renderEncoder pushDebugGroup:@"Setting buffers"];
        
        [renderEncoder setVertexBuffer:_uniformBuffer[_currentBufferIndex] offset:0 atIndex:PSFrameUniformBuffer];
        
        [_particleSystem encode:renderEncoder];
        
        [renderEncoder popDebugGroup];
        
        [renderEncoder pushDebugGroup:@"Rendering model mesh"];
        
        [_mesh renderWithEncoder:renderEncoder instanceCount:instanceCount];
        
        [renderEncoder popDebugGroup];
        
        [renderEncoder endEncoding];
        
        __block dispatch_semaphore_t block_semaphore = _inflight_semaphore;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(block_semaphore);
        }];
        
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
        
        _currentBufferIndex = (_currentBufferIndex + 1) % kInFlightCommandBuffers;
    }
    else {
        dispatch_semaphore_signal(_inflight_semaphore);
    }
}

- (void)update:(ViewController *)controller
{
    _angle += [controller timeSinceLastDraw] * 0.1;
    simd::float3 cameraPosition = { sinf(_angle) * 10.f, 2.5f, cosf(_angle) * 10.f };
    _viewMatrix = MathUtils::lookAt(cameraPosition);
    
    [self updateUniformBuffer];
    
    [_particleSystem update];
}

- (void)reshape:(View *)view
{
    _projectionMatrix = MathUtils::projectionMatrix(view.bounds.size.width, view.bounds.size.height);
}

#pragma mark -
#pragma mark Buffers

- (void) updateUniformBuffer
{
    uniforms_t *uniforms = (uniforms_t *) [_uniformBuffer[_currentBufferIndex] contents];
    uniforms->viewMatrix = _viewMatrix;
    uniforms->projectionMatrix = _projectionMatrix;
}

@end
