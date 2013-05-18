//
//  DRT.h
//  Director
//
//  Created by Steven Troughton-Smith on 28/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#ifndef Director_DRT_h
#define Director_DRT_h

typedef unsigned char Byte;

#define COLUMNS 40
#define ROWS 30
#define SCREEN_WIDTH COLUMNS*16
#define SCREEN_HEIGHT ROWS*16

#define RAM_SIZE 1024
#define STACK_SIZE 10000
#define STARTADDR 100

#define MAGIC 0xDBF00000

typedef struct _DBFHeaderInternal
{
	Byte magic;
	int filesize;
	Byte unused[97];
} DBFHeaderInternal;

typedef DBFHeaderInternal * DBFHeader;

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;

#endif

enum COLOR_PALETTE {
	COLOR_BLACK = 0,
	COLOR_BLUE = 1,
	COLOR_GREEN = 2,
	COLOR_LIGHTBLUE = 4,
	COLOR_RED = 8,
	COLOR_PINK = 16,
	COLOR_YELLOW = 32,
	COLOR_WHITE = 64
};