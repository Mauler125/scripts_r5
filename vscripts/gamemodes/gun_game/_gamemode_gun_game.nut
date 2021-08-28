// GUN GAME GAMEMODE
//  Made by @Pebbers#9558, @TheyCallMeSpy#1337, @sal#3261 and @Edorion#1761
//
//  This is a modified version of the TDM made so we can have weapon upgrade, balancing when you're not good enough, etc
//  Have fun !!





global function _Gun_Game_Init


//ALREADY EXISTS IN sh_gamemode_custom_tdm, tho for a weird reason I have to duplicate it
global function _RegisterLocation_Gun_Game


string ALTERNATOR = "mp_weapon_alternator_smg"
string CHARGE_RIFLE = "mp_weapon_defender"
string DEVOTION = "mp_weapon_esaw"
string EPG = "mp_weapon_epg"
string EVA = "mp_weapon_shotgun"
string FLATLINE = "mp_weapon_vinson"
string G7 = "mp_weapon_g2"
string HAVOC = "mp_weapon_energy_ar"
string HEMLOK = "mp_weapon_hemlok"
string KRABER = "mp_weapon_sniper"
string LONGBOW = "mp_weapon_dmr"
string LSTAR = "mp_weapon_lstar"
string MASTIFF = "mp_weapon_mastiff"
string MOZAMBIQUE = "mp_weapon_shotgun_pistol"
string P2020 = "mp_weapon_semipistol"
string PEACEKEEPER = "mp_weapon_energy_shotgun"
string PROWLER = "mp_weapon_pdw"
string R301 = "mp_weapon_rspn101"
string R99 = "mp_weapon_r97"
string RE45 = "mp_weapon_autopistol"
string SPITFIRE = "mp_weapon_lmg"
string TRIPLE_TAKE = "mp_weapon_doubletake"
string WINGMAN = "mp_weapon_wingman"
string MELEE = "mp_weapon_melee_survival"

// ARMORS
string WHITE_SHIELD = "armor_pickup_lv1"
string BLUE_SHIELD = "armor_pickup_lv2"
string PURPLE_SHIELD = "armor_pickup_lv3"


array<string> GUN_LIST =[
    "mp_weapon_shotgun",
    "mp_weapon_r97",
    "mp_weapon_lmg",
    "mp_weapon_energy_shotgun",
    "mp_weapon_rspn101",
    "mp_weapon_wingman",
    "mp_weapon_pdw",
    "mp_weapon_hemlok",
    "mp_weapon_esaw",
    "mp_weapon_energy_ar",
    "mp_weapon_lstar",
    "mp_weapon_alternator_smg",
    "mp_weapon_doubletake",
    "mp_weapon_dmr",
    "mp_weapon_g2",
    "mp_weapon_shotgun_pistol",
    "mp_weapon_autopistol",
    "mp_weapon_semipistol",
    "mp_weapon_sniper",
    "mp_weapon_melee_survival"
]


array<string> ATTACHMENTS_LEVEL1 =[
    "optic_cq_hcog_classic",
    "barrel_stabilizer_l1",
    "stock_tactical_l1",
    "stock_sniper_l1",
    "shotgun_bolt_l1",
    "bullets_mag_l1",
    "highcal_mag_l1",
    "energy_mag_l1"
]

array<string> ATTACHMENTS_LEVEL2 =[
    "optic_cq_holosight_variable",
    "barrel_stabilizer_l2",
    "stock_tactical_l2",
    "stock_sniper_l2",
    "shotgun_bolt_l2",
    "bullets_mag_l2",
    "highcal_mag_l2",
    "energy_mag_l2"
]

array<string> ATTACHMENTS_LEVEL3 =[
    "optic_cq_hcog_bruiser",
    "barrel_stabilizer_l3",
    "stock_tactical_l3",
    "stock_sniper_l3",
    "shotgun_bolt_l3",
    "bullets_mag_l3",
    "highcal_mag_l3",
    "energy_mag_l3",
    "hopup_highcal_rounds",
    "hopup_energy_choke"
]

