function completeContractParameter {
    parameter partName.
    FOR part IN SHIP:partsnamed(partName) {
        print partName.
        LOCAL m TO part:getmodule("ModuleTestSubject").
        if m:alleventnames:contains("run test") {
            m:doevent("run test").
        }
    }
}

function getResource {
    parameter res.
    SET resAmount TO 0.
    FOR resource in SHIP:resources {
        IF resource:NAME = res {
            SET resAmount TO resource:amount.
        }
    }
    return resAmount.
}

function enableResourceFlow {
    parameter resources.
    FOR resource in resources {
        FOR part in SHIP:parts {
            FOR part_resource in part:resources {
                if part_resource:name = resource {
                    SET part_resource:enabled TO true.
                }
            }
        }
    }
}

function disconnect {
    FOR connector IN SHIP:partsnamedpattern("RTS") {
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

function openVents {
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
    Wait 2.
    completeContractParameter("beacon3").
}

function breachHab {
    disconnect().
    enableResourceFlow(list("Organics","Compost","Atmosphere","WasteAtmosphere")).
    openVents().
    SHIP:PARTSDUBBED("AL102")[0]:getModule("ModuleDecouple"):doEvent("decouple").
    wait 0.1.
    SHIP:PARTSDUBBED("Airlock O2 Tank")[0]:getmodule("ModuleKaboom"):doEvent("kaboom!").
}

function statusCheck {
    IF checkChildPart("RRTankStackGas125", "rcsTankMini") 
    AND checkChildPart("rcsTankMini", "kerbalism-chemicalplant") 
    AND getResource("Hydrazine") = 80 {
        completeContractParameter("beacon1").
    }
    IF getResource("Hydrogen") > 0.02 AND SHIP:PARTSDUBBED("excess_O2"):length = 1 {
        SHIP:PARTSDUBBED("excess_O2")[0]:getmodule("ModuleKaboom"):doEvent("kaboom!").
        Wait 3.
        completeContractParameter("beacon2").
    }
    IF getResource("Food") > 500 {
        print "Wow! Those are tasty taters!".
        return true.
    }
    Wait 5.
    return false.
}

///////////////////////////////

print "Waiting for crew".
Wait until SHIP:crew:length > 0.
FOR member in SHIP:crew {
   IF member:NAME = "Mark Watney" {
        print member:NAME + " is aboard".
        SET mark TO member.
   }
}

Wait until statusCheck().

Wait until SHIP:crew:length > 0.
Wait until mark:part:tag = "Airlock 1".
print "Cycling Airlock 1".
wait 0.05. print ".". wait 0.05. print ".". wait 0.05. print ".". wait 0.05. print ".".
breachHab().
wait 10.
sealVents().