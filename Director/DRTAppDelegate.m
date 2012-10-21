//
//  DRTAppDelegate.m
//  Director
//
//  Created by Steven Troughton-Smith on 25/08/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import "DRTAppDelegate.h"

@interface BlackView : NSView
@end

@implementation BlackView

-(void)drawRect:(NSRect)dirtyRect
{
	[[NSColor blackColor] set];
	NSRectFillUsingOperation(self.bounds, NSCompositeSourceAtop);
}

@end

@implementation DRTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
#if 1
	
	NSView *themeFrame = (NSView *)[[self.window contentView] superview];
	
	BlackView *_betaBar = [[BlackView alloc] initWithFrame:CGRectMake(0,0,100,25)];
	[_betaBar setAutoresizingMask:NSViewMinYMargin|NSViewWidthSizable];
	
	NSRect c = [themeFrame frame];  // c for "container"
									//c.size.height += 20;
									//c.origin.y -= 40;
	NSRect aV = [_betaBar frame];      // aV for "accessory view"
	NSRect newFrame = NSMakeRect(
								 0,   // x position
								 c.size.height - aV.size.height, // y position
								 c.size.width,  // width
								 aV.size.height);        // height
	[_betaBar setFrame:newFrame];
	
	//	[themeFrame setFrame:c];
	
	[themeFrame addSubview:_betaBar positioned:NSWindowBelow relativeTo:nil];
#endif

}

@end