array<string> ATTACHMENTS_LEVEL4 =[
    "optic_cq_hcog_bruiser",
    "barrel_stabilizer_l4_flash_hider",
    "stock_tactical_l3",
    "stock_sniper_l3",
    "shotgun_bolt_l3",
    "bullets_mag_l3",
    "highcal_mag_l3",
    "energy_mag_l3",
    "hopup_double_tap",
    "hopup_turbocharger",
    "hopup_highcal_rounds",
    "hopup_energy_choke",
    "hopup_double_tap",
    "hopup_unshielded_dmg"
]

struct {
    int tdmState = eGameState.Playing
    array<entity> playerSpawnedProps
    LocationSettings_Gun_Game& selectedLocation
    array<LocationSettings_Gun_Game> locationSettings

    entity winner
} file






//
// INIT
//
void function _Gun_Game_Init()
{
    //In lava fissure you can freefall, so we have to initialize particles to avoid crashes
	SurvivalFreefall_Init()

    AddCallback_OnPlayerKilled(void function(entity victim, entity attacker, var damageInfo) {thread SV_OnPlayerDied(victim, attacker, damageInfo)})
    AddCallback_OnClientConnected( void function(entity player) { thread SV_OnPlayerConnected(player) } )

    AddClientCommandCallback("gg_next_round", ClientCommand_NextRound)
    AddClientCommandCallback("gg_clear_invincible_all", ClientCommand_ClearInvincibleAll)
    AddClientCommandCallback("gg_clear_invincible", ClientCommand_ClearInvincible)
    AddClientCommandCallback("gg_remove_passive", ClientCommand_RemovePassive)
    AddClientCommandCallback("gg_add_passive", ClientCommand_AddPassive)

    thread RunTDM()
}

//
// Used to set spawn location
//
void function _RegisterLocation_Gun_Game(LocationSettings_Gun_Game locationSettings)
{
    file.locationSettings.append(locationSettings)
}








//
//
// SERVER EVENTS
//
//

//Lobby location for each map
LocPair_Gun_Game function SV_GetVotingLocation()
{
    switch(GetMapName())
    {
        case "mp_rr_canyonlands_staging":
            return NewLocPair_Gun_Game(<26794, -6241, -27479>, <0, 0, 0>)
        case "mp_rr_canyonlands_64k_x_64k":
        case "mp_rr_canyonlands_mu1":
        case "mp_rr_canyonlands_mu1_night":
            return NewLocPair_Gun_Game(<-6252, -16500, 3296>, <0, 0, 0>)
        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
            return NewLocPair_Gun_Game(<1763, 5463, -3145>, <5, -95, 0>)
        default:
            Assert(false, "No voting location for the map!")
    }
    unreachable
}

//Used so we can destroy all unwanted objects when game end
void function SV_OnPropDynamicSpawned(entity prop)
{
    file.playerSpawnedProps.append(prop)
}

//Set all player vars and stuff when he's connected (passive, gamemode info)
void function SV_OnPlayerConnected(entity player)
{
    wait 2

	if(!IsValidPlayer(player))
        return

  printl("DEBUG: Player Connected and is valid")

    //Give passive regen (pilot blood)
    GivePassive(player, ePassives.PAS_PILOT_BLOOD)

    DecideRespawnPlayer(player)
    TpPlayerToSpawnPoint(player)
	Reset(player)
    PlayerRestoreHP(player, 100)
    PlayerRestoreShields(player, player.GetShieldHealthMax())
    SetPlayerSettings(player, GUN_GAME_PLAYER_SETTINGS)


    switch(GetGameState())
    {
        case eGameState.WaitingForPlayers:
            //player.FreezeControlsOnServer()
            break
        case eGameState.Playing:
            player.UnfreezeControlsOnServer()
            Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_DoAnnouncement", 5, eGUNGAMEAnnounce.ROUND_START)
            break
        case eGameState.WinnerDetermined:
            player.FreezeControlsOnServer()
            break
        default:
            break
    }
}


