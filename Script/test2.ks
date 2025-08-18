clearScreen.
SET RemoteVessel TO VESSEL("Pathfinder Probe").

function convertSeconds {
    parameter seconds.
    return FLOOR(seconds / 60) + "min " + Mod(seconds,60) + "sec".
}

function getSol {
    SET sol TO TIME:year * 365 + TIME:day.
    return sol - 31356.
}

function sendMessage {
    parameter MESSAGE. 
    SET C TO RemoteVessel:CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) {
        Wait 1. 
        return "Message sent!  Delay is " + convertSeconds(ROUND(C:DELAY)).
    }
    return "[ERROR] - Message not sent ".
}

function radioChat {
    SET chatGUI TO GUI(800,400).
    SET title TO chatGUI:addlabel("<b><color=red><size=30>Pathfinder Communications Subsystem</size></color></b>"). title.
    SET title:style:align TO "CENTER".
    SET hbox1 TO chatGUI:addhbox().
    SET labelLogo TO hbox1:addlabel(). SET labelLogo:image to "pathfinder". labelLogo.
    SET receivedBox TO hbox1:addscrollbox().
    SET receivedBox:style:width TO 500.
    receivedBox:addlabel("Ready to receive...").

    //SET labelSignal TO hbox1:addlabel("Signal Delay: " + ROUND(ADDONS:RT:DELAY(RemoteVessel)) + " sec"). labelSignal.
    //SET labelDataFormat TO hbox1:addlabel("Data format: "). labelDataFormat.
    //SET popup1 TO hbox1:addpopupmenu(). popup1.
    //popup1:addoption("Send as ASCII Text").
    //popup1:addoption("Convert to Base64").
    //popup1:addoption("Convert to Decimal").
    //popup1:addoption("Convert to Hexadecimal").

    SET inputField TO chatGUI:addtextfield("").
    SET tooltip TO "Enter Text to Send".
    SET inputField:tooltip TO "   " + tooltip.
    SET inputField:style:fontsize TO 20.
    SET sendButton TO chatGUI:ADDBUTTON("SEND").

    chatGUI:SHOW(). 
    SET chatGUI:Y To 200.

    UNTIL False {
        Wait until sendButton:TAKEPRESS.
        WAIT(1.1).
        IF inputField:text:length > 0 {
            receivedBox:addlabel("Sol " + getSol() + " - " + TIME:clock + " - Sending message to " + RemoteVessel).
            receivedBox:addlabel(">>> " + inputField:text).
            receivedBox:addlabel(sendMessage(inputField:text)).
        }
        SET inputField:text TO "".
        SET receivedBox:position TO V(0,999999,0).
    }
}

SET P TO SHIP:PARTSNAMED("IR.Camera")[0].
SET M TO P:GETMODULE("ModuleScienceExperiment").
print M.
WAIT UNTIL M:HASDATA.
print "Bingo!!".
//radioChat().

//Wait 0.
//chatGUI:HIDE().
//SET TextInput TO inputField:text. TextInput.