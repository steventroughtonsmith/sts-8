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

CGContextRef ctx;
uint32_t *videoBuffer;

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
	//	NSLog(@"key = %i", [theEvent.characters UTF8String][0]);
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
	videoBuffer = (uint32_t*)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * 4);
	size_t bitsPerComponent = 8;
	size_t bytesPerPixel    = 4;
	size_t bytesPerRow      = (SCREEN_WIDTH * bitsPerComponent * bytesPerPixel + 7) / 8;
	
	ctx = CGBitmapContextCreate(videoBuffer, SCREEN_WIDTH, SCREEN_HEIGHT, bitsPerComponent, bytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);
	
	
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
	
	int y = (416/TILE_SIZE)-1;
	
	while (offset >= 26)
	{
		offset -= 26;
		y--;
	}
	
	CGPoint tileMapPosition = CGPointMake(offset, y);
	
	NSRect imageRect = CGRectMake(tileMapPosition.x*TILE_SIZE, tileMapPosition.y*TILE_SIZE, TILE_SIZE, TILE_SIZE);
	
	[charset drawAtPoint:CGPointZero fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawFramebufferModeRect:(NSRect)dirtyRect
{
	for (int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++)
	{
		Byte byte = (int)[[DRTCPU sharedInstance] vram][i];
		int palette_color = 0;
		
		switch (byte) {
			case COLOR_BLACK:
				palette_color = 0xFF000000;
				break;
			case COLOR_BLUE:
				palette_color = 0xFF0000FF;
				break;
			case COLOR_GREEN:
				palette_color = 0xFF00FF00;
				break;
			case COLOR_LIGHTBLUE:
				palette_color = 0xFFFFFF00;
				break;
			case COLOR_RED:
				palette_color = 0xFFFF0000;
				break;
			case COLOR_PINK:
				palette_color = 0xFFFF00FF;
				break;
			case COLOR_YELLOW:
				palette_color = 0xFF00FFFF;
				break;
			case COLOR_WHITE:
				palette_color = 0xFFFFFFFF;
				break;
			default:
				palette_color = 0xFF000000;
				break;
		}
		
		
		videoBuffer[i] = palette_color;
	}
		
	[[NSColor blackColor] set];
	
	NSRectFill(self.bounds);
	
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	
	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	
	
	CGContextDrawImage(context, CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), cgImage);
	CGImageRelease(cgImage);
	
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([DRTCPU sharedInstance].vmode == 1)
		[self drawFramebufferModeRect:dirtyRect];
	else
		[self drawCharacterModeRect:dirtyRect];
}

- (void)drawCharacterModeRect:(NSRect)dirtyRect
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
		
		while (![[DRTCPU sharedInstance] halted]){}
		
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
