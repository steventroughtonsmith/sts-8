//
//  sts8-core.c
//  Director
//
//  Created by Steven Troughton-Smith on 12/05/2013.
//  Copyright (c) 2013 Steven Troughton-Smith. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sts8-core.h"
#include "sts8.h"

#define DRT_DEBUG 0

#if DRT_DEBUG
#define DEBUG_PRINTF(...) printf(__VA_ARGS__)
#else
#define DEBUG_PRINTF(...)
#endif

Byte binary[RAM_SIZE];

void STS8::init()
{
	_halted = 1;
}

void STS8::setKey(int key)
{
	keyChar = key;
}

Byte *STS8::vram()
{
	return screen.vram;
}

void STS8::halt()
{
	_halted = 1;
}

int STS8::halted()
{
	return _halted;
}

void STS8::load(char *filePath)
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
		
		DEBUG_PRINTF("binary loaded:\n");
		for (int i = 0; i < count; i++)
		{
			DEBUG_PRINTF("%X|", binary[i]);
		}
		DEBUG_PRINTF("\n");
		
		fclose (fin);
	}
}

void STS8::coldBoot()
{
	_halted = 1;
	
	for (int i = STARTADDR; i < RAM_SIZE; i++)
	{
		ram[i] = 0;
	}
	
	registers.programCounter = STARTADDR;
	registers.accumulator = 0;
	registers.x = 0;
	registers.y = 0;
	registers.stackPointer = STACK_SIZE;
	keyChar = -1;
	screen.vmode = 0;
	
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
		screen.vram[i] = 0x0;
	}
	
	_halted = 0;
	
}

