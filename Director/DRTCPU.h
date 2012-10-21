//
//  DRTCPU.h
//  Director
//
//  Created by Steven Troughton-Smith on 25/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DRT.h"

#define VRAMSIZE COLUMNS*ROWS

@interface DRTCPU : NSObject
{
	Byte ram[RAM_SIZE];
	
	struct {
		Byte vram[VRAMSIZE];
	} screen;

	struct {
		int accumulator;
		int x;
		int y;
		
		int programCounter;
		int stackPointer;
	} registers;

	int stack[STACK_SIZE];
	int keyChar;
	int halted;
}


-(void)setKey:(int)key;

-(Byte *)vram;
+(NSDictionary *)opcodes;

+ (DRTCPU *)sharedInstance;
-(void)load:(char *)filePath;
-(void)coldBoot;
-(void)halt;
-(int)halted;
@end
