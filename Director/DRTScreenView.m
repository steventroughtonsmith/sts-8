//
//  DRTScreenView.m
//  Director
//
//  Created by Steven Troughton-Smith on 26/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import "DRTScreenView.h"
#import "DRTCPU.h"
#import "DRTAssembler.h"

@implementation DRTScreenView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self _commonInit];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _commonInit];
    }
    return self;
}


-(void)awakeFromNib
{
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(void)keyDown:(NSEvent *)theEvent
{
	[[DRTCPU sharedInstance] setKey:[theEvent.characters UTF8String][0]];
}

-(void)keyUp:(NSEvent *)theEvent
{
	//[[DRTCPU sharedInstance] setKey:0];
}

-(BOOL)mouseDownCanMoveWindow
{
	return YES;
}

-(void)_commonInit
{
	
	[self registerForDraggedTypes:
	 [NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
	
	NSTimer *screenTimer = [NSTimer timerWithTimeInterval:1.0/60.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:screenTimer forMode:NSRunLoopCommonModes];
	
}

-(void)tick
{
	[self display];
}

#define TILE_SIZE 16

-(void)drawCharacter:(Byte)c
{
	NSImage *charset = [NSImage imageNamed:@"charset.png"];
	
	int offset = c;
	
	int y = 0;
	
	while (offset >= 26)
	{
		offset -= 26;
		y++;
	}
	
	CGPoint tileMapPosition = CGPointMake(offset, y);
	
	NSRect imageRect = CGRectMake((1+tileMapPosition.x*TILE_SIZE)+tileMapPosition.x, (1+tileMapPosition.y)+tileMapPosition.y*TILE_SIZE, TILE_SIZE, TILE_SIZE);
	
	[charset drawAtPoint:CGPointZero fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawRect:(NSRect)dirtyRect
{
	Byte *vram = [[DRTCPU sharedInstance] vram];
	
	[[NSColor blackColor] set];
	
	NSRectFill(self.bounds);
	
	[[NSColor whiteColor] set];
	
	CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
	CGContextSaveGState(ctx);
	
	//	CGContextSetAllowsAntialiasing(ctx, NO);
	for (int y = 0; y < ROWS; y++)
	{
		for (int x = 0; x < COLUMNS; x++)
		{
			CGContextSaveGState(ctx);
			CGContextTranslateCTM(ctx, x*16, (ROWS-1-y)*16);
			
			[self drawCharacter:vram[((y*COLUMNS)+x)]];
			
			CGContextRestoreGState(ctx);
		}
	}
	//	CGContextSetAllowsAntialiasing(ctx, YES);
	
	CGContextRestoreGState(ctx);
	
}

#pragma mark - Drag

- (NSDragOperation)draggingEntered:(id )sender
{
	if ((NSDragOperationGeneric & [sender draggingSourceOperationMask])
		== NSDragOperationGeneric) {
		
		return NSDragOperationGeneric;
		
	} // end if
	
	// not a drag we can use
	return NSDragOperationNone;
	
} // end draggingEntered

- (BOOL)prepareForDragOperation:(id )sender {
	return YES;
} // end prepareForDragOperation




- (BOOL)performDragOperation:(id )sender {
	NSPasteboard *zPasteboard = [sender draggingPasteboard];
	// define the images  types we accept
	// NSPasteboardTypeTIFF: (used to be NSTIFFPboardType).
	// NSFilenamesPboardType:An array of NSString filenames
	NSArray *zImageTypesAry = [NSArray arrayWithObjects:NSPasteboardTypeTIFF,
							   NSFilenamesPboardType, nil];
	
	NSString *zDesiredType =
	[zPasteboard availableTypeFromArray:zImageTypesAry];
	
    if ([zDesiredType isEqualToString:NSFilenamesPboardType]) {
		// the pasteboard contains a list of file names
		//Take the first one
		NSArray *zFileNamesAry =
		[zPasteboard propertyListForType:@"NSFilenamesPboardType"];
		NSString *zPath = [zFileNamesAry objectAtIndex:0];
		
		NSLog(@"LOADING = %@", zPath);
		
		[[DRTCPU sharedInstance] halt];
		
		
		if ([[zPath pathExtension] isEqualToString:@"s"])
		{
			NSString *assemblyCode = [NSString stringWithContentsOfFile:zPath encoding:NSUTF8StringEncoding error:nil];
			
			
			NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"o"]];
			
			[assemblyCode writeToFile:temporaryFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
			
			DRTAssembler *assembler = [DRTAssembler new];
			
			NSString *binaryFilePath =  [assembler _compileFile:temporaryFilePath];
			
			[[DRTCPU sharedInstance] load: (char *)[binaryFilePath UTF8String]];
			
		}
		else
		{
			[[DRTCPU sharedInstance] load: (char *)[zPath UTF8String]];
		}
		
		[[DRTCPU sharedInstance] coldBoot];
		
		return YES;
		
	}// end if
	
	//this cant happen ???
	return NO;
	
} // end performDragOperation


- (void)concludeDragOperation:(id )sender {
	[self setNeedsDisplay:YES];
} // end concludeDragOperation


@end
