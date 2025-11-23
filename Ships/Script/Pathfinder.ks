print "Welcome Pathfinder".
print "Initializing RemoteTech communications module...".
Wait Until SHIP:connection:isconnected. Wait 2.

//CORE:DOEVENT("Open Terminal"). // TESTING
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
        IF vsl:type <> "SpaceObject"
        AND vsl:body <> SHIP:body
        AND vsl:status = "LANDED"
        AND vsl:connection:isconnected
        AND ADDONS:RT:HASCONNECTION(vsl) {
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

SET COMMDELAY_sec TO ROUND(MAX(RemoteVessel:CONNECTION:delay(),SHIP:CONNECTION:delay())).
IF COMMDELAY_sec <= 1 {
    SET COMMDELAY_sec TO ROUND(MAX(ADDONS:RT:DELAY(RemoteVessel),ADDONS:RT:DELAY(SHIP))).
}
SET COMMDELAY TO convertSeconds(COMMDELAY_sec).
print "Transmission delay:    " + COMMDELAY.

IF EXISTS("CommLog") {
    SET COMMLOG TO OPEN("CommLog").
} ELSE {
    SET COMMLOG TO CREATE("CommLog").
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    SET RECEIVED TO SHIP:MESSAGES:PEEK.
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
        //print s + " > CharCode="+ch+" > Hex="+hex1+":"+hex2+" > position="+pos1+","+pos2.  // TESTING
        posList:add(pos1). posList:add(pos2).
    }
    posList:add(0.46).
    return posList.
}

function warpInterrupt {
    IF kuniverse:timewarp:RATE > 1 {
        print "Warping to " + kuniverse:timewarp:RATE + "x Speed".
        Wait Until kuniverse:timewarp:RATE = 1.
        Wait Until kuniverse:timewarp:issettled.
        print "Timewarp Settled".
        return true.
    }
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
        Wait until warpInterrupt() OR (drawPointer() AND cp < tp + 0.1 AND cp > tp - 0.1).
        Wait 2.
    }
    IF BODY:name = "Mars" AND servo = "Pitch" AND positionList:length >= 2 {
        /// CONTRACT PARAMETER COMPLETE, Mark arms up YESS photo
        contractParameter("kOSparam_Pathfinder2","COMPLETE").
    }
    CLEARVECDRAWS().
}

