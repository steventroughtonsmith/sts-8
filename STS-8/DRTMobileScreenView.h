//
//  DRTMobileScreenView.h
//  Director
//
//  Created by Steven Troughton-Smith on 17/09/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DRTMobileScreenView : UIView <UIKeyInput, UITextInputTraits>
{
	CGContextRef ctx;
	uint32_t *videoBuffer;
}
@end
