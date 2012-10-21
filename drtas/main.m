//
//  main.m
//  drtas
//
//  Created by Steven Troughton-Smith on 28/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DRTAssembler.h"

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		
		if (argc != 2)
		{
			printf("Usage: drtas file.s\n");
			return -1;
		}
	    
	    // insert code here...
		DRTAssembler *assembler = [[DRTAssembler alloc] init];
		
		[assembler _compileFile:[NSString stringWithUTF8String:argv[1]]];
	    
	}
    return 0;
}

