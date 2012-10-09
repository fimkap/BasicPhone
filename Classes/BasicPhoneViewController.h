//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import <UIKit/UIKit.h>

@class BasicPhone;

@interface BasicPhoneViewController : UIViewController 
{
	BasicPhone* _phone;
	
	UIButton* _mainButton;
	UITextView* _textView;
	UISwitch* _speakerSwitch;
	UIAlertView* _alertView;
}

@property (nonatomic,retain) IBOutlet UIButton* mainButton;
@property (nonatomic,retain) IBOutlet UITextView* textView;
@property (nonatomic,retain) IBOutlet UISwitch* speakerSwitch;
@property (nonatomic,retain) BasicPhone* phone;

//Button actions
-(IBAction)mainButtonPressed:(id)sender;
-(IBAction)speakerSwitchPressed:(id)sender;

@end

