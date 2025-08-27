wait until ship:unpacked. //Wait 2.
clearscreen.
print "Loading remote firmware from JPL servers...".
Wait Until SHIP:connection:isconnected.
runpath("0:Pathfinder.ks").