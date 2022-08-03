// Credits Time !
// 𝕮𝖗𝖎𝖔𝖘𝕮𝖍𝖆𝖓 クリオスちゃん#0221 -- Mode Main + Map Builder
// Julefox#0050 -- Floppytown Map Builder
// sal#3261 -- CUSTOM TDM Main
// @Shrugtal -- CUSTOM TDM score ui
// AyeZee#6969 -- Better understanding of how gamemodes work (CTF)

global function Sh_CustomHideAndSeek_Init

global function NewSpawnLoc

global enum eHASAnnounce
{
	NONE = 0
	WAITING_FOR_PLAYERS = 1
	ROUND_START_SEEKER = 2
	ROUND_START_HIDDEN = 3
	HIDETOSEEK = 4
	END_SEEKER = 5
	END_HIDDEN = 6
    NEW_SEEKER = 7
    SEEKER_SEARCH = 8
    SEEKER_DISCONNECTED = 9
    WAITFORPLAYER = 10
}

global enum eHASLegends
{
    HIDDEN = 0
    SEEKER = 1
}

global struct SpawnLoc
{
    vector origin = <0, 0, 0>
    vector angles = <0, 0, 0>
}

global struct LocationSettingsHAS
{
    string name
    array<SpawnLoc> spawns
}

const asset BUILDING_PLATFORM_LARGE        = $"mdl/desertlands/construction_bldg_platform_01.rmdl"

struct {
} file;

void function Sh_CustomHideAndSeek_Init()
{
    switch(GetMapName())
    {
        case "mp_rr_floppytown":
            NewLocationSpawn(
                NewSpawn( //For seeker
                    "Floppytown",
                    [
                        NewSpawnLoc(<772, 85, 2846>, <12, 89, 0>),
                        NewSpawnLoc(<502, 437, 2380>, < 15, 89, 0 >)
                    ]
                )
            )
        case "mp_rr_desertlands_64k_x_64k_nx":
        case "mp_rr_desertlands_64k_x_64k":
        {
            NewLocationSpawn(
                NewSpawn( //For seeker
                    "Desertlands",
                    [
                        NewSpawnLoc(<772, 85, 2846>, <12, 89, 0>),
                        NewSpawnLoc(<502, 437, 2380>, < 15, 89, 0 >)
                    ]
                )
            )
            CreateHASModel(BUILDING_PLATFORM_LARGE, <310, 9100, -4200>, <90,0,0>)
            CreateHASModel(BUILDING_PLATFORM_LARGE, <310, 9100, -3200>, <90,0,0>)
            CreateHASModel(BUILDING_PLATFORM_LARGE, <310, 9100, -2200>, <90,0,0>)
        }

        default: // Yeah I know it's so sad that there are no other maps
            Assert(false, "No Hide and Seek locations found for this map!")
    }

    RegisterSignal( "ClosePlayerListRUI" )
}

entity function CreateHASModel( asset a, vector pos, vector ang)
{
    entity prop = CreatePropDynamic( a, pos, ang)

    //FLOPPYTOWN_ENTITIES.append( prop )

return prop }

SpawnLoc function NewSpawnLoc(vector origin, vector angles)
{
    SpawnLoc spawnLoc
    spawnLoc.origin = origin
    spawnLoc.angles = angles

    return spawnLoc
}

LocationSettingsHAS function NewSpawn(string name, array<SpawnLoc> spawnloc)
{
    LocationSettingsHAS spawn
    spawn.name = name
    spawn.spawns = spawnloc
    
    return spawn
}

void function NewLocationSpawn(LocationSettingsHAS seekerSpawn)
{
    #if SERVER
    _HasRegisterLocation(seekerSpawn)
    #endif


    #if CLIENT
    Cl_RegisterLocationHAS(seekerSpawn)
    #endif
}
