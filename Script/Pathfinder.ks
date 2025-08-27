print "Welcome Pathfinder".
print "Initializing RemoteTech communications module...".

CLEARVECDRAWS().
Wait Until SHIP:connection:isconnected.
IF shipName = "Pathfinder Demo"
{
    CORE:DOEVENT("Open Terminal"). // TESTING
    SET RemoteVessel TO VESSEL("Pathfinder Probe").
} ELSE IF shipName = "Pathfinder Probe" {
    SET RemoteVessel TO VESSEL("Pathfinder Demo").
}
IF ADDONS:available("RT") {
    print "Control delay:         " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
}

SET C TO RemoteVessel:CONNECTION.
SET COMMDELAY TO convertSeconds(ROUND(C:delay())).
print "Transmission delay:    " + COMMDELAY.

IF EXISTS("CommLog") {
    SET COMMLOG TO OPEN("CommLog").
} ELSE {
    SET COMMLOG TO CREATE("CommLog").
}

///////////////////////

function powerCycle {
    parameter action.
    SET IRpivot TO SHIP:partsdubbed("CamPitch")[0].
    SET pivotServo TO IRpivot:getmodule("ModuleIRServo_v3").
    SET IRextend TO SHIP:partsdubbed("CamExtend")[0].
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

function drawPointer {
    CLEARVECDRAWS().
    SET CamPart TO SHIP:partsnamed("IR.Camera")[0].
    SET RotatePart TO SHIP:partsdubbed("CamRotate")[0].
    SET PitchPart TO SHIP:partsdubbed("CamPitch")[0].
    SET getRotation TO RotatePart:getmodule("ModuleIRServo_v3"):getfield("current position").
    SET getPitch TO PitchPart:getmodule("ModuleIRServo_v3"):getfield("current position").
    SET direction to HEADING(getRotation-46,-getPitch).
    VECDRAW(CamPart:position, direction:vector, green, "Camera",2.0,TRUE,0.01,TRUE,TRUE).
    return True.
}

function rotateCam {
    parameter msg.
    CLEARVECDRAWS().
    SET module TO SHIP:partsdubbed("CamRotate")[0]:getmodule("ModuleIRServo_v3").
    module:setfield("target position", 0).
    FOR s IN msg {
        SET tp TO unchar(s).
        print s + "=" + tp.  // TESTING
        module:setfield("target position", tp).
        LOCK cp TO module:getfield("current position").
        wait until drawPointer() AND cp < tp + 0.1 AND cp > tp - 0.1. wait 2.
    }
    CLEARVECDRAWS().
    module:setfield("target position", 0).
}

function takePhoto {
    SET IRcamera TO SHIP:partsnamedpattern("IR.Camera")[0].
    SET cameraLight TO IRcamera:getmodule("ModuleLight").
    cameraLight:doaction("turn light on", true).
    HUDTEXT("Say Cheese!! \n", 3, 1, 32, blue, false).
    Wait 3.
    SET cameraControl TO IRcamera:getmodule("ModuleScienceExperiment").
    cameraControl:doaction("perform observation", true).
    cameraLight:doaction("turn light off", true).
}

function convertSeconds {
    parameter seconds.
    return FLOOR(seconds / 60) + " min  " + Round(Mod(seconds,60), 0) + " sec".
}

function getSol {
    SET sol TO TIME:year * 365 + TIME:day.
    return sol - 31356.
}

function sendMessage {
    parameter MESSAGE.
    IF (MESSAGE:tostring():length = 0) { return False. }
    SET C TO RemoteVessel:CONNECTION.
    print "Delay is " + COMMDELAY.
    print "Sending message.... ".
    print "   > " + MESSAGE.
    IF C:SENDMESSAGE(MESSAGE) {
        Wait 1.
        print "Message sent!".
    }
}

function rcvMessage {
    IF kuniverse:timewarp:warp <> 0 {
        set kuniverse:timewarp:warp TO 0.
        Wait Until kuniverse:timewarp:issettled.
    }
    HUDTEXT("Receiving Message.... \n", 10, 1, 32, yellow, false). 
    SET RECEIVED TO SHIP:MESSAGES:POP.
    //print "Sent by " + RECEIVED:SENDER + " at " + RECEIVED:SENTAT + " >>> ".
    //print RECEIVED:CONTENT.
    return RECEIVED.
}

LOCAL TextInput IS "".

function rawComm {
    SET signGUI TO GUI(800,440).
    SET inputField TO signGUI:addtextfield("").
    SET tooltip TO "Write text on sign".
    SET inputField:tooltip TO "   " + tooltip.
    SET labelLogo TO signGUI:addlabel(). SET labelLogo:image to "pathfinder". labelLogo.
    SET writeButton TO signGUI:ADDBUTTON("Write").

    SET P TO SHIP:PARTSNAMED("IR.Camera")[0].
    SET M TO P:GETMODULE("ModuleScienceExperiment").
    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        IF NOT SHIP:messages:empty
        {
            SET RECEIVED TO rcvMessage(). Wait 10.
            rotateCam(RECEIVED:CONTENT).            
        }
        IF M:HASDATA {
            signGUI:show().
            Wait Until writeButton:PRESSED.
            signGUI:hide().
            HUDTEXT("Send Image File \n", 3, 1, 32, white, false).
            Wait Until NOT M:HASDATA.
            SET text TO inputField:text.
            print "Imaging sign > " + text.
            sendMessage(TIME:seconds + ".jpg(" + text + ")").
        }
    }
}

