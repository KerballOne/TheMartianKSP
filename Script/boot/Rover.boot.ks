wait until ship:unpacked.
clearscreen.
print "Welcome to the Rover".
//SET SHIP:type TO "Rover".
//CORE:DOEVENT("Open Terminal"). // TESTING

function completeContractParameter {
    parameter paramName.
    IF ADDONS:available("CAREER") {
        IF ADDONS:CAREER:ACTIVECONTRACTS():length > 0 {
            SET ALL TO ADDONS:CAREER:ACTIVECONTRACTS()[0]:PARAMETERS().
            FOR P IN ALL {
                IF P:ID = paramName {
                    P:CHEAT_SET_STATE("COMPLETE").
                    wait 0.2.
                }
            }
        } 
    } ELSE {
        HUDTEXT("ERROR! \n kOS:Career addon must be installed. \n", 10, 1, 32, red, false).
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

GLOBAL chargingMode TO false.
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
        print BVactionStr.
        IF BVmodule:alleventnames:contains(BVactionStr) {
            BVmodule:doevent(BVactionStr).
        }
    }
    FOR wheel IN SHIP:partsnamed("wheelMed") {
        LOCAL wheelModule is wheel:getmodule("ModuleWheelMotor").
        wheelModule:doaction(WHLaction + " motor", true).
    }
    SET chargingMode TO charging.
}

function powerFaultCheck {
    FOR panel IN SHIP:partsnamedpattern("LgRadialSolarPanel") {
        SET panelParent to panel:parent:name.
        IF NOT panelParent:contains("PortPylon") 
        AND NOT panelParent:contains("LgRadialSolarPanel") {
            print panelParent + " cannot support Solar Panels".
            powerFaultProtection(panelParent + " cannot support Solar Panels").
        }
        FOR pylon IN SHIP:partsnamedpattern("PortPylon") {
            IF NOT pylon:children:tostring:contains("groundAnchor") {
                print pylon:name + " is not grounded!".
                powerFaultProtection(panel:name + " is not grounded!").
            }
        }
    }
    Wait 10.
}

function powerFaultProtection {
    parameter reason.
    BRAKES ON.
    HUDTEXT("Warning! \n Electrical Power ground fault detected! \n", 10, 1, 32, red, false).
    HUDTEXT(reason, 10, 1, 26, yellow, false).
    HUDTEXT("Isolating Main Traction Battery", 10, 1, 22, red, false).
    FOR part in SHIP:parts {
        FOR part_resource in part:resources {
            if part_resource:name = "ElectricCharge" AND part_resource:capacity > 200 {
                SET part_resource:enabled TO false.
            }
        }
    }
}

UNTIL false {
    //print timestamp().
    IF SHIP:partsnamedpattern("LgRadialSolarPanel"):length > 0 {
        IF NOT chargingMode { setChargingMode(true). }
        powerFaultCheck().
    } ELSE {
        IF chargingMode { setChargingMode(false). }
    }
    IF childPartDist("Ares-Cockpit","rtg") < 1.1 {
        HUDTEXT("Success! \n RTG Installed! \n", 10, 1, 32, green, false).
        completeContractParameter("kOSparam6").
    }
    wait 1.
}