//Used to upgrade weapons, shield
void function SV_OnPlayerDied(entity victim, entity attacker, var damageInfo)
{

    PlayerStartSpectating( victim, attacker )

    //Upgrade attacker
	UpgradeWeapons(attacker)


    //Resets shield
    UpgradeShields(attacker, false)
    UpgradeShields(victim, true)

    switch(GetGameState())
    {
        case eGameState.Playing:

            //Get current weapons
            string weapon0 = SURVIVAL_GetWeaponBySlot(victim, 0)
            string weapon1 = SURVIVAL_GetWeaponBySlot(victim, 1)

            wait GetCurrentPlaylistVarFloat("respawn_delay", 3)

            //If victim is indeed a player
            if(IsValidPlayer(victim))
            {

                //Respawn him
                DecideRespawnPlayer( victim )

                //Sets consecutive death vars
                victim.SetPlayerGameStat( PGS_DEATHS, victim.GetPlayerGameStat( PGS_DEATHS ) + 1 )

                //Sets his weapon, and since he died he'll have attachments based on hom many consecutive deaths he has
                PlayerRestoreWeapons(victim, weapon0, weapon1, GetAttachmentsBasedOnLevel(weapon0, victim.GetPlayerGameStat( PGS_DEATHS )))


                //Set gamemode settings
                SetPlayerSettings(victim, GUN_GAME_PLAYER_SETTINGS)

                //Heal
                PlayerRestoreHP(victim, 100)
                PlayerRestoreShields(victim, victim.GetShieldHealthMax())

                //Spawns him in the correct place
                TpPlayerToSpawnPoint(victim)

                //Make him invicible for 5 seconds
                thread GrantSpawnImmunity(victim, 5)
            }


            //If attacker is indeed a player and is not himself
            if(IsValidPlayer(attacker) && IsAlive(attacker) && attacker != victim)
            {
                //Reset death streak
                attacker.SetPlayerGameStat( PGS_DEATHS, 0)
            }

            //Tell each player to update their Score RUI
            ResetUI()
            break
    default:
        break
    }
}



//Returns a valid spawn point based on team and how many players are near the spawn point
LocPair_Gun_Game function SV_GetAppropriateSpawnLocation(entity player)
{
    int ourTeam = player.GetTeam()

    LocPair_Gun_Game selectedSpawn = SV_GetVotingLocation()

    switch(GetGameState())
    {
        //If we're in game
        case eGameState.Playing:
            float maxDistToEnemy = 0
            foreach(spawn in file.selectedLocation.spawns)
            {
                vector enemyOrigin = GetClosestEnemyToOrigin(spawn.origin, ourTeam)
                float distToEnemy = Distance(spawn.origin, enemyOrigin)

                if(distToEnemy > maxDistToEnemy)
                {
                    maxDistToEnemy = distToEnemy
                    selectedSpawn = spawn
                }
            }
            break
        //If not in game, return default lobby location to avoid any bugs
        default:
            selectedSpawn = SV_GetVotingLocation()
            break
    }
    return selectedSpawn
}











//
//
// MAIN GAMEMODE FUNCTIONS
//
//

//Main function
void function RunTDM()
{
    WaitForGameState(eGameState.Playing)
    AddSpawnCallback("prop_dynamic", SV_OnPropDynamicSpawned)

    SetGameState(eGameState.MapVoting)
    //For an unlimited time, play the gamemode
    for(  )
    {
        //Vote for the map
        VotingPhase()
        //Then start the game. When finished, do this all over again
        StartRound()
    }
    WaitForever()
}



