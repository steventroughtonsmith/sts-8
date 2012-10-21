//
//  DRTAppDelegate.h
//  STS-8
//
//  Created by Steven Troughton-Smith on 17/09/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DRTViewController;

@interface DRTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DRTViewController *viewController;

@end
