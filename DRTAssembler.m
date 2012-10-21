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
	
	NSArray *_components = [codeStripped componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
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
			[components addObject:instruction];
		
	}
	
	
	
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
		
		i++;
	}
	
	/* ROM routines */
	[jumps setObject:@(1) forKey:@"_keyboard"];
	
	
	i = STARTADDR;
	NSInteger idx = 0;
	
	for (NSString *instruction in components)
	{
		
		if ([instruction hasSuffix:@":"])
		{
			idx++;
			continue;
		}
		
		
		if ([instruction isEqualToString:@".byte"])
		{
			NSString *byteVal = [components objectAtIndex:idx+1];
			
			
			
			byteVal = [byteVal substringWithRange:NSMakeRange(1, byteVal.length-2)];
			
			
			NSLog(@"byecal = %@", byteVal);
			
			for (int m = 0; m < byteVal.length; m++)
			{
				binary[i] = [byteVal UTF8String][m];
				i++;
			}
			
//			binary[i] = 0;
//	i++;
			
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
		
		NSLog(@"inst = %@", instruction);
		
		if ([[opcodes allKeys] containsObject:instruction])
		{
			binary[i] = (Byte)[opcodes[instruction] unsignedCharValue];
		}
		else
		{
			if ([[jumps allKeys] containsObject:instruction])
			{
				binary[i] = (Byte)[jumps[instruction] unsignedCharValue];
			}
			else
				binary[i] = (Byte)[instruction intValue];
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
