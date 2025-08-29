Wait Until SHIP:connection:isconnected.
clearScreen.
CORE:DOEVENT("Open Terminal"). 
function convertSeconds {
    parameter seconds.
    return FLOOR(seconds / 60) + " min  " + Round(Mod(seconds,60), 0) + " sec".
}


IF shipName = "Pathfinder Demo"
{
    SET RemoteVessel TO VESSEL("Mars Rover").
} ELSE IF shipName = "Mars Rover" {
    SET RemoteVessel TO VESSEL("Pathfinder Demo").
}
IF ADDONS:available("RT") {
    print "Control delay:         " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
    print "HasConnection SHIP = " + ADDONS:RT:HASKSCCONNECTION(SHIP).
    print "HasConnection Remote = " + ADDONS:RT:HASKSCCONNECTION(RemoteVessel).
}

print TIME:clock.
SET C TO RemoteVessel:CONNECTION.
SET COMMDELAY TO convertSeconds(ROUND(C:delay())).
print "Transmission delay:    " + COMMDELAY.

print "RT Remote Vessel delay:    " + RemoteVessel + " --> " + ROUND(ADDONS:RT:Delay(RemoteVessel)) + " sec".
print "RT SELF delay:    " + SHIP + " --> " + ROUND(ADDONS:RT:Delay(SHIP)) + " sec".

print "Delay is " + COMMDELAY.
print "Sending message.... ".
IF C:SENDMESSAGE("I am " + SHIP:shipname + " " + TIME:clock) {
    Wait 1.
    print "Message sent!".
}
Wait until NOT SHIP:messages:empty.
Until SHIP:messages:empty {
    SET RECEIVED TO SHIP:MESSAGES:POP.
    print "Sent by " + RECEIVED:SENDER + " at " + RECEIVED:SENTAT + " >>> ".
    print RECEIVED:CONTENT.
}

print TIME:clock.