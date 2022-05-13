// Credits
// AyeZee#6969 -- ctf gamemode and ui
// sal#3261 -- base custom_tdm mode to work off
// Retículo Endoplasmático#5955 -- giving me the ctf sound names
// everyone else -- advice

global function Sh_CustomCTF_Init
global function NewCTFLocationSettings
global function NewCTFLocPair

global function CTF_Equipment_GetDefaultShieldHP
global function CTF_GetOOBDamagePercent

global int CTF_SCORE_GOAL_TO_WIN
global int CTF_ROUNDTIME
global const int NUMBER_OF_MAP_SLOTS = 4
global const int NUMBER_OF_CLASS_SLOTS = 6
global bool GIVE_ALT_AFTER_CAPTURE
global bool USE_LEGEND_ABILITYS
global int CTF_RESPAWN_TIMER

//Custom Messages IDS
global enum eCTFMessage
{
    PickedUpFlag = 0
    EnemyPickedUpFlag = 1
    TeamReturnedFlag = 2
}

//PointHint IDS
global enum eCTFFlag
{
    Defend = 0
    Capture = 1
    Attack = 2
    Escort = 3
    Return = 4
}

//PointHint IDS
global enum eCTFClassSlot
{
    Primary = 0
    Secondary = 1
    Tactical = 2
    Ultimate = 3
}

//Screen IDS
global enum eCTFScreen
{
	WinnerScreen = 0
	VoteScreen = 1
	TiedScreen = 2
	SelectedScreen = 3
	NextRoundScreen = 4
    NotUsed = 230
}

//Stats IDS
global enum eCTFStats
{
    Clear = 0
    Captures = 1
    Kills = 2
}

global enum eCTFAnnounce
{
	NONE = 0
	WAITING_FOR_PLAYERS = 1
	ROUND_START = 2
	VOTING_PHASE = 3
	MAP_FLYOVER = 4
	IN_PROGRESS = 5
}

global struct LocPairCTF
{
    vector origin = <0, 0, 0>
    vector angles = <0, 0, 0>
}

global struct LocationSettingsCTF
{
    string name
    array<LocPairCTF> bubblespots
    vector imcflagspawn
    vector milflagspawn
    array<LocPairCTF> imcspawns
    array<LocPairCTF> milspawns
    LocPairCTF &deathcam
    LocPairCTF &victorypos
}

global struct CTFClasses
{
    string name
    string primary
    string secondary
    array<string> primaryattachments
    array<string> secondaryattachments
    string tactical
    string ult
}

global struct CTFPlaylistWeapons
{
    string name
    array<string> mods
}

struct {
    LocationSettingsCTF &selectedLocation
    array choices
    array<LocationSettingsCTF> locationSettings
    array<CTFClasses> ctfclasses
    var scoreRui

} file;

CTFClasses function NewCTFClass(string name, string primary, array<string> primaryattachments, string secondary, array<string> secondaryattachments, string tactical, string ult)
{
    CTFClasses ctfclass
    ctfclass.name = name
    ctfclass.primary = primary
    ctfclass.secondary = secondary
    ctfclass.primaryattachments = primaryattachments
    ctfclass.secondaryattachments = secondaryattachments
    ctfclass.tactical = tactical
    ctfclass.ult = ult

    file.ctfclasses.append(ctfclass)

    return ctfclass
}

void function Shared_RegisterCTFClass(CTFClasses ctfclass)
{
    #if SERVER
    _CTFRegisterCTFClass(ctfclass)
    #endif

    #if CLIENT
    Cl_CTFRegisterCTFClass(ctfclass)
    #endif
}

