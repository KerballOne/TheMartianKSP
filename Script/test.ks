clearScreen.

function convertSeconds {
    parameter seconds.
    return FLOOR(seconds / 60) + " min  " + Round(Mod(seconds,60), 0) + " sec".
}

IF ADDONS:available("RT") {
    print "Control delay:      " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
    IF shipName = "Pathfinder Demo"
    {
        CORE:DOEVENT("Open Terminal"). // TESTING
        SET RemoteVessel TO VESSEL("Pathfinder Probe").
    } ELSE IF shipName = "Pathfinder Probe" {
        SET RemoteVessel TO VESSEL("Pathfinder Demo").
    }
    IF NOT Addons:RT:HASLOCALCONTROL(SHIP) {
        SET COMMDELAY TO convertSeconds(ROUND(Addons:RT:Delay(RemoteVessel))).
    } ELSE {
        SET COMMDELAY TO convertSeconds(ROUND(Addons:RT:Delay(SHIP))).
    }
    print "Transmission delay: " + COMMDELAY.
}

print Addons:RT:HASLOCALCONTROL(SHIP).
print "SHIP " + convertSeconds(ROUND(Addons:RT:Delay(SHIP))).
print "REMT " + convertSeconds(ROUND(Addons:RT:Delay(RemoteVessel))).

SET C TO RemoteVessel:CONNECTION.
print C:delay().
SET MESSAGE TO "Test".
print "Sending message.... ".
print "   > " + MESSAGE.
IF C:SENDMESSAGE(MESSAGE) {
    Wait 1.
    print "Message sent!".
}