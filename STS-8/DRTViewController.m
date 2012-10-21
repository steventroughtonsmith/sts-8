//
//  DRTViewController.m
//  STS-8
//
//  Created by Steven Troughton-Smith on 17/09/2012.
//  Copyright (c) 2012 Steven Troughton-Smith. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DRTViewController.h"
#import "DRTAssembler.h"
#import "DRTCPU.h"
#import "DRTMobileScreenView.h"

@interface DRTViewController ()

@end

@implementation DRTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.scrollView.contentSize = self.contentView.bounds.size;
	
	[self.scrollView addSubview:self.contentView];
	
	[self reset:nil];
	
	CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
	link.frameInterval = 1;
	[link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	
	
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[self handleScreenChange];
	}];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[self handleScreenChange];
	}];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIScreenModeDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[self handleScreenChange];
	}];
	
	[self handleScreenChange];
	
}

-(void)handleScreenChange
{
	if ([UIScreen screens].count > 1)
	{
		UIScreen *externalScreen = [[UIScreen screens] lastObject];
		
		DRTMobileScreenView *mirror = [[DRTMobileScreenView alloc] initWithFrame:CGRectMake(CGRectGetMidX(externalScreen.bounds)-320, CGRectGetMidY(externalScreen.bounds)-240, 640, 480)];
		
		if (!mirrorWindow)
		{
			mirrorWindow = [[UIWindow alloc] initWithFrame:externalScreen.bounds];
			mirrorWindow.backgroundColor = [UIColor blackColor];
		}
		else
			mirrorWindow.frame = externalScreen.bounds;
		
		mirrorWindow.screen = externalScreen;
		[mirrorWindow setHidden:NO];
		
		[mirrorWindow addSubview:mirror];
		
		CGFloat scale = externalScreen.bounds.size.height/480;
		mirror.layer.magnificationFilter = kCAFilterNearest;
		mirror.layer.transform = CATransform3DMakeScale(scale, scale, 1.0);
	}
}

-(void)tick
{
	if ([[DRTCPU sharedInstance] halted])
	{
		self.led.image = [UIImage imageNamed:@"LED-Off.png"];
	}
	else
	{
		self.led.image = [UIImage imageNamed:@"LED-On.png"];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)reset:(id)sender {
	
	NSString *assemblyCode = self.editView.text;
	
	
	NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"txt"]];
	
	[assemblyCode writeToFile:temporaryFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
	
	DRTAssembler *assembler = [DRTAssembler new];
	
	NSString *binaryFilePath =  [assembler _compileFile:temporaryFilePath];
	
	[[DRTCPU sharedInstance] halt];
	[[DRTCPU sharedInstance] load:[binaryFilePath UTF8String]];
	[[DRTCPU sharedInstance] coldBoot];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// 112, 852, 800, 600
	[UIView animateWithDuration:0.3 animations:^{
		self.editView.frame = CGRectMake(112, 852, 800, 292);
		
	}];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// 112, 852, 800, 600
	[UIView animateWithDuration:0.3 animations:^{
		self.editView.frame = CGRectMake(112, 852, 800, 600);
	}];
	
}

@end
