
clearScreen.

print SHIP:shipname.
function checkChildPart {
    parameter parent, child.
    SET partParent TO SHIP:partsnamedpattern(parent)[0].
    print partParent.
    FOR childpart IN partParent:children {
        print "    " + childpart.
        IF childpart:name:contains(child) {
            return true.
        }
    }
}
function sealVents {
    print "Waiting for duct tape and hab canvas...".
    Wait until checkChildPart("Decoupler", "KKAOSS.gangway.end").
    FOR module in SHIP:modulesnamed("ModuleResourceDrain") {
        module:setfield("drain", False).
    }
}

print checkChildPart("Decoupler", "KKAOSS.gangway.end").
sealVents().