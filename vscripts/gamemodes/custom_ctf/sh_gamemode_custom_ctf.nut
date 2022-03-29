// Credits
// AyeZee#6969 -- whole ctf gamemode and ui
// @Shrugtal -- score ui
// everyone else -- advice

global function Sh_CustomCTF_Init
global function NewCTFLocationSettings
global function NewCTFLocPair

global function CTF_GetRespawnDelay
global function CTF_Equipment_GetDefaultShieldHP
global function CTF_GetOOBDamagePercent
global function CTF_GetVotingTime
global function GetDeathcamHeight
global function SendCurrentLocation

#if SERVER
global function CTF_Equipment_GetRespawnKitEnabled
global function CTF_Equipment_GetRespawnKit_PrimaryWeapon
global function CTF_Equipment_GetRespawnKit_SecondaryWeapon
global function CTF_Equipment_GetRespawnKit_Tactical
global function CTF_Equipment_GetRespawnKit_Ultimate
global function GetRandomPlayerSpawnOrigin
global function GetRandomPlayerSpawnAngles
global function GetFlagLocation
#endif


global const CTF_SCORE_GOAL_TO_WIN = 5

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
    array<LocPairCTF> spawns
    vector cinematicCameraOffset
}

struct {
    LocationSettingsCTF &selectedLocation
    array choices
    array<LocationSettingsCTF> locationSettings
    var scoreRui

} file;




