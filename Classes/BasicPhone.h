//
//  Copyright 2011 Twilio. All rights reserved.
//
 
#import <Foundation/Foundation.h>
#import "TwilioClient.h"

@interface BasicPhone : NSObject<TCDeviceDelegate, TCConnectionDelegate, UIAlertViewDelegate> 
{
@private
	TCDevice* _device;
	TCConnection* _connection;
	TCConnection* _pendingIncomingConnection;
	BOOL _speakerEnabled;
    NSString *ringbackTone;
    NSString *username;
    NSMutableArray* _contactsList;
}

@property (nonatomic,retain) TCDevice* device;
@property (nonatomic,retain) TCConnection* connection;
@property (nonatomic,retain) TCConnection* pendingIncomingConnection;
@property(readwrite, copy) NSString *ringbackTone;
@property(readwrite, copy) NSString *username;
@property (nonatomic,retain) NSArray* contactsList;

-(void)login;

// Turn the speaker on or off.
-(void)setSpeakerEnabled:(BOOL)enabled;

//TCConnection Methods
-(void)connect:(NSString*)dst;
-(void)disconnect;
-(void)acceptConnection;
-(void)ignoreIncomingConnection;
-(void)initContactsList;

@end
