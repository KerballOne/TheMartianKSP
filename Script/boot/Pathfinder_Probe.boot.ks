wait until ship:unpacked. Wait 5.
clearscreen.
print "Welcome Pathfinder".
//runpath("0:test.ks").

clearScreen.

function powerCycle {
    parameter action.
    SET IRpivot TO SHIP:partsnamedpattern("IR.Pivotron")[0].
    SET pivotServo TO IRpivot:getmodule("ModuleIRServo_v3").
    SET IRextend TO SHIP:partsnamedpattern("IR.Extendatron")[0].
    SET extendServo TO IRextend:getmodule("ModuleIRServo_v3").
    IF action = "wake" {
        pivotServo:setfield("target position", 15.0).
        extendServo:setfield("target position", 0.5).
    } ELSE IF action = "sleep" {
        pivotServo:setfield("target position", 0.0).
        extendServo:setfield("target position", 0.0).
    }
}

function rotate {
    parameter msg.
    SET module TO SHIP:partsdubbed("CamRotator")[0]:getmodule("ModuleIRServo_v3").
    FOR tp IN msg {
        //print "Target=" + tp.
        module:setfield("target position", tp).
        LOCK cp TO module:getfield("current position").
        wait until cp < tp + 0.1 AND cp > tp - 0.1. wait 2.
    }
}

function Photo {
    SET IRcamera TO SHIP:partsnamedpattern("IR.Camera")[0].
    SET cameraLight TO IRcamera:getmodule("ModuleLight").
    cameraLight:doaction("turn light on", true).
    HUDTEXT("Say Cheese!! \n", 3, 1, 32, blue, false).
    Wait 3.
    SET cameraControl TO IRcamera:getmodule("ModuleScienceExperiment").
    cameraControl:doaction("perform observation", true).
    cameraLight:doaction("turn light off", true).
}

//powerCycle("wake").
//set message to list(50,90,40).
//rotate(message).

function TextBoxTest {
    LOCAL string IS "".
    SET my_gui TO GUI(600,400).
    SET myTextField TO my_gui:addtextfield("").
    SET myTextField:tooltip TO "HelpText".
    my_gui:addlabel("This is <color=orange><size=30>important</size></color>").
    SET button TO my_gui:ADDBUTTON("SUBMIT").
    set myTextField:ONCHANGE to {
        parameter str. 
        print myTextField.
        SET string TO str.
    }.
    my_gui:SHOW().
    UNTIL button:TAKEPRESS WAIT(0.1).
    my_gui:HIDE().
    IF string = "ttt" {
        print "!!!".
    }
}

function messageSatellite {
    SET MESSAGE TO "HELLO WORLD". 
    SET C TO VESSEL("Mars Relay Satellite"):CONNECTION.
    PRINT "Delay is " + C:DELAY + " seconds".
    IF C:SENDMESSAGE(MESSAGE) {
    PRINT "Message sent!".
    }
}


//SET KUniverse:ACTIVEVESSEL TO VESSEL("Mars Relay Satellite").

