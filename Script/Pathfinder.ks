print "Welcome Pathfinder".
print "Initializing RemoteTech communications module...".
Wait Until SHIP:connection:isconnected. Wait 2.

CORE:DOEVENT("Open Terminal"). // TESTING
CLEARVECDRAWS().

IF shipName = "Pathfinder Demo"
{
    SET RemoteVessel TO VESSEL("Mars Rover").
} ELSE IF shipName = "Mars Rover" {
    SET RemoteVessel TO VESSEL("Pathfinder Demo").
}
IF ADDONS:available("RT") {
    print "Control delay:         " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
}

print "Waiting for connection to remote...". Wait 2.
Wait Until RemoteVessel:connection:isconnected.
print "SIGNAL ACQUIRED!". print " ".

SET C TO RemoteVessel:CONNECTION.
SET COMMDELAY TO convertSeconds(ROUND(C:delay())).
print RemoteVessel.
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
    getvoice(0):PLAY( LIST(NOTE(440, 0.35),NOTE(440, 0.25),NOTE(240, 0.5))).
    HUDTEXT("Receiving Message.... \n", 10, 1, 32, yellow, false). 
    SET RECEIVED TO SHIP:MESSAGES:POP.
    return RECEIVED.
}

function drawPointer {
    CLEARVECDRAWS().
    SET CamPart TO SHIP:partsnamed("IR.Camera")[0].
    SET CamFwdDir to R(CamPart:rotation:pitch - 180, CamPart:rotation:yaw, CamPart:rotation:roll).
    VECDRAW(CamPart:position, CamFwdDir:vector, green,"",2.0,TRUE,0.05,TRUE,TRUE).
    return True.
}

function ascii2servo {
    parameter msg, servo.
    set posList to list().
    IF servo = "None" { return msg. }
    IF servo = "Rotate" { SET div TO FLOOR(360 / 16). }
    IF servo = "Pitch" { SET div TO FLOOR(120 / 16). }
    IF servo = "Extend" { SET div TO 0.46 / 16. }
    FOR s IN msg {
        SET ch TO unchar(s).
        SET hex1 TO FLOOR(ch/16). SET pos1 TO hex1 * div.
        SET hex2 TO MOD(ch,16). SET pos2 TO hex2 * div.
        IF servo = "Pitch" { SET pos1 TO pos1 - 60. SET pos2 TO pos2 - 60. }
        print s+" > CharCode="+ch+" > Hex="+hex1+":"+hex2+" > position="+pos1+","+pos2.  // TESTING
        posList:add(pos1). posList:add(pos2).
    }
    posList:add(0.46).
    return posList.
}

function moveServos {
    parameter input.
    SET tuple TO input:split("::").
    SET servo TO tuple[0].
    SET positionList TO tuple[1]:split(",").
    CLEARVECDRAWS().
    SET moveServo TO SHIP:partsdubbed("Cam"+servo)[0]:getmodule("ModuleIRServo_v3").
    FOR val IN positionList {
        SET tp TO val:TONUMBER(0).
        moveServo:setfield("target position", tp).
        LOCK cp TO moveServo:getfield("current position").
        wait until drawPointer() AND cp < tp + 0.1 AND cp > tp - 0.1.
        Wait 2.
    }
    CLEARVECDRAWS().
}

function hasSignFlag {
    LIST Targets IN Vessels.
    SET CamPart TO SHIP:partsnamed("IR.Camera")[0].
    FOR vsl IN Vessels {
        SET vec TO (vsl:position - CamPart:position) / 2.
        IF vsl:type = "Flag" AND vec:mag < 10 {
            SET CamFwdDir to R(CamPart:rotation:pitch - 180, CamPart:rotation:yaw, CamPart:rotation:roll).
            SET angle TO ROUND(VECTORANGLE(vec, CamFwdDir:vector), 2).
            HUDTEXT("Flag: " + vsl:shipname + " " + ROUND(vec:mag, 2) + " meters, at " + angle + " degrees", 2, 1, 16, blue, false).
            drawPointer().
            VECDRAW(CamPart:position, vec, yellow, "To Flag",2.0,TRUE,0.02,TRUE,TRUE).
            Wait 2. CLEARVECDRAWS().
            IF angle < 10 {
                return vsl:shipname.
            }
        }
    }
    return "".
}

function takePhoto {
    parameter countdown.
    SET timer TO countdown:TONUMBER(0).
    SET IRcamera TO SHIP:partsnamedpattern("IR.Camera")[0].
    SET cameraControl TO IRcamera:getmodule("ModuleScienceExperiment").
    SET cameraLight TO IRcamera:getmodule("ModuleLight").

    drawPointer().
    SET pitchServo TO SHIP:partsdubbed("CamPitch")[0]:getmodule("ModuleIRServo_v3").
    pitchServo:setfield("target position", 15).
    cameraLight:doaction("turn light on", true).
    Until timer <= 0 {
        HUDTEXT("Image Caputure in " + timer + " seconds...", 1, 1, 32, blue, false). Wait 1.
        SET timer TO timer - 1.
    }
    HUDTEXT("Say Cheese!! \n", 3, 1, 32, blue, false). Wait 3.
    cameraControl:doaction("perform observation", true).
    Wait Until cameraControl:HASDATA.
    CLEARVECDRAWS().
    cameraLight:doaction("turn light off", true).
    cameraControl:TRANSMIT.
}

