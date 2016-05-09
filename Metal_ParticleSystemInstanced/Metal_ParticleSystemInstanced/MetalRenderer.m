//
//  MetalRenderer.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "MetalRenderer.h"
#import "ShaderTypes.h"

const unsigned kNumberOfInflightBuffers = 3;

@implementation MetalRenderer
{
    id <MTLLibrary> _defaultLibrary;
    id <MTLCommandQueue> _commandQueue;
    dispatch_semaphore_t _inflight_semaphore;
    
    id <MTLDepthStencilState> _depthState;
    id <MTLRenderPipelineState> _pipelineState;
    
    NSString *_vertexShaderName;
    NSString *_fragmentShaderName;
    
    // Mesh
    Mesh *_mesh;
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
        
        [self initializePipelineStateWithVertexShader:_vertexShaderName andFragmentShader:_fragmentShaderName];
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
    MTLVertexDescriptor *mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    
    mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLMeshVertexBuffer;
    
    mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatFloat3;
    mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 12;
    mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLMeshVertexBuffer;
    
    mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stride = 24;
    mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stepRate = 1;
    mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stepFunction = MTLVertexStepFunctionPerVertex;
    
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
    [pipelineStateDescriptor setVertexDescriptor:mtlVertexDescriptor];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat = _depthPixelFormat;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState || error) {
        assert(0);
    }
    
    // model object
    _mesh = [[Mesh alloc] initWithModelName:@"sphere" device:_device andMTLVertexDescriptor:mtlVertexDescriptor];
}

- (void)render:(View *)view
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor) {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [renderEncoder setDepthStencilState:_depthState];
        
        // render
        
        [renderEncoder endEncoding];
        
        __block dispatch_semaphore_t block_semaphore = _inflight_semaphore;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
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
    const float aspect = fabs(view.bounds.size.width / view.bounds.size.height);
    
    // set new projection matrix
}

- (void)update:(ViewController *)controller
{
    // set new view matrix
}


@end
