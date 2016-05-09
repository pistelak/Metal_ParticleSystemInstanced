//
//  View.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@protocol ViewDelegate;

@interface View : UIView

@property (nonatomic, readonly) id <MTLDevice> device;
@property (nonatomic, readonly) id <CAMetalDrawable> currentDrawable;
@property (nonatomic, readonly) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic) MTLPixelFormat depthPixelFormat;

@property (nonatomic, weak) id<ViewDelegate> delegate;

- (void) display;

@end

@protocol ViewDelegate <NSObject>

- (void) reshape:(View *) view;
- (void) render:(View *) view;

@end