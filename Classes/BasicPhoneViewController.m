//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import "BasicPhoneViewController.h"
#import "BasicPhoneAppDelegate.h"
#import "BasicPhoneNotifications.h"
#import "BasicPhone.h"
#import "ContactsViewController.h"
#import "AVFoundation/AVAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIPickerView.h>

@interface BasicPhoneViewController () // Internal methods that don't get exposed.

-(void)syncMainButton;
-(void)addStatusMessage:(NSString*)message;
-(void)constructAlert:(NSString*)from;

// notifications
-(void)loginDidStart:(NSNotification*)notification;
-(void)loginDidFinish:(NSNotification*)notification;
-(void)loginDidFailWithError:(NSNotification*)notification;

-(void)connectionDidConnect:(NSNotification*)notification;
-(void)connectionDidFailToConnect:(NSNotification*)notification;
-(void)connectionIsDisconnecting:(NSNotification*)notification;
-(void)connectionDidDisconnect:(NSNotification*)notification;
-(void)connectionDidFailWithError:(NSNotification*)notification;

-(void)pendingIncomingConnectionDidDisconnect:(NSNotification*)notification;
-(void)pendingIncomingConnectionReceived:(NSNotification*)notification;

-(void)deviceDidStartListeningForIncomingConnections:(NSNotification*)notification;
-(void)deviceDidStopListeningForIncomingConnections:(NSNotification*)notification;
-(void)deviceDidReceivePresenceUpdate:(NSNotification*)notification;

-(void) writeUsernameToFile:(NSString*)username;
-(NSString*) readUsernameFromFile;


@end

@implementation BasicPhoneViewController

@synthesize ringtoneSSID, contactPicker;
@synthesize phone = _phone;
@synthesize contacts = _contacts;
@synthesize mainButton = _mainButton;
@synthesize textView = _textView;
@synthesize speakerSwitch = _speakerSwitch;
@synthesize contactsList = _contactsList;
@synthesize switchLogButton = _switchLogButton;

#pragma mark -
#pragma mark Application behavior

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Limit to portrait for simplicity.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewDidLoad
{
	[super viewDidLoad];
    //[self.view addSubview:self.contacts.ContactsTableView];

	// Register for notifications that will be broadcast from the 
	// BasicPhone model/controller.  These may be received on any
	// thread, so calls that may update UI state should perform those
	// changes on the main thread.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidStart:)
												 name:BPLoginDidStart
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidFinish:)
												 name:BPLoginDidFinish
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidFailWithError:)
												 name:BPLoginDidFailWithError
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionIsConnecting:)
												 name:BPConnectionIsConnecting
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidConnect:)
												 name:BPConnectionDidConnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidDisconnect:)
												 name:BPConnectionDidDisconnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionIsDisconnecting:)
												 name:BPConnectionIsDisconnecting
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidFailToConnect:)
												 name:BPConnectionDidFailToConnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidFailWithError:)
												 name:BPConnectionDidFailWithError
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pendingIncomingConnectionReceived:)
												 name:BPPendingIncomingConnectionReceived
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pendingIncomingConnectionDidDisconnect:)
												 name:BPPendingIncomingConnectionDidDisconnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidStartListeningForIncomingConnections:)
												 name:BPDeviceDidStartListeningForIncomingConnections
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidStopListeningForIncomingConnections:)
												 name:BPDeviceDidStopListeningForIncomingConnections
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidReceivePresenceUpdate:)
												 name:BPDeviceDidReceivePresenceUpdate
											   object:nil];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
   
    [self getUserName];
    
    contactPicker.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	contactPicker.delegate = self;
	contactPicker.dataSource = self;
	
	// add this picker to our view controller, initially hidden
	contactPicker.hidden = NO;
	[self.view addSubview:contactPicker];
    
    //UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    
    //AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (sessionCategory),&sessionCategory);
    //AudioSessionSetActive (true);
    
    //[_phone initContactsList];
    
    //_contactsList = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];

}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self syncMainButton]; // make sure the main button is up to date with the connection's status.
}

