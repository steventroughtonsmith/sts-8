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
	
	for (int y = 25; y >= 0; y--)
	{
		for (int x = 0; x < 26; x++)
		{
			CGPoint tileMapPosition = CGPointMake(x,y);

				CGRect imageRect = CGRectMake((1+tileMapPosition.x*TILE_SIZE)+tileMapPosition.x, (1+tileMapPosition.y)+tileMapPosition.y*TILE_SIZE, TILE_SIZE, TILE_SIZE);
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

- (void)drawRect:(CGRect)dirtyRect
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

@end
