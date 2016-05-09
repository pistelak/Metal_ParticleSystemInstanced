//
//  View.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "View.h"

@implementation View
{
    __weak CAMetalLayer *_metalLayer;
    
    BOOL _layerSizeDidUpdate;
    
    id <MTLTexture>  _depthTex;
    id <MTLTexture>  _stencilTex;
    id <MTLTexture>  _msaaTex;
}

@synthesize currentDrawable      = _currentDrawable;
@synthesize renderPassDescriptor = _renderPassDescriptor;

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.opaque = YES;
        self.backgroundColor = nil;
        
        _metalLayer = (CAMetalLayer *) self.layer;
        _device = MTLCreateSystemDefaultDevice();
        
        _metalLayer.device          = _device;
        _metalLayer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
        
    }
    
    return self;
}

+ (Class) layerClass
{
    return [CAMetalLayer class];
}

- (void)setupRenderPassDescriptorForTexture:(id <MTLTexture>) texture
{
    if (_renderPassDescriptor == nil)
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    MTLRenderPassColorAttachmentDescriptor *colorAttachment = _renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture = texture;
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.clearColor = MTLClearColorMake(0.f, 0.7f, 0.f, 1.f);
    
    if(_depthPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate = (_depthTex.width != texture.width) ||  (_depthTex.height != texture.height);
        
        if(!_depthTex || doUpdate)
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _depthPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType = MTLTextureType2D;
            
            _depthTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassDepthAttachmentDescriptor *depthAttachment = _renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTex;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
}

- (MTLRenderPassDescriptor *)renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable) {
        NSLog(@"ERR: No drawable!");
        _renderPassDescriptor = nil;
    }
    else {
        [self setupRenderPassDescriptorForTexture:drawable.texture];
    }
    
    return _renderPassDescriptor;
}


- (id <CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil)
        _currentDrawable = [_metalLayer nextDrawable];
    
    return _currentDrawable;
}

- (void)display
{
    @autoreleasepool
    {
        if(_layerSizeDidUpdate)
        {
            CGSize drawableSize = self.bounds.size;
            drawableSize.width  *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            
            _metalLayer.drawableSize = drawableSize;
            
            [_delegate reshape:self];
            
            _layerSizeDidUpdate = NO;
        }
        
        [self.delegate render:self];
        
        _currentDrawable    = nil;
    }
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}

@end
