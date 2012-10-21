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

Byte binary[RAM_SIZE];


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
	keyChar = key;
}

-(Byte *)vram
{
	return screen.vram;
}

+(NSDictionary *)opcodes
{
	return @{
	
	/*
		ROM ROUTINES
	 
		JMP 0xFE - print stack
		JMP 0xFF - print a
		
		MEMORY LOCATIONS
		'_keyboard', or ram[0x1]
		
	*/
	
	
	/* CPU */
	@"HLT" : @0xFF,
	
	/* accumulator */
	@"LD" : @0x01, // a = operand
	@"LDA" : @0x02,	// byte@operand -> a
	@"ST" : @0x03, // a -> byte@operand
	
	/* math */
	@"ADD" : @0x10, // a += operand
	@"SUB" : @0x11,	// a -= operand
	@"MUL" : @0x12, // a *= operand
	@"DIV" : @0x13, // a /= operand
	
	/* branching*/
	@"B" : @0x20, // goto operand
	@"BP" : @0x20, // if (a > 0) goto operand
	@"BN" : @0x21, // if (a < 0) goto operand
	@"BZ" : @0x22, // if (a == 0) goto operand
	
	/* subroutines */
	@"JMP" : @0x30, // PC->stack; goto operand
	@"RET" : @0x31, // stack->PC; return to PC
	@"PUSH" : @0x32, // a->stack
	@"POP" : @0x33, // stack->a
	
	/* x & y*/
	@"X" : @0x40, // x = operand
	@"Y" : @0x41, // y = operand
	@"INCX" : @0x42, // x++
	@"INCY" : @0x43, // y++
	@"DECX" : @0x44, // x--
	@"DECY" : @0x45, // y--
	
	/* VRAM */
	@"TAX" : @0x50, // transfer a to vram[x][y]
	@"TXA" : @0x51, // transfer x to a
	@"RXA" : @0x52, // transfer byte@operand+x to a
	
	
	};
}

- (id)init
{
    self = [super init];
    if (self) {
		
		opcodes = [DRTCPU opcodes];
		
		
    }
    return self;
}

-(void)load:(char *)filePath
{
	FILE *fin = fopen (filePath, "r");
	if (fin != NULL) {
		
		int count = 0;
		while (!feof(fin))
		{
			fgetc(fin);
			count++;
		}
		
		fseek(fin, 0, SEEK_SET);
		
		fread(binary, count, 1, fin);
		
		printf("binary loaded:\n");
		for (int i = 0; i < count; i++)
		{
			printf("%X|", binary[i]);
		}
		printf("\n");
		
		fclose (fin);
	}
}

-(void)halt
{
	halted = 1;
}

-(int)halted
{
	return halted;
}

-(void)coldBoot
{
	for (int i = STARTADDR; i < RAM_SIZE; i++)
	{
		ram[i] = 0;
	}
	
	registers.programCounter = STARTADDR;
	registers.accumulator = 0;
	registers.x = 0;
	registers.y = 0;
	registers.stackPointer = STACK_SIZE;
	halted = 0;
	keyChar = -1;
	
	for (int i = STARTADDR; i < RAM_SIZE; i++)
	{
		ram[i] = binary[i];
	}
	
	for (int i = 0; i < STACK_SIZE; i++)
	{
		stack[i] = 0xFF;
	}
	
	for (int i = 0; i < VRAMSIZE; i++)
	{
		screen.vram[i] = 0;
	}
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		while (!halted)
		{
			[self tick];
		}
	});
}

#define INSTR(x) [opcodes[[NSString stringWithFormat:@"%s", x]] isEqual:@(operation)]

uint64_t lastTick;

