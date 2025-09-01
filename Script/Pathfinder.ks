print "Welcome Pathfinder".
print "Initializing RemoteTech communications module...".
Wait Until SHIP:connection:isconnected. Wait 2.

CORE:DOEVENT("Open Terminal"). // TESTING
CLEARVECDRAWS().

IF ADDONS:available("RT") {
    print "Control delay:         " + ROUND(ADDONS:RT:KSCDELAY(SHIP)) + " sec".
        IF SHIP:parts:tostring:contains("MediumDishAntenna") {
        SET dish TO SHIP:partsnamed("MediumDishAntenna")[0].
        SET module TO dish:getmodule("ModuleRTAntenna").
        IF module:getfield("status") = "Connected" {
            SET SHIP:type TO "Probe".
        }
    }
} ELSE { 
    HUDTEXT("RemoteTech not installed.... \n", 3, 1, 32, blue, false). Wait Until False.
}

function getRemoteVessel {
    LIST Targets IN Vessels.
    FOR vsl IN Vessels {
        IF vsl:type = "Probe" {
            print "Remote Target: " + vsl + " - Type: " + vsl:type.
            return VESSEL(vsl:name).
        }
    }
    print "No Remote Probe Found!".
    HUDTEXT("No Remote Probe Connection! \n", 10, 1, 16, red, false).
    Wait 20. Reboot.
}

SET RemoteVessel TO getRemoteVessel().
print "Waiting for connection to remote...". Wait 2.
Wait Until RemoteVessel:connection:isconnected.
print "SIGNAL ACQUIRED!". print " ".

SET C TO RemoteVessel:CONNECTION.
SET COMMDELAY TO convertSeconds(ROUND(C:delay())).
print "Transmission delay:    " + COMMDELAY.

IF EXISTS("CommLog") {
    SET COMMLOG TO OPEN("CommLog").
} ELSE {
    SET COMMLOG TO CREATE("CommLog").
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function completeContractParameter {
    parameter partName.
    FOR part IN SHIP:partsnamed(partName) {
        print partName.
        LOCAL m TO part:getmodule("ModuleTestSubject").
        if m:alleventnames:contains("run test") {
            m:doevent("run test").
        }
    }
}

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
    print "Sending " + MESSAGE:tostring():length + " bytes...".
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
    SET RECEIVED TO SHIP:MESSAGES:POP.
    HUDTEXT("Receiving Message.... \n" + RECEIVED:CONTENT:Length + " bytes", 10, 1, 32, yellow, false). 
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
    SET posList TO list().
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
    IF BODY:name = "Mars" AND servo = "Pitch" AND positionList:length >= 2 {
        /// CONTRACT PARAMETER COMPLETE, Mark arms up YESS photo
        completeContractParameter("beacon12").
    }
    CLEARVECDRAWS().
}

function signFlag {
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

function highlightConsole {
    IF SHIP:parts:tostring:contains("RTShortAntenna1") {
        SET COM_Terminal TO SHIP:partsnamedpattern("RTShortAntenna1")[0].
        SET highlightCOM TO HIGHLIGHT(COM_Terminal, YELLOW). highlightCOM. 
        SET moduleCOM TO COM_Terminal:getmodule("ModuleRTAntenna").
        SET highlightCOM:ENABLED TO True.
    }
}

SET fw_file TO "1:firmware_rover_v0.1.42.bin".
SET fw_oldline1 TO "00000D00  31 39 32 2E 31 36 38 2E 30 2E 31 30 35 22 3B 0A  |192.168.0.105".
SET fw_oldline2 TO "00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 35 30 30 35  |.ServPort = 5005".
SET fw_newline1 TO "00000D00  31 39 32 2E 31 36 38 2E 31 2E 32 35 35 22 3B 0A  |192.168.1.255".
SET fw_newline2 TO "00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 32 36 30 30  |.ServPort = 2600".
SET fw_instructions TO "D00:IP>1.255,D10:Port>2600".

function loadFirmware {
    IF CORE:volume:name <> "PCS_3M_9766" AND ADDONS:RT:HASKSCCONNECTION(SHIP) {
        print "Loading remote firmware from JPL servers...".
        COPYPATH("0:firmware_rover_v0.1.42.bin", "1:firmware_rover_v0.1.42.bin").
    }
    IF EXISTS(fw_file) {
        SET bin TO OPEN(fw_file).
        SET firmware TO bin:READALL:string.
        IF firmware:contains(fw_oldline1) OR firmware:contains(fw_oldline2) {
            print "Bootloader file integrity check: PASSED (Original Firmware)".
            return False.
        }
        IF firmware:contains(fw_newline1) AND firmware:contains(fw_newline2) {
            print "Rover firmware successfully hacked!".
            /// CONTRACT PARAMETER COMPLETE, hex hacking rover firmware
            completeContractParameter("beacon14").
            SET CORE:volume:name TO "PCS_3M_9766".
            return True.
        }
        return False.
    }
}

function rawComm {
    parameter doHighlight.
    loadFirmware().
    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        SET IRcamera TO SHIP:partsnamedpattern("IR.Camera")[0].
        SET cameraControl TO IRcamera:getmodule("ModuleScienceExperiment").
        IF NOT SHIP:messages:empty
        {
            SET RECEIVED TO rcvMessage(). Wait 10.
            IF RECEIVED:CONTENT:tostring():contains("CaptureImage::") {
                print "Received CaptureImage command".
                takePhoto(RECEIVED:CONTENT:tostring():split("::")[1]).
            } ELSE IF RECEIVED:CONTENT:tostring():contains("::") {
                print "Received MoveServos command".
                moveServos(RECEIVED:CONTENT).
            } 
            IF RECEIVED:CONTENT:tostring():contains("file_attachment") {
                print "Received compressed file".
                completeContractParameter("beacon13").
                SET CORE:volume:name TO "PCS_2M_4575".
                SET doHighlight TO True.
            }
        }
        IF doHighlight { 
            highlightConsole().
            IF moduleCOM:getfield("status") <> "Off" {
                EDIT fw_file.
                moduleCOM:doevent("Deactivate").
                SET highlightCOM:ENABLED TO False.
            }
        }
        IF cameraControl:HASDATA {
            SET flagText TO signFlag().
            print "Imaging sign > " + flagText.
            sendMessage(TIME:seconds + ".jpg (" + flagText + ")").
        }
        Wait 1.
    }
}

