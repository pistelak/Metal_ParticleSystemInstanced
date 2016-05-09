//
//  Mesh.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "Mesh.h"

@interface Submesh : NSObject

- (instancetype) initWithSubmesh:(MTKSubmesh *) MTKsubmesh;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;

@end

@implementation Submesh
{
    MTKSubmesh *_submesh;
}

- (instancetype) initWithSubmesh:(MTKSubmesh *) MTKsubmesh
{
    self = [super init];
    if (self) {
        _submesh = MTKsubmesh;
    }
    
    return self;
}

- (void) renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    
    [encoder drawIndexedPrimitives:_submesh.primitiveType
                        indexCount:_submesh.indexCount
                         indexType:_submesh.indexType
                       indexBuffer:_submesh.indexBuffer.buffer
                 indexBufferOffset:_submesh.indexBuffer.offset];
}

@end

@implementation Mesh
{
    MTLVertexDescriptor *_vertexDescriptor;
    
    NSArray<MTKMesh *> *_meshes;
    MTKMesh *_mesh;
    NSMutableArray<Submesh *> *_submeshes;
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
        _submeshes = [[NSMutableArray alloc] initWithCapacity:_mesh.submeshes.count];
        
        for(NSUInteger index = 0; index < _mesh.submeshes.count; index++) {
            Submesh *submesh = [[Submesh alloc] initWithSubmesh:_mesh.submeshes[index]];
            [_submeshes addObject:submesh];
        }
    }
    
    return self;
}

- (NSURL *) urlForResource
{
    return [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"obj"];
}

- (MDLVertexDescriptor *) modelIOVertexDescriptor
{
    MDLVertexDescriptor *mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(_vertexDescriptor);
    mdlVertexDescriptor.attributes[0].name = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[1].name = MDLVertexAttributeNormal;
    
    return mdlVertexDescriptor;
}

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    
    [_mesh.vertexBuffers enumerateObjectsUsingBlock:^(MTKMeshBuffer *vertexBuffer, NSUInteger index, BOOL *stop) {
        if (vertexBuffer.buffer != nil) {
            [encoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:index];
        }
    }];
    
    for(Submesh *submesh in _submeshes) {
        [submesh renderWithEncoder:encoder];
    }
}

@end
