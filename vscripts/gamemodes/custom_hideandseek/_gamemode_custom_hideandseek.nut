// Credits Time !
// 𝕮𝖗𝖎𝖔𝖘𝕮𝖍𝖆𝖓 クリオスちゃん#0221 -- Mode Main + Map Builder
// Julefox#0050 -- Floppytown Map Builder
// sal#3261 -- CUSTOM TDM Main
// @Shrugtal -- CUSTOM TDM score ui
// AyeZee#6969 -- Better understanding of how gamemodes work (CTF)

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
} file;

struct {
    array<entity> HIDDENPlayers
    array<entity> SEEKERPlayers
} HAS;

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
    wait 1
    SetGameState(eGameState.Playing)

    entity Seeker = GetPlayerArray().getrandom()

    HAS.HIDDENPlayers.clear()
    HAS.SEEKERPlayers.clear()

    foreach(player in GetPlayerArray())
    {
        if (IsValid( player ))
        {
            if(player != Seeker){
                HAS.HIDDENPlayers.push(player)
                player.UnfreezeControlsOnServer()   
                TpPlayerToSpawnPoint(player, 1)
            } else if (player == Seeker){
                HAS.SEEKERPlayers.push(player)
                player.FreezeControlsOnServer()
                TpPlayerToSpawnPoint(player, 0)
            }
            ClearInvincible(player)
        }
    }

    foreach(player in GetPlayerArray())
    {
        if (IsValid(player))
        {
            if(player != Seeker){
                Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.ROUND_START_HIDDEN, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
            } else if (player == Seeker){
                Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.ROUND_START_SEEKER, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
            }
        }
    }
    wait 15
    if(IsValid(Seeker)) Seeker.UnfreezeControlsOnServer()
    foreach(player in GetPlayerArray()){
        if(IsValid(player)){
            Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.SEEKER_SEARCH, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
        }
    }
    float endTime = Time() + GetCurrentPlaylistVarFloat("round_time", 120)
    while( Time() <= endTime )
    {
        if(file.hasState == eHASState.WINNER_DECIDED)
            break
        
        if( Time() >= endTime-1 ){
            foreach(player in GetPlayerArray()){
                if(IsValid(player)){
                    Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.END_HIDDEN, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
                    player.FreezeControlsOnServer()
                }
            }
            wait 10
            file.hasState = eHASState.WINNER_DECIDED
            break
        }
        WaitFrame()
    }
    file.hasState = eHASState.IN_PROGRESS

}

void function _OnPlayerConnected(entity player)
{
    if( !IsValid( player ) )
    return

    if( !IsAlive( player ) )
        _HandleRespawn( player , 1, true)
    
    switch( GetGameState() )
    {

        case eGameState.WaitingForPlayers:
            //player.FreezeControlsOnServer()
            break
        case eGameState.Playing:
            player.UnfreezeControlsOnServer();
            HAS.SEEKERPlayers.push(player)
            Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.ROUND_START_SEEKER, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len() )
            foreach(otherplayer in GetPlayerArray())
            {
                if (IsValid( otherplayer ))
                {
                    if(otherplayer != player){
                        Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.NEW_SEEKER, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len() )
                    }
                }
            }
        break
    default: 
        break
    }
}

bool function exist(array<entity> Array, entity player)
{
    foreach (index, item in Array)  {
        if (item == player)  {
            return true
        }
    }
    return false
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
                    if(!exist(HAS.SEEKERPlayers, victim))
                    {
                        HAS.HIDDENPlayers.remove(HAS.HIDDENPlayers.find(victim))
                        HAS.SEEKERPlayers.push(victim)
                    }

                    victim.p.storedWeapons = StoreWeapons(victim)

                    _HandleRespawn( victim, 0, false)
                }
            }

            thread victimHandleFunc()

            if(HAS.HIDDENPlayers.len() <= 0)
            {
                foreach( entity player in GetPlayerArray() )
                {
                    Remote_CallFunction_NonReplay(player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.END_SEEKER, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
                }
                wait 10
                file.hasState = eHASState.WINNER_DECIDED
                break
            }

            foreach( player in GetPlayerArray() )
            {
                Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_PlayerKilled", HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
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


void function _HandleRespawn(entity player, int team, bool join){
    wait 1
    if(!IsValid(player))
        return

    if( player.IsObserver() )
    {
        player.StopObserverMode()
        Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")
    }

    if(!IsAlive(player) && join == false)
    {
        DecideRespawnPlayer(player, false)
        GiveWeaponsFromStoredArray(player, player.p.storedWeapons)
    } else if (!IsAlive(player) && join == true){
        DecideRespawnPlayer(player, true)
    }
    SetPlayerSettings(player, HIDEANDSEEK_PLAYER_SETTINGS)
    player.UnfreezeControlsOnServer()
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