//
//  Mesh.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "Mesh.h"
#import "ShaderTypes.h"

@implementation Mesh
{
    MTLVertexDescriptor *_vertexDescriptor;
    
    NSArray<MTKMesh *> *_meshes;
    MTKMesh *_mesh;
    MTKSubmesh *_submesh;
}

- (instancetype) initWithModelName:(NSString *)modelName
                            device:(id<MTLDevice>)device
            andMTLVertexDescriptor:(MTLVertexDescriptor *) vertexDescriptor
{
    self = [super init];
    if (self) {
        
        _modelName = modelName;
        _vertexDescriptor = vertexDescriptor;
        
        // load mesh
        MDLAsset *asset = [[MDLAsset alloc] initWithURL:[self urlForResource]
                                       vertexDescriptor:[self modelIOVertexDescriptor]
                                        bufferAllocator:[[MTKMeshBufferAllocator alloc] initWithDevice:device]];

        NSError *error;
       _meshes = [MTKMesh newMeshesFromAsset:asset
                                      device:device
                                sourceMeshes:nil
                                       error:&error];
        
        if (!_meshes || error) {
            assert(0);
        }
        
        _mesh = [_meshes firstObject];
        _submesh = [_mesh.submeshes firstObject];
    }
    
    return self;
}

- (nullable NSURL *) urlForResource
{
    return [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"obj"];
}

- (MDLVertexDescriptor *) modelIOVertexDescriptor
{
    MDLVertexDescriptor *mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(_vertexDescriptor);
    mdlVertexDescriptor.attributes[PSVertexAttributePosition].name = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[PSVertexAttributeNormal].name = MDLVertexAttributeNormal;
    
    return mdlVertexDescriptor;
}

- (void) renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder instanceCount:(NSUInteger)instanceCount
{
    [encoder pushDebugGroup:@"Rendering model mesh"];
    
    MTKMeshBuffer *vertexBuffer = [_mesh.vertexBuffers firstObject];
    
    [encoder setVertexBuffer:vertexBuffer.buffer
                      offset:vertexBuffer.offset
                     atIndex:PSMeshVertexBuffer];
    
    [encoder drawIndexedPrimitives:_submesh.primitiveType
                        indexCount:_submesh.indexCount
                         indexType:_submesh.indexType
                       indexBuffer:_submesh.indexBuffer.buffer
                 indexBufferOffset:_submesh.indexBuffer.offset
                     instanceCount:instanceCount];

    [encoder popDebugGroup];
}

@end