//Executed before the match starts. Selects a location after spawning each player in the "lobby"
void function VotingPhase()
{
    WaitForGameState(eGameState.MapVoting)

    //Remove all props created by players on the maps
    DestroyPlayerProps()

    //Place each player in the lobby and freezes them
    foreach(player in GetPlayerArray())
    {
        if(!IsValidPlayer(player)) continue
        //Respawn
        DecideRespawnPlayer(player)
        TpPlayerToSpawnPoint(player)

        //Make the player unable to do anything
        player.SetInvulnerable()

		//For some reason this disable abilities and we cant enable them again
	    //HolsterAndDisableWeapons(player)


        //launch the cinematic
        thread Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_DoAnnouncement", 2, eGUNGAMEAnnounce.VOTING_PHASE)

        //Unfreezes controls so the player can at least move
        player.UnfreezeControlsOnServer()

        //Gives default weapon so the user has something to do while waiting for the game to start
        Reset(player)
    }

    //Voting time, even tho this isn't technically a vote since it's still random. Taken from custom_tdm
    int waitTime = GetCurrentPlaylistVarInt("voting_time", 10)

    for(int i = waitTime  i > 0  i-=1) {
        foreach(player in GetPlayerArray()) {
            if(!IsValidPlayer(player)) continue
            thread Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_DoCountDown", i)
            EmitSoundOnEntity( player, "UI_Survival_Intro_LaunchCountDown_10Seconds" )
        }
        wait 1
    }



    int choice = RandomIntRangeInclusive(0, file.locationSettings.len() - 1)

    file.selectedLocation = file.locationSettings[choice]

    //Send the location to each player
    foreach(player in GetPlayerArray())
    {
        if(!IsValidPlayer(player)) continue
        thread Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_SetSelectedLocation", choice)
    }

    SetGameState(eGameState.Playing)
}


//Called when game start. Contains main game loop
void function StartRound()
{
    SetGameState(eGameState.Playing)

    foreach(player in GetPlayerArray())
    {
        if(!IsValidPlayer(player)) continue

        //Resets each player with default weapon, stat, etc
		Reset(player)
        player.ClearInvulnerable()

        //Freeze during cinematic
        player.FreezeControlsOnServer()

        //Play cinematic
        thread Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_DoLocationIntroCutscene")
        thread Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_AddWinningSquadData", -1, player.GetEncodedEHandle())
        thread ScreenFadeToFromBlack(player)
    }
    wait 1

    foreach(player in GetPlayerArray())
    {
        if(!IsValidPlayer(player)) continue

        //Reset all player location
        DecideRespawnPlayer(player)
        //Make them go to their spawn point
        TpPlayerToSpawnPoint(player)
        //Launch beginning cinematic
        Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_DoAnnouncement", 4, eGUNGAMEAnnounce.MAP_FLYOVER)
    }


    //Wait for the cinematic to end
    wait LOCATION_CUTSCENE_DURATION_GUN_GAME
    wait 2

    //For all players
    foreach(player in GetPlayerArray())
    {
        if(!IsValidPlayer(player)) continue

        Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_DoAnnouncement", 5, eGUNGAMEAnnounce.ROUND_START)

        //For some reason this disable abilities and we cant enable them again
        //DeployAndEnableWeapons(player)

        player.UnfreezeControlsOnServer()

        PlayerRestoreHP(player, 100)
        PlayerRestoreShields(player, player.GetShieldHealthMax())
        player.ClearInvulnerable()
    }


    float endTime = Time() + GetCurrentPlaylistVarInt("round_time", 999999)

    //Main loop, will continue until winner is decided
    while( Time() <= endTime )
	{
        if(GetGameState() == eGameState.WinnerDetermined) {

            foreach( entity player in GetPlayerArray() )
            {
                //Stop everything
                player.SetInvulnerable()
                player.FreezeControlsOnServer()

                //For some reason this disable abilities and we cant enable them again
	    	    //HolsterAndDisableWeapons(player)

                //Play win sound
                thread EmitSoundOnEntityOnlyToPlayer( player, player, "diag_ap_aiNotify_winnerFound" )
            }

            ResetAllPlayerStats()
            break
        }
		WaitFrame()
	}


    thread threadedVictory()
    //SetGameState(eGameState.MapVoting)
}







//
//
// UTILITY
//
//

