clearScreen.

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
                    print param:ID.
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

////////////////////////////////////

SET delay TO 1.0.

function CompleteVPGs {
    contractParameter("DefineHabVPG","COMPLETE"). Wait delay.
    contractParameter("DefineRoverVPG","COMPLETE"). Wait delay.
    contractParameter("DefineIrisVPG","COMPLETE"). Wait delay.
    contractParameter("DefineHermesVPG","COMPLETE"). Wait delay.
    contractParameter("DefineMAVVPG","COMPLETE"). Wait delay.
}
function CompleteAct_1 {
    contractParameter("Act_1_start","COMPLETE"). Wait delay.
    // SoilSequence
        contractParameter("kOSparam_Hab1","COMPLETE"). Wait delay.
        contractParameter("RoverDirtVPG","COMPLETE"). Wait delay.
            contractParameter("PartValidationSmallTank","COMPLETE"). Wait delay.
            contractParameter("ReachBasaltFlats","COMPLETE"). Wait delay.
        contractParameter("HabDirtVPG","COMPLETE"). Wait delay.
            contractParameter("HasDirt","COMPLETE"). Wait delay.
            contractParameter("HasCapacityEC","COMPLETE"). Wait delay.
        contractParameter("CreateSoilVPG","COMPLETE"). Wait delay.
            contractParameter("HasSoil","COMPLETE"). Wait delay.

    // WaterSequence
        contractParameter("GetHydrazineVPG","COMPLETE"). Wait delay.
            contractParameter("HasHydrazine","COMPLETE"). Wait delay.
        contractParameter("InstallHydrazineVPG","COMPLETE"). Wait delay.
            contractParameter("kOSparam_Hab2","COMPLETE"). Wait delay.
            contractParameter("HasCapacityEC2","COMPLETE"). Wait delay.
        contractParameter("CreateHydrogenVPG","COMPLETE"). Wait delay.
            contractParameter("HasHydrogen","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Hab2a","COMPLETE"). Wait delay.

    // RTGSequence
        contractParameter("RTGSearchVPG","COMPLETE"). Wait delay.
            contractParameter("HasCrew2","COMPLETE"). Wait delay.
            contractParameter("RTGNearby","COMPLETE"). Wait delay.
        contractParameter("RTGtimer","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Rover1","COMPLETE"). Wait delay.
}
function CompleteAct_2 {
    contractParameter("Act_2_start","COMPLETE"). Wait delay.
    // PathfinderSequence
        contractParameter("PathfinderSequence_start","COMPLETE"). Wait delay.
        contractParameter("PFSearchVPG","COMPLETE"). Wait delay.
            contractParameter("HasCrew4","COMPLETE"). Wait delay.
            contractParameter("PFNearby","COMPLETE"). Wait delay.
        contractParameter("PFtimer","COMPLETE"). Wait delay.
    // CommunicationSequence
        contractParameter("kOSparam_Pathfinder1","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Pathfinder2","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Pathfinder3","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Pathfinder4","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Pathfinder5","COMPLETE"). Wait delay.
    // GreenhouseSequence
        contractParameter("HasFoodVPG","COMPLETE"). Wait delay.
            contractParameter("HasFood","COMPLETE"). Wait delay.
        contractParameter("AirlockVPG","COMPLETE"). Wait delay.
            contractParameter("AirlockNotHere","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Hab4","COMPLETE"). Wait delay.
        contractParameter("AirlockDialogWait","COMPLETE"). Wait delay.
        contractParameter("kOSparam_Hab5","COMPLETE"). Wait delay.
}
function CompleteAct_3 {
    contractParameter("Act_3_start","COMPLETE"). Wait delay.
    //LaunchIris1VPG
    contractParameter("LaunchIris1VPG","COMPLETE"). Wait delay.
        contractParameter("LaunchIRIS","COMPLETE"). Wait delay.
        contractParameter("IrisDestroyed","COMPLETE"). Wait delay.
    contractParameter("HermesTimer","COMPLETE"). Wait delay.
    // RichPurnellManeuver
        contractParameter("RichPurnellManeuver","COMPLETE"). Wait delay.
    // RescueMark
        contractParameter("SchiaparelliVPG","COMPLETE"). Wait delay.
            contractParameter("ReachSchiaparelli","COMPLETE"). Wait delay.
        contractParameter("MAVTimer","COMPLETE"). Wait delay.
        contractParameter("MAVMassVPG","COMPLETE"). Wait delay.
            contractParameter("MAVMass","COMPLETE"). Wait delay.
        contractParameter("ReachMarsVPG","COMPLETE"). Wait delay.
            contractParameter("ReachMars","COMPLETE"). Wait delay.
        contractParameter("MarkRescuedVPG","COMPLETE"). Wait delay.
            contractParameter("HasCrew6","COMPLETE"). Wait delay.
        contractParameter("HasFullCrew","COMPLETE"). Wait delay.
        contractParameter("ReturnToEarth","COMPLETE"). Wait delay.
}

function CompleteContract {
    CompleteVPGs().
    IF contractParameter("=== Act_1 ===","getState") <> "Complete" { CompleteAct_1(). }
    print "Act_1 COMPLETE". print " ". Wait 5.
    IF contractParameter("=== Act_2 ===","getState") <> "Complete" { CompleteAct_2(). }
    print "Act_2 COMPLETE". print " ". Wait 5.
    IF contractParameter("=== Act_3 ===","getState") <> "Complete" { CompleteAct_3(). }
    print "Act_3 COMPLETE". print " ". 
}

CompleteContract(). 



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Set core:volume:name TO "Init0".
//SET CORE:volume:name TO "HAB_3M_5342".
//contractParameter("SpawnHermes","COMPLETE"). Wait delay.