function PCSTerminal {
    parameter show.
    SET chatGUI TO GUI(800,440).
    chatGUI:HIDE().
    highlightConsole().

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
    IF show >= 1 {
        SET convertButton TO hbox2:ADDBUTTON("Convert >>").
        SET selector TO hbox2:addpopupmenu(). selector.
        SET selector:options TO LIST("None", "Rotate", "Pitch", "Extend").
        SET testButton TO hbox2:ADDBUTTON("Localhost Test").
    }
    SET sendButton TO hbox2:ADDBUTTON("<color=orange><b>SEND</b></color>").
    SET closeButton TO hbox2:ADDBUTTON(" X"). SET closeButton:style:width TO 20.
    IF show >= 2 {
        SET sendfwUpdButton TO chatGUI:ADDBUTTON("<color=red><b>SEND firmware update instructions</b></color>").
    }
    
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
            IF RECEIVED:CONTENT:tostring():contains(".jpg") AND BODY:name = "Earth" {
                /// CONTRACT PARAMETER COMPLETE, Are you receiving me?
                completeContractParameter("beacon11").
                IF show = 0 { SET CORE:volume:name TO "PCS_2E_1665". }
                IF show = 1 { SET CORE:volume:name TO "PCS_3E_4571". SET show TO 2. }
            }
        }
        IF getImageButton:PRESSED {
            getImageButton:TAKEPRESS.
            SET inputField:text TO "CaptureImage::10".
        }
        IF show >= 1 AND convertButton:PRESSED {
            convertButton:TAKEPRESS.
            IF NOT inputField:text:contains("::") AND selector:value:tostring() <> "None" {
                outputBox:addlabel("Converted '" + inputField:text + "' to " + selector:value + " format").
                SET inputField:text TO selector:value + "::" + ascii2servo(inputField:text, selector:value):join(",").
            }  
        }
        IF show >= 1 AND testButton:PRESSED {
            testButton:TAKEPRESS.
            IF inputField:text:contains("CaptureImage") {
                takePhoto(inputField:text:split("::")[1]).
            } ELSE {
                moveServos(inputField:text).
            }
        }
        IF  show >= 2 AND sendfwUpdButton:PRESSED {
            sendfwUpdButton:TAKEPRESS.
            LOCAL text TO "{file_attachment>FirmwareUpdate/README.md}".
            LOCAL output TO "Message sent on Sol " + getSol() + " @ " + TIME:clock + " >> <color=white>" + text + "</color>".
            outputBox:addlabel(output).
            SET outputBox:position TO V(0,999999,0).
            COMMLOG:writeln(output).
            sendMessage(text). Wait 5.
            sendMessage("Rotate::" + ascii2servo(fw_instructions, "Rotate"):join(",")).
        }
        IF sendButton:PRESSED {
            sendButton:TAKEPRESS.
            LOCAL text TO inputField:text.
            IF text:length > 0 {
                LOCAL output TO "Message sent on Sol " + getSol() + " @ " + TIME:clock + " >> <color=white>" + text + "</color>".
                outputBox:addlabel(output).
                COMMLOG:writeln(output).
                SET inputField:text TO "".
                SET outputBox:position TO V(0,999999,0).
                sendMessage(text).
            }
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SET CORE:volume:name TO "".  /// TESTING RESET
IF CORE:volume:name = "" { SET CORE:volume:name TO "Init0". }
print CORE:volume:name.
IF CORE:volume:name = "Init0" AND RemoteVessel:CONNECTION:ISCONNECTED {
    COMMLOG:clear.
    powerCycle("wake").
    Wait 3. print "Connection established with " + RemoteVessel:name.
    IF BODY:name = "Earth" { SET CORE:volume:name TO "PCS_1E_8429". }
    IF BODY:name = "Mars"  { SET CORE:volume:name TO "PCS_1M_2347". }
}

IF CORE:volume:name = "PCS_1E_8429" { PCSTerminal(0). }
IF CORE:volume:name = "PCS_2E_1665" { PCSTerminal(1). }
IF CORE:volume:name = "PCS_3E_4571" { PCSTerminal(2). }

IF CORE:volume:name = "PCS_1M_2347" { rawComm(False). }
IF CORE:volume:name = "PCS_2M_4575" { rawComm(True). }
IF CORE:volume:name = "PCS_3M_9766" { PCSTerminal(0). }

