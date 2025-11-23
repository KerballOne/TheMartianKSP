wait until ship:unpacked.
clearscreen.
//CORE:DOEVENT("Open Terminal"). // TESTING
print "=== Ares III Habitat Management System v0.1.6 ===".
SET SHIP:type TO "Base".

function contractParameter {
    parameter paramName, action.
    IF NOT ADDONS:available("CAREER") {
        HUDTEXT("ERROR! \n kOS:Career addon must be installed. \n", 10, 1, 32, red, false).
        return false.
    }
    FOR contract IN ADDONS:CAREER:ACTIVECONTRACTS() {
        FOR param IN contract:PARAMETERS() {
            IF param:ID = paramName {
                IF action = "getState" {
                    return param:state.
                } ELSE {
                    IF contractParameter(paramName,"getState") <> action {
                        param:CHEAT_SET_STATE(action).
                        HUDTEXT("SUCCESS! \n Objective " + param:state + "\n", 10, 1, 32, green, false).
                        return param:ID + " " + param:state.
                    }
                }
                wait 0.2.
            }
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

function getResourceRate {
    parameter res, span.
    SET init TO getResource(res). Wait span.
    return (getResource(res) - init) / span.
}

function changeResourceFlow {
    parameter resources, state.
    FOR resource in resources {
        FOR part in SHIP:parts {
            FOR part_resource in part:resources {
                if part_resource:name = resource {
                    SET part_resource:enabled TO state.
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

function closeExhaust {
    Wait until getResource("Atmosphere") < 1.
    FOR vent IN SHIP:partsnamed("ReleaseValveExhaust") {
        SET moduleEx TO vent:getmodule("ModuleResourceDrain").
        moduleEx:setfield("drain", False).
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

function breachHab {
    disconnect().
    changeResourceFlow(list("Organics","Compost","Atmosphere","WasteAtmosphere"), true).
    openVents().
    SHIP:PARTSDUBBED("AL102")[0]:getModule("ModuleDecouple"):doEvent("decouple").
    wait 0.1.
    SHIP:PARTSDUBBED("Airlock O2 Tank")[0]:getmodule("ModuleKaboom"):doEvent("kaboom!").

}
function analyzingData {
    SET str TO "surface sample (mars landed acidalia planitia)".
    IF SHIP:modulesnamed("Laboratory"):tostring():contains(str) {
        return true.
    }
}
function analyzedData {
    FOR hdd IN SHIP:modulesnamed("HardDrive") {
        FOR evtname IN hdd:alleventnames {
            IF evtname:length > 22 {
                return evtname:substring(13,6):tonumber(0).
            }
        }
    }
    return 0.
}

function getResourceCapacity {
    parameter res.
    SET resCapacity TO 0.
    FOR resource in SHIP:resources {
        IF resource:NAME = res {
            SET resCapacity TO resource:capacity.
        }
    }
    return resCapacity.
}
function getResourceFlow {
    parameter res.
    SET flowing TO 0.
    FOR part in SHIP:parts {
        FOR part_resource in part:resources {
            if part_resource:name = res 
            AND part_resource:enabled {
                SET flowing TO flowing + 1.
            }
        }
    }
    return flowing.
}

function checkHydrazineDrip {
    IF getResource("Hydrogen") > 1.0 
    AND SHIP:PARTSDUBBED("excess_O2"):length = 1 {
        SHIP:PARTSDUBBED("excess_O2")[0]:getmodule("ModuleKaboom"):doEvent("kaboom!").
    }
    IF getResource("Hydrazine") > 0 AND getResourceCapacity("Hydrogen") > 0
    AND getResourceFlow("Hydrogen") > 0 {
        IF (NOT checkChildPart("RRTankStackGas125", "rcsTankMini")
        OR NOT checkChildPart("rcsTankMini", "kerbalism-chemicalplant")) {
            changeResourceFlow(list("Hydrazine","Hydrogen"), false).
            HUDTEXT("ERROR! \n Hydrazine system not installed correctly. \n ChemPlant must attach on top of Hydrazine tank, which must attach on top of Gas Storage tanks on top of the Hab.", 20, 1, 20, red, false).
        } ELSE {
            return true.
        }
    }
}

function main {
    IF CORE:volume:name = "Init0"
    AND analyzingData() {
        print "Analyzing Martian regolith surface samples".
        SET CORE:volume:name TO "HAB_1M_1222".
    }
    IF CORE:volume:name = "HAB_1M_1222"
    AND analyzedData() > 849.9 {
        print analyzedData() + " MB of Martian regolith analyzed".
        contractParameter("kOSparam_Hab1","COMPLETE").
        SET CORE:volume:name TO "HAB_2M_5462".
    }
    IF CORE:volume:name = "HAB_2M_5462" {
        IF checkHydrazineDrip() {
            contractParameter("kOSparam_Hab2","COMPLETE").
            SET CORE:volume:name TO "HAB_3M_5342".
        }
    }
    IF CORE:volume:name = "HAB_3M_5342" 
    AND getResourceRate("Water",60) > 0.000005 {
        contractParameter("kOSparam_Hab2a","COMPLETE").
        SET CORE:volume:name TO "HAB_4M_2353".
    }
    IF CORE:volume:name = "HAB_4M_2353" 
    AND getResource("Food") > 500 {
        contractParameter("kOSparam_Hab3","COMPLETE").
        SET CORE:volume:name TO "HAB_5M_7686".
    }
    IF CORE:volume:name = "HAB_5M_7686" 
    AND SHIP:crew:length > 0 {
        FOR cm in SHIP:crew {
            IF cm:NAME = "Mark Watney" AND cm:part:tag = "Airlock 1" {
                print "Cycling Airlock 1".
                breachHab(). Wait 2. closeExhaust().
                Wait 3. contractParameter("kOSparam_Hab4","COMPLETE").
                SET CORE:volume:name TO "HAB_6M_2348".
            }       
        }
    }
    IF CORE:volume:name = "HAB_6M_2348"
    AND checkChildPart("Decoupler", "KKAOSS.gangway.end") {
        print "Habitat hole sealed!".
        FOR module in SHIP:modulesnamed("ModuleResourceDrain") {
            module:setfield("drain", False).
        }
        Wait 2. contractParameter("kOSparam_Hab5","COMPLETE").
        SET CORE:volume:name TO "HAB_7M_2348".
    }
    Wait 5.
    return false.
}

///////////////////////////////

IF CORE:volume:name = "" { SET CORE:volume:name TO "Init0". }
IF contractParameter("Prologue","getState") = "Incomplete" { SET CORE:volume:name TO "Init0". }
print CORE:volume:name.

Wait until main().
