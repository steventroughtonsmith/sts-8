//
//  DRTViewController.h
//  STS-8
//
//  Created by Steven Troughton-Smith on 17/09/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DRTMobileScreenView;
@interface DRTViewController : UIViewController
{
	UIWindow *mirrorWindow ;
}

@property (weak, nonatomic) IBOutlet DRTMobileScreenView *screenView;
@property (weak, nonatomic) IBOutlet UITextView *editView;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *led;

- (IBAction)reset:(id)sender;

@end