void STS8::tickCPU()
{
	if (_halted)
		return;
	
	int operation = ram[registers.programCounter];
	int operand = ram[registers.programCounter+1];
	
	switch (operation)
	{
		case TAX:
		{
			if (screen.vmode == 1)
			{
				if ((SCREEN_WIDTH*(registers.y))+registers.x >= SCREEN_WIDTH*SCREEN_HEIGHT)
				{
					_halted = 1;
					return;
				}
				
				screen.vram[(SCREEN_WIDTH*(registers.y))+registers.x] = registers.accumulator;
			}
			else
			{
				screen.vram[(COLUMNS*(registers.y))+registers.x] = registers.accumulator;
			}
			registers.programCounter++;
			break;
		}
			
		case TXA:
		{
			DEBUG_PRINTF("TXA] A = X(%i)\n", registers.x);
			registers.accumulator = registers.x;
			registers.programCounter++;
			break;
		}
			
		case RXA:
		{
			DEBUG_PRINTF("RXA] A = ram[%i+X(%i)]:%i\n", operand, registers.x, ram[operand+registers.x]);
			registers.accumulator = ram[operand+registers.x];
			registers.programCounter+=2;
			break;
		}
			
		case RA:
		{
			DEBUG_PRINTF("RA] A = ram[a]:%i\n", ram[registers.accumulator]);
			registers.accumulator = ram[registers.accumulator];
			registers.programCounter++;
			break;
		}
			
			/* Accumulator */
			
		case LD:
		{
			DEBUG_PRINTF("LD] A = %X (%i)\n", operand, operand);
			registers.accumulator = operand;
			registers.programCounter+=2;
			break;
		}
			
		case LDA:
		{
			DEBUG_PRINTF("LDA] A = ram[%i]:%i\n", operand, ram[operand]);
			
			if (operand == 0x1) // _keyboard
			{
				if (keyChar >= 0)
				{
					DEBUG_PRINTF("key input = %i\n", keyChar);
				}
				registers.accumulator = keyChar;
				
				registers.programCounter+=2;
				
				keyChar = -1;
			}
			else if (operand == 0x2) // $X
			{
				registers.accumulator = registers.x;
				registers.programCounter+=2;
				
			}
			else if (operand == 0x3) // $Y
			{
				registers.accumulator = registers.y;
				registers.programCounter+=2;
			}
			else if (operand == 0x4) // $VMODE_C
			{
				screen.vmode = 0;
				registers.programCounter+=2;
			}
			else if (operand == 0x5) // $VMODE_FB
			{
				screen.vmode = 1;
				registers.programCounter+=2;
			}
			else
			{
				registers.accumulator = ram[operand];
				registers.programCounter+=2;
			}
			break;
		}
			
		case ST:
		{
			DEBUG_PRINTF("ST] ram[%i] = A:%i\n", operand, registers.accumulator);
			if (operand == 0x2) // $X
			{
				registers.x = registers.accumulator;
				registers.programCounter+=2;
				
			}
			else if (operand == 0x3) // $Y
			{
				registers.y = registers.accumulator;
				registers.programCounter+=2;
				
			}
			else
			{
				ram[operand] = registers.accumulator;
				registers.programCounter+=2;
			}
			break;
		}
			
			
			/* Subroutines */
			
		case JMP:
		{
			registers.stackPointer--;
			
			if (registers.stackPointer < 0)
			{
				DEBUG_PRINTF("STACK OVERFLOW\n");
				_halted = 1;
			}
			
			stack[registers.stackPointer] = registers.programCounter;
			DEBUG_PRINTF("JMP] from %i to %i\n", registers.programCounter, operand);
			registers.programCounter = operand;
			
			/* ROM Routines */
			
			switch (operand) {
				case 253:
				{
					DEBUG_PRINTF("x: %i, y: %i\n", registers.x, registers.y);
					
					registers.programCounter = stack[registers.stackPointer]+2;
					registers.stackPointer++;
					
					break;
				}
				case 254:
				{
					DEBUG_PRINTF("STACK = \n");
					
					for (int i = 0; i <STACK_SIZE; i++)
					{
						DEBUG_PRINTF("%X ", stack[i]);
					}
					
					registers.programCounter = stack[registers.stackPointer]+2;
					registers.stackPointer++;
					
					break;
				}
					
				case 255:
				{
					DEBUG_PRINTF("ACC = %i\n", registers.accumulator);
					
					registers.programCounter = stack[registers.stackPointer]+2;
					registers.stackPointer++;
					break;
				}
					
				default:
					break;
			}
			break;
		}
			
		case RET:
		{
			DEBUG_PRINTF("RET] back to = %i\n", stack[registers.stackPointer]);
			registers.programCounter = stack[registers.stackPointer]+2;
			registers.stackPointer++;
			break;
		}
			
			
			/* Stack */
			
		case PUSH:
		{
			DEBUG_PRINTF("PUSH]\n");
			registers.stackPointer--;
			stack[registers.stackPointer] = registers.accumulator;
			
			registers.programCounter ++;
			break;
		}
			
		case POP:
		{
			DEBUG_PRINTF("POP] a = %i\n", stack[registers.stackPointer]);
			registers.accumulator = stack[registers.stackPointer];
			registers.stackPointer++;
			
			registers.programCounter ++;
			break;
		}
			
			/* Math */
			
		case ADD:
		{
			DEBUG_PRINTF("ADD] a += %i\n", operand);
			registers.accumulator = registers.accumulator + operand;
			registers.programCounter+=2;
			break;
		}
			
			// SUB
			
		case SUB:
		{
			DEBUG_PRINTF("SUB] a -= %i\n", operand);
			registers.accumulator = registers.accumulator - operand;
			registers.programCounter+=2;
			break;
		}
			
		case MUL:
		{
			DEBUG_PRINTF("MUL] a *= %i\n", operand);
			registers.accumulator = registers.accumulator * operand;
			registers.programCounter+=2;
			break;
		}
			
		case DIV:
		{
			DEBUG_PRINTF("DIV] a /= %i\n", operand);
			registers.accumulator = registers.accumulator / operand;
			
			registers.programCounter+=2;
			break;
		}
			
			/* Branching */
			
		case B:
		{
			DEBUG_PRINTF("B] from %i to %i\n", registers.programCounter, operand);
			registers.programCounter = operand;
			break;
		}
			
		case BP:
		{
			DEBUG_PRINTF("BP] from %i to %i if a(%i) > 0\n", registers.programCounter, operand, registers.accumulator);
			if (registers.accumulator > 0)
			{
				registers.programCounter = operand;
			}
			else
				registers.programCounter+=2;
			
			break;
		}
			
		case BN:
		{
			DEBUG_PRINTF("BN] from %i to %i if a(%i) < 0\n", registers.programCounter, operand, registers.accumulator);
			if (registers.accumulator < 0)
			{
				registers.programCounter = operand;
			}
			else
				registers.programCounter+=2;
			
			break;
		}
			
		case BZ:
		{
			DEBUG_PRINTF("BZ] from %i to %i if a(%i) == 0\n", registers.programCounter, operand, registers.accumulator);
			if (registers.accumulator == 0)
			{
				registers.programCounter = operand;
			}
			else
				registers.programCounter+=2;
			
			break;
		}
			
			
			/* X & Y */
			
		case X:
		{
			DEBUG_PRINTF("X] x = %i\n", operand);
			registers.x = operand;
			
			registers.programCounter+=2;
			break;
		}
			
		case Y:
		{
			DEBUG_PRINTF("Y] y = %i\n", operand);
			registers.y = operand;
			registers.programCounter+=2;
			break;
		}
			
		case INCX:
		{
			DEBUG_PRINTF("INCX]");
			registers.x++;
			registers.programCounter++;
			break;
		}
			
		case DECX:
		{
			DEBUG_PRINTF("DECX]");
			registers.x--;
			registers.programCounter++;
			break;
		}
			
		case INCY:
		{
			DEBUG_PRINTF("INCY]");
			registers.y++;
			registers.programCounter++;
			break;
		}
			
		case DECY:
		{
			DEBUG_PRINTF("DECY]");
			registers.y--;
			registers.programCounter++;
			break;
		}
			
			/* CPU Flow */
			
		case HLT:
		{
			
			DEBUG_PRINTF("A = %i\nX = %i\nY = %i\n", registers.accumulator, registers.x, registers.y);
			
			DEBUG_PRINTF("------------ HALTED ------------\n");
			
			_halted = 1;
			break;
		}
			
			
			
		default:
			break;
	}
}