void function Sh_CustomCTF_Init() 
{


    // Map locations

    switch(GetMapName())
    {
    case "mp_rr_canyonlands_staging":
        Shared_RegisterLocation(
            NewCTFLocationSettings(
                "Firing Range",
                [
                    NewCTFLocPair(<33560, -8992, -29126>, <0, 90, 0>),
					NewCTFLocPair(<34525, -7996, -28242>, <0, 100, 0>),
                    NewCTFLocPair(<33507, -3754, -29165>, <0, -90, 0>),
					NewCTFLocPair(<34986, -3442, -28263>, <0, -113, 0>)
                ],
                <0, 0, 3000>
            )
        )
        break
		
    case "mp_rr_ashs_redemption":
        Shared_RegisterLocation(
            NewCTFLocationSettings(
                "Ash's Redemption",
                [
                    NewCTFLocPair(<-22104, 6009, -26929>, <0, 0, 0>),
					NewCTFLocPair(<-21372, 3709, -26955>, <-5, 55, 0>),
                    NewCTFLocPair(<-19356, 6397, -26861>, <-4, -166, 0>),
					NewCTFLocPair(<-20713, 7409, -26742>, <-4, -114, 0>)
                ],
                <0, 0, 1000>
            )
        )
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
                <0, 0, 3000>
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
                <0, 0, 3000>
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
                <0, 0, 3000>
            )
        )

        Shared_RegisterLocation(
            NewCTFLocationSettings(
                "WetLands",
                [
                    NewCTFLocPair(<29585, 16597, 4641>, <0, 90, 0>),
                    NewCTFLocPair(<19983, 14582, 4670>, <0, 18, 0>),
                    NewCTFLocPair(<25244, 16658, 3871>, <0, 180, 0>)
                ],
                <0, 0, 3000>
            )
        )

        break

        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
            Shared_RegisterLocation(
                NewCTFLocationSettings(
                    "Lava City",
                    [
                        NewCTFLocPair(<22663, -28134, -2706>, <0, 40, 0>),
                        NewCTFLocPair(<22844, -28222, -3030>, <0, 90, 0>),
                        NewCTFLocPair(<22687, -27605, -3434>, <0, -90, 0>),
                        NewCTFLocPair(<22610, -26999, -2949>, <0, 90, 0>),
                        NewCTFLocPair(<22607, -26018, -2749>, <0, -90, 0>),
                        NewCTFLocPair(<22925, -25792, -3500>, <0, -120, 0>),
                        NewCTFLocPair(<24235, -27378, -3305>, <0, -100, 0>),
                        NewCTFLocPair(<24345, -28872, -3433>, <0, -144, 0>),
                        NewCTFLocPair(<24446, -28628, -3252>, <13, 0, 0>),
                        NewCTFLocPair(<23931, -28043, -3265>, <0, 0, 0>),
                        NewCTFLocPair(<27399, -28588, -3721>, <0, 130, 0>),
                        NewCTFLocPair(<26610, -25784, -3400>, <0, -90, 0>),
                        NewCTFLocPair(<26757, -26639, -3673>, <-10, 90, 0>),
                        NewCTFLocPair(<26750, -26202, -3929>, <-10, -90, 0>)
                    ],
                    <0, 0, 3000>
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

LocationSettingsCTF function NewCTFLocationSettings(string name, array<LocPairCTF> spawns, vector cinematicCameraOffset)
{
    LocationSettingsCTF locationSettings
    locationSettings.name = name
    locationSettings.spawns = spawns
    locationSettings.cinematicCameraOffset = cinematicCameraOffset

    file.locationSettings.append(locationSettings)

    return locationSettings
}


void function Shared_RegisterLocation(LocationSettingsCTF locationSettings)
{
    #if SERVER
    _CTFRegisterLocation(locationSettings)
    #endif
}

vector function GetFlagLocation(LocationSettingsCTF locationSettings, int team)
{
    vector spawnorg
    switch(locationSettings.name)
    {
        case "Firing Range":
            if (team == TEAM_IMC)
                spawnorg = <33040,-3430,-29226>
            if (team == TEAM_MILITIA)
                spawnorg = <32598,-8657,-29189>
            break
        case "Artillery":
            if (team == TEAM_IMC)
                spawnorg = <9400,30767,5028>
            if (team == TEAM_MILITIA)
                spawnorg = <3690,30767,5028>
            break
        case "Airbase":
            if (team == TEAM_IMC)
                spawnorg = <-25775, 1599, 2583>
            if (team == TEAM_MILITIA)
                spawnorg = <-24845,-5112,2571>
            break
        case "Relay":
            if (team == TEAM_IMC)
                spawnorg = <23258, 22476, 3914>
            if (team == TEAM_MILITIA)
                spawnorg = <30139,25359,4216>
            break
        case "WetLands":
            if (team == TEAM_IMC)
                spawnorg = <28495, 16316, 4206>
            if (team == TEAM_MILITIA)
                spawnorg = <19843, 14597, 4670>
            break
        
    }

    return spawnorg
}

void function SendCurrentLocation(LocationSettingsCTF locationSettings)
{
    file.selectedLocation = locationSettings
}

vector function GetDeathcamHeight()
{
    vector spawnorg
    switch(file.selectedLocation.name)
    {
        case "Firing Range":
            spawnorg = <0,0,5000>
            break
        case "Artillery":
            spawnorg = <0,0,5000>
            break
        case "Airbase":
            spawnorg = <0,0,5000>
            break
        case "Relay":
            spawnorg = <0,0,5000>
            break
        case "WetLands":
            spawnorg = <0,0,7000>
            break
        
    }

    return spawnorg
}

#if SERVER
array<vector> function GetRandomPlayerSpawnOrigin(LocationSettingsCTF locationSettings, entity player)
{
    array<vector> spawnorg
    if (locationSettings.name == "Firing Range")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<32778, -3522, -29173>)
            break
            case TEAM_MILITIA:
                spawnorg.append(<32778, -3522, -29173>)
            break
        }
    }
    else if (locationSettings.name == "Artillery")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<10250, 30984, 4828>) //Ang: 0 -170 0
                spawnorg.append(<10237, 30573, 4828>) //Ang: 0 170 0
                spawnorg.append(<9127, 30626, 4832>) //Ang: 0 170 0
                spawnorg.append(<8997, 30943, 4828>) //Ang: 0 -170 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<4402, 30619, 4828>) //Ang: 0 8 0
                spawnorg.append(<4148, 30573, 4828>) //Ang: 0 -8 0
                spawnorg.append(<3415, 30626, 4832>) //Ang: 0 -8 0
                spawnorg.append(<3263, 30943, 4828>) //Ang: 0 8 0
            break
        }
    }
    else if (locationSettings.name == "Airbase")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<-26435, 2024, 2568>) //Ang: 0 -70 0
                spawnorg.append(<-26870, 650, 2599>) //Ang: 0 -30 0
                spawnorg.append(<-24342, 51, 2568>) //Ang: 0 -125 0
                spawnorg.append(<-27234, -254, 2568>) //Ang: 0 -20 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<-25699, -5971, 2580>) //Ang: 0 19 0
                spawnorg.append(<-23893, -4242, 2568>) //Ang: 0 90 0
                spawnorg.append(<-26251, -4939, 2573>) //Ang: 0 44 0
                spawnorg.append(<-27554, -4611, 2536>) //Ang: 0 45 0
            break
        }
    }
    else if (locationSettings.name == "Relay")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<24272, 21828, 3914>) //Ang: 0 40 0
                spawnorg.append(<23815, 23703, 4058>) //Ang: 0 35 0
                spawnorg.append(<22419, 23489, 4251>) //Ang: 0 0 0
                spawnorg.append(<21577, 22943, 4256>) //Ang: 0 -15 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<30000, 26381, 4216>) //Ang: 0 -135 0
                spawnorg.append(<29036, 24253, 4216>) //Ang: 0 90 0
                spawnorg.append(<27698, 28291, 4102>) //Ang: 0 -160 0
                spawnorg.append(<27628, 25640, 4370>) //Ang: 0 160 0
            break
        }
    }
    else if (locationSettings.name == "WetLands")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<27589, 17568, 4206>) //Ang: 0 -160 0
                spawnorg.append(<27560, 15678, 4350>) //Ang: 0 0 0
                spawnorg.append(<29963, 17119, 4366>) //Ang: 0 165 0
                spawnorg.append(<29234, 15319, 4206>) //Ang: 0 135 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<20337, 13229, 4670>) //Ang: 0 50 0
                spawnorg.append(<20230, 16421, 4670>) //Ang: 0 0 0
                spawnorg.append(<21194, 16925, 4518>) //Ang: 0 -60 0
                spawnorg.append(<22281, 13742, 4422>) //Ang: 0 40 0
            break
        }
    }

    return spawnorg
}