void function DestroyPlayerProps()
{
    foreach(prop in file.playerSpawnedProps)
    {
        if(IsValid(prop))
            prop.Destroy()
    }
    file.playerSpawnedProps.clear()
}


void function ScreenFadeToFromBlack(entity player, float fadeTime = 1, float holdTime = 1)
{
    if( IsValidPlayer( player ) )
        ScreenFadeToBlack(player, fadeTime / 2, holdTime / 2)
    wait fadeTime
    if( IsValidPlayer( player ) )
        ScreenFadeFromBlack(player, fadeTime / 2, holdTime / 2)
}


//Get closest ennemy distance from point
vector function GetClosestEnemyToOrigin(vector origin, int ourTeam)
{
    float minDist = -1
    vector enemyOrigin = <0, 0, 0>

    foreach(player in GetPlayerArray_Alive())
    {
        if(player.GetTeam() == ourTeam) continue

        float dist = Distance(player.GetOrigin(), origin)
        if(dist < minDist || minDist < 0)
        {
            minDist = dist
            enemyOrigin = player.GetOrigin()
        }
    }

    return enemyOrigin
}


//Self explanatory
void function TpPlayerToSpawnPoint(entity player)
{

	LocPair_Gun_Game loc = SV_GetAppropriateSpawnLocation(player)

    player.SetOrigin(loc.origin)
    player.SetAngles(loc.angles)


    PutEntityInSafeSpot( player, null, null, player.GetOrigin() + <0,0,128>, player.GetOrigin() )
}

//Restore shield health by X amount
void function PlayerRestoreShields(entity player, int shields)
{
    if(IsValidPlayer(player) && IsAlive( player ))
        player.SetShieldHealth(clamp_gun_game(shields, 0, player.GetShieldHealthMax()))
}

void function PlayerRestoreHP(entity player, int health)
{
    if(IsValidPlayer(player) && IsAlive( player ))
        player.SetHealth( health )
}

int function clamp_gun_game(int value, int min, int max) {
    if(value < min) return min
    else if (value > max) return max
    else return value

    unreachable
}

//Restore weapon with given attachments (if there's one)
void function PlayerRestoreWeapons(entity player, string weapon0, string weapon1, array<string> mods1 = [], array<string> mods2 = [])
{
    if(IsValid(weapon0) && weapon0 != "")
    {
        player.GiveWeapon(weapon0, WEAPON_INVENTORY_SLOT_PRIMARY_0, mods1)
    }
    if(IsValid(weapon1) && weapon1 != "")
    {
        player.GiveWeapon_NoDeploy(weapon1, WEAPON_INVENTORY_SLOT_PRIMARY_1, mods2)
    }
}


void function GrantSpawnImmunity(entity player, float duration)
{
    if(!IsValidPlayer(player)) return
    player.SetInvulnerable()
    wait duration

    //Check if player is valid again because he could have disconnected
    if(!IsValidPlayer(player)) return
    player.ClearInvulnerable()
}


//Upgrade shield
void function UpgradeShields(entity player, bool died) {

    if (!IsValidPlayer(player)) return

    //If player to upgrade died, then dont do killstreak upgrade, just reset their shield
    if (died) {
        player.SetPlayerGameStat( PGS_TITAN_KILLS, 0 )
        Inventory_SetPlayerEquipment(player, WHITE_SHIELD, "armor")
    } else {
        player.SetPlayerGameStat( PGS_TITAN_KILLS, player.GetPlayerGameStat( PGS_TITAN_KILLS ) + 1)

        switch (player.GetPlayerGameStat( PGS_TITAN_KILLS )) {
	    	case 1:
                Inventory_SetPlayerEquipment(player, WHITE_SHIELD, "armor")
                break
            case 2:
            case 3:
                Inventory_SetPlayerEquipment(player, BLUE_SHIELD, "armor")
                break
            default:
                Inventory_SetPlayerEquipment(player, PURPLE_SHIELD, "armor")
                break
        }
    }



    PlayerRestoreShields(player, player.GetShieldHealthMax())
    PlayerRestoreHP(player, 100)
}


