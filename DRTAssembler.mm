//
//  DRTAssembler.m
//  Director
//
//  Created by Steven Troughton-Smith on 28/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import "DRTAssembler.h"
//#import "DRTCPU.h"


@implementation DRTAssembler

+(NSDictionary *)opcodes
{
	return @{
		  
		/*
		 ROM ROUTINES
		 
		 JMP 0xFE - print stack
		 JMP 0xFF - print a
		 
		 MEMORY LOCATIONS
		 '_keyboard', or ram[0x1]
		 
		 $X, $Y, $A
		 
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
		@"BP" : @0x21, // if (a > 0) goto operand
		@"BN" : @0x22, // if (a < 0) goto operand
		@"BZ" : @0x23, // if (a == 0) goto operand
		
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
		@"RA" : @0x53, // transfer byte@a to a
	
	};
}


-(NSArray *)_componentsForLine:(NSString *)line
{
	NSArray *_components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSMutableArray *components = [NSMutableArray arrayWithCapacity:3];
	
	BOOL _isInQuote = NO;
	
	NSMutableString *buffer = [NSMutableString stringWithCapacity:3];
	
	for (NSString *instruction in _components)
	{
		if (!instruction.length)
		{
			continue;
		}
		
		if ([instruction hasPrefix:@"\""])
			_isInQuote = YES;
		
		if (_isInQuote)
		{
			[buffer appendFormat:@"%@ ", instruction];
		}
		
		if ([instruction hasSuffix:@"\""])
		{
			
			_isInQuote = NO;
			[components addObject:buffer];
			continue;
		}
		
		if (!_isInQuote)
		{
			[components addObject:instruction];
		}
		
	}
	
	if (components.count)
		return components;
	else
		return nil;
}

-(NSString *)_compileFile:(NSString *)source
{
	NSDictionary *opcodes = [DRTAssembler opcodes];
	
	Byte binary[4096];
	
	for (int i =0 ; i < 4096; i++)
	{
		binary[i] = 0;
	}
	
	NSString *code = [NSString stringWithContentsOfFile:source encoding:NSUTF8StringEncoding error:nil];
	
	NSMutableString *codeStripped = [NSMutableString stringWithCapacity:0];
	
	/* Strip comments */
	[code enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		if (![line hasPrefix:@";"] && ![line hasPrefix:@"//"])
		{
			NSRange cmtRange = [line rangeOfString:@";"];
			if (cmtRange.length)
			{
				[codeStripped appendFormat:@"%@\n", [line substringToIndex:cmtRange.location]];
			}
			else
				[codeStripped appendFormat:@"%@\n", line];
			
		}
	}];
	
	/* Parse */
	
	NSMutableArray *components = [[NSMutableArray alloc] initWithCapacity:3];
	
	[codeStripped enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		
		NSArray *lineCmpts = [self _componentsForLine:line];
		
		if (lineCmpts.count)
			[components addObjectsFromArray:lineCmpts];
	}];
	
	NSMutableDictionary *jumps = [NSMutableDictionary dictionaryWithCapacity:3];
	
	int i = STARTADDR ;
	
	// one pass for jumps
	for (NSString *instruction in components)
	{
		if ([instruction hasSuffix:@":"])
		{
			
			jumps[[instruction substringToIndex:instruction.length-1]] = @(i);
			
			continue;
		}
		
		
		if ([instruction hasPrefix:@"\""])
		{
			i+= instruction.length-3;
		}
		else
			i++;
	}
	
	/* ROM routines */
	[jumps setObject:@(1) forKey:@"_keyboard"];
	[jumps setObject:@(2) forKey:@"$X"];
	[jumps setObject:@(3) forKey:@"$Y"];
	[jumps setObject:@(4) forKey:@"$VMODE_C"];
	[jumps setObject:@(5) forKey:@"$VMODE_FB"];

	
	i = STARTADDR ;
	NSInteger idx = 0;
	
	for (NSString *instruction in components)
	{
		
		if ([instruction hasSuffix:@":"])
		{
			idx++;
			continue;
		}
		
		if ([instruction hasPrefix:@"\""])
		{
			continue;
		}
		
		if ([instruction isEqualToString:@".byte"])
		{		
			NSString *byteVal = [components objectAtIndex:idx+1];
			
			if (![byteVal hasPrefix:@"\""])
			{
				binary[i] = [byteVal intValue];
				i++;
			}
			else
			{
				//NSLog(@"Stripping string = %@", byteVal);
				
				byteVal = [byteVal substringWithRange:NSMakeRange(1, byteVal.length-3)];
				
				//NSLog(@"BYTES = %@", byteVal);
				
				for (int m = 0; m < byteVal.length; m++)
				{
					binary[i] = [byteVal UTF8String][m];
					i++;
				}
			}

			idx++;
			
			continue;
		}
		
		if ([instruction isEqualToString:@".var"])
		{
			NSString *byteVal = [components objectAtIndex:idx+1];
			
			binary[i] = [byteVal UTF8String][0];
			
			idx++;
			i++;
			
			continue;
		}
		
		
		if ([[opcodes allKeys] containsObject:instruction])
		{
			//NSLog(@"[%i] = %@", i, instruction);
			
			binary[i] = [opcodes[instruction] intValue];
		}
		else
		{
			if ([[jumps allKeys] containsObject:instruction])
			{
				binary[i] = [jumps[instruction] intValue];
				
				//NSLog(@"[%i] = %@(%i)", i, instruction, binary[i]);
				
			}
			else
			{
				binary[i] = [instruction intValue];
				//NSLog(@"[%i] = %@", i, instruction);
				
			}
		}
		
		i++;
		idx++;
	}
	
	int count = i;
	
	/* File Header */
	
	DBFHeaderInternal t;
	DBFHeader header = &t;
	
	header->magic = MAGIC;
	header->filesize = count;
	
	memccpy(binary, header, 1, sizeof(DBFHeader));
	
	/* * * * * * * */
	
	NSString *outFile = [source stringByDeletingPathExtension];
	outFile = [outFile stringByAppendingPathExtension:@"o"];
	
	FILE *fout = fopen ([outFile UTF8String], "w");
	if (fout != NULL) {
		for (int i = 0; i < count; i++) {
			fputc(binary[i], fout);
		}
		fclose (fout);
	}
	
	
	return outFile;
}


@end
