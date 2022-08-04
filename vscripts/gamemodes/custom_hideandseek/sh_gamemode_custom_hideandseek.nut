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
const asset WALL_CANYON        = $"mdl/levels_terrain/mp_rr_canyonlands/mil_base_south_runway_02.rmdl"

struct {
} file;

void function Sh_CustomHideAndSeek_Init()
{
    switch(GetMapName())
    {
        case "mp_rr_floppytown":
            NewLocationSpawn(
                NewSpawn(
                    "Floppytown",
                    [
                        NewSpawnLoc(<772, 85, 2846>, <12, 89, 0>),
                        NewSpawnLoc(<502, 437, 2380>, < 15, 89, 0 >)
                    ]
                )
            )
            break
        case "mp_rr_desertlands_64k_x_64k_nx":
        case "mp_rr_desertlands_64k_x_64k":
        {
            NewLocationSpawn(
                NewSpawn(
                    "Desertlands",
                    [
                        NewSpawnLoc(<2769, 10129, -3633>, <3, 103, 0>),
                        NewSpawnLoc(<2731, 10405, -3996>, < -16, 115, 0 >)
                    ]
                )
            )
            #if SERVER
                generateHASWall("mp_rr_desertlands")
            #endif
            break
        }
        case "mp_rr_canyonlands_mu1":
        case "mp_rr_canyonlands_mu1_night":
        case "mp_rr_canyonlands_64k_x_64k":
        {
            NewLocationSpawn(
                NewSpawn(
                    "Canyonlands",
                    [
                        NewSpawnLoc(<25202, -6028, 4742>, <0, 0, 0>),
                        NewSpawnLoc(<25638, -6014, 4336>, < 0, 0, 0 >)
                    ]
                )
            )
            #if SERVER
                generateHASWall("mp_rr_canyonlands")
            #endif
            break
        }
        case "mp_rr_aqueduct_night":
        case "mp_rr_aqueduct":
        {
            NewLocationSpawn(
                NewSpawn(
                    "Aqueduct",
                    [
                        NewSpawnLoc(<713, -3283, 2163>, <0, -90, 0>),
                        NewSpawnLoc(<715, -3788, 542>, < 0, -90, 0 >)
                    ]
                )
            )
            break
        }
        case "mp_rr_arena_composite":
        {
            NewLocationSpawn(
                NewSpawn(
                    "Composite",
                    [
                        NewSpawnLoc(<-957, 5111, 733>, <0, -45, 0>),
                        NewSpawnLoc(<-723, 4892, 188>, < 0, -45, 0 >)
                    ]
                )
            )
            break
            
        }

        default: // Yeah I know it's so sad that there are no other maps
            Assert(false, "No Hide and Seek locations found for this map!")
    }

    RegisterSignal( "ClosePlayerListRUI" )
}

void function generateHASWall(string name)
{
    printt("WallGeneration")
    switch(name)
    {
        case "mp_rr_desertlands":
            generateWall(2, 14, <310, 9120, -4300>, "n", <0,0,0>, name)
            generateWall(2, 11, <310, 9120-350, -4300>, "w", <0, 90, 0>, name)
            generateWall(2, 14, <310 + 350*11, 9120-350, -4300>, "n", <0, 0, 180>, name)
            generateWall(2, 11, <310 + 350, 9120+350*13, -4300>, "w", <0, -90, 0>, name)
            break
        case "mp_rr_canyonlands":
            generateWall(3, 2, <28761, -8323, 2924>, "n", <0,0,180>, name)
            generateWall(3, 2, <23600, -8250, 2924>, "w", <0,90,0>, name)
            generateWall(3, 3, <23600, -3223, 2924>, "w", <0,-90,0>, name)
            generateWall(3, 3, <23000, -8323, 2924>, "n", <0,0,0>, name)

    }
}

void function generateWall(int width, int height, vector origin, string angle, vector angles, string name)
{
    switch(name)
    {
        case "mp_rr_desertlands":
        {
            switch(angle)
            {
                case "n":
                    for(int i = 0; i <= height-1; i++)
                    {
                        for (int j = 0; j <= width-1; j++)
                        {
                            CreateHASModel(BUILDING_PLATFORM_LARGE, origin + <0, 350 * i, 1020*j>, <90,0,0> + angles)
                        }
                    }
                    break
                case "w":
                    for(int i = 0; i <= height-1; i++)
                    {
                        for (int j = 0; j <= width-1; j++)
                        {
                            CreateHASModel(BUILDING_PLATFORM_LARGE, origin + <350 * i, 0, 1020*j>, <90,0,0> + angles)
                        }
                    }
                    break
            }
            break
        }
        case "mp_rr_canyonlands":
        {
            switch(angle)
            {
                case "n":
                    for(int i = 0; i <= height-1; i++)
                    {
                        for (int j = 0; j <= width-1; j++)
                        {
                            CreateHASModel(WALL_CANYON, origin + <1*i, 3000 * i, 1300*j>, <90,0,0> + angles)
                        }
                    }
                    break
                case "w":
                    for(int i = 0; i <= height-1; i++)
                    {
                        for (int j = 0; j <= width-1; j++)
                        {
                            CreateHASModel(WALL_CANYON, origin + <3000 * i, 1*i, 1300*j>, <90,0,0> + angles)
                        }
                    }
                    break
            }
            break
        }
    }
    
    
}

entity function CreateHASModel( asset a, vector pos, vector ang)
{
    entity prop = CreatePropDynamic(a,pos,ang)
    #if SERVER
        prop = CreatePropDynamic(a,pos,ang, SOLID_VPHYSICS, 20000)
    #endif

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
