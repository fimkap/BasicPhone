<Response>
<?php
	// if the From is from "client:basic" (e.g. the iOS App), redirect to the normal
	// quickstart URL to say a nice "Welcome to Twilio Client" message.
	// Otherwise, if the From is a phone number, have it call the client named "basic"
	// to dial into the iOS app.
	$from = isset($_REQUEST["From"]) ? $_REQUEST["From"] : "";
	if ( $from == "client:basic" )
	{ // redirect to the sample app URL
?>
	<Say>Welcome to Twilio Client.  You have successfully made a call from your i o s application!</Say>
<?php
	}
	else if (preg_match("/^\+?\d+$/", $from)) // (zero or one '+' chars, then one or more digits)
	{ // else if it's from a phone number, dial the client named "basic"
?>
	<Say>Dialing the Twilio Client named basic</Say>
	<Dial>
		<Client>basic</Client>
	</Dial>
<?php
	} 
?>
</Response>

