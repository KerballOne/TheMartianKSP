function getResource {
    parameter res.
    FOR resource in SHIP:resources {
        IF resource:NAME = res { SET res TO resource:amount. }
    }
    return res.
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

function CabinHeat {
    FOR module in SHIP:modulesnamed("ProcessController") {
        FOR action in module:allactionnames {
            IF action:contains("cabin heater") {
                print "Restarting Cabin Heat".
                module:doaction(action,true).
            }
        }
    }
}

function getPowerFlow {
    FOR res in SHIP:resources {
        IF res:name:contains("ElectricCharge") {
            LOCAL prevAmount to res:amount.
            wait 1.
            return (res:amount - prevAmount).
        }
    }
}

function powerFaultProtection {
    parameter reason.
    BRAKES ON.
    HUDTEXT("Warning! \n Power fault detected! \n" + reason, 10, 1, 32, red, false).
    HUDTEXT("Shutting down wheel motors", 10, 1, 22, red, false).
    HUDTEXT("Isolating Main Traction Battery", 10, 1, 22, red, false).
    FOR part in SHIP:parts {
            FOR part_resource in part:resources {
                if part_resource:name = "ElectricCharge" AND part_resource:capacity > 200 {
                    SET part_resource:enabled TO false.
                }
            }
        }
    FOR wheel IN SHIP:partsnamed("wheelMed") {
        LOCAL module is wheel:getmodule("ModuleWheelMotor").
        module:doaction("disable motor", true).
    }
    wait 1.
}

function checkPower {
    FOR panel IN SHIP:partsnamedpattern("SolarPanel") {
        SET panelParent to panel:parent:name.
        IF NOT panelParent:contains("PortPylon") 
        AND NOT panelParent:contains("SolarPanel") {
            print panelParent + " cannot support Solar Panels".
            return true.
        }
        IF panel:parent:name:contains("PortPylon") {
            FOR pylonChild IN panel:parent:children {
                IF NOT pylonChild:name:contains("groundAnchor") 
                AND NOT pylonChild:name:contains("SolarPanel") {
                    print panel:name + " is not grounded!".
                    return true.
                }
            }
        }
    }
}

UNTIL false {
    //print timestamp().
    IF SHIP:partsnamedpattern("SolarPanel"):length > 0 AND getPowerFlow() > 1.0 {
        IF SHIP:groundspeed > 1 {
            powerFaultProtection("== CURRENT DRAW ==").
        }
        IF checkPower() {
            powerFaultProtection("== NOT GROUNDED ==").
        }
    }
    IF getResource("_CabinHeater") = 0 AND NOT checkChildPart("Ares-Cockpit","rtg") {
        CabinHeat().
    }
    wait 10.
}