void function Sh_CustomCTF_Init()
{
    //Set Playlist Vars
    CTF_SCORE_GOAL_TO_WIN = GetCurrentPlaylistVarInt( "max_score", 5 )
    CTF_ROUNDTIME = GetCurrentPlaylistVarInt( "round_time", 1500 )
    GIVE_ALT_AFTER_CAPTURE = GetCurrentPlaylistVarBool( "give_ult_after_capture", false )
    USE_LEGEND_ABILITYS = GetCurrentPlaylistVarBool( "use_legend_abilitys", false )
    CTF_RESPAWN_TIMER = GetCurrentPlaylistVarInt( "respawn_timer", 10 )

    //Register Classes
    for(int i = 1; i < 6; i++ ) {
        Shared_RegisterCTFClass(
            NewCTFClass(
                CTF_Equipment_GetClass_PrimaryWeapon("ctf_respawn_class" + i + "_name").name,
                CTF_Equipment_GetClass_PrimaryWeapon("ctf_respawn_class" + i + "_primary").name,
                CTF_Equipment_GetClass_PrimaryWeapon("ctf_respawn_class" + i + "_primary").mods,
                CTF_Equipment_GetClass_SecondaryWeapon("ctf_respawn_class" + i + "_secondary").name,
                CTF_Equipment_GetClass_SecondaryWeapon("ctf_respawn_class" + i + "_secondary").mods,
                CTF_Equipment_GetClass_Tactical("ctf_respawn_class" + i + "_tactical").name,
                CTF_Equipment_GetClass_Ultimate("ctf_respawn_class" + i + "_ultimate").name
            )
        )
    }

    // Map locations
    //This is only used for the boundary bubble
    switch(GetMapName())
    {
        case "mp_rr_canyonlands_staging":
            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Firing Range",
                    [ //BubbleSpots
                        NewCTFLocPair(<33560, -8992, -29126>, <0, 90, 0>),
                        NewCTFLocPair(<34525, -7996, -28242>, <0, 100, 0>),
                        NewCTFLocPair(<33507, -3754, -29165>, <0, -90, 0>),
                        NewCTFLocPair(<34986, -3442, -28263>, <0, -113, 0>),
                        NewCTFLocPair(<30567, -6373, -29041>, <0, -113, 0>)
                    ],
                    <33076, -8916, -29125>, //imc flag spawn
                    <32856, -3596, -29165>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<34498, -8254, -28845>, <0, 130, 0>),
                        NewCTFLocPair(<31926, -8875, -29125>, <0, 105, 0>),
                        NewCTFLocPair(<34529, -9354, -28972>, <0, 145, 0>),
                        NewCTFLocPair(<32302, -9478, -29145>, <0, 60, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<32240, -2723, -28903>, <0, -50, 0>),
                        NewCTFLocPair(<34943, -3502, -28254>, <0, -113, 0>),
                        NewCTFLocPair(<30857, -3860, -28729>, <0, -30, 0>),
                        NewCTFLocPair(<31836, -4098, -29081>, <0, -50, 0>)
                    ],
                    NewCTFLocPair(<0,0,5000>, <90,180,0>), //deathcam angle and height
                    NewCTFLocPair(<32575,-5068, -28845>, <0, 0, 0>) //Victory Pos
                )
            )
            break

        case "mp_rr_aqueduct":
            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Overflow",
                    [
                        NewCTFLocPair(<4859, -4097, 351>, <0, 0, 0>),
                        NewCTFLocPair(<-3436, -4097, 351>, <0, 0, 0>)
                    ],
                    <4859, -4097, 351>, //imc flag spawn
                    <-3436, -4097, 351>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<4386, -3185, 332>, <0, -145, 0>),
                        NewCTFLocPair(<4372, -5591, 460>, <0, 161, 0>),
                        NewCTFLocPair(<4528, -4683, 332>, <0, -130, 0>),
                        NewCTFLocPair(<4208, -3785, 332>, <0, -165, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<-2914, -5607, 460>, <0, 0, 0>),
                        NewCTFLocPair(<-3205, -4625, 332>, <0, -14, 0>),
                        NewCTFLocPair(<-2870, -3833, 332>, <0, -37, 0>),
                        NewCTFLocPair(<-2997, -3094, 332>, <0, -19, 0>)
                    ],
                    NewCTFLocPair(<0,0,5000>, <90,-90,0>), //deathcam angle and height
                    NewCTFLocPair(<8212, -3014, 783>, <0, 120, 0>) //Victory Pos
                )
            )
            break

        case "mp_rr_ashs_redemption":
            break

        case "mp_rr_canyonlands_mu1":
        case "mp_rr_canyonlands_mu1_night":
        case "mp_rr_canyonlands_64k_x_64k":
            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Artillery",
                    [
                        NewCTFLocPair(<9614, 30792, 4868>, <0, 90, 0>),
                        NewCTFLocPair(<6379, 30792, 4868>, <0, 18, 0>),
                        NewCTFLocPair(<3603, 30792, 4868>, <0, 180, 0>),
                        NewCTFLocPair(<6379, 29172, 4868>, <0, 50, 0>)
                    ],
                    <9400, 30767, 5028>, //imc flag spawn
                    <3690, 30767, 5028>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<10250, 30984, 4828>, <0, -170, 0>),
                        NewCTFLocPair(<10237, 30573, 4828>, <0, 170, 0>),
                        NewCTFLocPair(<9127, 30626, 4832>, <0, 170, 0>),
                        NewCTFLocPair(<8997, 30943, 4828>, <0, -170, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<4402, 30619, 4828>, <0, 8, 0>),
                        NewCTFLocPair(<4148, 30573, 4828>, <0, -8, 0>),
                        NewCTFLocPair(<3415, 30626, 4832>, <0, -8, 0>),
                        NewCTFLocPair(<3263, 30943, 4828>, <0, 8, 0>)
                    ],
                    NewCTFLocPair(<0,0,5000>, <90,90,0>), //deathcam angle and height
                    NewCTFLocPair(<-29300, -4209, 2540>, <0, 100, 0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Airbase",
                    [
                        NewCTFLocPair(<-25775, 1599, 2583>, <0, 90, 0>),
                        NewCTFLocPair(<-24845,-5112,2571>, <0, 18, 0>),
                        NewCTFLocPair(<-28370, -2238, 2550>, <0, 180, 0>)
                    ],
                    <-25775, 1599, 2583>, //imc flag spawn
                    <-24845, -5112, 2571>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<-26435, 2024, 2568>, <0, -70, 0>),
                        NewCTFLocPair(<-26870, 650, 2599>, <0, -30, 0>),
                        NewCTFLocPair(<-24342, 51, 2568>, <0, -125, 0>),
                        NewCTFLocPair(<-27234, -254, 2568>, <0, -20, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<-25699, -5971, 2580>, <0, 19, 0>),
                        NewCTFLocPair(<-23893, -4242, 2568>, <0, 90, 0>),
                        NewCTFLocPair(<-26251, -4939, 2573>, <0, 44, 0>),
                        NewCTFLocPair(<-27554, -4611, 2536>, <0, 45, 0>)
                    ],
                    NewCTFLocPair(<0,0,5000>, <90,0,0>), //deathcam angle and height
                    NewCTFLocPair(<-29300, -4209, 2540>, <0, 100, 0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Relay",
                    [
                        NewCTFLocPair(<29625, 25371, 4216>, <0, 90, 0>),
                        NewCTFLocPair(<22958, 22128, 3914>, <0, 18, 0>),
                        NewCTFLocPair(<26825, 30767, 4790>, <0, 180, 0>)
                    ],
                    <23258, 22476, 3914>, //imc flag spawn
                    <30139, 25359, 4216>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<24272, 21828, 3914>, <0, 40, 0>),
                        NewCTFLocPair(<23815, 23703, 4058>, <0, 35, 0>),
                        NewCTFLocPair(<22419, 23489, 4251>, <0, 180, 0>),
                        NewCTFLocPair(<21577, 22943, 4256>, <0, -15, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<30000, 26381, 4216>, <0, -135, 0>),
                        NewCTFLocPair(<29036, 24253, 4216>, <0, 90, 0>),
                        NewCTFLocPair(<27698, 28291, 4102>, <0, -160, 0>),
                        NewCTFLocPair(<27628, 25640, 4370>, <0, 160, 0>)
                    ],
                    NewCTFLocPair(<0,0,6000>, <90,-70,0>), //deathcam angle and height
                    NewCTFLocPair(<-29300, -4209, 2540>, <0, 100, 0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Wetlands",
                    [
                        NewCTFLocPair(<29585, 16597, 4641>, <0, 90, 0>),
                        NewCTFLocPair(<19983, 14582, 4670>, <0, 18, 0>),
                        NewCTFLocPair(<25244, 16658, 3871>, <0, 180, 0>)
                    ],
                    <28495, 16316, 4206>, //imc flag spawn
                    <19843, 14597, 4670>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<27589, 17568, 4206>, <0, -160, 0>),
                        NewCTFLocPair(<27560, 15678, 4350>, <0, 0, 0>),
                        NewCTFLocPair(<29963, 17119, 4366>, <0, 165, 0>),
                        NewCTFLocPair(<29234, 15319, 4206>, <0, 135, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<20337, 13229, 4670>, <0, 50, 0>),
                        NewCTFLocPair(<20230, 16421, 4670>, <0, 0, 0>),
                        NewCTFLocPair(<21194, 16925, 4518>, <0, -60, 0>),
                        NewCTFLocPair(<22281, 13742, 4422>, <0, 40, 0>)
                    ],
                    NewCTFLocPair(<0,0,7000>, <90,90,0>), //deathcam angle and height
                    NewCTFLocPair(<-29300, -4209, 2540>, <0, 100, 0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Repulsor",
                    [
                        NewCTFLocPair(<20269, -14999, 4824>, <0, 90, 0>),
                        NewCTFLocPair(<29000, -15195, 4726>, <0, 18, 0>),
                        NewCTFLocPair(<24417, -15196, 5203>, <0, 180, 0>)
                    ],
                    <21422, -14999, 4824>, //imc flag spawn
                    <27967, -15195, 4726>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<21925, -12916, 4726>, <0, -50, 0>),
                        NewCTFLocPair(<21925, -16826, 4726>, <0, 50, 0>),
                        NewCTFLocPair(<22251, -15589, 4598>, <0, 35, 0>),
                        NewCTFLocPair(<22251, -14171, 4598>, <0, -35, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<28347, -13383, 4726>, <0, 180, 0>),
                        NewCTFLocPair(<28347, -17113, 4726>, <0, 180, 0>),
                        NewCTFLocPair(<26507, -15813, 4730>, <0, -135, 0>),
                        NewCTFLocPair(<26507, -14500, 4730>, <0, 135, 0>)
                    ],
                    NewCTFLocPair(<0,0,7000>, <90,90,0>), //deathcam angle and height
                    NewCTFLocPair(<-29300, -4209, 2540>, <0, 100, 0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Skull Town",
                    [
                        NewCTFLocPair(<-12391, -19413, 3166>, <0, 90, 0>),
                        NewCTFLocPair(<-6706, -13383, 3174>, <0, 18, 0>),
                        NewCTFLocPair(<-9746, -16127, 4062>, <0, 180, 0>)
                    ],
                    <-12391, -19413, 3166>, //imc flag spawn
                    <-6706, -13383, 3174>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<-11246, -19126, 3285>, <0, 70, 0>),
                        NewCTFLocPair(<-12575, -18156, 3170>, <0, 0, 0>),
                        NewCTFLocPair(<-12125, -17650, 3186>, <0, 45, 0>),
                        NewCTFLocPair(<-11241, -18068, 3187>, <0, 45, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<-6509, -14479, 3166>, <0, -135, 0>),
                        NewCTFLocPair(<-7242, -13374, 3166>, <0, 170, 0>),
                        NewCTFLocPair(<-7573, -13783, 3186>, <0, -100, 0>),
                        NewCTFLocPair(<-7472, -14763, 3183>, <0, -150, 0>)
                    ],
                    NewCTFLocPair(<0,0,7000>, <90,-45,0>), //deathcam angle and height
                    NewCTFLocPair(<-29300, -4209, 2540>, <0, 100, 0>) //Victory Pos
                )
            )

            break

        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Overlook",
                    [
                        NewCTFLocPair(<26893, 13646, -3199>, <0, 40, 0>),
                        NewCTFLocPair(<30989, 8510, -3329>, <0, 90, 0>),
                        NewCTFLocPair(<32922, 9423, -3329>, <0, 90, 0>)
                    ],
                    <26893, 13646, -3199>, //imc flag spawn
                    <30989, 8510, -3329>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<25997, 13028, -3139>, <0, -30, 0>),
                        NewCTFLocPair(<28416, 13515, -3230>, <0, -88, 0>),
                        NewCTFLocPair(<26215, 14402, -3081>, <0, -65, 0>),
                        NewCTFLocPair(<27408, 14510, -3141>, <0, -65, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<31780, 8514, -3329>, <0, 137, 0>),
                        NewCTFLocPair(<30207, 7910, -3313>, <0, 101, 0>),
                        NewCTFLocPair(<31254, 9956, -3393>, <0, 90, 0>),
                        NewCTFLocPair(<32519, 9890, -3525>, <0, 166, 0>)
                    ],
                    NewCTFLocPair(<0,0,5000>, <90,27,0>), //deathcam angle and height
                    NewCTFLocPair(<3990,7540,-4242>, <0,90,0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Refinery",
                    [
                        NewCTFLocPair(<22630, 21512, -4516>, <0, 40, 0>),
                        NewCTFLocPair(<19147, 30973, -4602>, <0, 90, 0>)
                    ],
                    <22630, 22243, -4516>, //imc flag spawn
                    <19147, 30973, -4602>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<21618, 22558, -4499>, <0, 110, 0>),
                        NewCTFLocPair(<20873, 23929, -4557>, <0, 140, 0>),
                        NewCTFLocPair(<22247, 22785, -4523>, <0, 67, 0>),
                        NewCTFLocPair(<23384, 21955, -4523>, <0, 108, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<18034, 30657, -4578>, <0, -42, 0>),
                        NewCTFLocPair(<19757, 31462, -4340>, <0, -63, 0>),
                        NewCTFLocPair(<18320, 29370, -4778>, <0, -101, 0>),
                        NewCTFLocPair(<16344, 29093, -4441>, <0, -13, 0>)
                    ],
                    NewCTFLocPair(<0,0,7000>, <90,-165,0>),//deathcam angle and height
                    NewCTFLocPair(<3990,7540,-4242>, <0,90,0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Capitol City",
                    [
                        NewCTFLocPair(<1750, 5158, -3334>, <0, 40, 0>),
                        NewCTFLocPair(<11690, 6300, -4065>, <0, 90, 0>)
                    ],
                    <1750, 5158, -3334>, //imc flag spawn
                    <11690, 6300, -4065>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<2102, 5999, -4225>, <0, 0, 0>),
                        NewCTFLocPair(<1761, 5356, -3953>, <0, -29, 0>),
                        NewCTFLocPair(<1392, 4444, -3006>, <0, 40, 0>),
                        NewCTFLocPair(<2979, 4051, -4225>, <0, 50, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<12050, 7446, -4281>, <0, 170, 0>),
                        NewCTFLocPair(<12122, 5159, -4225>, <0, -170, 0>),
                        NewCTFLocPair(<10679, 4107, -4225>, <0, 120, 0>),
                        NewCTFLocPair(<12185, 6412, -4281>, <0, -130, 0>)
                    ],
                    NewCTFLocPair( < 0, 0, 7000 > , < 90, -85, 0 > ), //deathcam angle and height
                    NewCTFLocPair(<3990,7540,-4242>, <0,90,0>) //Victory Pos
                )
            )

            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Sorting Factory",
                    [ //bubblespots
                        NewCTFLocPair(<1874, -25365, -3385>, <0, 40, 0>),
                        NewCTFLocPair(<10684, -18468, -3584>, <0, 90, 0>)
                    ],
                    <1874, -25365, -3385>, //imc flag spawn
                    <10684, -18468, -3584>, //mil flag spawn
                    [ //imc spawns
                        NewCTFLocPair(<1747, -22990, -3561>, <0, 31, 0>),
                        NewCTFLocPair(<3904, -25013, -3561>, <0, 0, 0>),
                        NewCTFLocPair(<2110, -25117, -3037>, <0, 50, 0>),
                        NewCTFLocPair(<2242, -21858, -3657>, <0, -25, 0>)
                    ],
                    [ //mil spawns
                        NewCTFLocPair(<9020, -18238, -3563>, <0, -118, 0>),
                        NewCTFLocPair(<10076, -19642, -2889>, <0, -148, 0>),
                        NewCTFLocPair(<7793, -17583, -3657>, <0, -80, 0>),
                        NewCTFLocPair(<9377, -20718, -3569>, <0, -179, 0>)
                    ],
                    NewCTFLocPair( < 0, 0, 7000 > , < 90, -45, 0 > ), //deathcam angle and height
                    NewCTFLocPair(<3990,7540,-4242>, <0,90,0>) //Victory Pos
                )
            )


        default:
            Assert(false, "No TDM locations found for map!")
    }

    //Client Signals
    RegisterSignal( "CloseScoreRUI" )

}