//Upgrade weapons to the next level
void function UpgradeWeapons(entity player)
{
    printt(player)
    //Always check if entity is a player
	if (!player.IsPlayer())
		return



    int nextGun = player.GetPlayerGameStat( PGS_KILLS )
    printt(nextGun)

    //If the player has reached weapon number limit
    if (nextGun >= GUN_LIST.len()) {
        foreach( entity player_TMP in GetPlayerArray() )
        {
            thread EmitSoundOnEntityOnlyToPlayer( player_TMP, player_TMP, "diag_ap_aiNotify_winnerFound" )
        }
        file.winner = player
        SetGameState(eGameState.WinnerDetermined)
        return
    }

    //Gives the player next weaponw
    SetGun(player, GetNextGun(nextGun))
}


//Returns all attachments compatible with weaponName based on level
array<string> function GetAttachmentsBasedOnLevel(string weaponName, int level) {

    //We execute the function to find attachments based on lose streak (consecutive deaths)
    switch (level) {
        case 0:
        return []
            break
        case 1:
            return GetCompatibleAttachmentFromList(weaponName, ATTACHMENTS_LEVEL1)
            break
        case 2:
            return GetCompatibleAttachmentFromList(weaponName, ATTACHMENTS_LEVEL2)
            break
        case 3:
            return GetCompatibleAttachmentFromList(weaponName, ATTACHMENTS_LEVEL3)
            break
        default:
            return GetCompatibleAttachmentFromList(weaponName, ATTACHMENTS_LEVEL4)
            break
    }

    unreachable
}

//Return all valid attachment for weaponName that are in attachments
array<string> function GetCompatibleAttachmentFromList(string weaponName, array<string> attachments) {

    array<string> attachmentsToReturn = []
    foreach (attachment in attachments) {
        print(attachmentsToReturn)
        if (CanAttachToWeapon(attachment, weaponName)) attachmentsToReturn.append(attachment)
    }

    return attachmentsToReturn
}


//Self explanatory
void function ResetAllPlayerStats() {
    foreach(player in GetPlayerArray()) {
        if(!IsValidPlayer(player)) continue
        ResetPlayerStats(player)
    }
}

void function ResetUI() {
    foreach(player in GetPlayerArray()) {
        if(!IsValidPlayer(player)) continue
        Remote_CallFunction_NonReplay(player, "ServerCallback_Gun_Game_PlayerKilled", GetBestPlayer(), GetBestPlayerScore())
    }
}

void function ResetPlayerStats(entity player) {
    player.SetPlayerGameStat( PGS_SCORE, 0 )
    player.SetPlayerGameStat( PGS_DEATHS, 0)
    player.SetPlayerGameStat( PGS_TITAN_KILLS, 0)
    player.SetPlayerGameStat( PGS_KILLS, 0)
    player.SetPlayerGameStat( PGS_PILOT_KILLS, 0)
    player.SetPlayerGameStat( PGS_ASSISTS, 0)
    player.SetPlayerGameStat( PGS_ASSAULT_SCORE, 0)
    player.SetPlayerGameStat( PGS_DEFENSE_SCORE, 0)
    player.SetPlayerGameStat( PGS_ELIMINATED, 0)
}

//Used in the beginning of the match, set base weapon and reset stats
void function Reset(entity player) {
    SetGun(player, FLATLINE)
    ResetAllPlayerStats()
    UpgradeShields(player, true)
}

void function SetGun( entity ent, string weaponName, array<string> mods = [] )
{
	TakePrimaryWeapon( ent )
	if ( weaponName != "") {
		ent.GiveWeapon( weaponName, WEAPON_INVENTORY_SLOT_ANY, mods)
		ent.SetActiveWeaponByName( eActiveInventorySlot.mainHand, weaponName )
	}
}

string function GetNextGun(int index) {
    if (index >= GUN_LIST.len() || index < 0) {
        printt("INDEX OVERFLOW _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_")
        return FLATLINE
    }

    return GUN_LIST[index]
}

