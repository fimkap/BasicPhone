//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import <UIKit/UIKit.h>

@class BasicPhoneViewController;
@class BasicPhone;

@interface BasicPhoneAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow* _window;
    BasicPhoneViewController* _viewController;
	
	BasicPhone* _phone;
}

@property (nonatomic, retain) IBOutlet UIWindow* window;
@property (nonatomic, retain) IBOutlet BasicPhoneViewController* viewController;
@property (nonatomic, retain) BasicPhone* phone;

// Returns NO if the app isn't in the foreground in a multitasking OS environment.
-(BOOL)isForeground;

@end