LocPairCTF function NewCTFLocPair(vector origin, vector angles)
{
    LocPairCTF locPair
    locPair.origin = origin
    locPair.angles = angles

    return locPair
}

LocationSettingsCTF function NewCTFLocationSettings(string name, array < LocPairCTF > bubblespots, vector imcflagspawn, vector milflagspawn, array < LocPairCTF > imcspawns, array < LocPairCTF > milspawns, LocPairCTF deathcam, LocPairCTF victorypos)
{
    LocationSettingsCTF locationSettings
    locationSettings.name = name
    locationSettings.bubblespots = bubblespots
    locationSettings.imcflagspawn = imcflagspawn
    locationSettings.milflagspawn = milflagspawn
    locationSettings.imcspawns = imcspawns
    locationSettings.milspawns = milspawns
    locationSettings.deathcam = deathcam
    locationSettings.victorypos = victorypos

    file.locationSettings.append(locationSettings)

    return locationSettings
}


void function Shared_RegisterLocation(LocationSettingsCTF locationSettings)
{
    #if SERVER
    _CTFRegisterLocation(locationSettings)
    #endif

    #if CLIENT
    Cl_CTFRegisterLocation(locationSettings)
    #endif
}

// Playlist GET
float function CTF_Equipment_GetDefaultShieldHP()                        { return GetCurrentPlaylistVarFloat("default_shield_hp", 100) }
float function CTF_GetOOBDamagePercent()                      { return GetCurrentPlaylistVarFloat("oob_damage_percent", 25) }

