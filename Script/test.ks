clearScreen.

function getRemoteVessel {
    LIST Targets IN Vessels.
    FOR vsl IN Vessels {
        IF vsl:type <> "SpaceObject"
        AND vsl:body <> SHIP:body
        AND vsl:status = "LANDED"
        AND vsl:connection:isconnected
        AND ADDONS:RT:HASCONNECTION(vsl) {
            print "Remote Target: " + vsl + " - Type: " + vsl:type.
            print vsl:body.
            print vsl:status.
            print vsl:crew.
            print vsl:connection:isconnected.
            print vsl:connection:delay.
            print ADDONS:RT:DELAY(vsl).
            print ADDONS:RT:HASCONNECTION(vsl).
            print " ".
            return VESSEL(vsl:name).
        }
    }
    print "No Remote Probe Found!".
    //HUDTEXT("No Remote Probe Connection! \n", 10, 1, 16, red, false).
    //Wait 20. Reboot.
}

print getRemoteVessel().
print ADDONS:RT:DELAY(SHIP).