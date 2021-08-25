// GUN GAME GAMEMODE
//  Made by @Pebbers#9558, @TheyCallMeSpy#1337, @sal#3261 and @Edorion#1761
//
//  This is a modified version of the TDM made so we can have weapon upgrade, balancing when you're not good enough, etc
//  Have fun !!



global function Sh_Gun_Game_Init
global function NewLocationSettings_Gun_Game
global function NewLocPair_Gun_Game
global function NewWeaponKit_Gun_Game

global const LOCATION_CUTSCENE_DURATION_GUN_GAME = 9

global enum eGUNGAMEAnnounce
{
	NONE = 0
	WAITING_FOR_PLAYERS = 1
	ROUND_START = 2
	VOTING_PHASE = 3
	MAP_FLYOVER = 4
	IN_PROGRESS = 5
}


global struct LocPair_Gun_Game
{
    vector origin = <0, 0, 0>
    vector angles = <0, 0, 0>
}

global struct LocationSettings_Gun_Game {
    string name
    array<LocPair_Gun_Game> spawns
    vector cinematicCameraOffset
}

global struct WeaponKit_Gun_Game
{
    string weapon
    array<string> mods
    int slot
}

struct {
    LocationSettings_Gun_Game &selectedLocation
    array choices
    array<LocationSettings_Gun_Game> locationSettings
    var scoreRui

} file;




