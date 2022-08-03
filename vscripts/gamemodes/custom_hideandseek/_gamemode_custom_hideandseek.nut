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
    SEEKER_CANT_MOVE = 2
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
    AddCallback_OnPreClientDisconnected(void function(entity player) {thread _OnPlayerDisconnected(player)})
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

    file.hasState = eHASState.SEEKER_CANT_MOVE

    foreach(player in GetPlayerArray())
    {
        if (IsValid( player ))
        {
            if(player != Seeker){
                HAS.HIDDENPlayers.push(player)
                ChangePlayerCharacter(eHASLegends.HIDDEN, player)
                wait 1
                player.UnfreezeControlsOnServer()   
                TpPlayerToSpawnPoint(player, 1)
            } else if (player == Seeker){
                HAS.SEEKERPlayers.push(player)
                ChangePlayerCharacter(eHASLegends.SEEKER, player)
                wait 1
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
    foreach(seekers in HAS.SEEKERPlayers){
        if(IsValid(seekers)) seekers.UnfreezeControlsOnServer()
    }
    
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
    printt("Player Connected")
    if( !IsValid( player ) )
    return

    if( !IsAlive( player ) )
        _HandleRespawn( player , 0, true)
    
    switch( GetGameState() )
    {

        case eGameState.WaitingForPlayers:
            break
        case eGameState.Playing:
            player.UnfreezeControlsOnServer()
            HAS.SEEKERPlayers.push(player)
            Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.ROUND_START_SEEKER, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len() )
            if(file.hasState == eHASState.SEEKER_CANT_MOVE) player.FreezeControlsOnServer()
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

void function _OnPlayerDisconnected(entity player)
{
    printt("Player Disconnected")

    switch(GetGameState())
    {
        case eGameState.WaitingForPlayers:
            break
        case eGameState.Playing:
        {
            if(GetPlayerArray().len() < 2){
                foreach(players in GetPlayerArray())
                {
                    Remote_CallFunction_NonReplay( players, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.SEEKER_DISCONNECTED_WAITFORPLAYER, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len() )
                    wait 3
                    SetGameState(eGameState.WaitingForPlayers)
                    file.hasState = eHASState.IN_PROGRESS
                    break
                }
            }

            if(HAS.SEEKERPlayers.contains(player))
            {
                HAS.SEEKERPlayers.remove(HAS.SEEKERPlayers.find(player))
                if(HAS.SEEKERPlayers.len() == 0)
                {
                    if(HAS.HIDDENPlayers.len() > 1)
                    {
                        entity Seeker = HAS.HIDDENPlayers.getrandom()
                        HAS.HIDDENPlayers.remove(HAS.HIDDENPlayers.find(player))
                        
                        HAS.SEEKERPlayers.push(Seeker)
                        _HandleRespawn(Seeker, 0, false)
                        if(file.hasState == eHASState.SEEKER_CANT_MOVE)
                        {
                            Seeker.FreezeControlsOnServer()
                        }

                        foreach(players in GetPlayerArray())
                        {
                            if(IsValid(players))
                            {
                                Remote_CallFunction_NonReplay( player, "ServerCallback_HideAndSeek_DoAnnouncement", 5, eHASAnnounce.SEEKER_DISCONNECTED, HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len() )
                            }
                            break
                        }
                    }
                } else {
                    foreach(players in GetPlayerArray())
                    {
                        if(IsValid(players)){
                            Remote_CallFunction_NonReplay( players, "ServerCallback_HideAndSeek_PlayerKilled", HAS.HIDDENPlayers.len(), HAS.SEEKERPlayers.len())
                        }
                        break
                    }
                }
            }
        }
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
                    if(!HAS.SEEKERPlayers.contains(victim))
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

    if(HAS.SEEKERPlayers.contains(player))
    {
        ChangePlayerCharacter(eHASLegends.SEEKER, player)
    } else {
        ChangePlayerCharacter(eHASLegends.HIDDEN, player)
    }
    wait 1
    SetPlayerSettings(player, HIDEANDSEEK_PLAYER_SETTINGS)
    player.UnfreezeControlsOnServer()
    PlayerRestoreHP(player, 100, 0)
    TpPlayerToSpawnPoint(player, team)
}

void function ChangePlayerCharacter(int name, entity player){
    player.SetPlayerNetBool("hasLockedInCharacter", false)

    switch(name)
    {
        case eHASLegends.HIDDEN:
        {
            ItemFlavor item = GetItemFlavorByHumanReadableRef("character_lifeline")
            printt("Trying to change to Lifeline")
            ItemFlavor skin = LoadoutSlot_GetItemFlavor(ToEHI(player), Loadout_CharacterSkin(item))
            CharacterSelect_AssignCharacter(player, item)

            CharacterSkin_Apply(player, skin)

            player.TakeOffhandWeapon(OFFHAND_TACTICAL)
            player.TakeOffhandWeapon(OFFHAND_ULTIMATE)
    
            break
        }
        case eHASLegends.SEEKER:
        {
            ItemFlavor item = GetItemFlavorByHumanReadableRef("character_octane")
            printt("Trying to change to Octane")
            ItemFlavor skin = LoadoutSlot_GetItemFlavor(ToEHI(player), Loadout_CharacterSkin(item))
            CharacterSelect_AssignCharacter(player, item)

            CharacterSkin_Apply(player, skin)

            player.TakeOffhandWeapon(OFFHAND_TACTICAL)
            player.TakeOffhandWeapon(OFFHAND_ULTIMATE)
    
            break
        }
    }
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
