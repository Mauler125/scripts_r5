global function _CustomHideAndSeek_Init
global function _HasRegisterLocation

enum eHASState
{
    IN_PROGRESS = 0
    WINNER_DECIDED = 1
}

struct {
    int hasState = eHASState.IN_PROGRESS

    array<entity> playerSpawnedProps

    array<LocationSettingsHAS> locationSettings


    int seeker_number
    int hidden_number
} file;

void function _CustomHideAndSeek_Init()
{
    AddCallback_OnClientConnected(void function(entity player) {thread _OnPlayerConnected(player)})
    AddCallback_OnPlayerKilled(void function(entity victim, entity attacker, var damageInfo) {thread _OnPlayerDied(victim, attacker, damageInfo)})

    thread RunHAS()
}

void function RunHAS()
{
    WaitForGameState(eGameState.Playing)
    for ( ; ; )
    {
        StartRound();
    }
    WaitForever()
}

void function StartRound()
{
    SetGameState(eGameState.Playing)

    entity Seeker = GetPlayerArray().getrandom()

    file.seeker_number = 1
    file.hidden_number = GetPlayerArray().len() - 1

    foreach(player in GetPlayerArray())
    {
        if (IsValid( player ))
        {
            if(player != Seeker){
                Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.ROUND_START_HIDDEN)
                player.UnfreezeControlsOnServer()   
                TpPlayerToSpawnPoint(player, 1)
            } else if (player == Seeker){
                Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.ROUND_START_SEEKER)
                player.FreezeControlsOnServer()
                TpPlayerToSpawnPoint(player, 0)
            }
            ClearInvincible(player)
        }
    }
    wait 15
    Seeker.UnfreezeControlsOnServer()   
    float endTime = Time() + GetCurrentPlaylistVarFloat("round_time", 120)
    while( Time() <= endTime )
    {
        if(file.hasState == eHASState.WINNER_DECIDED)
            foreach(player in GetPlayerArray()){
                Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.END_HIDDEN)
            }
            break
        WaitFrame()
    }
    file.hasState = eHASState.IN_PROGRESS
}

void function _OnPlayerConnected(entity player)
{
    if( !IsValid( player ) )
    return

    if( !IsAlive( player ) )
        _HandleRespawn( player , 1)
    
    switch( GetGameState() )
    {

        case eGameState.WaitingForPlayers:
            player.FreezeControlsOnServer()
            break
        case eGameState.Playing:
            player.UnfreezeControlsOnServer();
            file.seeker_number = file.seeker_number + 1
            Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eTDMAnnounce.ROUND_START_SEEKER )

        break
    default: 
        break
    }
}

void function _OnPlayerDied( entity victim, entity attacker, var damageInfo ) 
{
    switch( GetGameState() )
    {
        case eGameState.Playing:

            void functionref() victimHandleFunc = void function() : ( victim, attacker, damageInfo )
            {
                if(!IsValid( victim ))
                    return

                if( IsValid( victim ) )
                {
                    file.hidden_number = file.hidden_number - 1
                    file.seeker_number = file.seeker_number + 1
                    _HandleRespawn( victim, 0)
                }
            }
            void functionref() attackerHandleFunc = void function() : (victim, attacker, damageInfo)  {
                if( IsValid(attacker) && attacker.IsPlayer() && IsAlive( attacker ) && attacker != victim )
                {
                    int invscore = attacker.GetPlayerNetInt( "kills" )
                    invscore++;

                    attacker.SetPlayerNetInt( "kills", invscore )
                }
            }

            if(file.hidden_number <= 0){
                foreach( entity player in GetPlayerArray() )
                {
                    Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.END_SEEKER)
                }
                file.hasState = eHASState.WINNER_DECIDED
            }

            thread victimHandleFunc()
            thread attackerHandleFunc()
            foreach( player in GetPlayerArray() )
            {
                Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_PlayerKilled" )
            }
            break
        default:
        
    }
}

void function PlayerRestoreHP(entity player, float health, float shields)
{
    if(!IsValid(player)) return;
    if(!IsAlive(player)) return;
    player.SetHealth( health )
    Inventory_SetPlayerEquipment(player, "helmet_pickup_lv4_abilities", "helmet")

    if(shields == 0) return;
    else if(shields <= 50)
        Inventory_SetPlayerEquipment(player, "armor_pickup_lv1", "armor")
    else if(shields <= 75)
        Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
    else if(shields <= 100)
        Inventory_SetPlayerEquipment(player, "armor_pickup_lv3", "armor")
    player.SetShieldHealth( shields )

}

void function _HasRegisterLocation(LocationSettingsHAS locationSettings)
{
    file.locationSettings.append(locationSettings)
}


void function _HandleRespawn(entity player, int team){
    if(!IsValid(player))
        return

    if(!IsAlive(player))
    {
        DecideRespawnPlayer(player, true)
    }
    SetPlayerSettings(player, HIDEANDSEEK_PLAYER_SETTINGS)
    PlayerRestoreHP(player, 100, 0)
    TpPlayerToSpawnPoint(player, team)
}

void function TpPlayerToSpawnPoint(entity player, int team)
{
    SpawnLoc loc
    switch(GetMapName()){
        case "mp_rr_floppytown":
            if(team == 0){ //Seeker
                loc = NewSpawnLoc(<772, 85, 2846>, <12, 89, 0>)
            } else { //Hidden
                loc = NewSpawnLoc(<502, 437, 2380>, < 15, 89, 0 >)
            }
        default:
             Assert(false, "No location for Hide and Seek in this map")
    }

    player.SetOrigin(loc.origin)
    player.SetAngles(loc.angles)
}