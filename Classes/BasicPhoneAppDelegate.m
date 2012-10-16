//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import "BasicPhoneAppDelegate.h"
#import "BasicPhoneViewController.h"
#import "ContactsViewController.h"
#import "BasicPhone.h" 

@implementation BasicPhoneAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize contactsViewController = _contactsViewController;
@synthesize phone = _phone;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{    
	// Set the view controller as the window's root view controller and display.
    self.window.rootViewController = self.viewController;
    //self.window.rootViewController = self.contactsViewController;
    [self.window makeKeyAndVisible];
	
	// Initialize the BasicPhone object that coordinates with the Twilio Client SDK.
	// Note that the code immediately fetches a Capability Token
	// in BasicPhone's login method and initializes a TCDevice.  In a production-ready
	// application, you will want to defer any network requests until after your UIApplication 
	// launch has completed in case any of those requests end up timing out -- otherwise
	// the application risks getting shut down by the operating system if the launch takes too long.
	self.phone = [[[BasicPhone alloc] init] autorelease];
	
	self.viewController.phone = self.phone;
    //[self.viewController getUserName];
	
	//[self.phone login];
	
    return YES;
}


#pragma mark -
#pragma mark UIApplication 

-(BOOL)isMultitaskingOS
{
	//Check to see if device's OS supports multitasking
	BOOL backgroundSupported = NO;
	UIDevice *currentDevice = [UIDevice currentDevice];
	if ([currentDevice respondsToSelector:@selector(isMultitaskingSupported)])
	{
		backgroundSupported = currentDevice.multitaskingSupported;
	}
	
	return backgroundSupported;
}

-(BOOL)isForeground
{
	//Check to see if app is currently in foreground
	if (![self isMultitaskingOS])
	{
		return YES;
	}
	
	UIApplicationState state = [UIApplication sharedApplication].applicationState;
	return (state==UIApplicationStateActive);
}


#pragma mark -
#pragma mark Memory management


- (void)dealloc 
{
    [_viewController release];
    [_contactsViewController release];
	[_window release];
	
	[_phone release];
	
    [super dealloc];
}


@end
