//
//  ViewController.h
//  Metal_ParticleSystemInstanced
//
//  Created by Radek Pistelak on 5/9/16.
//  Copyright © 2016 Radek Pistelak. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AAPLView.h"

@protocol ViewControllerDelegate;

@interface ViewController : UIViewController

@property (nonatomic, weak) id<ViewControllerDelegate> delegate;

@property (nonatomic, readonly) CFTimeInterval timeSinceLastDraw;

@end

@protocol ViewControllerDelegate <NSObject>

- (void)update:(ViewController *)controller;

@end
