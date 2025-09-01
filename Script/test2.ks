Wait Until SHIP:connection:isconnected.
clearScreen.

SET COM_Terminal TO SHIP:partsnamedpattern("RTShortAntenna1")[0].
SET module TO COM_Terminal:getmodule("ModuleRTAntenna").
print module:alleventnames.
print module:getfield("status").
IF module:getfield("status") <> "Off" { 
    print "turning off".
    module:doevent("Deactivate").
}

COMPILE "Pathfinder.ks" to "0:Pathfinder.ksm".