function PCSTerminal {
    SET chatGUI TO GUI(800,440).
    SET title TO chatGUI:addlabel("<b><color=black><size=30>
        Pathfinder Communications Subsystem        
        </size></color></b>"). title.
    SET title:style:align TO "CENTER".
    SET hbox1 TO chatGUI:addhbox().
    SET outputBox TO hbox1:addscrollbox().
    SET labelLogo TO hbox1:addlabel(). SET labelLogo:image to "pathfinder". labelLogo.
    SET inputField TO chatGUI:addtextfield("").
    SET tooltip TO "Enter Text to Send".
    SET inputField:tooltip TO "   " + tooltip.
    SET sendButton TO chatGUI:ADDBUTTON("SEND").
    chatGUI:SHOW(). 
    SET chatGUI:Y To 200.
    
    outputBox:addlabel("Communication subsystem status: ONLINE").
    outputBox:addlabel("===========================================================    ").
    Wait 2. outputBox:addlabel("Remote system target: " + RemoteVessel).
    Wait 2. outputBox:addlabel("Transmission Delay: " + COMMDELAY).
    Wait 2. outputBox:addlabel(COMMLOG:READALL:string).
    outputBox:addlabel("").

    print "MessageQueued = " + NOT SHIP:messages:empty.

    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        IF NOT SHIP:messages:empty
        {
            SET RECEIVED TO rcvMessage(). Wait 10.
            LOCAL output TO "Incoming Message from " + RECEIVED:SENDER + " transmitted at " + RECEIVED:SENTAT:tostring().
            COMMLOG:writeln(output).
            outputBox:addlabel(output).
            SET output TO "Message rcvd on Sol " + getSol() + " @ " + TIME:clock + " << <color=orange>" + RECEIVED:CONTENT + "</color>".
            COMMLOG:writeln(output).
            outputBox:addlabel(output).
            SET outputBox:position TO V(0,999999,0).
            IF NOT RECEIVED:CONTENT:tostring():contains(".jpg") {
                rotateCam(RECEIVED:CONTENT). 
            }         
        }
        IF sendButton:PRESSED
        {
            sendButton:TAKEPRESS.
            SET text TO inputField:text.
            SET inputField:text TO "".
            LOCAL output TO "Message sent on Sol " + getSol() + " @ " + TIME:clock + " >> <color=white>" + text + "</color>".
            outputBox:addlabel(output).
            COMMLOG:writeln(output).
            SET outputBox:position TO V(0,999999,0).
            sendMessage(text).
            rotateCam(text).
        }
        wait 1. 
    }
    chatGUI:HIDE().
    TextInput.
}

function hasFullCommLink {
    IF shipName = "Pathfinder Demo"
    {
        return True.
    }
    return False.
}

/////////////////////
//SET CORE:volume:name TO "".  /// TESTING RESET

IF CORE:volume:name = "" { SET CORE:volume:name TO "Init0". }

IF CORE:volume:name = "Init0" {
    COMMLOG:clear.
    powerCycle("wake").
    SET CORE:volume:name TO "Init1". 
}

IF CORE:volume:name = "Init1" {
    Wait 5.
    IF RemoteVessel:CONNECTION:ISCONNECTED {
        Wait 2. print "Connection established with " + RemoteVessel:name.
        SET CORE:volume:name TO "Init2".
    }
}

IF CORE:volume:name = "Init2" {
    IF hasFullCommLink {
        PCSTerminal().
    } ELSE {
        print "Receiving blind".
        rawComm().
    }
}

IF CORE:volume:name = "PCS_Start" {
    PCSTerminal().
    //SET CORE:volume:name TO "Next1".
}