-(void)viewDidUnload
{
	// Unregister this class from all notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.mainButton = nil;
	self.textView = nil;
	self.speakerSwitch = nil;
	
    [self setContactPicker:nil];
    [self setSwitchLogButton:nil];
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Button Actions 

-(IBAction)mainButtonPressed:(id)sender
{
	//Action for button on main view
	BasicPhoneAppDelegate* delegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	BasicPhone* basicPhone = delegate.phone;
    
    NSString* contact = [_contactsList objectAtIndex:[contactPicker selectedRowInComponent:0]];
    //NSLog(@"contact|%@", [contact substringFromIndex:4]);
    NSString* contactWithPrefix = [[NSString alloc] initWithFormat:@"xxx_%@",[contact substringFromIndex:4]];
	
	//Perform correct button function based on current connection
	if (!basicPhone.connection || basicPhone.connection.state == TCConnectionStateDisconnected)
	{
		//Connection doesn't exist or is disconnected, so make a call
		[basicPhone connect:contactWithPrefix];
	}
	else
	{
		//Connection state is open, pending, or conncting, so disconnect phone
		[basicPhone disconnect];
	}
}

-(IBAction)speakerSwitchPressed:(id)sender
{
	BasicPhoneAppDelegate* delegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	BasicPhone* basicPhone = delegate.phone;
    
//    _phone.ringbackTone = [[NSBundle mainBundle] pathForResource:@"outgoing" ofType:@"wav"];
//    NSLog(@"tone path %@", _phone.ringbackTone);
//    
//    CFURLRef        myURLRef;
//    
//    myURLRef = CFURLCreateWithFileSystemPath (
//                                              kCFAllocatorDefault,
//                                              (CFStringRef)_phone.ringbackTone,
//                                              kCFURLPOSIXPathStyle,
//                                              FALSE
//                                              );
//    OSStatus err = AudioServicesCreateSystemSoundID(myURLRef, &ringtoneSSID);
//    if (err)
//        NSLog(@"AudioServicesCreateSystemSoundID error");
//    CFRelease (myURLRef);
//    AudioServicesAddSystemSoundCompletion (
//                                           ringtoneSSID,
//                                           NULL,
//                                           NULL,
//                                           ringtoneCallback,
//                                           NULL
//                                           );
//    AudioServicesPlaySystemSound(ringtoneSSID);

	[basicPhone setSpeakerEnabled:self.speakerSwitch.on];
}

- (IBAction)switchLog:(id)sender
{
    if (contactPicker.hidden)
    {
        [self.switchLogButton setTitle:@"Log" forState:UIControlStateNormal];
        contactPicker.hidden = NO;
    }
    else
    {
        [self.switchLogButton setTitle:@"Contacts" forState:UIControlStateNormal];
        contactPicker.hidden = YES;
    }
}

#pragma mark -
#pragma mark Notifications

-(void)loginDidStart:(NSNotification*)notification
{
	[self addStatusMessage:@"-Logging in..."];		
}

-(void)loginDidFinish:(NSNotification*)notification
{
	NSNumber* hasOutgoing = [self.phone.device.capabilities objectForKey:TCDeviceCapabilityOutgoingKey];
	if ( [hasOutgoing boolValue] == YES )
	{
		[self addStatusMessage:@"-Outgoing calls allowed"];		
	}
	else
	{
		[self addStatusMessage:@"-Unable to make outgoing calls with current capabilities"];
	}
	
	if ( [hasOutgoing boolValue] == YES )
	{
		[self addStatusMessage:@"-Incoming calls allowed"];		
	}
	else
	{
		[self addStatusMessage:@"-Unable to receive incoming calls with current capabilities"];
	}
}

-(void)loginDidFailWithError:(NSNotification*)notification
{
	NSError* error = [[notification userInfo] objectForKey:@"error"];
	if ( error )
	{
		NSString* message = [NSString stringWithFormat:@"-Error logging in: %@ (%d)",
							 [error localizedDescription],
							 [error code]];
		[self addStatusMessage:message];		
	}
	else
	{
		[self addStatusMessage:@"-Unknown error logging in"];		
	}
	[self syncMainButton];	
}

-(void)connectionIsConnecting:(NSNotification*)notification
{
	[self addStatusMessage:@"-Attempting to connect"];
	[self syncMainButton];
}

-(void)connectionDidConnect:(NSNotification*)notification
{
	[self addStatusMessage:@"-Connection did connect"];
	[self syncMainButton];	
}

-(void)connectionDidFailToConnect:(NSNotification*)notification
{
	[self addStatusMessage:@"-Couldn't establish outgoing call"];	
}

-(void)connectionIsDisconnecting:(NSNotification*)notification
{
	[self addStatusMessage:@"-Attempting to disconnect"];
	[self syncMainButton];
}

-(void)connectionDidDisconnect:(NSNotification*)notification
{
	[self addStatusMessage:@"-Connection did disconnect"];
	[self syncMainButton];
}

-(void)connectionDidFailWithError:(NSNotification*)notification
{
	NSError* error = [[notification userInfo] objectForKey:@"error"];
	if ( error )
	{
		NSString* message = [NSString stringWithFormat:@"-Connection did fail with error code %d, domain %@",
														 [error code],
														 [error domain]];
		[self addStatusMessage:message];
	}
	[self syncMainButton];
}

-(void)deviceDidStartListeningForIncomingConnections:(NSNotification*)notification
{
	[self addStatusMessage:@"-Device is listening for incoming connections"];
}

-(void)deviceDidStopListeningForIncomingConnections:(NSNotification*)notification
{
	NSError* error = [[notification userInfo] objectForKey:@"error"]; // may be nil
	if ( error )
	{
		[self addStatusMessage:[NSString stringWithFormat:@"-Device is no longer listening for connections due to error %@",
								[error localizedDescription]]];
        [self getUserName]; // try to recover
	}
	else
	{
		[self addStatusMessage:@"-Device is no longer listening for connections"];
	}
}


-(BOOL)isForeground
{
	BasicPhoneAppDelegate* appDelegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	return [appDelegate isForeground];
}

-(void)pendingIncomingConnectionReceived:(NSNotification*)notification
{
    // CallerID
    NSString* from = [[notification userInfo] objectForKey:@"from"];
	//Show alert view asking if user wants to accept or ignore call
	[self performSelectorOnMainThread:@selector(constructAlert:) withObject:from waitUntilDone:NO];

    
	
	//Check for background support
	if ( ![self isForeground] )
	{
        _phone.ringbackTone = [[NSBundle mainBundle] pathForResource:@"ringtone" ofType:@"aif"];
        //NSLog(@"tone path %@", _phone.ringbackTone);
        
        CFURLRef        myURLRef;
        
        myURLRef = CFURLCreateWithFileSystemPath (
                                                  kCFAllocatorDefault,
                                                  (CFStringRef)_phone.ringbackTone,
                                                  kCFURLPOSIXPathStyle,
                                                  FALSE
                                                  );
        AudioServicesCreateSystemSoundID(myURLRef, &ringtoneSSID);
        //if (err)
        //   NSLog(@"AudioServicesCreateSystemSoundID error");
        CFRelease (myURLRef);
        AudioServicesAddSystemSoundCompletion (
                                               ringtoneSSID,
                                               NULL,
                                               NULL,
                                               ringtoneCallback,
                                               NULL
                                               );
        AudioServicesPlaySystemSound(ringtoneSSID);
        
        AudioSessionSetActive (true);
        UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        
        AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (sessionCategory),&sessionCategory);
        
		//App is not in the foreground, so send LocalNotification
		UIApplication* app = [UIApplication sharedApplication];
		UILocalNotification* notification = [[UILocalNotification alloc] init];
		NSArray* oldNots = [app scheduledLocalNotifications];
		
		if ([oldNots count]>0)
		{
			[app cancelAllLocalNotifications];
		}
		
        NSString* alertBody = [[NSString alloc] initWithFormat:@"Call from %@", from];
		notification.alertBody = alertBody;
        //[alertBody release];
        //notification.soundName = UILocalNotificationDefaultSoundName;
        //notification.soundName = [[NSBundle mainBundle] pathForResource:@"outgoing" ofType:@"wav"];
		
		[app presentLocalNotificationNow:notification];
		[notification release];
	}
	
	//[self addStatusMessage:@"-Received inbound connection from"];
    [self addStatusMessage:[[NSString alloc] initWithFormat:@"#### Received inbound connection from %@", from]];
	[self syncMainButton];	
}

