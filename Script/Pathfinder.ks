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

function ascii2angles {
    parameter msg.
    set rotList to list().
    FOR s IN msg {
        SET ch TO unchar(s).
        SET hex1 TO FLOOR(ch/16). SET rot1 TO hex1 * 22.
        SET hex2 TO MOD(ch,16). SET rot2 TO hex2 * 22.
        print s+" > CharCode="+ch+" > Hex="+hex1+":"+hex2+" > Rotation="+rot1+","+rot2.  // TESTING
        rotList:add(rot1). rotList:add(rot2).
    }
    return rotList.
}

function sendMessage {
    parameter MESSAGE, convert.
    IF (MESSAGE:tostring():length = 0) { return False. }
    SET C TO RemoteVessel:CONNECTION.
    print "Delay is " + COMMDELAY.
    print "Sending message.... ".
    print "   > " + MESSAGE.
    IF convert {
        print "Converting to rotational angles...".
        SET MESSAGE TO ascii2angles(MESSAGE).
    }
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

LOCAL TextInput IS "".
function updateFirmware {
    SET signGUI TO GUI(800,440).
    SET inputField TO signGUI:addtextfield("").
    SET tooltip TO "Edit source code and recompile".
    SET inputField:tooltip TO "   " + tooltip.
    SET labelLogo TO signGUI:addlabel(). SET labelLogo:image to "pathfinder". labelLogo.
    SET writeButton TO signGUI:ADDBUTTON("Recompile").
    signGUI:show().
    Wait Until writeButton:PRESSED.
    signGUI:hide().
    SET text TO inputField:text.
}

function drawPointer {
    CLEARVECDRAWS().
    SET CamPart TO SHIP:partsnamed("IR.Camera")[0].
    SET CamFwdDir to R(CamPart:rotation:pitch - 180, CamPart:rotation:yaw, CamPart:rotation:roll).
    VECDRAW(CamPart:position, CamFwdDir:vector, green, "Camera",2.0,TRUE,0.05,TRUE,TRUE).
    return True.
}

function rotateCam {
    parameter rot.
    CLEARVECDRAWS().
    SET rotateServo TO SHIP:partsdubbed("CamRotate")[0]:getmodule("ModuleIRServo_v3").
    rotateServo:setfield("target position", 0).
    FOR a IN rot {
        rotateServo:setfield("target position", a).
        LOCK cp TO rotateServo:getfield("current position").
        wait until drawPointer() AND cp < a + 0.1 AND cp > a - 0.1.
        Wait 2.
    }
    CLEARVECDRAWS().
    rotateServo:setfield("target position", 0).
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
            VECDRAW(CamPart:position, vec, red, "To Flag",2.0,TRUE,0.02,TRUE,TRUE).
            Wait 2. CLEARVECDRAWS().
            IF angle < 10 {
                SET vsl:type TO "Debris".
                return vsl:shipname.
            }
        }
    }
    return "".
}

function takePhoto {
    SET IRcamera TO SHIP:partsnamedpattern("IR.Camera")[0].
    SET cameraLight TO IRcamera:getmodule("ModuleLight").
    cameraLight:doaction("turn light on", true).
    HUDTEXT("Say Cheese!! \n", 3, 1, 32, blue, false). Wait 3.
    SET cameraControl TO IRcamera:getmodule("ModuleScienceExperiment").
    cameraControl:doaction("perform observation", true).
    Wait Until cameraControl:HASDATA.
    cameraLight:doaction("turn light off", true).
    cameraControl:TRANSMIT. Wait 2.
    Wait Until NOT cameraControl:HASDATA.
}

function rawComm {
    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        IF NOT SHIP:messages:empty
        {
            SET RECEIVED TO rcvMessage(). Wait 10.
            rotateCam(RECEIVED:CONTENT).            
        }
        SET newFlag TO hasSignFlag().
        IF newFlag:tostring():length > 0 {
            takePhoto().
            print "Imaging sign > " + newFlag.
            sendMessage(TIME:seconds + ".jpg (" + newFlag + ")", False).
        }
        Wait 1.
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
    SET hbox2 TO chatGUI:addhbox().
    SET sendButton TO hbox2:ADDBUTTON("SEND as ASCII").
    SET rotButton TO hbox2:ADDBUTTON("SEND as θ(hex)").
    chatGUI:SHOW(). 
    SET chatGUI:Y To 800.
    
    outputBox:addlabel("Communication subsystem status: ONLINE").
    outputBox:addlabel("===========================================================    ").
    Wait 2. outputBox:addlabel("Remote system target: " + RemoteVessel).
    Wait 2. outputBox:addlabel("Transmission Delay: " + COMMDELAY).
    Wait 2. outputBox:addlabel(COMMLOG:READALL:string).
    outputBox:addlabel("").
    SET outputBox:position TO V(0,999999,0).

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
            //IF NOT RECEIVED:CONTENT:tostring():contains(".jpg") {
            //    rotateCam(ascii2angles(RECEIVED:CONTENT)).
            //}         
        }
        IF sendButton:PRESSED OR rotButton:PRESSED {
            SET text TO inputField:text.
            SET inputField:text TO "".
            LOCAL output TO "Message sent on Sol " + getSol() + " @ " + TIME:clock + " >> <color=white>" + text + "</color>".
            outputBox:addlabel(output).
            COMMLOG:writeln(output).
            SET outputBox:position TO V(0,999999,0).
            IF sendButton:PRESSED {
                sendButton:TAKEPRESS.
                sendMessage(text, False).
            } ELSE IF rotButton:PRESSED {
                rotButton:TAKEPRESS.
                sendMessage(text, True).
                rotateCam(ascii2angles(text)).  // Debugging
            }
        }
        wait 1. 
    }
    chatGUI:HIDE().
    TextInput.
}

function loadFirmware {
    IF EXISTS("0:firmware_rover_v0.1.42.bin") {
        SET bin TO OPEN("0:firmware_rover_v0.1.42.bin").
        SET firmware TO bin:READALL:string.
        IF firmware:contains("00000D00  31 39 32 2E 31 36 38 2E 31 2E 32 35 35 22 3B 0A  |192.168.1.255") 
        AND firmware:contains("00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 32 36 30 30  |.ServPort = 2600") {
            print "Rover firmware successfully hacked!".
            return True.
        }
        IF firmware:contains("00000D00  31 39 32 2E 31 36 38 2E 30 2E 31 30 35 22 3B 0A  |192.168.0.105") 
        AND firmware:contains("00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 35 30 30 35  |.ServPort = 5005") {
            print "Original Firmware".
        }
        return False.
    }
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