function rawComm {
    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        SET IRcamera TO SHIP:partsnamedpattern("IR.Camera")[0].
        SET cameraControl TO IRcamera:getmodule("ModuleScienceExperiment").
        IF NOT SHIP:messages:empty
        {
            SET RECEIVED TO rcvMessage(). Wait 10.
            IF RECEIVED:CONTENT:tostring():contains("CaptureImage") {
                takePhoto(RECEIVED:CONTENT:tostring():split("::")[1]).
            } ELSE {
                moveServos(RECEIVED:CONTENT).
            }        
        }
        IF cameraControl:HASDATA {
            SET flagText TO hasSignFlag().
            print "Imaging sign > " + flagText.
            sendMessage(TIME:seconds + ".jpg (" + flagText + ")").
        }
        Wait 1.
    }
}

SET fw_file TO "0:firmware_rover_v0.1.42.bin".
SET fw_oldline1 TO "00000D00  31 39 32 2E 31 36 38 2E 30 2E 31 30 35 22 3B 0A  |192.168.0.105".
SET fw_oldline2 TO "00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 35 30 30 35  |.ServPort = 5005".
SET fw_newline1 TO "00000D00  31 39 32 2E 31 36 38 2E 31 2E 32 35 35 22 3B 0A  |192.168.1.255".
SET fw_newline2 TO "00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 32 36 30 30  |.ServPort = 2600".
SET fw_instructions TO "D00:chgIP>1.255,D10:chgPort>2600".

function loadFirmware {
    IF EXISTS(fw_file) {
        SET bin TO OPEN(fw_file).
        SET firmware TO bin:READALL:string.
        IF firmware:contains(fw_oldline1) OR firmware:contains(fw_oldline2) {
            print "Bootloader file integrity check: PASSED (Original Firmware)".
            return False.
        }
        IF firmware:contains(fw_newline1) AND firmware:contains(fw_newline2) {
            print "Rover firmware successfully hacked!".
            return True.
        }
        return False.
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
    SET chatGUI:Y To 800.
    
    outputBox:addlabel("Communication subsystem status: ONLINE").
    outputBox:addlabel("===========================================================    ").
    outputBox:addlabel("Remote system target: " + RemoteVessel).
    outputBox:addlabel("Transmission Delay: " + COMMDELAY).
    outputBox:addlabel(COMMLOG:READALL:string).
    outputBox:addlabel("").
    SET outputBox:position TO V(0,999999,0).

    SET inputField TO chatGUI:addtextfield("").
    SET hbox2 TO chatGUI:addhbox().
    SET getImageButton TO hbox2:ADDBUTTON("Capture Image").
    SET convertButton TO hbox2:ADDBUTTON("Convert >>").
    SET selector TO hbox2:addpopupmenu(). selector.
    SET selector:options TO LIST("None", "Rotate", "Pitch", "Extend").
    SET testButton TO hbox2:ADDBUTTON("Localhost Test").
    SET sendButton TO hbox2:ADDBUTTON("<color=orange><b>SEND</b></color>").
    SET closeButton TO hbox2:ADDBUTTON(" X"). SET closeButton:style:width TO 20.
    SET sendfwUpdButton TO chatGUI:ADDBUTTON("<color=red><b>SEND firmware update instructions</b></color>").
    
    SET COM_Terminal TO SHIP:partsnamedpattern("RTShortAntenna1")[0].
    SET highlightCOM TO HIGHLIGHT(COM_Terminal, YELLOW). highlightCOM. 
    SET moduleCOM TO COM_Terminal:getmodule("ModuleRTAntenna").
    chatGUI:HIDE(). SET highlightCOM:ENABLED TO True.

    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        IF moduleCOM:getfield("status") <> "Off" {
            chatGUI:SHOW().
            moduleCOM:doevent("Deactivate").
            SET highlightCOM:ENABLED TO False.
        }
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
        }
        IF getImageButton:PRESSED {
            getImageButton:TAKEPRESS.
            SET inputField:text TO "CaptureImage::10".
        }
        IF convertButton:PRESSED {
            convertButton:TAKEPRESS.
            IF NOT inputField:text:contains("::") AND selector:value:tostring() <> "None" {
                outputBox:addlabel("Converted '" + inputField:text + "' to " + selector:value + " format").
                SET inputField:text TO selector:value + "::" + ascii2servo(inputField:text, selector:value):join(",").
            }  
        }
        IF testButton:PRESSED {
            testButton:TAKEPRESS.
            IF inputField:text:contains("CaptureImage") {
                takePhoto(inputField:text:split("::")[1]).
            } ELSE {
                moveServos(inputField:text).
            }
        }
        IF sendfwUpdButton:PRESSED {
            sendfwUpdButton:TAKEPRESS.
            LOCAL text TO "Rotate::{file_attachment>README_FWUPD.md}".
            LOCAL output TO "Message sent on Sol " + getSol() + " @ " + TIME:clock + " >> <color=white>" + text + "</color>".
            outputBox:addlabel(output).
            COMMLOG:writeln(output).
            sendMessage(ascii2servo(fw_instructions, "Rotate")).
        }
        IF sendButton:PRESSED {
            sendButton:TAKEPRESS.
            LOCAL text TO inputField:text.
            LOCAL output TO "Message sent on Sol " + getSol() + " @ " + TIME:clock + " >> <color=white>" + text + "</color>".
            outputBox:addlabel(output).
            COMMLOG:writeln(output).
            SET inputField:text TO "".
            SET outputBox:position TO V(0,999999,0).
            sendMessage(text).
        }
        IF closeButton:PRESSED {
            chatGUI:HIDE().
            closeButton:TAKEPRESS.
            SET highlightCOM:ENABLED TO True.
        }
        wait 1. 
    }
    chatGUI:HIDE().
}

function hasFullCommLink {
    IF shipName = "Pathfinder Demo"
    {
        return True.
    }
    return loadFirmware().
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

