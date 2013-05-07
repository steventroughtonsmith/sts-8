//
//  DRT.h
//  Director
//
//  Created by Steven Troughton-Smith on 28/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#ifndef Director_DRT_h
#define Director_DRT_h


#define COLUMNS 40
#define ROWS 30
#define RAM_SIZE 1024
#define STACK_SIZE 10000
#define STARTADDR 100

#define MAGIC 0xDB|0xF0<<8

typedef struct _DBFHeaderInternal
{
	short magic;
	Byte filesize;
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