-(void)pendingIncomingConnectionDidDisconnect:(NSNotification*)notification
{
	// Make sure to cancel any pending notifications/alerts
	[self performSelectorOnMainThread:@selector(cancelAlert) withObject:nil waitUntilDone:NO];
	
	if ( ![self isForeground] )
	{
		//App is not in the foreground, so kill the notification we posted.
		UIApplication* app = [UIApplication sharedApplication];
		[app cancelAllLocalNotifications];
	}

	[self addStatusMessage:@"-Pending connection did disconnect"];
	[self syncMainButton];	
}

-(void)deviceDidReceivePresenceUpdate:(NSNotification*)notification
{
	TCPresenceEvent* presenceEvent = [[notification userInfo] objectForKey:@"presenceEvent"];
    
    NSString* prefix = @"xxx_";
    // Filter out all client but starting with the prefix
    if ([presenceEvent.name length] < 5)
    {
        return;
    }
    if (![prefix isEqualToString:[presenceEvent.name substringToIndex:4]])
    {
        return;
    }

    NSString* contactObjectON = [[NSString alloc] initWithFormat:@"ON  %@", [presenceEvent.name substringFromIndex:4]];
    NSString* contactObjectOFF = [[NSString alloc] initWithFormat:@"OFF %@", [presenceEvent.name substringFromIndex:4]];
    if (presenceEvent.available) {
        NSInteger index = [_contactsList indexOfObject:contactObjectOFF];
        if (index != NSNotFound)
        {
            [_contactsList replaceObjectAtIndex:index withObject:contactObjectON];
        }
        else if ([_contactsList indexOfObject:contactObjectON] == NSNotFound)
        {
            [_contactsList addObject:contactObjectON];
        }
        NSLog(@"name in View: %@ online", presenceEvent.name);
    }
    else {
        NSInteger index = [_contactsList indexOfObject:contactObjectON];
        if (index != NSNotFound)
        {
            [_contactsList replaceObjectAtIndex:index withObject:contactObjectOFF];
        }
        else if ([_contactsList indexOfObject:contactObjectOFF] == NSNotFound)
        {
            [_contactsList addObject:contactObjectOFF];
        }
        NSLog(@"name in View: %@ offline", presenceEvent.name);
    }

    [contactPicker reloadAllComponents];
    
    // TODO release strings
}


