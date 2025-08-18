wait until ship:unpacked. //Wait 2.
clearscreen.
print "Welcome Pathfinder".
SET RemoteVessel TO VESSEL("Pathfinder Probe").

function powerCycle {
    parameter action.
    SET IRpivot TO SHIP:partsnamedpattern("IR.Pivotron")[0].
    SET pivotServo TO IRpivot:getmodule("ModuleIRServo_v3").
    SET IRextend TO SHIP:partsnamedpattern("IR.Extendatron")[0].
    SET extendServo TO IRextend:getmodule("ModuleIRServo_v3").
    IF action = "wake" {
        HUDTEXT("Pathfinder booting up.... \n", 3, 1, 32, blue, false). Wait 3.
        getvoice(0):PLAY( LIST(NOTE(440, 0.35),NOTE(440, 0.25),NOTE(240, 0.5))).
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

function sendMessage {
    parameter MESSAGE. 
    SET C TO VESSEL("Pathfinder Probe"):CONNECTION.
    print "Delay is " + ROUND(C:DELAY) + " seconds".
    print "Sending message.... ".
    IF C:SENDMESSAGE(MESSAGE) {
        Wait 1.
        print "Message sent!".
    }
}

function receive {
    Wait 3.
    print "Ready to Receive...".
    Wait Until NOT SHIP:messages:empty.
    SET RECEIVED TO SHIP:MESSAGES:POP.
    print "Sent by " + RECEIVED:SENDER + " at " + RECEIVED:SENTAT + " >>> ".
    print RECEIVED:CONTENT.
    return RECEIVED:CONTENT.
}

LOCAL TextInput IS "".
function radioChat {
    SET chatGUI TO GUI(800,550).
    SET title TO chatGUI:addlabel("<b><color=red><size=30>
        Pathfinder Communications Subsystem
        </size></color></b>"). title.
    SET title:style:align TO "CENTER".
    SET hbox1 TO chatGUI:addhbox().
    SET labelLogo TO hbox1:addlabel(). SET labelLogo:image to "pathfinder". labelLogo.
    SET labelSignal TO hbox1:addlabel("Signal Delay: " + ROUND(ADDONS:RT:DELAY(RemoteVessel)) + " sec"). labelSignal.

    SET inputField TO chatGUI:addtextfield("").
    SET tooltip TO "Enter Text to Send".
    SET inputField:tooltip TO "   " + tooltip.
    SET sendButton TO chatGUI:ADDBUTTON("SEND").
    SET receivedBox TO chatGUI:addscrollbox().
    chatGUI:SHOW(). 
    SET chatGUI:Y To 200.
    SET T TO 0.
    UNTIL sendButton:TAKEPRESS {
        WAIT(1.1).
        SET T TO T + 1.
        receivedBox:addlabel(T:tostring()).
        SET receivedBox:position TO V(0,999999,0).
    }
    Wait 0.
    chatGUI:HIDE().
    SET TextInput TO inputField:text. TextInput.
    return TextInput.
}

/////////////////////
//SET CORE:volume:name TO "".  /// TEST

print "Status = " + CORE:volume:name.
IF CORE:volume:name = "" { SET CORE:volume:name TO "Startup". }

IF CORE:volume:name = "Startup" {
    powerCycle("wake").
    SET CORE:volume:name TO "Bootup".
}

IF NOT SHIP:messages:empty {
    receive().
}

IF shipName = "Pathfinder Demo" {
    CORE:DOEVENT("Open Terminal").
    Wait Until SHIP:connection:isconnected.
    IF ADDONS:available("RT") {
        print "Control delay: " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
        Wait Until RemoteVessel:CONNECTION:ISCONNECTED.
        print "Transmission delay with " + RemoteVessel:name + ": " + ROUND(ADDONS:RT:DELAY(RemoteVessel)) + " sec".
    }
    IF CORE:volume:name = "Bootup" {
        radioChat().
        //SET CORE:volume:name TO "Sent1".
    }
    IF CORE:volume:name = "Sent1" {
        SET CORE:volume:name TO "Sent2".
    }
}



