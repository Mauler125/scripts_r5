// Credits Time !
// 𝕮𝖗𝖎𝖔𝖘𝕮𝖍𝖆𝖓 クリオスちゃん#0221 -- Main
// sal#3261 -- CUSTOM TDM Main
// @Shrugtal -- CUSTOM TDM score ui

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

struct {
    var PlayerList
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
        default: // Yeah I know it's so sad that there are no other maps
            Assert(false, "No Hide and Seek locations found for this map!")
    }

    RegisterSignal( "ClosePlayerListRUI" )
}

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
