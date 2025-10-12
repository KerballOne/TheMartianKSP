function getResource {
    parameter res.
    FOR resource in SHIP:resources {
        IF resource:NAME = res { SET res TO resource:amount. }
    }
    return res.
}

function enableResourceFlow {
    parameter resources.
    FOR resource in resources {
        FOR part in SHIP:parts {
            FOR part_resource in part:resources {
                if part_resource:name = resource {
                    //print resource.
                    SET part_resource:enabled TO true.
                }
            }
        }
    }
}

function enableVents {
    FOR module in SHIP:modulesnamed("ModuleResourceDrain") {
        module:setfield("drain rate", 20).
        module:setfield("drain mode", True).
        module:setfield("drain", True).
    }
}

function checkChildPart {
    parameter parent, child.
    SET partParent TO SHIP:partsnamedpattern(parent)[0].
    //print partParent.
    FOR childpart IN partParent:children {
        //print "    " + childpart.
        IF childpart:name:contains(child) {
            return true.
        }
    }
}

function sealVents {
    print "Waiting for duct tape and hab canvas...".
    Wait until checkChildPart("Decoupler", "KKAOSS.gangway.end").
    Wait 2.
    FOR module in SHIP:modulesnamed("ModuleResourceDrain") {
        module:setfield("drain", False).
    }
}

function disconnect {
    FOR connector IN SHIP:partsnamedpattern("RTS") {
        print connector.
        LOCAL module is connector:getmodule("KASLinkResourceConnector").
        IF module:alleventnames:contains("detach connector") {
            module:doevent("detach connector").
        }
        wait 0.5.
        IF module:alleventnames:contains("lock connector") {
            module:doevent("lock connector").
        }
    }
}

function breachHab {
    disconnect().
    enableResourceFlow(list("Organics","Compost","Atmosphere","WasteAtmosphere")).
    enableVents().
    SHIP:PARTSDUBBED("Airlock O2 Tank")[0]:getmodule("ModuleKaboom"):DOEVENT("kaboom!").
    wait 1.5.
    SHIP:PARTSDUBBED("AL102")[0]:getModule("ModuleDecouple"):doEvent("decouple").
    wait 10.
    sealVents().
}

print "Waiting for crew".
Wait until SHIP:crew:length > 0.
FOR member in SHIP:crew {
   IF member:NAME = "Mark Watney" {
        print member:NAME + "is aboard".
        SET mark TO member.
   }
}

print "Waiting for harvest.".
Wait until getResource("Food") > 500.
Wait 1.
print "Wow! Those are tasty taters!".

Wait until SHIP:crew:length > 0.
Wait until mark:part:tag = "Airlock 1".
print "Cycling Airlock 1".
wait 0.25. print ".". wait 0.25. print ".". wait 0.25. print ".". wait 0.25. print ".".

breachHab().