array<vector> function GetRandomPlayerSpawnAngles(LocationSettingsCTF locationSettings, entity player)
{
    array<vector> spawnorg
    if (locationSettings.name == "Firing Range")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<32778, -3522, -29173>)
            break
            case TEAM_MILITIA:
                spawnorg.append(<32778, -3522, -29173>)
            break
        }
    }
    else if (locationSettings.name == "Artillery")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<0, -170, 0>) //Ang: 0 -170 0
                spawnorg.append(<0, 170, 0>) //Ang: 0 170 0
                spawnorg.append(<0, 170, 0>) //Ang: 0 170 0
                spawnorg.append(<0, -170, 0>) //Ang: 0 -170 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<0, 8, 0>) //Ang: 0 8 0
                spawnorg.append(<0, -8, 0>) //Ang: 0 -8 0
                spawnorg.append(<0, -8, 0>) //Ang: 0 -8 0
                spawnorg.append(<0, 8, 0>) //Ang: 0 8 0
            break
        }
    }
    else if (locationSettings.name == "Airbase")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<0, -70, 0>) //Ang: 0 -70 0
                spawnorg.append(<0, -30, 0>) //Ang: 0 -30 0
                spawnorg.append(<0, -125, 0>) //Ang: 0 -125 0
                spawnorg.append(<0, -20, 0>) //Ang: 0 -20 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<0, 19, 0>) //Ang: 0 19 0
                spawnorg.append(<0, 90, 0>) //Ang: 0 90 0
                spawnorg.append(<0, 44, 0>) //Ang: 0 44 0
                spawnorg.append(<0, 45, 0>) //Ang: 0 45 0
            break
        }
    }
    else if (locationSettings.name == "Relay")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<0, 40, 0>) //Ang: 0 40 0
                spawnorg.append(<0, 35, 0>) //Ang: 0 35 0
                spawnorg.append(<0, 0, 0>) //Ang: 0 0 0
                spawnorg.append(<0, -15, 0>) //Ang: 0 -15 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<0, -135, 0>) //Ang: 0 -135 0
                spawnorg.append(<0, 90, 0>) //Ang: 0 90 0
                spawnorg.append(<0, -160, 0>) //Ang: 0 -160 0
                spawnorg.append(<0, 160, 0>) //Ang: 0 160 0
            break
        }
    }
    else if (locationSettings.name == "WetLands")
    {
        switch(player.GetTeam())
        {
            case TEAM_IMC:
                spawnorg.append(<0, -160, 0>) //Ang: 0 -160 0
                spawnorg.append(<0, 0, 0>) //Ang: 0 0 0
                spawnorg.append(<0, 165, 0>) //Ang: 0 165 0
                spawnorg.append(<0, 135, 0>) //Ang: 0 135 0
            break
            case TEAM_MILITIA:
                spawnorg.append(<0, 50, 0>) //Ang: 0 50 0
                spawnorg.append(<0, 0, 0>) //Ang: 0 0 0
                spawnorg.append(<0, -60, 0>) //Ang: 0 -60 0
                spawnorg.append(<0, 40, 0>) //Ang: 0 40 0
            break
        }
    }

    return spawnorg
}


