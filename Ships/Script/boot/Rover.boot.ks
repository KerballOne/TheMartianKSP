wait until ship:unpacked.
clearscreen.
//CORE:DOEVENT("Open Terminal"). // TESTING
print "=== Ares III Rover Management System v0.1.2 ===".


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

function childPartDist {
    parameter parent, child.
    SET partParent TO SHIP:partsnamedpattern(parent)[0].
    //print partParent.
    FOR childpart IN partParent:children {
        //print "    " + childpart.
        IF childpart:name:contains(child) {
            SET vec TO partParent:position - childpart:position.
            return vec:mag.
        }
    }
    return 99999.
}

function setChargingMode {
    parameter charging.
    IF charging {
        SET BVaction TO "Shutdown".
        SET WHLaction TO "disable".
    } ELSE {
        SET BVaction TO "Activate".
        SET WHLaction TO "enable".
    }
    SET cockpit to SHIP:partsnamedpattern("cockpit")[0].
    IF cockpit:allmodules:contains("BonVoyageModule") {
        SET BVmodule TO cockpit:getmodule("BonVoyageModule").
        SET BVactionStr TO BVaction + " Bon Voyage Controller".
        IF BVmodule:alleventnames:contains(BVactionStr) {
            print BVactionStr.
            BVmodule:doevent(BVactionStr).
        }
    }
    FOR wheel IN SHIP:partsnamed("wheelMed") {
        SET wheelModule TO wheel:getmodule("ModuleWheelMotor").
        SET WHLactionStr TO WHLaction + " motor".
        IF wheelModule:allactionnames:contains(WHLactionStr) {
            wheelModule:doaction(WHLactionStr, true).
        }
    }
}

function powerFaultCheck {
    FOR panel IN SHIP:partsnamedpattern("LgRadialSolarPanel") {
        SET panelParent to panel:parent:name.
        IF panelParent:contains("LgRadialSolarPanel") { return false. }
        IF panelParent:contains("PortPylon") {
            SET pylon TO panelParent.
            IF NOT pylon:children:tostring:contains("groundAnchor")
            AND NOT pylon:parent:tostring:contains("IR.Segment.TubeSmall.2m50") {
                print pylon:name + " is not grounded!".
                powerFaultProtection(panel:name + " is not grounded!").
            }
        } ELSE {
            print panelParent + " cannot support Solar Panels".
            powerFaultProtection(panelParent + " cannot support Solar Panels").
        }           
    }
}

function powerFaultProtection {
    parameter reason.
    BRAKES ON.
    HUDTEXT("Warning! \n Electrical Power ground fault detected! \n", 10, 1, 32, red, false).
    HUDTEXT(reason, 10, 1, 26, yellow, false).
    HUDTEXT("Isolating Main Traction Battery", 10, 1, 22, red, false).
    FOR part in SHIP:parts {
        IF part:name = "Ares-Battery" OR part:name = "ksp.r.largeBatteryPack" {
            FOR part_resource in part:resources {
                if part_resource:name = "ElectricCharge" AND part_resource:capacity > 200 {
                    SET part_resource:enabled TO false.
                }
            }
        }
    }
}

UNTIL false {
    //print timestamp().
    IF SHIP:partsnamedpattern("LgRadialSolarPanel"):length > 0 {
        setChargingMode(true).
        powerFaultCheck().
    } ELSE {
        setChargingMode(false).
    }
    IF childPartDist("Ares-Cockpit","rtg") < 1.1 {
        contractParameter("kOSparam_Rover1","COMPLETE").
    }
    wait 3.
}


