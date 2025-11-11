wait until ship:unpacked.
clearscreen.
//CORE:DOEVENT("Open Terminal"). // TESTING
print "=== Iris Management System v0.1.0 ===".

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
                    print param:state.
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

Wait until SHIP:altitude > 42000.
IF contractParameter("IrisDestroyed","getState") = "Incomplete" {
    print "Payload unbalanced...".
    HUDTEXT("DANGER! \n Guidance system failure", 10, 1, 32, red, false).
    LOCK STEERING TO UP + R(500,500,500). Wait 3.
    HUDTEXT("Payload Sensors: CoM reading out of bounds. \n Payload is unbalanced", 10, 1, 32, yellow, false).
    Wait 12.
    SHIP:partsnamed("IRIS")[0]:getmodule("ModuleKaboom"):doEvent("kaboom!").
}