#endif


// Playlist GET
float function CTF_GetRespawnDelay()                          { return GetCurrentPlaylistVarFloat("respawn_delay", 8) }
float function CTF_Equipment_GetDefaultShieldHP()                        { return GetCurrentPlaylistVarFloat("default_shield_hp", 100) }
float function CTF_GetOOBDamagePercent()                      { return GetCurrentPlaylistVarFloat("oob_damage_percent", 25) }
float function CTF_GetVotingTime()                            { return GetCurrentPlaylistVarFloat("voting_time", 5) }
      
#if SERVER      
bool function CTF_Equipment_GetRespawnKitEnabled()                       { return GetCurrentPlaylistVarBool("respawn_kit_enabled", false) }

StoredWeapon function CTF_Equipment_GetRespawnKit_PrimaryWeapon()
{ 
    return Equipment_GetRespawnKit_Weapon(
        GetCurrentPlaylistVarString("respawn_kit_primary_weapon", "~~none~~"),
        eStoredWeaponType.main,
        WEAPON_INVENTORY_SLOT_PRIMARY_0
    ) 
}
StoredWeapon function CTF_Equipment_GetRespawnKit_SecondaryWeapon()
{ 
    return Equipment_GetRespawnKit_Weapon(
        GetCurrentPlaylistVarString("respawn_kit_secondary_weapon", "~~none~~"),
        eStoredWeaponType.main,
        WEAPON_INVENTORY_SLOT_PRIMARY_1
    )
}
StoredWeapon function CTF_Equipment_GetRespawnKit_Tactical()
{ 
    return Equipment_GetRespawnKit_Weapon(
        GetCurrentPlaylistVarString("respawn_kit_tactical", "~~none~~"),
        eStoredWeaponType.offhand,
        OFFHAND_TACTICAL
    )
}
StoredWeapon function CTF_Equipment_GetRespawnKit_Ultimate()
{ 
    return Equipment_GetRespawnKit_Weapon(
        GetCurrentPlaylistVarString("respawn_kit_ultimate", "~~none~~"),
        eStoredWeaponType.offhand,
        OFFHAND_ULTIMATE
    )
}

StoredWeapon function Equipment_GetRespawnKit_Weapon(string input, int type, int index)
{
    StoredWeapon weapon
    if(input == "~~none~~") return weapon

    array<string> args = split(input, " ")

    if(args.len() == 0) return weapon

    weapon.name = args[0]
    weapon.weaponType = type
    weapon.inventoryIndex = index
    weapon.mods = args.slice(1, args.len())

    return weapon
}
#endif