#pragma mark -
#pragma mark Update UI

-(void)syncMainButton
{
	if ( ![NSThread isMainThread] )
	{
		[self performSelectorOnMainThread:@selector(syncMainButton) withObject:nil waitUntilDone:NO];
		return;
	}
	
	// Sync the main button according to the current connection's state
	if (self.phone.connection)
	{
		if (self.phone.connection.state == TCConnectionStateDisconnected)
		{
			//Connection state is closed, show idle button
			[self.mainButton setImage:[UIImage imageNamed:@"idle"] forState:UIControlStateNormal];
		}
		else if (self.phone.connection.state == TCConnectionStateConnected)
		{
//            NSLog(@"dispose the sound");
//            AudioServicesDisposeSystemSoundID(ringtoneSSID);
//            OSStatus error = 0;
//            UInt32 allowMixing = false;
//            
//            error = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(allowMixing), &allowMixing);
//            if (error)
//                NSLog(@"AudioSessionSetProperty set to false failed");

            
			//Connection state is open, show in progress button
			[self.mainButton setImage:[UIImage imageNamed:@"inprogress"] forState:UIControlStateNormal];
		}
		else
		{
            // Fake ringback tone on early stage
//            OSStatus error = 0;
//            UInt32 allowMixing = true;
//            
//            error = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(allowMixing), &allowMixing);
//            if (error)
//                NSLog(@"AudioSessionSetProperty failed");


              //_phone.ringbackTone = [[NSBundle mainBundle] pathForResource:@"ringback-uk" ofType:@"mp3"];
//              _phone.ringbackTone = [[NSBundle mainBundle] pathForResource:@"outgoing" ofType:@"wav"];
//              NSLog(@"tone path %@", _phone.ringbackTone);
//            
//            CFURLRef        myURLRef;
//            
//            myURLRef = CFURLCreateWithFileSystemPath (
//                                                      kCFAllocatorDefault,
//                                                      (CFStringRef)_phone.ringbackTone,
//                                                      kCFURLPOSIXPathStyle,
//                                                      FALSE
//                                                      );
//            error = AudioServicesCreateSystemSoundID(myURLRef, &ringtoneSSID);
//            if (error)
//                NSLog(@"AudioServicesCreateSystemSoundID error");
//            CFRelease (myURLRef);
//            AudioServicesAddSystemSoundCompletion (
//                                                   ringtoneSSID,
//                                                   NULL,
//                                                   NULL,
//                                                   ringtoneCallback,
//                                                   NULL
//                                                   );
//            AudioServicesPlaySystemSound(ringtoneSSID);
			
            //Connection is in the middle of connecting. Show dialing button
			[self.mainButton setImage:[UIImage imageNamed:@"dialing"] forState:UIControlStateNormal];
		}
	}
	else
	{
		if (self.phone.pendingIncomingConnection)
		{
			//A pending incoming connection existed, show dialing button
			[self.mainButton setImage:[UIImage imageNamed:@"dialing"] forState:UIControlStateNormal];
		}
		else
		{
			//Both connection and _pending connnection do not exist, show idle button
			[self.mainButton setImage:[UIImage imageNamed:@"idle"] forState:UIControlStateNormal];
		}
	}
}

