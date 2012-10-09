<?php
// This php is to be put on your server, and change the URLs in BasicPhone.m
// to point to this file's public location. 
require "Services/Twilio/Capability.php";

$accountSid = "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
$authToken = "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY";
 
// The app outbound connections will use: 
$appSid = "APZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

// The client name for inbound connections: 
$clientName = "basic";

$capability = new Services_Twilio_Capability($accountSid, $authToken);

// This would allow inbound connections as $clientName:
$capability->allowClientIncoming($clientName);
 
// This allows outgoing connections to $appSid with the "From" parameter being $clientName 
$capability->allowClientOutgoing($appSid, array(), $clientName);

// This would return a token to use with Twilio based on 
// the account and capabilities defined above 
$token = $capability->generateToken();

echo $token; 
?>