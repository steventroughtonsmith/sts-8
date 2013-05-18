//
//  DRTMobileScreenView.m
//  Director
//
//  Created by Steven Troughton-Smith on 17/09/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.

//

#import <QuartzCore/QuartzCore.h>

#import "DRTMobileScreenView.h"
#import "DRTCPU.h"


@implementation DRTMobileScreenView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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


NSMutableArray *charsetMap = nil;

-(void)_commonInit
{
	videoBuffer = (uint32_t*)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * 4);
	size_t bitsPerComponent = 8;
	size_t bytesPerPixel    = 4;
	size_t bytesPerRow      = (SCREEN_WIDTH * bitsPerComponent * bytesPerPixel + 7) / 8;
	
	ctx = CGBitmapContextCreate(videoBuffer, SCREEN_WIDTH, SCREEN_HEIGHT, bitsPerComponent, bytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast);

	[self buildFont];
	
	CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
	link.frameInterval = 2;
	[link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];	
}

#define TILE_SIZE 16

-(void)buildFont
{
	charsetMap = [NSMutableArray arrayWithCapacity:3];
	UIImage *charset = [UIImage imageNamed:@"charset.png"];
	
	for (int y = 0; y < 26; y++)
	{
		for (int x = 0; x < 26; x++)
		{
			CGPoint tileMapPosition = CGPointMake(x,y);

			CGRect imageRect = CGRectMake(tileMapPosition.x*TILE_SIZE, tileMapPosition.y*TILE_SIZE, TILE_SIZE, TILE_SIZE);
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(TILE_SIZE, TILE_SIZE), YES, 1.0);
			
			
			[charset drawAtPoint:CGPointMake(-imageRect.origin.x,-imageRect.origin.y) blendMode:kCGBlendModeNormal alpha:1.0];
			
			UIImage *charImg = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			
			[charsetMap addObject:charImg];
		}
	}
}
-(void)tick
{
	[self setNeedsDisplay];
}

-(void)drawCharacter:(Byte)c
{
	UIImage *charImg = [charsetMap objectAtIndex:c];
	[charImg drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
}

- (void)drawFramebufferModeRect:(CGRect)dirtyRect
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
	
	[[UIColor blackColor] set];
	
	UIRectFill(self.bounds);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	
	CGContextScaleCTM(context, 1.0, -1.0);

	CGContextDrawImage(context, CGRectMake(0, -SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT), cgImage);
	CGImageRelease(cgImage);
	
}

- (void)drawRect:(CGRect)dirtyRect
{
	if ([DRTCPU sharedInstance].vmode == 1)
		[self drawFramebufferModeRect:dirtyRect];
	else
		[self drawCharacterModeRect:dirtyRect];
}

- (void)drawCharacterModeRect:(CGRect)dirtyRect
{
	Byte *vram = [[DRTCPU sharedInstance] vram];
	
	[[UIColor blackColor] set];
	
	UIRectFill(self.bounds);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(ctx);
	
	for (int y = 0; y < ROWS; y++)
	{
		for (int x = 0; x < COLUMNS; x++)
		{
			CGContextSaveGState(ctx);
			//(ROWS-1-y)
			CGContextTranslateCTM(ctx, x*16, y*16);
		
			[self drawCharacter:vram[((y*COLUMNS)+x)]];
			
			CGContextRestoreGState(ctx);
		}
	}
	
	CGContextRestoreGState(ctx);
	
}

#pragma mark - Key Input

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self becomeFirstResponder];
}

-(BOOL)canBecomeFirstResponder
{
	return YES;
}

- (BOOL)hasText
{
	return YES;
}

- (void)insertText:(NSString *)text
{	
	if ([text characterAtIndex:0] == 10)
		[[DRTCPU sharedInstance] setKey:13];
	else
	[[DRTCPU sharedInstance] setKey:[text characterAtIndex:0]];
}

- (void)deleteBackward
{
	[[DRTCPU sharedInstance] setKey:127];

}

@end
