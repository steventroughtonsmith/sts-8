//
//  sts8-core.h
//  Director
//
//  Created by Steven Troughton-Smith on 12/05/2013.
//  Copyright (c) 2013 Steven Troughton-Smith. All rights reserved.
//

#ifndef Director_sts8_core_h
#define Director_sts8_core_h

#define VRAMSIZE SCREEN_WIDTH*SCREEN_HEIGHT

struct STS8 {
	
	Byte ram[RAM_SIZE];
	
	struct {
		Byte vram[VRAMSIZE];
		int vmode;
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
	int _halted;
	
	
	
	void setKey(int key);
	Byte *vram();
	void halt();
	int halted();
	void load(char *filePath);
	void tickCPU();
	void coldBoot();
	
	void init();
} ;
#endif
