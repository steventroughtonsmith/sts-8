//
//  sts8.h
//  Director
//
//  Created by Steven Troughton-Smith on 14/05/2013.
//  Copyright (c) 2013 Steven Troughton-Smith. All rights reserved.
//

#ifndef Director_sts8_h
#define Director_sts8_h

/*
 ROM ROUTINES
 
 JMP 0xFE - print stack
 JMP 0xFF - print a
 
 MEMORY LOCATIONS
 '_keyboard', or ram[0x1]
 
 $X, $Y, $A
 
 */

/* CPU */
#define HLT 0xFF

/* accumulator */
#define LD 0x01		// a = operand
#define LDA 0x02	// byte@operand -> a
#define ST 0x03		// a -> byte@operand

/* math */
#define ADD 0x10	// a += operand
#define SUB 0x11	// a -= operand
#define MUL 0x12	// a *= operand
#define DIV 0x13	// a /= operand

/* branching*/
#define B 0x20		// goto operand
#define BP 0x21		// if (a > 0) goto operand
#define BN 0x22		// if (a < 0) goto operand
#define BZ 0x23		// if (a == 0) goto operand

/* subroutines */
#define JMP 0x30	// PC->stack; goto operand
#define RET 0x31	// stack->PC; return to PC
#define PUSH 0x32	// a->stack
#define POP 0x33	// stack->a

/* x & y*/
#define X 0x40		// x = operand
#define Y 0x41		// y = operand
#define INCX 0x42	// x++
#define INCY 0x43	// y++
#define DECX 0x44	// x--
#define DECY 0x45	// y--

/* VRAM */
#define TAX 0x50	// transfer a to vram[x][y]
#define TXA 0x51	// transfer x to a
#define RXA 0x52	// transfer byte@operand+x to a
#define RA 0x53		// transfer byte@a to a

#endif
