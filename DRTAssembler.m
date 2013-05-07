//
//  DRTAssembler.m
//  Director
//
//  Created by Steven Troughton-Smith on 28/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import "DRTAssembler.h"
#import "DRTCPU.h"



@implementation DRTAssembler

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
	NSDictionary *opcodes = [DRTCPU opcodes];
	
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
	
	int i = STARTADDR;
	
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
	
	
	i = STARTADDR;
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
			
			binary[i] = (Byte)[opcodes[instruction] unsignedCharValue];
		}
		else
		{
			if ([[jumps allKeys] containsObject:instruction])
			{
				binary[i] = (Byte)[jumps[instruction] unsignedCharValue];
				
				//NSLog(@"[%i] = %@(%i)", i, instruction, binary[i]);
				
			}
			else
			{
				binary[i] = (Byte)[instruction intValue];
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
