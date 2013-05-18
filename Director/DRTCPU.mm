//
//  DRTCPU.m
//  Director
//
//  Created by Steven Troughton-Smith on 25/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import "DRTCPU.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

#include "sts8-core.h"

STS8 cpucore;

#define SINGLE_STEP 0

@implementation DRTCPU

NSDictionary *opcodes = nil;

typedef enum Operation
{
	OperationAdd,
	OperationSubtract,
	OperationMultiply,
	OperationDivide
} _Operation;

+ (DRTCPU *)sharedInstance
{
	DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
		return [[self alloc] init];
	});
}

-(void)setKey:(int)key
{
#if SINGLE_STEP
	[self tick];
	return;
#endif
	cpucore.setKey(key);
}

-(int)vmode
{
	return cpucore.screen.vmode;
}

-(Byte *)vram
{
	return cpucore.vram();
}


- (id)init
{
    self = [super init];
    if (self)
	{
		cpucore.init();
    }
    return self;
}

-(void)load:(char *)filePath
{
	cpucore.load(filePath);
}

-(void)halt
{
	cpucore.halt();
}

-(int)halted
{
	return cpucore.halted();
}

-(void)coldBoot
{
	cpucore.coldBoot();
	
	#if !SINGLE_STEP
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			
			while (1)
				[self tick];
			
		});
	});
	
	#endif
}

uint64_t lastTick;

-(void)tick
{
	cpucore.tickCPU();
	
	uint64_t currentTick = mach_absolute_time();
	
	//printf("%.2fMHz\n", (NSEC_PER_SEC/(CGFloat)(currentTick-lastTick))/1000000.0);
	
	lastTick = currentTick;
	
#if THROTTLE
	while (mach_absolute_time() <= lastTick+(NSEC_PER_MSEC*2))
	{
	}
#endif
}


@end