void function Sh_Gun_Game_Init()
{


    // Map locations

    switch(GetMapName())
    {
    case "mp_rr_canyonlands_staging":
        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Firing Range",
                [
                    NewLocPair_Gun_Game(<33560, -8992, -29126>, <0, 90, 0>),
					NewLocPair_Gun_Game(<34525, -7996, -28242>, <0, 100, 0>),
                    NewLocPair_Gun_Game(<33507, -3754, -29165>, <0, -90, 0>),
					NewLocPair_Gun_Game(<34986, -3442, -28263>, <0, -113, 0>)
                ],
                <0, 0, 3000>
            )
        )
        break

	case "mp_rr_canyonlands_mu1":
	case "mp_rr_canyonlands_mu1_night":
    case "mp_rr_canyonlands_64k_x_64k":
        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Skull Town",
                [
                    NewLocPair_Gun_Game(<-9320, -13528, 3167>, <0, -100, 0>),
                    NewLocPair_Gun_Game(<-7544, -13240, 3161>, <0, -115, 0>),
                    NewLocPair_Gun_Game(<-10250, -18320, 3323>, <0, 100, 0>),
                    NewLocPair_Gun_Game(<-13261, -18100, 3337>, <0, 20, 0>)
                ],
                <0, 0, 3000>
            )
        )

        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Little Town",
                [
                    NewLocPair_Gun_Game(<-30190, 12473, 3186>, <0, -90, 0>),
                    NewLocPair_Gun_Game(<-28773, 11228, 3210>, <0, 180, 0>),
                    NewLocPair_Gun_Game(<-29802, 9886, 3217>, <0, 90, 0>),
                    NewLocPair_Gun_Game(<-30895, 10733, 3202>, <0, 0, 0>)
                ],
                <0, 0, 3000>
            )
        )

        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Market",
                [
                    NewLocPair_Gun_Game(<-110, -9977, 2987>, <0, 0, 0>),
                    NewLocPair_Gun_Game(<-1605, -10300, 3053>, <0, -100, 0>),
                    NewLocPair_Gun_Game(<4600, -11450, 2950>, <0, 180, 0>),
                    NewLocPair_Gun_Game(<3150, -11153, 3053>, <0, 100, 0>)
                ],
                <0, 0, 3000>
            )
        )

        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Runoff",
                [
                    NewLocPair_Gun_Game(<-23380, 9634, 3371>, <0, 90, 0>),
                    NewLocPair_Gun_Game(<-24917, 11273, 3085>, <0, 0, 0>),
                    NewLocPair_Gun_Game(<-23614, 13605, 3347>, <0, -90, 0>),
                    NewLocPair_Gun_Game(<-24697, 12631, 3085>, <0, 0, 0>)
                ],
                <0, 0, 3000>
            )
        )

        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Thunderdome",
                [
                    NewLocPair_Gun_Game(<-20216, -21612, 3191>, <0, -67, 0>),
                    NewLocPair_Gun_Game(<-16035, -20591, 3232>, <0, -133, 0>),
                    NewLocPair_Gun_Game(<-16584, -24859, 2642>, <0, 165, 0>),
                    NewLocPair_Gun_Game(<-19019, -26209, 2640>, <0, 65, 0>)
                ],
                <0, 0, 2000>
            )
        )

        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Water Treatment",
                [
                    NewLocPair_Gun_Game(<5583, -30000, 3070>, <0, 0, 0>),
                    NewLocPair_Gun_Game(<7544, -29035, 3061>, <0, 130, 0>),
                    NewLocPair_Gun_Game(<10091, -30000, 3070>, <0, 180, 0>),
                    NewLocPair_Gun_Game(<8487, -28838, 3061>, <0, -45, 0>)
                ],
                <0, 0, 3000>
            )
        )


        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "The Pit",
                [
                    NewLocPair_Gun_Game(<-18558, 13823, 3605>, <0, 20, 0>),
                    NewLocPair_Gun_Game(<-16514, 16184, 3772>, <0, -77, 0>),
                    NewLocPair_Gun_Game(<-13826, 15325, 3749>, <0, 160, 0>),
                    NewLocPair_Gun_Game(<-16160, 14273, 3770>, <0, 101, 0>)
                ],
                <0, 0, 7000>
            )
        )


        Shared_RegisterLocation(
            NewLocationSettings_Gun_Game(
                "Airbase",
                [
                    NewLocPair_Gun_Game(<-24140, -4510, 2583>, <0, 90, 0>),
                    NewLocPair_Gun_Game(<-28675, 612, 2600>, <0, 18, 0>),
                    NewLocPair_Gun_Game(<-24688, 1316, 2583>, <0, 180, 0>),
                    NewLocPair_Gun_Game(<-26492, -5197, 2574>, <0, 50, 0>)
                ],
                <0, 0, 3000>
            )
        )
        break

        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
	        Shared_RegisterLocation(
                NewLocationSettings_Gun_Game(
                    "Refinery",
                    [
                        NewLocPair_Gun_Game(<22970, 27159, -4612.43>, <0, 135, 0>),
                        NewLocPair_Gun_Game(<20430, 26361, -4140>, <0, 135, 0>),
                        NewLocPair_Gun_Game(<19142, 30982, -4612>, <0, -45, 0>),
                        NewLocPair_Gun_Game(<18285, 28502, -4140>, <0, -45, 0>)
                    ],
                    <0, 0, 6500>
                )
            )

            Shared_RegisterLocation(
                NewLocationSettings_Gun_Game(
                    "Geyser Cave",
                    [
                        NewLocPair_Gun_Game(<26330, -3506, -3933>, <8, -177, 0>),
                        NewLocPair_Gun_Game(<24159, -4296, -3915>, <-2.5, 92, 0>),
                        NewLocPair_Gun_Game(<22322, -3326, -3920>, <0, 0, 0>),
                        NewLocPair_Gun_Game(<24199, -2370, -3914>, <0, -90, 0>)
                    ],
                    <0, 0, 250>
                )
            )

            Shared_RegisterLocation(
                NewLocationSettings_Gun_Game(
                    "TTV Building",
                    [
                        NewLocPair_Gun_Game(<11393, 5477, -4289>, <0, 90, 0>),
                        NewLocPair_Gun_Game(<12027, 7121, -4290>, <0, -120, 0>),
                        NewLocPair_Gun_Game(<8105, 6156, -4266>, <0, -45, 0>),
                        NewLocPair_Gun_Game(<7965.0, 5976.0, -4266.0>, <0, -135, 0>)
                    ],
                    <0, 0, 3000>
                )
            )

            Shared_RegisterLocation(
                NewLocationSettings_Gun_Game(
                    "Thermal Station",
                    [
                        NewLocPair_Gun_Game(<-20091, -17683, -3984>, <0, -90, 0>),
						NewLocPair_Gun_Game(<-22919, -20528, -4010>, <0, 0, 0>),
                        NewLocPair_Gun_Game(<-20109, -23193, -4252>, <0, 90, 0>),
						NewLocPair_Gun_Game(<-17140, -20710, -3973>, <0, -180, 0>)
                    ],
                    <0, 0, 11000>
                )
            )

            Shared_RegisterLocation(
                NewLocationSettings_Gun_Game(
                    "Lava Fissure",
                    [
                        NewLocPair_Gun_Game(<-26550, 13746, -3048>, <0, -134, 0>),
						NewLocPair_Gun_Game(<-28877, 12943, -3109>, <0, -88.70, 0>),
                        NewLocPair_Gun_Game(<-29881, 9168, -2905>, <-1.87, -2.11, 0>),
						NewLocPair_Gun_Game(<-27590, 9279, -3109>, <0, 90, 0>)
                    ],
                    <0, 0, 2500>
                )
            )

            Shared_RegisterLocation(
                NewLocationSettings_Gun_Game(
                    "The Dome",
                    [
                        NewLocPair_Gun_Game(<17445.83, -36838.45, -2160.64>, <-2.20, -37.85, 0>),
						NewLocPair_Gun_Game(<17405.53, -39860.60, -2248>, <-6, -52, 0>),
                        NewLocPair_Gun_Game(<21700.48, -40169, -2164.30>, <2, 142, 0>),
						NewLocPair_Gun_Game(<20375.39, -36068.25, -2248>, <-1, -128, 0>)
                    ],
                    <0, 0, 2850>
                )
            )


        default:
            Assert(false, "No TDM locations found for map!")
    }

    //Client Signals
    RegisterSignal( "CloseScoreRUI" )

}

WeaponKit_Gun_Game function NewWeaponKit_Gun_Game(string weapon, array<string> mods, int slot)
{
    WeaponKit_Gun_Game weaponKit
    weaponKit.weapon = weapon
    weaponKit.mods = mods
    weaponKit.slot = slot

    return weaponKit
}

LocPair_Gun_Game function NewLocPair_Gun_Game(vector origin, vector angles)
{
    LocPair_Gun_Game locPair
    locPair.origin = origin
    locPair.angles = angles

    return locPair
}

LocationSettings_Gun_Game function NewLocationSettings_Gun_Game(string name, array<LocPair_Gun_Game> spawns, vector cinematicCameraOffset)
{
    LocationSettings_Gun_Game locationSettings
    locationSettings.name = name
    locationSettings.spawns = spawns
    locationSettings.cinematicCameraOffset = cinematicCameraOffset

    return locationSettings
}


void function Shared_RegisterLocation(LocationSettings_Gun_Game locationSettings)
{
    #if SERVER
    _RegisterLocation_Gun_Game(locationSettings)
    #endif


    #if CLIENT
    Cl_RegisterLocation_Gun_Game(locationSettings)
    #endif


}