int function GetBestPlayerScore() {
    int bestScore = 0
    foreach(player in GetPlayerArray()) {
        if(!IsValidPlayer(player)) continue
        if (player.GetPlayerGameStat( PGS_KILLS ) > bestScore) bestScore = player.GetPlayerGameStat( PGS_KILLS )
    }

    return bestScore
}

entity function GetBestPlayer() {
    int bestScore = 0
    entity bestPlayer
    foreach(player in GetPlayerArray()) {
        if(!IsValidPlayer(player)) continue
        if (player.GetPlayerGameStat( PGS_KILLS ) > bestScore) {
            bestScore = player.GetPlayerGameStat( PGS_KILLS )
            bestPlayer = player
        }
    }

    return bestPlayer
}




//
//
// VICTORY SCREEN
//
//

//Thanks to @Pebbers#9558 for extracting this code from br !!!
void function threadedVictory() {

    //If there is a winner
    if (file.winner != null) {
        //Launch end screen ("You are the champion") for each player
	    foreach ( playerO in GetPlayerArray() )
	    {
	    	Remote_CallFunction_NonReplay( playerO, "ServerCallback_PlayMatchEndMusic" )


            printl("DEBUG: " + file.winner.GetPlayerName() + " " + playerO.GetTeam())
            //Check if player is winner or is in winning team (first check isn't needed)
            if (file.winner == playerO || file.winner.GetTeam() == playerO.GetTeam()) {
	        	Remote_CallFunction_NonReplay( playerO, "ServerCallback_Gun_Game_MatchEndAnnouncement", true, file.winner.GetTeam() )
            } else { //If not in winning team
                Remote_CallFunction_NonReplay( playerO, "ServerCallback_Gun_Game_MatchEndAnnouncement", false, file.winner.GetTeam() )
            }
	    }
    } else {
        //Launch end screen ("You are the champion") for each player
	    foreach ( playerO in GetPlayerArray() )
	    {
        printl("DEBUG: " + file.winner.GetPlayerName() + " " + playerO.GetTeam())

	    	Remote_CallFunction_NonReplay( playerO, "ServerCallback_PlayMatchEndMusic" )
	    	Remote_CallFunction_NonReplay( playerO, "ServerCallback_Gun_Game_MatchEndAnnouncement", true, playerO.GetTeam() )
	    }
    }
	wait 6

    //Add winning data (required by the sequence)
    if (file.winner != null) {
	     foreach ( playerO in GetPlayerArray() )
	      {
          printl("DEBUG: " + file.winner.GetPlayerName() + " " + playerO.GetTeam())
     	    Remote_CallFunction_NonReplay(playerO, "ServerCallback_Gun_Game_AddWinningSquadData", 0, file.winner.GetEncodedEHandle())
	      }
     }

    //Play end cinematic
	foreach( playerO in GetPlayerArray() ) {
		thread Remote_CallFunction_NonReplay(playerO, "ServerCallback_Gun_Game_DoVictory")
	}

	wait 8

    SetGameState(eGameState.MapVoting)
}






//
//
// CONSOLE COMMANDS
//
//

bool function ClientCommand_NextRound(entity player, array<string> args)
{
    if( !IsServer() ) return false
    file.winner = player
    SetGameState(eGameState.WinnerDetermined)
    return true
}

bool function ClientCommand_ClearInvincibleAll(entity player, array<string> args) {
    foreach ( playerO in GetPlayerArray() )
	{
		playerO.ClearInvulnerable()
	}

    return true
}

bool function ClientCommand_ClearInvincible(entity player, array<string> args) {
	player.ClearInvulnerable()
    return true
}

bool function ClientCommand_RemovePassive(entity player, array<string> args) {
	player.RemovePassive( ePassives.PAS_PILOT_BLOOD )
    return true
}

bool function ClientCommand_AddPassive(entity player, array<string> args) {
    GivePassive(player, ePassives.PAS_PILOT_BLOOD)
    return true
}