-(void)addStatusMessage:(NSString*)message
{
	if ( ![NSThread isMainThread] )
	{
		[self performSelectorOnMainThread:@selector(addStatusMessage:) withObject:message waitUntilDone:NO];
		return;
	}
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];
	
	//Update the text view to tell the user what the phone is doing
	self.textView.text = [self.textView.text stringByAppendingFormat:@"\n[%@] %@",[dateFormatter stringFromDate:[NSDate date]],message];
	
	//Scroll textview automatically for readability
	[self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
}

#pragma mark -
#pragma mark UIAlertView

-(void)constructAlert:(NSString*)from
{
	_alertView = [[[UIAlertView alloc] initWithTitle:@"Incoming Call" 
											 message:from
											delegate:self 
								   cancelButtonTitle:nil 
								   otherButtonTitles:@"Accept",@"Ignore",nil] autorelease];
	[_alertView show];
}

-(void)cancelAlert
{
	if ( _alertView )
	{
		[_alertView dismissWithClickedButtonIndex:1 animated:YES];
		_alertView = nil; // autoreleased
	}
}

-(void)getUserName
{
    // Get user name. Make persistent.
    _phone.username = [self readUsernameFromFile];
    if (_phone.username == nil)
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Username" message:@"Enter your user name" delegate:self cancelButtonTitle:@"Ready" otherButtonTitles:nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
        [alert release];
    }
    else
    {
        // Enter yourself into Picker list with OFF until presence update comes
        NSString* myself = [[NSString alloc] initWithFormat:@"OFF %@", _phone.username];
        _contactsList = [[NSMutableArray alloc]initWithObjects:myself,nil];
        [contactPicker reloadAllComponents];
        [_phone login]; // check it
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView* )alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView numberOfButtons] == 1)
    {
        _phone.username = [[NSString alloc] initWithString:[[alertView textFieldAtIndex:0] text]];
        NSLog(@"Entered: %@",_phone.username);
        [self writeUsernameToFile:_phone.username];
        // Enter yourself into Picker list with OFF until presence update comes
        NSString* myself = [[NSString alloc] initWithFormat:@"OFF %@", _phone.username];
        _contactsList = [[NSMutableArray alloc]initWithObjects:myself,nil];
        [contactPicker reloadAllComponents];
        [_phone login];
        return;
    }
	if(buttonIndex==0)
	{
        AudioServicesDisposeSystemSoundID(ringtoneSSID);
		//Accept button pressed
		if(!self.phone.connection)
		{
			[self.phone acceptConnection];
		}
		else
		{
			//A connection already existed, so disconnect old connection and connect to current pending connectioon
			[self.phone disconnect];
			
			//Give the client time to reset itself, then accept connection
			[self.phone performSelector:@selector(acceptConnection) withObject:nil afterDelay:0.2];
		}
	}
	else
	{
        AudioServicesDisposeSystemSoundID(ringtoneSSID);
		// We don't release until after the delegate callback for connectionDidConnect:
		[self.phone ignoreIncomingConnection];
	}
}

#pragma mark -
#pragma mark Memory managment

- (void)dealloc 
{
    // Release array with strings TODO
    [contactPicker release];
    [_switchLogButton release];
    [super dealloc];
}

#pragma mark -
#pragma mark Picker

-(NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _contactsList.count;
}

-(NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [_contactsList objectAtIndex:row];
}

static void ringtoneCallback (SystemSoundID  mySSID,void* inClientData)
{
    //AudioServicesPlaySystemSound(mySSID);
    //AudioServicesDisposeSystemSound(mySSID);
}

#pragma mark -
#pragma mark Auxillary

//Method writes a string to a text file
-(void) writeUsernameToFile:(NSString*)username
{
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/username.txt",documentsDirectory];
    //save content to the documents directory
    [username writeToFile:fileName
                    atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                    error:nil];
}

//Method retrieves content from documents directory and
//displays it in an alert
-(NSString*) readUsernameFromFile
{
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [NSString stringWithFormat:@"%@/username.txt",documentsDirectory];
    return [[NSString alloc] initWithContentsOfFile:fileName usedEncoding:nil error:nil];
    
    //[content release];
    
}

@end
