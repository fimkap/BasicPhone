//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import "BasicPhoneViewController.h"
#import "BasicPhoneAppDelegate.h"
#import "BasicPhoneNotifications.h"
#import "BasicPhone.h"
#import "AVFoundation/AVAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

@interface BasicPhoneViewController () // Internal methods that don't get exposed.

-(void)syncMainButton;
-(void)addStatusMessage:(NSString*)message;

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

@end

@implementation BasicPhoneViewController

@synthesize phone = _phone;
@synthesize mainButton = _mainButton;
@synthesize textView = _textView;
@synthesize speakerSwitch = _speakerSwitch;
@synthesize ringtoneSSID;

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
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    if (_phone.username == nil)
    {
        [self getUserName];
    }
    
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
	
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Button Actions 

-(IBAction)mainButtonPressed:(id)sender
{
	//Action for button on main view
	BasicPhoneAppDelegate* delegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	BasicPhone* basicPhone = delegate.phone;
	
	//Perform correct button function based on current connection
	if (!basicPhone.connection || basicPhone.connection.state == TCConnectionStateDisconnected)
	{
		//Connection doesn't exist or is disconnected, so make a call
		[basicPhone connect];
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

	[basicPhone setSpeakerEnabled:self.speakerSwitch.on];
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
	//Show alert view asking if user wants to accept or ignore call
	[self performSelectorOnMainThread:@selector(constructAlert) withObject:nil waitUntilDone:NO];
	
	//Check for background support
	if ( ![self isForeground] )
	{
		//App is not in the foreground, so send LocalNotification
		UIApplication* app = [UIApplication sharedApplication];
		UILocalNotification* notification = [[UILocalNotification alloc] init];
		NSArray* oldNots = [app scheduledLocalNotifications];
		
		if ([oldNots count]>0)
		{
			[app cancelAllLocalNotifications];
		}
		
		notification.alertBody = @"Incoming Call";
        //notification.soundName = UILocalNotificationDefaultSoundName;
		
		[app presentLocalNotificationNow:notification];
		[notification release];
	}
	
	[self addStatusMessage:@"-Received inbound connection"];
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
            NSLog(@"dispose the sound");
            AudioServicesDisposeSystemSoundID(ringtoneSSID);
            
			//Connection state is open, show in progress button
			[self.mainButton setImage:[UIImage imageNamed:@"inprogress"] forState:UIControlStateNormal];
		}
		else
		{
            // Fake ringback tone on early stage
//            NSError *error = NULL;
//            NSURL *url = [[NSURL alloc ] initWithString:_phone.ringbackTone];
//            AVAudioPlayer *av = [[AVAudioPlayer alloc ] initWithContentsOfURL:url error:&error];
//            [av setNumberOfLoops:-1];
//            [av setDelegate:self];
//            [av play];
            
            UInt32 sessionCategory;
            UInt32 categorySize = sizeof(UInt32);
            AudioSessionGetProperty (kAudioSessionProperty_AudioCategory, &categorySize,&sessionCategory);
            NSLog(@"audio session %ld", sessionCategory);

            switch(sessionCategory) {
            case kAudioSessionCategory_AmbientSound:
                NSLog(@"AmbientSound");
                break;
            case kAudioSessionCategory_SoloAmbientSound:
                NSLog(@"SoloAmbientSound");
                break;
            case kAudioSessionCategory_MediaPlayback:
                NSLog(@"MediaPlayback");
                break;
            case kAudioSessionCategory_RecordAudio:
                NSLog(@"RecordAudio");
                break;
            case kAudioSessionCategory_PlayAndRecord:
                NSLog(@"PlayAndRecord");
                break;
            case kAudioSessionCategory_AudioProcessing:
                NSLog(@"AudioProcessing");
                break;
            default:
                NSLog(@"Unknown!");
            }

              //_phone.ringbackTone = [[NSBundle mainBundle] pathForResource:@"ringback-uk" ofType:@"mp3"];
              _phone.ringbackTone = [[NSBundle mainBundle] pathForResource:@"outgoing" ofType:@"wav"];
              NSLog(@"tone path %@", _phone.ringbackTone);
            
            CFURLRef        myURLRef;
            
            myURLRef = CFURLCreateWithFileSystemPath (
                                                      kCFAllocatorDefault,
                                                      (CFStringRef)_phone.ringbackTone,
                                                      kCFURLPOSIXPathStyle,
                                                      FALSE
                                                      );
            OSStatus err = AudioServicesCreateSystemSoundID(myURLRef, &ringtoneSSID);
            if (err)
                NSLog(@"AudioServicesCreateSystemSoundID error");
            CFRelease (myURLRef);
            AudioServicesAddSystemSoundCompletion (
                                                   ringtoneSSID,
                                                   NULL,
                                                   NULL,
                                                   ringtoneCallback,
                                                   NULL
                                                   );
            AudioServicesPlaySystemSound(ringtoneSSID);
			
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
	
	//Update the text view to tell the user what the phone is doing
	self.textView.text = [self.textView.text stringByAppendingFormat:@"\n%@",message];
	
	//Scroll textview automatically for readability
	[self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
}

#pragma mark -
#pragma mark UIAlertView

-(void)constructAlert
{
	_alertView = [[[UIAlertView alloc] initWithTitle:@"Incoming Call" 
											 message:@"Accept or Ignore?"
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
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Username" message:@"Enter your user name" delegate:self cancelButtonTitle:@"Ready" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    [alert release];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView* )alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView numberOfButtons] == 1)
    {
        _phone.username = [[NSString alloc] initWithString:[[alertView textFieldAtIndex:0] text]];
        NSLog(@"Entered: %@",_phone.username);
        [_phone login];
        return;
    }
	if(buttonIndex==0)
	{
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
		// We don't release until after the delegate callback for connectionDidConnect:
		[self.phone ignoreIncomingConnection];
	}
}

#pragma mark -
#pragma mark Memory managment

- (void)dealloc 
{
    [super dealloc];
}

static void ringtoneCallback (SystemSoundID  mySSID,void* inClientData)
{
    //AudioServicesDisposeSystemSound(mySSID);
}

@end
