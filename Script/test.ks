//clearScreen.

function loadFirmware {
    IF EXISTS("0:firmware_rover_v0.1.42.bin") {
        SET bin TO OPEN("0:firmware_rover_v0.1.42.bin").
        SET firmware TO bin:READALL:string.
        IF firmware:contains("00000D00  31 39 32 2E 31 36 38 2E 31 2E 32 35 35 22 3B 0A  |192.168.1.255") 
        AND firmware:contains("00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 32 36 30 30  |.ServPort = 2600") {
            print "NEW".
        }
        IF firmware:contains("00000D00  31 39 32 2E 31 36 38 2E 30 2E 31 30 35 22 3B 0A  |192.168.0.105") 
        AND firmware:contains("00000D10  09 53 65 72 76 50 6F 72 74 20 3D 20 35 30 30 35  |.ServPort = 5005") {
            print "OLD".
        }
    }
}

loadFirmware().
//EDIT "0:firmware_rover_v0.1.42.bin".