CTFPlaylistWeapons function CTF_Equipment_GetClass_PrimaryWeapon(string playlistvar)
{
    return Equipment_GetClass_Weapon(GetCurrentPlaylistVarString(playlistvar, "~~none~~"))
}

CTFPlaylistWeapons function CTF_Equipment_GetClass_SecondaryWeapon(string playlistvar)
{
    return Equipment_GetClass_Weapon(GetCurrentPlaylistVarString(playlistvar, "~~none~~"))
}

CTFPlaylistWeapons function CTF_Equipment_GetClass_Tactical(string playlistvar)
{
    return Equipment_GetClass_Weapon(GetCurrentPlaylistVarString(playlistvar, "~~none~~"))
}

CTFPlaylistWeapons function CTF_Equipment_GetClass_Ultimate(string playlistvar)
{
    return Equipment_GetClass_Weapon(GetCurrentPlaylistVarString(playlistvar, "~~none~~"))
}

CTFPlaylistWeapons function Equipment_GetClass_Weapon(string input)
{
    CTFPlaylistWeapons weapon
    if(input == "~~none~~") return weapon

    array<string> args = split(input, " ")

    if(args.len() == 0) return weapon

    weapon.name = args[0]
    weapon.mods = args.slice(1, args.len())

    return weapon
}