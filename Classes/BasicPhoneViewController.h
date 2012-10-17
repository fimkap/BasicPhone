//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@class BasicPhone;
@class ContactsViewController;

@interface BasicPhoneViewController : UIViewController
{
	BasicPhone* _phone;
    ContactsViewController *_contacts;
	
	UIButton* _mainButton;
	UITextView* _textView;
	UISwitch* _speakerSwitch;
	UIAlertView* _alertView;
    SystemSoundID ringtoneSSID;
    NSMutableArray* _contactsList;
    UIButton* _switchLogButton;
    //UITableView* _contactsList;
}

@property (nonatomic,retain) IBOutlet UIButton* mainButton;
@property (nonatomic,retain) IBOutlet UITextView* textView;
@property (nonatomic,retain) IBOutlet UISwitch* speakerSwitch;
@property (nonatomic,retain) BasicPhone* phone;
@property (nonatomic,retain) ContactsViewController* contacts;
@property(readwrite) SystemSoundID ringtoneSSID;
@property (nonatomic,retain) NSArray* contactsList;
@property (retain, nonatomic) IBOutlet UIPickerView *contactPicker;
@property (retain, nonatomic) IBOutlet UIButton *switchLogButton;

//Button actions
-(IBAction)mainButtonPressed:(id)sender;
-(IBAction)speakerSwitchPressed:(id)sender;
- (IBAction)switchLog:(id)sender;


-(void)getUserName;

@end

