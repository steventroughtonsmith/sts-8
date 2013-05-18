//
//  main.m
//  Director
//
//  Created by Steven Troughton-Smith on 25/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DRT.h"
#import "DRTCPU.h"

int main(int argc, char *argv[])
{
	if (argc > 1)
	{
		
		//[[DRTCPU sharedInstance] halt];
		//[[DRTCPU sharedInstance] load:argv[1]];
		//[[DRTCPU sharedInstance] coldBoot];
	}
	
	return NSApplicationMain(argc, (const char **)argv);
}
