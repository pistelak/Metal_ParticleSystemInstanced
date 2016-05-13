//
//  ViewController.m
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import "ViewController.h"

#import "MetalRenderer.h"

@interface ViewController ()

@end

@implementation ViewController
{
@private
    // display
    CADisplayLink *_timer;
    
    MetalRenderer *_renderer;
    
    BOOL _firstDrawOccurred;
    CFTimeInterval _timeSinceLastDrawPreviousTime;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        // pass
    }
    
    return self;
}

- (void) loadView
{
    self.view = [[AAPLView alloc] init];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _renderer = [[MetalRenderer alloc] initWithVertexShader:@"vertexFunction" andFragmentShader:@"fragmentFunction"];
    
    AAPLView *metalView = (AAPLView *) self.view;
    
    assert([metalView isKindOfClass:[AAPLView class]]);
    
    metalView.contentScaleFactor = [UIScreen mainScreen].nativeScale;
    metalView.depthPixelFormat = _renderer.depthPixelFormat;
    metalView.stencilPixelFormat = _renderer.stencilPixelFormat;
    metalView.sampleCount = _renderer.sampleCount;
    metalView.delegate = _renderer;
    self.delegate = _renderer;
    
    [self dispatchGameLoop];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

#pragma mark -
#pragma mark Drawing

- (void) dispatchGameLoop
{
    _timer = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(gameloop)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void) gameloop
{
    [_delegate update:self];
    
    if(!_firstDrawOccurred) {
        _timeSinceLastDraw             = 0.0;
        _timeSinceLastDrawPreviousTime = CACurrentMediaTime();
        _firstDrawOccurred              = YES;
    }
    else {
        CFTimeInterval currentTime = CACurrentMediaTime();
        _timeSinceLastDraw = currentTime - _timeSinceLastDrawPreviousTime;
        _timeSinceLastDrawPreviousTime = currentTime;
    }
    
    [(AAPLView *) self.view display];
}

@end
