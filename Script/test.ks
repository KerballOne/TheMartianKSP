clearScreen.

function contractParameter {
    parameter paramName, action.
    IF ADDONS:available("CAREER") {
        IF ADDONS:CAREER:ACTIVECONTRACTS():length > 0 {
            SET ALL TO ADDONS:CAREER:ACTIVECONTRACTS()[0]:PARAMETERS().
            FOR P IN ALL {
                IF P:ID = paramName {
                    IF action = "state" {
                        return P:state.
                    } ELSE {
                        P:CHEAT_SET_STATE(action).
                    }
                    wait 0.2.
                }
            }
        } 
    } ELSE {
        HUDTEXT("ERROR! \n kOS:Career addon must be installed. \n", 10, 1, 32, red, false).
    }
}


IF contractParameter("kOSparam11","state") = "Incomplete" {
    print "COMPLETING kOSparam11".
    contractParameter("kOSparam11","COMPLETE").
}
Wait 6.
IF contractParameter("kOSparam6","state") = "Incomplete" {
    print "COMPLETING kOSparam6".
    contractParameter("kOSparam6","COMPLETE").
}
LIST Targets IN Vessels.
FOR vsl IN Vessels {
    IF vsl:type <> "SpaceObject" {
        print Vessels.
    }
}

//print "Active:".
//FOR C1 IN ADDONS:CAREER:ACTIVECONTRACTS() {
//    print "    " + C1:TITLE.
//    print C1.
//}
//print "All:".
//FOR C2 IN ADDONS:CAREER:ALLCONTRACTS() {
//    print "    " + C2:TITLE.
//}
//print "Offered:".
//FOR C3 IN ADDONS:CAREER:OFFEREDCONTRACTS() {
//    print "    " + C3:TITLE.
//}

