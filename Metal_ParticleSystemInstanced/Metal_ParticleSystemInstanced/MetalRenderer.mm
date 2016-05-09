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

const unsigned kNumberOfInflightBuffers = 3;

@implementation MetalRenderer
{
    id<MTLLibrary> _defaultLibrary;
    NSString *_vertexShaderName;
    NSString *_fragmentShaderName;
    
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLDepthStencilState> _depthState;
    id<MTLRenderPipelineState> _pipelineState;
    MTLVertexDescriptor *_mtlVertexDescriptor;
    
    float _angle;
    
    dispatch_semaphore_t _inflight_semaphore;
    
    id<MTLBuffer> _uniformBuffer;
    NSInteger _currentBufferIndex;
    
    // Mesh
    Mesh *_mesh;
    
    simd::float4x4 _modelMatrix;
    simd::float4x4 _viewMatrix;
    simd::float4x4 _projectionMatrix;
}

- (instancetype) initWithVertexShader:(NSString *) vertexShaderName
                    andFragmentShader:(NSString *) fragmentShaderName
{
    self = [super init];
    if (self) {
        
        _vertexShaderName = vertexShaderName;
        _fragmentShaderName = fragmentShaderName;
        _depthPixelFormat = MTLPixelFormatDepth32Float;
        
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _defaultLibrary = [_device newDefaultLibrary];
        
        _inflight_semaphore = dispatch_semaphore_create(kNumberOfInflightBuffers);
        _currentBufferIndex = 0;
        
        [self initializePipelineStateWithVertexShader:_vertexShaderName andFragmentShader:_fragmentShaderName];
        [self initializeDataBuffers];
    }
    
    return self;
}

- (void)initializePipelineStateWithVertexShader:(NSString*)vertexShaderName andFragmentShader:(NSString*)fragmentShaderName
{
    // shaders
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:vertexShaderName];
    if(!vertexProgram) {
        assert(0);
    }
    
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:fragmentShaderName];
    if(!fragmentProgram) {
        assert(0);
    }
    
    // vertex descriptor
    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 12;
    
    _mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stride = 24;
    _mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stepRate = 1;
    _mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stepFunction = MTLVertexStepFunctionPerVertex;
    
    // depth
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    if (!_depthState) {
        assert(0);
    }
    
    // pipeline state
    NSError *error;
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    [pipelineStateDescriptor setVertexDescriptor:_mtlVertexDescriptor];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat = _depthPixelFormat;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState || error) {
        assert(0);
    }
}

- (void) initializeDataBuffers
{
    // model object
    _mesh = [[Mesh alloc] initWithModelName:@"sphere" device:_device andMTLVertexDescriptor:_mtlVertexDescriptor];
    
    // uniform buffer
    _uniformBuffer = [_device newBufferWithLength:sizeof(uniforms_t) * kNumberOfInflightBuffers
                                          options:MTLResourceCPUCacheModeDefaultCache];
    _uniformBuffer.label = @"Uniforms";
}

- (void)render:(View *)view
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor) {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        
        // render
        const NSUInteger uniformBufferOffset = sizeof(uniforms_t) * _currentBufferIndex;
        [renderEncoder setVertexBuffer:_uniformBuffer offset:uniformBufferOffset atIndex:AAPLFrameUniformBuffer];
        
        [_mesh renderWithEncoder:renderEncoder];
        
        [renderEncoder endEncoding];
        
        __block dispatch_semaphore_t block_semaphore = _inflight_semaphore;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            _currentBufferIndex = (_currentBufferIndex + 1) % kNumberOfInflightBuffers;
            dispatch_semaphore_signal(block_semaphore);
        }];
        
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
    else {
        dispatch_semaphore_signal(_inflight_semaphore);
    }
}

- (void)reshape:(View *)view
{
    _projectionMatrix = MathUtils::projectionMatrix(view.bounds.size.width, view.bounds.size.height);
    
    [self updateUniformBuffer];
}

- (void)update:(ViewController *)controller
{
    _angle += [controller timeSinceLastDraw] * 0.1;
    simd::float3 cameraPosition = { sinf(_angle) * 10.f, 2.5f, cosf(_angle) * 10.f };
    _viewMatrix = MathUtils::lookAt(cameraPosition);
    
    [self updateUniformBuffer];
}

- (void) updateUniformBuffer
{
    uniforms_t uniforms;
    uniforms.modelMatrix = matrix_identity_float4x4;
    uniforms.viewMatrix = _viewMatrix;
    uniforms.projectionMatrix = _projectionMatrix;
    
    const size_t offset = sizeof(uniforms_t) * _currentBufferIndex;
    
    // I hate c++
    char *uniformBufferBgn = (char *) [_uniformBuffer contents];
    memcpy(uniformBufferBgn + offset, &uniforms, sizeof(uniforms));
}

@end
