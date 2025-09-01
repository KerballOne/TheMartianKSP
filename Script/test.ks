//clearScreen.

function completeContractParameter {
    parameter partName.
    FOR part IN SHIP:partsnamed(partName) {
        print partName.
        LOCAL m TO part:getmodule("ModuleTestSubject").
        if m:alleventnames:contains("run test") {
            print "Triggering Event".
            m:doevent("run test").
        } ELSE {
            print "No Event".
        }
    }
}

completeContractParameter("beacon13").