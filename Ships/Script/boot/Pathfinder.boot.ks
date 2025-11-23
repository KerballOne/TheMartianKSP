wait until ship:unpacked.
clearscreen.

Wait Until SHIP:connection:isconnected. Wait 2.
IF ADDONS:available("RT") {
    IF ADDONS:RT:HASKSCCONNECTION(SHIP) {
        print "Loading remote firmware from JPL servers...".
        COPYPATH("0:Pathfinder.ks", "1:Pathfinder.ks").
        runpath("Pathfinder.ks").
    } ELSE IF EXISTS("1:Pathfinder.ks") {
        runpath("Pathfinder.ks").
    } ELSE {
        print "No firmware found!".
        Wait Until False.
    }
}


