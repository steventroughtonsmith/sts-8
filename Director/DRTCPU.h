//
//  DRTCPU.h
//  Director
//
//  Created by Steven Troughton-Smith on 25/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DRT.h"


@interface DRTCPU : NSObject
{
	
}


-(void)setKey:(int)key;

-(Byte *)vram;
-(int)vmode;


+ (DRTCPU *)sharedInstance;
-(void)load:(char *)filePath;
-(void)coldBoot;
-(void)halt;
-(int)halted;
@end