function signFlag {
    LIST Targets IN Vessels.
    SET CamPart TO SHIP:partsnamed("IR.Camera")[0].
    FOR vsl IN Vessels {
        SET vec TO (vsl:position - CamPart:position) / 2.
        IF vsl:type = "Flag" AND vec:mag < 20 {
            SET CamFwdDir to R(CamPart:rotation:pitch - 180, CamPart:rotation:yaw, CamPart:rotation:roll).
            SET angle TO ROUND(VECTORANGLE(vec, CamFwdDir:vector), 2).
            HUDTEXT("Flag: " + vsl:shipname + " " + ROUND(vec:mag, 2) + " meters, at " + angle + " degrees", 2, 1, 16, blue, false).
            drawPointer().
            VECDRAW(CamPart:position, vec, yellow, "To Flag",2.0,TRUE,0.02,TRUE,TRUE).
            Wait 2. CLEARVECDRAWS().
            IF angle < 20 {
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

SET fw_file TO "1:firmware_rover_v0.1.42.bin".
SET fw_oldline1 TO "00000D00  31 39 32 2E 31 36 38 2E 30 2E 31 30 35 22 3B 0A  |192.168.0.105".
SET fw_newline1 TO "00000D00  31 39 32 2E 31 36 38 2E 31 2E 32 35 35 22 3B 0A  |192.168.1.255".
SET fw_oldline2 TO "00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 35 30 30 35  |.ServPort = 5005".
SET fw_newline2 TO "00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 32 36 30 30  |.ServPort = 2600".
SET fw_instructions TO "D00:IP>1.255,D10:Port>2600".

function loadFirmware {
    IF CORE:volume:name <> "PCS_2M_4575" AND CORE:volume:name <> "PCS_3M_9766"
    AND ADDONS:RT:HASKSCCONNECTION(SHIP) {
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
            contractParameter("kOSparam_Pathfinder4","COMPLETE").
            SET CORE:volume:name TO "PCS_3M_9766".
            return True.
        }
        return False.
    }
}

function messageCounter {
    SET commlog_grp TO COMMLOG:READALL:string:split("FirmwareUpdate").
    if commlog_grp:length > 1 {
        SET chats TO commlog_grp[commlog_grp:length - 1].
        return chats:split(" >> "):length + chats:split(" << "):length.
    }
    return 0.
}

function rawComm {
    parameter fwUpdate.
    loadFirmware().

    //// PATHFINDER IMAGING SUBSYSTEM LOOP ////
    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        FOR COM_Terminal IN SHIP:partsnamedpattern("probeCoreOcto2.v2") {
            SET moduleCOMM TO COM_Terminal:getmodule("ModuleResourceConverter").
            IF moduleCOMM:getfield("Communications Terminal") <> "Operational" {
                CLEARGUIS().
                Wait 1. moduleCOMM:doevent("Start Comm System").
                Reboot.
            }
        }
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
                HUDTEXT("Receiving compressed file...", 10, 1, 22, yellow, true). 
                SET CORE:volume:name TO "PCS_2M_4575".
                SET fwUpdate TO True.
                SHIP:MESSAGES:POP. Reboot.
            }
            SHIP:MESSAGES:POP.
        }
        IF fwUpdate { 
            FOR COM_Terminal IN SHIP:partsnamedpattern("Ares-Cockpit") {
                SET moduleCOMM TO COM_Terminal:getmodule("ModuleResourceConverter").
                IF moduleCOMM:getfield("Communications Terminal") <> "Inactive" {
                    Wait 2. moduleCOMM:doevent("Stop Comm System").
                    EDIT fw_file.
                }
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
    CLEARGUIS().
    SET chatGUI TO GUI(800,440).
    
    SET title TO chatGUI:addlabel("<b><color=black><size=30>
        Pathfinder Communications System        
        </size></color></b>"). title.
    SET title:style:align TO "CENTER".
    SET hbox1 TO chatGUI:addhbox().
    SET outputBox TO hbox1:addscrollbox().
    SET labelLogo TO hbox1:addlabel(). SET labelLogo:image to "pathfinder". labelLogo.
    SET chatGUI:Y To 800.
    
    outputBox:addlabel("Communication system status: ONLINE").
    outputBox:addlabel("===========================================================    ").
    outputBox:addlabel("Remote system target: " + RemoteVessel).
    outputBox:addlabel("Transmission Delay: " + COMMDELAY).
    outputBox:addlabel(COMMLOG:READALL:string).
    outputBox:addlabel("").
    SET outputBox:position TO V(0,999999,0).

    SET hbox2 TO chatGUI:addhbox().
    SET hbox3 TO chatGUI:addhbox().
    IF show >= 1 {
        SET getImageButton TO hbox2:ADDBUTTON("Auto Capture Remote Image (sec)").
        SET getImageButton:style:width TO 255.
    }
    IF show >= 2 {
        SET selector TO hbox2:addpopupmenu(). selector.
        SET selector:text TO "Convert to list of servo positions >".
        SET selector:options TO LIST("None", "Rotate", "Pitch", "Extend").
        SET selector:style:width TO 255.
        SET convertButton TO hbox2:ADDBUTTON(" >> ").
        SET convertButton:style:width TO 30.
        set selector:ONCHANGE to {
            parameter choice. choice.
            SET convertButton:PRESSED TO true.  
        }.
    }
    SET inputField TO hbox3:addtextfield("").
    IF show >= 1 {
        SET testButton TO hbox3:ADDBUTTON("Localhost Test").
        SET testButton:style:width TO 150.
    }
    SET sendButton TO hbox3:ADDBUTTON("<color=red><b>SEND TO REMOTE</b></color>").
    SET sendButton:style:width TO 160.
    SET closeButton TO hbox3:ADDBUTTON(" X"). SET closeButton:style:width TO 26.
    IF show >= 3 {
        SET sendfwUpdButton TO hbox2:ADDBUTTON("<color=red><b>SEND firmware update instructions</b></color>").
        SET sendfwUpdButton:style:width TO 260.
    }
    chatGUI:SHOW().

    //// PATHFINDER COMM TERMINAL LOOP ////
    UNTIL False {
        //CORE:DOEVENT("Close Terminal").
        FOR COM_Terminal IN SHIP:partsnamedpattern("probeCoreOcto2.v2") {
            SET moduleCOMM TO COM_Terminal:getmodule("ModuleResourceConverter").
            IF moduleCOMM:getfield("Communications Terminal") <> "Operational" {
                CLEARGUIS().
                Wait 1. moduleCOMM:doevent("Start Comm System").
                Reboot.
            }
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
                IF RECEIVED:CONTENT:tostring():contains("Are you receiving me") {
                    /// CONTRACT PARAMETER COMPLETE, Are you receiving me?
                    contractParameter("kOSparam_Pathfinder1","COMPLETE").
                    IF show = 1 { SET CORE:volume:name TO "PCS_2E_1665". }
                    SHIP:MESSAGES:POP. Reboot.
                } ELSE IF show = 2 {
                    SET CORE:volume:name TO "PCS_3E_4571".
                    SET show TO 3.
                    contractParameter("kOSparam_Pathfinder3","COMPLETE").
                    SHIP:MESSAGES:POP. Reboot. 
                }
            }
            SHIP:MESSAGES:POP.
            IF messageCounter() > 4 {
                contractParameter("kOSparam_Pathfinder5","COMPLETE").
            }
        }
        IF show >= 1 AND getImageButton:PRESSED {
            getImageButton:TAKEPRESS.
            SET inputField:text TO "CaptureImage::10".
        }
        IF show >= 2 AND convertButton:PRESSED {
            convertButton:TAKEPRESS.
            IF NOT inputField:text:contains("::") AND selector:value:tostring() <> "None" 
             {
                outputBox:addlabel("Converted '" + inputField:text + "' to " + selector:value + " format").
                SET inputField:text TO selector:value + "::" + ascii2servo(inputField:text, selector:value):join(",").
            }  
        }
        IF show >= 2 AND testButton:PRESSED {
            testButton:TAKEPRESS.
            IF inputField:text:contains("CaptureImage") {
                takePhoto(inputField:text:split("::")[1]).
            } ELSE IF inputField:text:contains("::") {
                moveServos(inputField:text).
            } ELSE {
                outputBox:addlabel("ERROR - incorrect format").
                SET outputBox:position TO V(0,999999,0).
            }
        }
        IF  show >= 3 AND sendfwUpdButton:PRESSED {
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
        }
        wait 1. 
    }
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

IF CORE:volume:name = "PCS_1E_8429" { PCSTerminal(1). }
IF CORE:volume:name = "PCS_2E_1665" { PCSTerminal(2). }
IF CORE:volume:name = "PCS_3E_4571" { PCSTerminal(3). }

IF CORE:volume:name = "PCS_1M_2347" { rawComm(False). }
IF CORE:volume:name = "PCS_2M_4575" { rawComm(True). }
IF CORE:volume:name = "PCS_3M_9766" { PCSTerminal(0). }