-(void)tick
{
	int operation = ram[registers.programCounter];
	int operand = ram[registers.programCounter+1];
	
	if (halted)
		return;
	
	//	printf("tick; op = %X\n", operation);
	
	if (INSTR("TAX"))
	{
		screen.vram[(COLUMNS*(registers.y))+registers.x] = registers.accumulator;
		registers.programCounter++;
		
	}
	
	if (INSTR("TXA"))
	{
		registers.accumulator = registers.x;
		registers.programCounter++;
		
	}
	
	if (INSTR("RXA"))
	{
		registers.accumulator = ram[operand+registers.x];
		registers.programCounter+=2;
	}
	
	/* Accumulator */
	
	if (INSTR("LD"))
	{
		registers.accumulator = operand;
		registers.programCounter+=2;
	}
	
	if (INSTR("LDA"))
	{
		if (operand == 0x01)
		{
			if (keyChar >= 0)
			{
				printf("key input = %i\n", keyChar);
			}
			registers.accumulator = keyChar;

			registers.programCounter+=2;
			
			keyChar = -1;
		}
		else
		{
			registers.accumulator = ram[operand];
			registers.programCounter+=2;
		}
	}
	
	if (INSTR("ST"))
	{
		ram[operand] = registers.accumulator;
		registers.programCounter+=2;
	}
	
	
	/* Subroutines */
	
	if (INSTR("JMP"))
	{
		//		printf("JMP to %i\n", argument);
		
		
		
		registers.stackPointer--;
		
		if (registers.stackPointer < 0)
		{
			printf("STACK OVERFLOW\n");
			halted = 1;
		}
		
		stack[registers.stackPointer] = registers.programCounter;
		
		printf("old pc = %i, new = %i\n", registers.programCounter, operand);
		registers.programCounter = operand;
		
		/* ROM Routines */
		
		switch (operand) {
			case 0xFE:
			{
				printf("STACK = \n");
				
				for (int i = 0; i <STACK_SIZE; i++)
				{
					printf("%X ", stack[i]);
				}
				
				registers.programCounter = stack[registers.stackPointer]+2;
				registers.stackPointer++;
				
				break;
			}
				
			case 0xFF:
			{
				printf("ACC = %i\n", registers.accumulator);
				
				registers.programCounter = stack[registers.stackPointer]+2;
				registers.stackPointer++;
				break;
			}
				
			default:
				break;
		}
		
	}
	
	if (INSTR("RET"))
	{
		
		printf("returning to = %i\n", stack[registers.stackPointer]);
		
		registers.programCounter = stack[registers.stackPointer]+2;
		registers.stackPointer++;
	}
	
	
	/* Stack */
	
	if (INSTR("PUSH"))
	{
		registers.stackPointer--;
		stack[registers.stackPointer] = registers.accumulator;
		
		registers.programCounter ++;
	}
	
	if (INSTR("POP"))
	{
		registers.accumulator = stack[registers.stackPointer];
		registers.stackPointer++;
		
		registers.programCounter ++;
	}
	
	/* Math */
	
	if (INSTR("ADD"))
	{
		registers.accumulator = registers.accumulator + operand;
		registers.programCounter+=2;
	}
	
	if (INSTR("SUB"))
	{
		registers.accumulator = registers.accumulator - operand;
		registers.programCounter+=2;
		
	}
	
	if (INSTR("MUL"))
	{
		registers.accumulator = registers.accumulator * operand;
		registers.programCounter+=2;
	}
	
	if (INSTR("DIV"))
	{
		registers.accumulator = registers.accumulator / operand;
		registers.programCounter+=2;
	}
	
	/* Branching */
	
	if (INSTR("B"))
	{
		registers.programCounter = operand;
	}
	
	if (INSTR("BP"))
	{
		if (registers.accumulator > 0)
		{
			registers.programCounter = operand;
		}
		else
			registers.programCounter+=2;
	}
	
	if (INSTR("BN"))
	{
		if (registers.accumulator < 0)
		{
			registers.programCounter = operand;
		}
		else
			registers.programCounter+=2;
	}
	
	if (INSTR("BZ"))
	{
		if (registers.accumulator == 0)
		{
			registers.programCounter = operand;
		}
		else
			registers.programCounter+=2;
	}
	
	
	/* X & Y */
	
	if (INSTR("X"))
	{
		printf("load x = %i\n", operand);
		registers.x = operand;
		
		registers.programCounter+=2;
	}
	
	if (INSTR("Y"))
	{
		registers.y = operand;
		registers.programCounter+=2;
	}
	
	if (INSTR("INCX"))
	{
		registers.x++;
		registers.programCounter++;
		
	}
	
	if (INSTR("DECX"))
	{
		registers.x--;
		registers.programCounter++;
		
	}
	
	if (INSTR("INCY"))
	{
		registers.y++;
		registers.programCounter++;
		
	}
	
	if (INSTR("DECY"))
	{
		registers.y--;
		registers.programCounter++;
		
	}
	
	/* CPU Flow */
	
	if (INSTR("HLT"))
	{
		printf("halted.\n");
		
		printf("A = %i\nX = %i\nY = %i\n", registers.accumulator, registers.x, registers.y);
		halted = 1;
	}
	
	
	
	uint64_t currentTick = mach_absolute_time();
	
	//	printf("%.0fHz\n", NSEC_PER_SEC/(CGFloat)(currentTick-lastTick));
	
	lastTick = currentTick;
	
#if TARGET_CPU_ARM
	
#else
	while (mach_absolute_time() <= lastTick+(NSEC_PER_MSEC))
	{
	}
#endif
}


@end
