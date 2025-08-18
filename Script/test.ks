clearScreen.
//print "kOS - IsConnected=" + VESSEL("Pathfinder Demo"):CONNECTION:ISCONNECTED.
//print "RT - HasConnection=" + ADDONS:RT:HASCONNECTION(VESSEL("Pathfinder Demo")).
//print "RT - Delay=" + ADDONS:RT:Delay(VESSEL("Pathfinder Demo")).
//print "RT - KSCDelay=" + ADDONS:RT:KSCDelay(VESSEL("Pathfinder Demo")).


function receive {
    print "Ready to Receive...".
    Wait Until NOT SHIP:messages:empty.
    SET RECEIVED TO SHIP:MESSAGES:POP.
    print "Sent by " + RECEIVED:SENDER + " at " + RECEIVED:SENTAT + " >>> ".
    print RECEIVED:CONTENT.
}

print "Waiting for connection... ".
Wait Until SHIP:connection:isconnected.
print SHIP:connection:destination.

if ADDONS:available("RT") {
    print ADDONS:RT:HASKSCCONNECTION(SHIP).
    print "Control delay: " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
    print "Transmission delay: " + ROUND(ADDONS:RT:DELAY(SHIP)) + " sec".
}
receive().