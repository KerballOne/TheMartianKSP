wait until ship:unpacked.
clearscreen.
//CORE:DOEVENT("Open Terminal"). // TESTING
print "=== Hermes Management System v0.1.0 ===".

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

function setEarthOrbit {
    IF SHIP:OBT:nextpatch:body:name = "Earth" {
        SET np TO SHIP:OBT:nextpatch:ETA:PERIAPSIS.
        SET myNode to NODE(TIME:SECONDS+np,0,0,0).
        add myNode.
        SET vel TO myNode:orbit:velocity:orbit:mag.
        SET retro TO (vel - 4000).
        SET myNode:prograde TO -retro.
    }
}

function checkChildPart {
    parameter parent, child.
    SET partParent TO SHIP:partsnamedpattern(parent)[0].
    FOR childpart IN partParent:children {
        IF childpart:name:contains(child) {
            return true.
        }
    }
}

function breachAirlock {
    SHIP:PARTSDUBBED("Airlock O2 Tank")[0]:getmodule("ModuleKaboom"):doEvent("kaboom!").
    FOR module in SHIP:modulesnamed("Habitat") {
        module:doEvent("vent atmosphere").
    }
    FOR ied IN SHIP:partsnamed("Space.IED") {
        ied:getModule("ModuleEngines"):doEvent("activate engine").
        Wait 1.2.
        ied:getModule("ModuleDecouple"):doEvent("decouple").
    }
}

function isLightOn {
    SET part TO SHIP:PARTSDUBBED("fwdDockingPort")[0].
    SET module TO part:getmodule("ModuleColorChanger").
    IF module:alleventnames:tostring:contains("lights off") {
        module:doevent("lights off").
        return true.
    }
}

UNTIL false {
    IF body:name = "Sun" AND core:volume:name <> "Init0" {
        SET core:volume:name TO "Init0".
        Wait 10.
        setEarthOrbit().
    }
    IF body:name = "Mars" {
        IF SHIP:PARTSDUBBED("Airlock O2 Tank"):length > 0 
        AND checkChildPart("dockingPort1","Space.IED")
        AND isLightOn() {
            breachAirlock().
            Wait 10.
            contractParameter("kOSparam_Hermes1","COMPLETE").
        }
    }
    Wait 2.
}