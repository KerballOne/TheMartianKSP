//clearScreen.

function mainBattEnergy {
   SET batteries TO LIST(SHIP:partsnamed("Ares-Battery"),SHIP:partsnamedpattern("BatteryPack")).
    SET EC TO 0.
    FOR battery_type IN batteries { 
        FOR battery IN battery_type {
            SET res TO battery:resources[0].
            IF res:name:contains("ElectricCharge") {
                SET EC TO EC + res:amount.
            }
        }
    }
    return EC.
}

function getPowerFlow {
    SET prevAmount TO mainBattEnergy().
    wait 1.
    return (mainBattEnergy() - prevAmount).
}

print getPowerFlow().