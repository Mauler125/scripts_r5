// Credits
// AyeZee#6969 -- ctf gamemode and ui
// sal#3261 -- base custom_tdm mode to work off
// Retículo Endoplasmático#5955 -- giving me the ctf sound names
// everyone else -- advice


//Ok now, this code is not good and im sorry, im not a code wizard like rexx
//But if it works dont fix it

global function _CustomCTF_Init
global function _CTFRegisterLocation


enum eCTFState
{
	IN_PROGRESS = 0
	WINNER_DECIDED = 1
}

struct {
    int ctfState = eCTFState.IN_PROGRESS
    array<entity> playerSpawnedProps
    LocationSettingsCTF& selectedLocation

    array<LocationSettingsCTF> locationSettings


    array<string> whitelistedWeapons

    entity bubbleBoundary
} file;

struct
{
	int IMCPoints = 0
    int MILITIAPoints = 0
    vector bubbleCenter
    float bubbleRadius
    bool setmap = false
    int selectedmap
    int currentmapindex = 0
    array<entity> votedPlayers // array of players that have already voted (bad var name idc)
    bool votingtime = false
    bool votestied = false
    array<int> mapVotes
    array<int> mapIds

    int mappicked
} CTF;

struct
{
	entity pole
    entity pointfx
    entity beamfx
    entity trigger
    entity returntrigger
    entity trailfx
    bool pickedup = false
    bool dropped = false
    bool flagatbase = true
    entity holdingplayer
    int teamnum
    vector spawn = <0,0,0>
    bool isbeingreturned = false
    entity beingreturnedby
} IMCPoint;

struct
{
	entity pole
    entity pointfx
    entity beamfx
    entity trigger
    entity returntrigger
    entity trailfx
    bool pickedup = false
    bool dropped = false
    bool flagatbase = true
    entity holdingplayer
    int teamnum
    vector spawn = <0,0,0>
    bool isbeingreturned = false
    entity beingreturnedby
} MILITIAPoint;

const int NUMBER_OF_MAP_SLOTS = 4

void function _CustomCTF_Init()
{

    PrecacheModel($"mdl/props/pathfinder_zipline/pathfinder_zipline.rmdl")

    AddCallback_OnClientConnected( void function(entity player) { thread _OnPlayerConnected(player) } )
    AddCallback_OnClientDisconnected( void function(entity player) { thread _OnPlayerDisconnected(player) } )
    AddCallback_OnPlayerKilled(void function(entity victim, entity attacker, var damageInfo) {thread _OnPlayerDied(victim, attacker, damageInfo)})

    AddClientCommandCallback("next_round", ClientCommand_NextRound)

    //Used for sending votes from client to server
    AddClientCommandCallback("VoteForMap", ClientCommand_VoteForMap)

    CTF_SCORE_GOAL_TO_WIN = GetCurrentPlaylistVarInt( "max_score", 5 )
    CTF_ROUNDTIME = GetCurrentPlaylistVarInt( "round_time", 1500 )

    thread RUNCTF()

    // Whitelisted weapons
    for(int i = 0; GetCurrentPlaylistVarString("whitelisted_weapon_" + i.tostring(), "~~none~~") != "~~none~~"; i++)
    {
        file.whitelistedWeapons.append(GetCurrentPlaylistVarString("whitelisted_weapon_" + i.tostring(), "~~none~~"))
    }

}

bool function ClientCommand_VoteForMap(entity player, array<string> args)
{
    // don't allow multiple votes
    if (CTF.votedPlayers.contains(player))
        return false

    // dont allow votes if its not voting time
    if (!CTF.votingtime)
        return false

    //get map id from args
    int mapid = args[0].tointeger()

    // reject map ids that are outside of the range
    if (mapid >= NUMBER_OF_MAP_SLOTS || mapid < 0)
        return false

    // add a vote for selected maps
    CTF.mapVotes[mapid]++

    // update current amount of votes for each map
    foreach(players in GetPlayerArray())
    {
        Remote_CallFunction_Replay(players, "ServerCallback_CTF_UpdateMapVotesClient", CTF.mapVotes[0], CTF.mapVotes[1], CTF.mapVotes[2], CTF.mapVotes[3])
    }

    // append player to the list of players the voted so they cant vote again
    CTF.votedPlayers.append(player)

    return true
}

void function ResetMapVotes()
{
    CTF.mapVotes.clear()
    CTF.mapVotes.resize( NUMBER_OF_MAP_SLOTS )
}

void function _CTFRegisterLocation(LocationSettingsCTF locationSettings)
{
    file.locationSettings.append(locationSettings)
}

LocPairCTF function _GetVotingLocation()
{
    switch(GetMapName())
    {
        case "mp_rr_canyonlands_staging":
            return NewCTFLocPair(<26794, -6241, -27479>, <0, 0, 0>)
        case "mp_rr_aqueduct":
            return NewCTFLocPair(<706, -4381, 492>, <0, 0, 0>)
        case "mp_rr_ashs_redemption":
            return NewCTFLocPair(<-20917, 5852, -26741>, <0, -90, 0>)
        case "mp_rr_canyonlands_64k_x_64k":
        case "mp_rr_canyonlands_mu1":
        case "mp_rr_canyonlands_mu1_night":
            return NewCTFLocPair(<-6252, -16500, 3296>, <0, 0, 0>)
        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
                return NewCTFLocPair(<1763, 5463, -3145>, <5, -95, 0>)
        default:
            Assert(false, "No voting location for the map!")
    }
    unreachable
}

void function _OnPropDynamicSpawned(entity prop)
{
    file.playerSpawnedProps.append(prop)

}
void function RUNCTF()
{
    WaitForGameState(eGameState.Playing)
    AddSpawnCallback("prop_dynamic", _OnPropDynamicSpawned)

    for(; ; )
    {
        VotingPhase();
        StartRound();
    }
    WaitForever()
}

void function DestroyPlayerProps()
{
    foreach(prop in file.playerSpawnedProps)
    {
        if(IsValid(prop))
            prop.Destroy()
    }
    file.playerSpawnedProps.clear()
}


// purpose: handle map voting phase
void function VotingPhase()
{
    DestroyPlayerProps();
    SetGameState(eGameState.MapVoting)

    //Reset scores
    CTF.MILITIAPoints = 0
    CTF.IMCPoints = 0

    //Reset score RUI
    foreach(player in GetPlayerArray())
    {
        Remote_CallFunction_Replay(player, "ServerCallback_CTF_PointCaptured", CTF.IMCPoints, CTF.MILITIAPoints)
    }

    //Voting phase so disable weapons and make invincible
    foreach(player in GetPlayerArray())
    {
        if( !IsValid( player ) )
            continue;

        MakeInvincible(player)
		HolsterAndDisableWeapons( player )
        player.ForceStand()
        TpPlayerToSpawnPoint(player)
        player.UnfreezeControlsOnServer();
        player.SetPlayerNetInt("kills", 0) //Reset for kills
	    player.SetPlayerNetInt("assists", 0) //Reset for deaths
    }

    foreach( int votes in CTF.mapVotes )
    {
        if( votes > 0 )
        {
            file.selectedLocation = file.locationSettings[CTF.mappicked]
            return
        }
    }

    int choice = 0

    //if the map index is out the the range set to 0 to prevent crash
    if(CTF.currentmapindex > file.locationSettings.len() - 1)
        CTF.currentmapindex = 0

    //if setmap then force that to be the next map
    if(CTF.setmap)
    {
        file.selectedLocation = file.locationSettings[CTF.selectedmap]
        choice = CTF.selectedmap
    }
    else
    {
        file.selectedLocation = file.locationSettings[CTF.currentmapindex]
        choice = CTF.currentmapindex
    }

    CTF.currentmapindex++
    CTF.setmap = false

    //Set the next location client side for each player
    foreach(player in GetPlayerArray())
    {
        Remote_CallFunction_NonReplay(player, "ServerCallback_CTF_SetSelectedLocation", choice)
    }
}

// purpose: handle the start of a new round for players and props
void function StartRound()
{
    //set
    SetGameState(eGameState.Playing)

    //reset map votes
    ResetMapVotes()

    foreach(player in GetPlayerArray())
    {
        if( IsValid( player ) )
        {
            if(!IsAlive(player))
            {
                _HandleRespawn(player)
            }
            Remote_CallFunction_NonReplay(player, "ServerCallback_CTF_DoAnnouncement", 5, eCTFAnnounce.ROUND_START)
            Remote_CallFunction_NonReplay(player, "ServerCallback_CTF_SetObjectiveText", CTF_SCORE_GOAL_TO_WIN)
            ClearInvincible(player)
            DeployAndEnableWeapons(player)
            player.UnforceStand()
            player.UnfreezeControlsOnServer()
            TpPlayerToSpawnPoint(player)
        }
    }

    //spawn CTF flags based on location
    SpawnCTFPoints()

    //create the bubble based on location
    file.bubbleBoundary = CreateBubbleBoundary(file.selectedLocation)

    //set the score ui and team ui
    foreach(player in GetPlayerArray())
    {
        Remote_CallFunction_Replay(player, "ServerCallback_CTF_TeamText", player.GetTeam())
    }

    float endTime = Time() + CTF_ROUNDTIME
    while( Time() <= endTime )
	{
        if(file.ctfState == eCTFState.WINNER_DECIDED)
        {
            //for each player, if the player is holding the flag on round end. make them drop it so it dosnt cause a crash
            foreach(player in GetPlayerArray())
            {
                if( IsValid( player ) )
                {
                    if (player == IMCPoint.holdingplayer)
                    {
                        IMCPoint.pole.ClearParent()
                        IMCPoint.dropped = false
                        IMCPoint.holdingplayer = null
                        IMCPoint.pickedup = false
                        IMCPoint.flagatbase = true
                    }

                    if (player == MILITIAPoint.holdingplayer)
                    {
                        MILITIAPoint.pole.ClearParent()
                        MILITIAPoint.dropped = false
                        MILITIAPoint.holdingplayer = null
                        MILITIAPoint.pickedup = false
                        MILITIAPoint.flagatbase = true
                    }
                }
            }

            //remove trail fx from players
            if(IsValid(IMCPoint.trailfx))
                IMCPoint.trailfx.Destroy()
            if(IsValid(MILITIAPoint.trailfx))
                MILITIAPoint.trailfx.Destroy()

            //Destroy old flags, triggers, and fx
            IMCPoint.pole.Destroy()
            IMCPoint.trigger.Destroy()
            IMCPoint.pointfx.Destroy()
            IMCPoint.beamfx.Destroy()
            MILITIAPoint.pole.Destroy()
            MILITIAPoint.trigger.Destroy()
            MILITIAPoint.pointfx.Destroy()
            MILITIAPoint.beamfx.Destroy()

            int TeamWon = 69;

            //See what team has more points to decide on the winner
            if (CTF.IMCPoints > CTF.MILITIAPoints)
                TeamWon = TEAM_IMC
            else if (CTF.MILITIAPoints > CTF.IMCPoints)
                TeamWon = TEAM_MILITIA

            foreach(player in GetPlayerArray())
            {
                //if player is dead, respawn
                if(!IsAlive(player))
                {
                    _HandleRespawn(player)
                }

                if( IsValid( player ) )
                {
                    // round is over so make the player invinvible
                    MakeInvincible(player)

                    // battle chatter we won
                    switch(TeamWon)
                    {
                        case TEAM_IMC:
                            if(player.GetTeam() == TEAM_IMC)
                                PlayBattleChatterLineToSpeakerAndTeam( player, "bc_weAreChampionSquad" )
                            break
                        case TEAM_MILITIA:
                            if(player.GetTeam() == TEAM_MILITIA)
                                PlayBattleChatterLineToSpeakerAndTeam( player, "bc_weAreChampionSquad" )
                            break
                    }
                }
            }

            //Only do voting for maps with multi locations
            if (file.locationSettings.len() >= NUMBER_OF_MAP_SLOTS)
            {
                if(file.locationSettings.len() > NUMBER_OF_MAP_SLOTS) // if the map has more then NUMBER_OF_MAP_SLOTS locations then randomize the loactions up for vote
                {

                    for(int i = 0; i < NUMBER_OF_MAP_SLOTS; ++i)
                    {
                        while(true)
                        {
                            //Get a random location id from the available locations
                            int randomId = RandomIntRange(0, file.locationSettings.len())

                            //If the map already isnt picked for voting then append it to the array, otherwise keep looping till it finds one that isnt picked yet
                            if( !CTF.mapIds.contains( randomId ) )
                            {
                                CTF.mapIds.append( randomId )
                                break
                            }
                        }
                    }
                }
                else if (file.locationSettings.len() == NUMBER_OF_MAP_SLOTS) // if the map has exactly 4 maps, remove the guess work for randomizing the maps as it would cause a rare crash
                {
                    CTF.mapIds[0] = 0
                    CTF.mapIds[1] = 1
                    CTF.mapIds[2] = 2
                    CTF.mapIds[3] = 3
                }

                //for each player, open the vote menu and set it to the winning team screen
                foreach(player in GetPlayerArray())
                {
                    if( IsValid( player ) )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetVoteMenuOpen", true)
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_WinnerScreen, TeamWon, CTF_NotUsed, CTF_NotUsed)
                    }
                }

                //Wait for timing
                wait 8

                //Set voting to be allowed
                CTF.votingtime = true

                //For each player, set voting screen and update maps that are picked for voting
                foreach(player in GetPlayerArray())
                {
                    if( IsValid( player ) )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_UpdateVotingMaps", CTF.mapIds[0], CTF.mapIds[1], CTF.mapIds[2], CTF.mapIds[3])
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_VoteScreen, CTF_NotUsed, CTF_NotUsed, CTF_NotUsed)
                    }
                }

                //Wait for voting time to be over
                wait 16

                CTF.votestied = false
                bool anyVotes = false

                //See if there was any votes in the first place
                foreach( int votes in CTF.mapVotes )
                {
                    if( votes > 0 )
                    {
                        anyVotes = true
                        break
                    }
                }

                if (anyVotes)
                {
                    // store the highest vote count for any of the maps
                    int highestVoteCount = -1

                    // store the last map id of the map that has the highest vote count
                    int highestVoteId = -1

                    // store map ids of all the maps with the highest vote count
                    array<int> mapsWithHighestVoteCount


                    for(int i = 0; i < NUMBER_OF_MAP_SLOTS; ++i)
                    {
                        int votes = CTF.mapVotes[i]
                        if( votes > highestVoteCount )
                        {
                            highestVoteCount = votes
                            highestVoteId = CTF.mapIds[i]

                            // we have a new highest, so clear the array
                            mapsWithHighestVoteCount.clear()
                            mapsWithHighestVoteCount.append(CTF.mapIds[i])
                        }
                        else if( votes == highestVoteCount ) // if this map also has the highest vote count, add it to the array
                        {
                            mapsWithHighestVoteCount.append(CTF.mapIds[i])
                        }
                    }

                    // if there are multiple maps with the highest vote count then it's a tie
                    if( mapsWithHighestVoteCount.len() > 1 )
                    {
                        CTF.votestied = true
                    }
                    else // else pick the map with the highest vote count
                    {
                        //Set the vote screen for each player to show the chosen location
                        foreach(player in GetPlayerArray())
                        {
                            Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_SelectedScreen, CTF_NotUsed, highestVoteId, CTF_NotUsed)
                        }

                        //Set the location to the location that won
                        CTF.mappicked = highestVoteId
                    }

                    if (CTF.votestied)
                    {
                        foreach(player in GetPlayerArray())
                        {
                            Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_TiedScreen, CTF_NotUsed, 254, CTF_NotUsed)
                        }

                        mapsWithHighestVoteCount.randomize()
                        waitthread RandomizeTiedLocations(mapsWithHighestVoteCount)
                    }
                }
                else //No one voted so pick random map
                {
                    //Pick a random location id from the aviable locations
                    CTF.mappicked = RandomIntRange(0, file.locationSettings.len() - 1)

                    //Set the vote screen for each player to show the chosen location
                    foreach(player in GetPlayerArray())
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_SelectedScreen, CTF_NotUsed, CTF.mappicked, CTF_NotUsed)
                    }
                }

                //Just a wait for timing
                wait 5

                //Close the votemenu for each player
                foreach(player in GetPlayerArray())
                {
                    if( IsValid( player ) )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetVoteMenuOpen", false)
                    }
                }
            }
            else
            {
                //Open the vote menu for each player and set it to the winners screen
                foreach(player in GetPlayerArray())
                {
                    if( IsValid( player ) )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetVoteMenuOpen", true)
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_WinnerScreen, TeamWon, CTF_NotUsed, CTF_NotUsed)
                    }
                }

                //Wait 10 seconds so the winning team can be shown
                wait 10

                //Set the votemenu screen to show next round text
                foreach(player in GetPlayerArray())
                {
                    if( IsValid( player ) )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_NextRoundScreen, CTF_NotUsed, CTF_NotUsed, CTF_NotUsed)
                    }
                }

                //Just a wait for timing
                wait 5

                //Close the votemenu for each player
                foreach(player in GetPlayerArray())
                {
                    if( IsValid( player ) )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetVoteMenuOpen", false)
                    }
                }
            }

            //Make voting not allowed
            CTF.votingtime = false

            //Clear players the voted for next voting
            CTF.votedPlayers.clear()

            //Clear mapids for next voting
            CTF.mapIds.clear()

            break
        }
		WaitFrame()
	}

    file.ctfState = eCTFState.IN_PROGRESS

    //Destory bubble
    file.bubbleBoundary.Destroy()

    //Reset flag icons for each player
    foreach(player in GetPlayerArray())
    {
        if( IsValid( player ) )
        {
            ClearInvincible(player)
            Remote_CallFunction_Replay(player, "ServerCallback_CTF_ResetFlagIcons")
        }
    }
}

// purpose: display the UI for randomization of tied maps at the end of voting
void function RandomizeTiedLocations(array<int> maps)
{
    bool donerandomizing = false
    int randomizeammount = RandomIntRange(50, 75)
    int i = 0
    int mapslength = maps.len()
    int currentmapindex = 0
    int selectedamp = 0

    while (!donerandomizing)
    {
        //If currentmapindex is out of range set to 0
        if (currentmapindex >= mapslength)
            currentmapindex = 0

        //Update Randomizer ui for each player
        foreach(player in GetPlayerArray())
        {
            Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_TiedScreen, 69, maps[currentmapindex], 0)
        }

        //stop randomizing once the randomize ammount is done
        if (i >= randomizeammount)
        {
            donerandomizing = true
            selectedamp = currentmapindex
        }

        i++
        currentmapindex++

        if (i >= randomizeammount - 15 && i < randomizeammount - 5) // slow down voting randomizer speed
        {
            wait 0.15
        }
        else if (i >= randomizeammount - 5) // slow down voting randomizer speed
        {
            wait 0.25
        }
        else // default voting randomizer speed
        {
            wait 0.05
        }
    }

    //Show final selected map
    foreach(player in GetPlayerArray())
    {
        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_TiedScreen, 69, maps[selectedamp], 1)
    }

    //Pause on selected map for a sec for visuals
    wait 0.5

    //Procede to final location picked screen
    foreach(player in GetPlayerArray())
    {
        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetScreen", CTF_SelectedScreen, 69, maps[selectedamp], CTF_NotUsed)
    }

    //Set selected location on server
    CTF.mappicked = maps[selectedamp]
}

void function _HandleRespawnOnLand(entity player)
{
    RemovePlayerMovementEventCallback(player, ePlayerMovementEvents.TOUCH_GROUND, _HandleRespawnOnLand)
}

void function ScreenFadeToFromBlack(entity player, float fadeTime = 1, float holdTime = 1)
{
    if( IsValid( player ) )
        ScreenFadeToBlack(player, fadeTime / 2, holdTime / 2)
    wait fadeTime
    if( IsValid( player ) )
        ScreenFadeFromBlack(player, fadeTime / 2, holdTime / 2)
}

bool function ClientCommand_NextRound(entity player, array<string> args)
{
    if( !IsServer() ) return false;

    if(args.len() < 1)
    {
        file.ctfState = eCTFState.WINNER_DECIDED
        return true
    }

    if (args[0].tointeger() > file.locationSettings.len() - 1) return false;

    CTF.setmap = true
    CTF.selectedmap = args[0].tointeger()
    file.ctfState = eCTFState.WINNER_DECIDED
    return true
}

void function SpawnCTFPoints()
{
    //Get ground pos below spawn points
    IMCPoint.spawn = OriginToGround( GetFlagLocation(file.selectedLocation, TEAM_IMC) )
    MILITIAPoint.spawn = OriginToGround( GetFlagLocation(file.selectedLocation, TEAM_MILITIA) )

    //Point 1
    IMCPoint.pole = CreateEntity( "prop_dynamic" )
	IMCPoint.pole.SetValueForModelKey( $"mdl/props/wattson_electric_fence/wattson_electric_fence.rmdl" )
    IMCPoint.pole.SetOrigin(IMCPoint.spawn)
    DispatchSpawn( IMCPoint.pole )

    thread PlayAnim( IMCPoint.pole, "prop_fence_expand", IMCPoint.pole.GetOrigin(), IMCPoint.pole.GetAngles() )

    IMCPoint.trigger = CreateEntity( "trigger_cylinder" )
	IMCPoint.trigger.SetRadius( 75 )
	IMCPoint.trigger.SetAboveHeight( 100 ) //Still not quite a sphere, will see if close enough
	IMCPoint.trigger.SetBelowHeight( 0 )
	IMCPoint.trigger.SetOrigin( IMCPoint.spawn )
    IMCPoint.trigger.SetEnterCallback( IMCPoint_Trigger )
	DispatchSpawn( IMCPoint.trigger )

    IMCPoint.pointfx = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( $"P_ar_loot_drop_point" ), IMCPoint.pole.GetOrigin(), <0, 0, 0> )
    IMCPoint.beamfx = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( $"P_ar_loot_drop_point_far" ), IMCPoint.pole.GetOrigin(), <0, 0, 0> )

    CustomHighlight(IMCPoint.pole, 0, 0, 1)

    IMCPoint.teamnum = TEAM_IMC

    IMCPoint.flagatbase = true

    //Point 2
    MILITIAPoint.pole = CreateEntity( "prop_dynamic" )
	MILITIAPoint.pole.SetValueForModelKey( $"mdl/props/wattson_electric_fence/wattson_electric_fence.rmdl" )
    MILITIAPoint.pole.SetOrigin(MILITIAPoint.spawn)
    DispatchSpawn( MILITIAPoint.pole )

    thread PlayAnim( MILITIAPoint.pole, "prop_fence_expand", MILITIAPoint.pole.GetOrigin(), MILITIAPoint.pole.GetAngles() )

    MILITIAPoint.trigger = CreateEntity( "trigger_cylinder" )
	MILITIAPoint.trigger.SetRadius( 75 )
	MILITIAPoint.trigger.SetAboveHeight( 100 ) //Still not quite a sphere, will see if close enough
	MILITIAPoint.trigger.SetBelowHeight( 0 )
	MILITIAPoint.trigger.SetOrigin( MILITIAPoint.spawn )
    MILITIAPoint.trigger.SetEnterCallback( MILITIA_Point_Trigger )
	DispatchSpawn( MILITIAPoint.trigger )

    MILITIAPoint.pointfx = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( $"P_ar_loot_drop_point" ), MILITIAPoint.pole.GetOrigin(), <0, 0, 0> )
    MILITIAPoint.beamfx = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( $"P_ar_loot_drop_point_far" ), MILITIAPoint.pole.GetOrigin(), <0, 0, 0> )

    DrawBox( IMCPoint.spawn, <-32,-32,-32>, <32,32,32>, 255, 0, 0, true, 0.2 )

    CustomHighlight(MILITIAPoint.pole, 1, 0, 0)

    MILITIAPoint.teamnum = TEAM_IMC

    MILITIAPoint.flagatbase = true

    foreach(player in GetPlayerArray())
    {
        if( IsValid( player ) )
        {
            if (player.GetTeam() == TEAM_IMC)
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_AddPointIcon", IMCPoint.pole, MILITIAPoint.pole, TEAM_IMC)
            }
            else if (player.GetTeam() == TEAM_MILITIA)
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_AddPointIcon", IMCPoint.pole, MILITIAPoint.pole, TEAM_MILITIA)
            }
        }
    }
}

void function CustomHighlight(entity e, int r, int g, int b)
{
    e.Highlight_ShowInside( 1.0 )
	e.Highlight_ShowOutline( 1.0 )
    e.Highlight_SetFunctions( 0, 114, true, 125, 2.0, 2, false )
    e.Highlight_SetParam( 0, 0, <r, g, b> )
}

void function ClearCustomHighlight(entity e)
{
    e.Highlight_SetFunctions( 0, 0, true, 0, 2, 0, false )
}

void function PlayerPickedUpFlag(entity ent)
{
    CustomHighlight(ent, 0, 0, 1)
    Highlight_SetEnemyHighlightWithParam0( ent, "bloodhound_sonar", <0,0,1> )
    ent.SetShieldHealthMax( 0 )
    StatusEffect_AddEndless( ent, eStatusEffect.speed_boost, 0.1 )
    if(ent.GetTeam() == TEAM_IMC)
    {
        int AttachID = ent.LookupAttachment( "CHESTFOCUS" )
	    IMCPoint.trailfx = StartParticleEffectOnEntity_ReturnEntity( ent, GetParticleSystemIndex( $"P_ar_holopilot_trail" ), FX_PATTACH_ABSORIGIN_FOLLOW, AttachID )
    }
    else
    {
        int AttachID = ent.LookupAttachment( "CHESTFOCUS" )
	    MILITIAPoint.trailfx = StartParticleEffectOnEntity_ReturnEntity( ent, GetParticleSystemIndex( $"P_ar_holopilot_trail" ), FX_PATTACH_ABSORIGIN_FOLLOW, AttachID )
    }
    TakeWeaponsForFlagCarrier( ent )
    Remote_CallFunction_Replay(ent, "ServerCallback_CTF_CustomMessages", ent, PickedUpFlag)
}

void function PlayerDroppedFlag(entity ent)
{
    GiveBackWeapons(ent)
    ClearCustomHighlight(ent)
    Highlight_ClearEnemyHighlight(ent)
    ent.SetShieldHealthMax( CTF_Equipment_GetDefaultShieldHP() )
    StatusEffect_StopAllOfType( ent, eStatusEffect.speed_boost )
    if(ent.GetTeam() == TEAM_IMC)
    {
        if(IsValid(IMCPoint.trailfx))
            IMCPoint.trailfx.Destroy()
    }
    else
    {
        if(IsValid(MILITIAPoint.trailfx))
            MILITIAPoint.trailfx.Destroy()
    }
}

void function IMCPoint_Trigger( entity trigger, entity ent )
{
	if ( ent.IsPlayer() && IsValid(ent))
    {
        if (ent.GetTeam() != TEAM_IMC)
        {
            if (!IMCPoint.pickedup)
            {
                IMCPoint.pole.SetParent(ent)
                IMCPoint.pole.SetOrigin(ent.GetOrigin())
                IMCPoint.pole.MakeInvisible()

                IMCPoint.holdingplayer = ent
                IMCPoint.pickedup = true
                IMCPoint.flagatbase = false

                PlayerPickedUpFlag(ent)

                array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	            foreach ( player in teamplayers )
                {
                    Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Escort)
                }

                array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	            foreach ( player in enemyplayers )
                {
                    Remote_CallFunction_Replay(player, "ServerCallback_CTF_CustomMessages", player, EnemyPickedUpFlag)
                    Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Attack)
                }

                EmitSoundToTeamPlayers("UI_CTF_3P_TeamGrabFlag", TEAM_MILITIA)
                EmitSoundToTeamPlayers("UI_CTF_3P_EnemyGrabFlag", TEAM_IMC)

                PlayBattleChatterLineToSpeakerAndTeam( ent, "bc_podLeaderLaunch" )
            }
        }

        if (MILITIAPoint.pickedup)
        {
            if(MILITIAPoint.holdingplayer == ent)
            {
                if (IMCPoint.flagatbase)
                {
                    PlayerDroppedFlag(ent)

                    CTF.IMCPoints++
                    foreach(player in GetPlayerArray())
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_PointCaptured", CTF.IMCPoints, CTF.MILITIAPoints)
                    }

                    array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	                foreach ( player in teamplayers )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Capture)
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_FlagCaptured", IMCPoint.holdingplayer, 0)
                    }

                    array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	                foreach ( player in enemyplayers )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Defend)
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_FlagCaptured", IMCPoint.holdingplayer, 1)
                    }

                    if(CTF.IMCPoints >= CTF_SCORE_GOAL_TO_WIN)
                    {
                        foreach( entity player in GetPlayerArray() )
                        {
                            thread EmitSoundOnEntityOnlyToPlayer( player, player, "diag_ap_aiNotify_winnerFound" )
                        }
                        file.ctfState = eCTFState.WINNER_DECIDED
                    }

                    MILITIAPoint.holdingplayer = null
                    MILITIAPoint.pickedup = false
                    MILITIAPoint.dropped = false
                    MILITIAPoint.flagatbase = true
                    MILITIAPoint.pole.ClearParent()
                    MILITIAPoint.pole.SetOrigin(MILITIAPoint.spawn)
                    MILITIAPoint.pole.MakeVisible()

                    EmitSoundToTeamPlayers("ui_ctf_enemy_score", TEAM_MILITIA)
                    EmitSoundToTeamPlayers("ui_ctf_team_score", TEAM_IMC)
                    thread PlayAnim( MILITIAPoint.pole, "prop_fence_expand", MILITIAPoint.pole.GetOrigin(), MILITIAPoint.pole.GetAngles() )
                }
            }
        }
    }
}

void function MILITIA_Point_Trigger( entity trigger, entity ent )
{
	if ( ent.IsPlayer() && IsValid(ent))
    {
        if (ent.GetTeam() != TEAM_MILITIA)
        {
            if (!MILITIAPoint.pickedup)
            {
                MILITIAPoint.pole.SetParent(ent)
                MILITIAPoint.pole.SetOrigin(ent.GetOrigin())
                MILITIAPoint.pole.MakeInvisible()

                MILITIAPoint.holdingplayer = ent
                MILITIAPoint.pickedup = true
                MILITIAPoint.flagatbase = false

                PlayerPickedUpFlag(ent)

                array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	            foreach ( player in teamplayers )
                {
                    Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Escort)
                }

                array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	            foreach ( player in enemyplayers )
                {
                    Remote_CallFunction_Replay(player, "ServerCallback_CTF_CustomMessages", player, EnemyPickedUpFlag)
                    Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Attack)
                }

                EmitSoundToTeamPlayers("UI_CTF_3P_TeamGrabFlag", TEAM_IMC)
                EmitSoundToTeamPlayers("UI_CTF_3P_EnemyGrabFlag", TEAM_MILITIA)

                PlayBattleChatterLineToSpeakerAndTeam( ent, "bc_podLeaderLaunch" )
            }
        }

        if (IMCPoint.pickedup)
        {
            if(IMCPoint.holdingplayer == ent)
            {
                if (MILITIAPoint.flagatbase)
                {
                    PlayerDroppedFlag(ent)

                    CTF.MILITIAPoints++
                    foreach(player in GetPlayerArray())
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_PointCaptured", CTF.IMCPoints, CTF.MILITIAPoints)
                    }

                    array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	                foreach ( player in teamplayers )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Capture)
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_FlagCaptured", IMCPoint.holdingplayer, 0)
                    }

                    array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	                foreach ( player in enemyplayers )
                    {
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Defend)
                        Remote_CallFunction_Replay(player, "ServerCallback_CTF_FlagCaptured", IMCPoint.holdingplayer, 1)
                    }

                    if(CTF.MILITIAPoints >= CTF_SCORE_GOAL_TO_WIN)
                    {
                        foreach( entity player in GetPlayerArray() )
                        {
                            thread EmitSoundOnEntityOnlyToPlayer( player, player, "diag_ap_aiNotify_winnerFound" )
                        }
                        file.ctfState = eCTFState.WINNER_DECIDED
                    }

                    IMCPoint.holdingplayer = null
                    IMCPoint.pickedup = false
                    IMCPoint.dropped = false
                    IMCPoint.flagatbase = true
                    IMCPoint.pole.ClearParent()
                    IMCPoint.pole.SetOrigin(IMCPoint.spawn)
                    IMCPoint.pole.MakeVisible()

                    EmitSoundToTeamPlayers("ui_ctf_enemy_score", TEAM_IMC)
                    EmitSoundToTeamPlayers("ui_ctf_team_score", TEAM_MILITIA)
                    thread PlayAnim( IMCPoint.pole, "prop_fence_expand", IMCPoint.pole.GetOrigin(), IMCPoint.pole.GetAngles() )
                }
            }
        }
    }
}

void function TakeWeaponsForFlagCarrier(entity player)
{
    player.p.storedWeapons = StoreWeapons(player)
    TakeAllWeapons(player)
    player.GiveWeapon( "mp_weapon_melee_survival", WEAPON_INVENTORY_SLOT_PRIMARY_2, [] )
    player.GiveOffhandWeapon( "melee_data_knife", OFFHAND_MELEE, ["ctf_knife"] )
    player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, WEAPON_INVENTORY_SLOT_PRIMARY_2)
}

void function GiveBackWeapons(entity player)
{
    TakeAllWeapons(player)
    player.TakeOffhandWeapon(OFFHAND_TACTICAL)
    player.TakeOffhandWeapon(OFFHAND_ULTIMATE)
    player.TakeOffhandWeapon(OFFHAND_MELEE)
    array<StoredWeapon> weapons = [
        CTF_Equipment_GetRespawnKit_PrimaryWeapon(),
        CTF_Equipment_GetRespawnKit_SecondaryWeapon(),
        CTF_Equipment_GetRespawnKit_Tactical(),
        CTF_Equipment_GetRespawnKit_Ultimate()
    ]

    foreach (storedWeapon in weapons)
    {
        if ( !storedWeapon.name.len() ) continue
        printl(storedWeapon.name + " " + storedWeapon.weaponType)
        if( storedWeapon.weaponType == eStoredWeaponType.main)
            player.GiveWeapon( storedWeapon.name, storedWeapon.inventoryIndex, storedWeapon.mods )
        else
            player.GiveOffhandWeapon( storedWeapon.name, storedWeapon.inventoryIndex, storedWeapon.mods )
    }

    player.GiveWeapon( "mp_weapon_melee_survival", WEAPON_INVENTORY_SLOT_PRIMARY_2, [] )
    player.GiveOffhandWeapon( "melee_data_knife", OFFHAND_MELEE, [] )
    player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, WEAPON_INVENTORY_SLOT_PRIMARY_0)
}

void function _OnPlayerConnected(entity player)
{
    if(!IsValid(player)) return

    //Give passive regen (pilot blood)
    GivePassive(player, ePassives.PAS_PILOT_BLOOD)
    //SetPlayerSettings(player, CTF_PLAYER_SETTINGS)

    Remote_CallFunction_NonReplay(player, "ServerCallback_CTF_SetObjectiveText", CTF_SCORE_GOAL_TO_WIN)

    if(!IsAlive(player))
    {
        _HandleRespawn(player)
    }

    switch(GetGameState())
    {

    case eGameState.WaitingForPlayers:
        player.FreezeControlsOnServer()
        Remote_CallFunction_NonReplay(player, "ServerCallback_CTF_DoAnnouncement", 2, eCTFAnnounce.VOTING_PHASE)
        break
    case eGameState.Playing:
        player.UnfreezeControlsOnServer();
        Remote_CallFunction_NonReplay(player, "ServerCallback_CTF_DoAnnouncement", 5, eCTFAnnounce.ROUND_START)

        if(player.GetTeam() == TEAM_IMC || player.GetTeam() == TEAM_MILITIA)
            Remote_CallFunction_Replay(player, "ServerCallback_CTF_AddPointIcon", IMCPoint.pole, MILITIAPoint.pole, player.GetTeam())

        break
    default:
        break
    }
}

void function _OnPlayerDisconnected(entity player)
{
    //Only if the flag is picked up
    if (IMCPoint.pickedup)
    {
        //Only if the flag is held by said player
        if(IMCPoint.holdingplayer == player)
        {
            IMCPoint.pole.ClearParent()
            bool foundSafeSpot = false

            PlayerDroppedFlag(player)

            //Clear parent and set the flag to current death location
            IMCPoint.holdingplayer = null
            IMCPoint.pickedup = false
            IMCPoint.dropped = true
            IMCPoint.pole.MakeVisible()

            IMCPoint.pole.SetOrigin(OriginToGround( IMCPoint.pole.GetOrigin() ))

            array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	        foreach ( players in teamplayers )
            {
		        Remote_CallFunction_Replay(players, "ServerCallback_CTF_CustomMessages", players, EnemyPickedUpFlag)
                Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Capture)
            }

            array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	        foreach ( players in enemyplayers )
            {
                Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Defend)
            }


            if(IMCPoint.pole.GetOrigin().z > 1000)
            {
                if(Distance(IMCPoint.pole.GetOrigin(), CTF.bubbleCenter) > CTF.bubbleRadius)
                {
                    IMCPoint.flagatbase = true
                    IMCPoint.pole.SetOrigin(OriginToGround( IMCPoint.spawn ))
                }
                else
                {
                    foundSafeSpot = true
                }
            }
            else
            {
                IMCPoint.flagatbase = true
                IMCPoint.pole.SetOrigin(OriginToGround( IMCPoint.spawn ))
            }

            //Play expand anim
            thread PlayAnim( IMCPoint.pole, "prop_fence_expand", IMCPoint.pole.GetOrigin(), IMCPoint.pole.GetAngles() )

            if (foundSafeSpot)
            {
                //Create the recapture trigger
                IMCPoint.returntrigger = CreateEntity( "trigger_cylinder" )
	            IMCPoint.returntrigger.SetRadius( 150 )
	            IMCPoint.returntrigger.SetAboveHeight( 100 )
	            IMCPoint.returntrigger.SetBelowHeight( 0 )
	            IMCPoint.returntrigger.SetOrigin( IMCPoint.pole.GetOrigin() )
                IMCPoint.returntrigger.SetEnterCallback( IMC_PoleReturn_Trigger )
	            DispatchSpawn( IMCPoint.returntrigger )
            }
        }
    }

    //Only if the flag is picked up
    if (MILITIAPoint.pickedup)
    {
        //Only if the flag is held by said player
        if(MILITIAPoint.holdingplayer == player)
        {
            MILITIAPoint.pole.ClearParent()
            bool foundSafeSpot = false

            PlayerDroppedFlag(player)

            //Clear parent and set the flag to current death location
            MILITIAPoint.holdingplayer = null
            MILITIAPoint.pickedup = false
            MILITIAPoint.dropped = true
            MILITIAPoint.pole.MakeVisible()


            MILITIAPoint.pole.SetOrigin(OriginToGround( MILITIAPoint.pole.GetOrigin() ))

            array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	        foreach ( players in teamplayers )
            {
		        Remote_CallFunction_Replay(players, "ServerCallback_CTF_CustomMessages", players, EnemyPickedUpFlag)
                Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Capture)
            }

            array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	        foreach ( players in enemyplayers )
            {
                Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Return)
            }


            if(MILITIAPoint.pole.GetOrigin().z > 1000)
            {
                if(Distance(MILITIAPoint.pole.GetOrigin(), CTF.bubbleCenter) > CTF.bubbleRadius)
                {
                    MILITIAPoint.flagatbase = true
                    MILITIAPoint.pole.SetOrigin(OriginToGround( MILITIAPoint.spawn ))
                }
                else
                {
                    foundSafeSpot = true
                }
            }
            else
            {
                MILITIAPoint.flagatbase = true
                MILITIAPoint.pole.SetOrigin(OriginToGround( MILITIAPoint.spawn ))
            }

            //Play expand anim
            thread PlayAnim( MILITIAPoint.pole, "prop_fence_expand", MILITIAPoint.pole.GetOrigin(), MILITIAPoint.pole.GetAngles() )

            if (foundSafeSpot)
            {
                //Create the recapture trigger
                MILITIAPoint.returntrigger = CreateEntity( "trigger_cylinder" )
	            MILITIAPoint.returntrigger.SetRadius( 75 )
	            MILITIAPoint.returntrigger.SetAboveHeight( 100 )
	            MILITIAPoint.returntrigger.SetBelowHeight( 0 )
	            MILITIAPoint.returntrigger.SetOrigin( MILITIAPoint.pole.GetOrigin() )
                MILITIAPoint.returntrigger.SetEnterCallback( MILITIA_PoleReturn_Trigger )
	            DispatchSpawn( MILITIAPoint.returntrigger )
            }
        }
    }
}

void function MILITIA_PoleReturn_Trigger( entity trigger, entity ent )
{
    if ( ent.IsPlayer() && IsValid(ent) )
    {
        //If is on team IMC pick back up
        if (ent.GetTeam() == TEAM_IMC)
        {
            MILITIAPoint.returntrigger.Destroy()
            MILITIAPoint.pole.SetParent(ent)
            MILITIAPoint.pole.SetOrigin(ent.GetOrigin())
            MILITIAPoint.pole.MakeInvisible()

            PlayerPickedUpFlag(ent)

            MILITIAPoint.holdingplayer = ent
            MILITIAPoint.pickedup = true
            MILITIAPoint.dropped = false

            array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	        foreach ( player in teamplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Escort)
            }

            array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	        foreach ( player in enemyplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_CustomMessages", player, EnemyPickedUpFlag)
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Attack)
            }

            EmitSoundToTeamPlayers("UI_CTF_3P_TeamGrabFlag", TEAM_IMC)
            EmitSoundToTeamPlayers("UI_CTF_3P_EnemyGrabFlag", TEAM_MILITIA)
        }

        //If is on team MIL start return countdown
        if (ent.GetTeam() == TEAM_MILITIA)
        {
            if(!IMCPoint.isbeingreturned)
            {
                MILITIAPoint.isbeingreturned = true
                MILITIAPoint.beingreturnedby = ent
                thread StartMILFlagReturnTimer(ent)
            }
        }
    }
}

void function StartMILFlagReturnTimer(entity player)
{
    bool returnsuccess = false

    float starttime = Time()
    float endtime = Time() + 10
    Remote_CallFunction_Replay(player, "ServerCallback_CTF_RecaptureFlag", TEAM_MILITIA, starttime, endtime)

    while(Distance(player.GetOrigin(), MILITIAPoint.pole.GetOrigin()) < 150 && IsAlive(player) && returnsuccess == false)
    {
        if(Time() >= endtime)
        {
            returnsuccess = true
            MILITIAPoint.isbeingreturned = false
        }
        wait 0.01
    }

    if(returnsuccess)
    {
        MILITIAPoint.pole.ClearParent()
        MILITIAPoint.dropped = false
        MILITIAPoint.holdingplayer = null
        MILITIAPoint.pickedup = false
        MILITIAPoint.flagatbase = true
        MILITIAPoint.pole.SetOrigin(MILITIAPoint.spawn)
        MILITIAPoint.returntrigger.Destroy()
        thread PlayAnim( MILITIAPoint.pole, "prop_fence_expand", MILITIAPoint.pole.GetOrigin(), MILITIAPoint.pole.GetAngles() )
        MILITIAPoint.trigger.SearchForNewTouchingEntity()

        array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	    foreach ( players in teamplayers )
        {
            Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Capture)
        }

        array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	    foreach ( players in enemyplayers )
        {
            Remote_CallFunction_Replay(players, "ServerCallback_CTF_CustomMessages", players, TeamReturnedFlag)
            Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Defend)
        }
    }
    else
    {
        MILITIAPoint.isbeingreturned = false
        MILITIAPoint.beingreturnedby = null
        Remote_CallFunction_Replay(player, "ServerCallback_CTF_EndRecaptureFlag")
        MILITIAPoint.returntrigger.SearchForNewTouchingEntity()
    }
}

void function IMC_PoleReturn_Trigger( entity trigger, entity ent )
{
    if ( ent.IsPlayer() && IsValid(ent) )
    {
        //If is on team MILITIA pick back up
        if (ent.GetTeam() == TEAM_MILITIA)
        {
            IMCPoint.returntrigger.Destroy()
            IMCPoint.pole.SetParent(ent)
            IMCPoint.pole.SetOrigin(ent.GetOrigin())
            IMCPoint.pole.MakeInvisible()

            PlayerPickedUpFlag(ent)

            IMCPoint.holdingplayer = ent
            IMCPoint.pickedup = true
            IMCPoint.dropped = false

            array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	        foreach ( player in teamplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Escort)
            }

            array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	        foreach ( player in enemyplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_CustomMessages", player, EnemyPickedUpFlag)
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Attack)
            }

            EmitSoundToTeamPlayers("UI_CTF_3P_TeamGrabFlag", TEAM_MILITIA)
            EmitSoundToTeamPlayers("UI_CTF_3P_EnemyGrabFlag", TEAM_IMC)
        }

        //If is on team IMC start return countdown
        if (ent.GetTeam() == TEAM_IMC)
        {
            if(!IMCPoint.isbeingreturned)
            {
                IMCPoint.isbeingreturned = true
                IMCPoint.beingreturnedby = ent
                thread StartIMCFlagReturnTimer(ent)
            }
        }
    }
}

void function StartIMCFlagReturnTimer(entity player)
{
    bool returnsuccess = false

    float starttime = Time()
    float endtime = Time() + 10
    Remote_CallFunction_Replay(player, "ServerCallback_CTF_RecaptureFlag", TEAM_IMC, starttime, endtime)

    while(Distance(player.GetOrigin(), IMCPoint.pole.GetOrigin()) < 150 && IsAlive(player) && returnsuccess == false)
    {
        if(Time() >= endtime)
        {
            returnsuccess = true
            IMCPoint.isbeingreturned = false
        }
        wait 0.01
    }

    if(returnsuccess)
    {
        IMCPoint.pole.ClearParent()
        IMCPoint.dropped = false
        IMCPoint.holdingplayer = null
        IMCPoint.pickedup = false
        IMCPoint.flagatbase = true
        IMCPoint.pole.SetOrigin(IMCPoint.spawn)
        IMCPoint.returntrigger.Destroy()
        thread PlayAnim( IMCPoint.pole, "prop_fence_expand", IMCPoint.pole.GetOrigin(), IMCPoint.pole.GetAngles() )
        IMCPoint.trigger.SearchForNewTouchingEntity()

        array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	    foreach ( players in teamplayers )
        {
            Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Capture)
        }

        array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	    foreach ( players in enemyplayers )
        {
            Remote_CallFunction_Replay(players, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Defend)
            Remote_CallFunction_Replay(players, "ServerCallback_CTF_CustomMessages", players, TeamReturnedFlag)
        }
    }
    else
    {
        IMCPoint.isbeingreturned = false
        IMCPoint.beingreturnedby = null
        Remote_CallFunction_Replay(player, "ServerCallback_CTF_EndRecaptureFlag")
        IMCPoint.returntrigger.SearchForNewTouchingEntity()
    }
}

void function CheckPlayerForFlag(entity victim)
{
    float undermap

    switch(GetMapName())
    {
        case "mp_rr_canyonlands_staging":
            undermap = -30000
            break
        case "mp_rr_ashs_redemption":
            undermap = 1000
            break
        case "mp_rr_canyonlands_mu1":
	    case "mp_rr_canyonlands_mu1_night":
        case "mp_rr_canyonlands_64k_x_64k":
            undermap = 1000
            break
        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
            undermap = -6000
            break
        default:
            undermap = 100
    }

    //Only if the flag is picked up
    if (IMCPoint.pickedup)
    {
        //Only if the flag is held by said player
        if(IMCPoint.holdingplayer == victim)
        {
            IMCPoint.pole.ClearParent()
            bool foundSafeSpot = false

            PlayerDroppedFlag(victim)

            //Clear parent and set the flag to current death location
            IMCPoint.holdingplayer = null
            IMCPoint.pickedup = false
            IMCPoint.dropped = true
            IMCPoint.pole.MakeVisible()

            IMCPoint.pole.SetOrigin(OriginToGround( IMCPoint.pole.GetOrigin() ))

            array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	        foreach ( player in teamplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Capture)
            }

            array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	        foreach ( player in enemyplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_IMC, CTF_Defend)
            }

            //Check for if the flag ends up under the map
            if(IMCPoint.pole.GetOrigin().z > undermap)
            {
                if(Distance(IMCPoint.pole.GetOrigin(), CTF.bubbleCenter) > CTF.bubbleRadius)
                {
                    IMCPoint.flagatbase = true
                    IMCPoint.pole.SetOrigin(OriginToGround( IMCPoint.spawn ))
                }
                else
                {
                    foundSafeSpot = true
                }
            }
            else
            {
                IMCPoint.flagatbase = true
                IMCPoint.pole.SetOrigin(OriginToGround( IMCPoint.spawn ))
            }

            //Play expand anim
            thread PlayAnim( IMCPoint.pole, "prop_fence_expand", IMCPoint.pole.GetOrigin(), IMCPoint.pole.GetAngles() )

            if (foundSafeSpot)
            {
                //Create the recapture trigger
                IMCPoint.returntrigger = CreateEntity( "trigger_cylinder" )
	            IMCPoint.returntrigger.SetRadius( 100 )
	            IMCPoint.returntrigger.SetAboveHeight( 200 )
	            IMCPoint.returntrigger.SetBelowHeight( 200 )
	            IMCPoint.returntrigger.SetOrigin( IMCPoint.pole.GetOrigin() )
                IMCPoint.returntrigger.SetEnterCallback( IMC_PoleReturn_Trigger )
	            DispatchSpawn( IMCPoint.returntrigger )
            }
        }
    }

    //Only if the flag is picked up
    if (MILITIAPoint.pickedup)
    {
        //Only if the flag is held by said player
        if(MILITIAPoint.holdingplayer == victim)
        {
            MILITIAPoint.pole.ClearParent()
            bool foundSafeSpot = false

            PlayerDroppedFlag(victim)

            //Clear parent and set the flag to current death location
            MILITIAPoint.holdingplayer = null
            MILITIAPoint.pickedup = false
            MILITIAPoint.dropped = true
            MILITIAPoint.pole.MakeVisible()


            MILITIAPoint.pole.SetOrigin(OriginToGround( MILITIAPoint.pole.GetOrigin() ))

            array<entity> teamplayers = GetPlayerArrayOfTeam( TEAM_IMC )
	        foreach ( player in teamplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Capture)
            }

            array<entity> enemyplayers = GetPlayerArrayOfTeam( TEAM_MILITIA )
	        foreach ( player in enemyplayers )
            {
                Remote_CallFunction_Replay(player, "ServerCallback_CTF_SetPointIconHint", TEAM_MILITIA, CTF_Return)
            }

            //Check for if the flag ends up under the map
            if(MILITIAPoint.pole.GetOrigin().z > undermap)
            {
                if(Distance(MILITIAPoint.pole.GetOrigin(), CTF.bubbleCenter) > CTF.bubbleRadius)
                {
                    MILITIAPoint.flagatbase = true
                    MILITIAPoint.pole.SetOrigin(OriginToGround( MILITIAPoint.spawn ))
                }
                else
                {
                    foundSafeSpot = true
                }
            }
            else
            {
                MILITIAPoint.flagatbase = true
                MILITIAPoint.pole.SetOrigin(OriginToGround( MILITIAPoint.spawn ))
            }

            //Play expand anim
            thread PlayAnim( MILITIAPoint.pole, "prop_fence_expand", MILITIAPoint.pole.GetOrigin(), MILITIAPoint.pole.GetAngles() )

            if (foundSafeSpot)
            {
                //Create the recapture trigger
                MILITIAPoint.returntrigger = CreateEntity( "trigger_cylinder" )
	            MILITIAPoint.returntrigger.SetRadius( 100 )
	            MILITIAPoint.returntrigger.SetAboveHeight( 200 )
	            MILITIAPoint.returntrigger.SetBelowHeight( 200 )
	            MILITIAPoint.returntrigger.SetOrigin( MILITIAPoint.pole.GetOrigin() )
                MILITIAPoint.returntrigger.SetEnterCallback( MILITIA_PoleReturn_Trigger )
	            DispatchSpawn( MILITIAPoint.returntrigger )
            }
        }
    }
}


void function _OnPlayerDied(entity victim, entity attacker, var damageInfo)
{
    //If player is holding the flag on death try to drop flag at current loaction
    CheckPlayerForFlag(victim)

    switch(GetGameState())
    {
    case eGameState.Playing:

        // What happens to victim
        void functionref() victimHandleFunc = void function() : (victim, attacker, damageInfo) {

            if(!IsValid(victim)) return

            //Remote_CallFunction_Replay( victim, "ServerCallback_CTF_ResetFlagIcons")
            victim.p.storedWeapons = StoreWeapons(victim)

            if (!CTF.votingtime)
            {
                Remote_CallFunction_NonReplay(victim, "ServerCallback_CTF_OpenCTFRespawnMenu", CTF.bubbleCenter, CTF.IMCPoints, CTF.MILITIAPoints, attacker)

                float reservedTime = 4// so we dont immediately go to killcam
                wait reservedTime

                Remote_CallFunction_NonReplay(victim, "ServerCallback_CTF_PlayerDied", CTF.bubbleCenter, CTF.IMCPoints, CTF.MILITIAPoints, attacker)

                //Add a death to the victim
                int invscore = victim.GetPlayerNetInt( "assists" )
                invscore++;
                victim.SetPlayerNetInt( "assists", invscore )

                wait 6

                if(IsValid(victim) )
                {
                    Remote_CallFunction_NonReplay(victim, "ServerCallback_CTF_PlayerSpawning")
                    _HandleRespawn( victim )
                }
            }

        }


        // What happens to attacker
        void functionref() attackerHandleFunc = void function() : (victim, attacker, damageInfo)  {
            if(IsValid(attacker) && attacker.IsPlayer() && IsAlive(attacker) && attacker != victim)
            {
                int invscore = attacker.GetPlayerNetInt( "kills" )
			    invscore++;
			    attacker.SetPlayerNetInt( "kills", invscore )

                if(IMCPoint.holdingplayer == attacker)
                {
                    //Do Nothing
                }
                else
                {
                    if(MILITIAPoint.holdingplayer == attacker)
                    {
                        //Do Nothing
                    }
                    else
                    {
                        PlayerRestoreHP(attacker, 100, CTF_Equipment_GetDefaultShieldHP())
                    }
                }
            }
        }

        thread victimHandleFunc()
        thread attackerHandleFunc()
        break
    default:

    }
}

void function _HandleRespawn(entity player, bool forceGive = false)
{
    if(!IsValid(player)) return

    if( player.IsObserver())
    {
        player.StopObserverMode()
        Remote_CallFunction_NonReplay(player, "ServerCallback_KillReplayHud_Deactivate")
    }

    if(!IsAlive(player) || forceGive)
    {

        if(CTF_Equipment_GetRespawnKitEnabled())
        {
            DecideRespawnPlayer(player, true)
            player.TakeOffhandWeapon(OFFHAND_TACTICAL)
            player.TakeOffhandWeapon(OFFHAND_ULTIMATE)
            array<StoredWeapon> weapons = [
                CTF_Equipment_GetRespawnKit_PrimaryWeapon(),
                CTF_Equipment_GetRespawnKit_SecondaryWeapon(),
                CTF_Equipment_GetRespawnKit_Tactical(),
                CTF_Equipment_GetRespawnKit_Ultimate()
            ]

            foreach (storedWeapon in weapons)
            {
                if ( !storedWeapon.name.len() ) continue
                printl(storedWeapon.name + " " + storedWeapon.weaponType)
                if( storedWeapon.weaponType == eStoredWeaponType.main)
                    player.GiveWeapon( storedWeapon.name, storedWeapon.inventoryIndex, storedWeapon.mods )
                else
                    player.GiveOffhandWeapon( storedWeapon.name, storedWeapon.inventoryIndex, storedWeapon.mods )
            }
            player.TakeOffhandWeapon(OFFHAND_MELEE)
            player.GiveOffhandWeapon( "melee_data_knife", OFFHAND_MELEE, [] )
            player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, WEAPON_INVENTORY_SLOT_PRIMARY_0)
        }
        else
        {
            if(!player.p.storedWeapons.len())
            {
                DecideRespawnPlayer(player, true)
            }
            else
            {
                DecideRespawnPlayer(player, false)
                GiveWeaponsFromStoredArray(player, player.p.storedWeapons)
            }

        }
    }

    SetPlayerSettings(player, CTF_PLAYER_SETTINGS)
    PlayerRestoreHP(player, 100, CTF_Equipment_GetDefaultShieldHP())

    TpPlayerToSpawnPoint(player)
    thread GrantSpawnImmunity(player, 3)

    //Point icons disappear on death, so this fixes that.
    Remote_CallFunction_Replay(player, "ServerCallback_CTF_ResetFlagIcons")

    foreach(players in GetPlayerArray())
    {
        if( IsValid( players ) && IsValid(IMCPoint.pole) && IsValid(MILITIAPoint.pole))
        {
            if (players.GetTeam() == TEAM_IMC)
            {
                Remote_CallFunction_Replay(players, "ServerCallback_CTF_AddPointIcon", IMCPoint.pole, MILITIAPoint.pole, TEAM_IMC)
            }
            else if (players.GetTeam() == TEAM_MILITIA)
            {
                Remote_CallFunction_Replay(players, "ServerCallback_CTF_AddPointIcon", IMCPoint.pole, MILITIAPoint.pole, TEAM_MILITIA)
            }
        }
    }
}


entity function CreateBubbleBoundary(LocationSettingsCTF location)
{
    array<LocPairCTF> spawns = location.spawns

    vector bubbleCenter
    foreach(spawn in spawns)
    {
        bubbleCenter += spawn.origin
    }

    bubbleCenter /= spawns.len()

    float bubbleRadius = 0

    foreach(LocPairCTF spawn in spawns)
    {
        if(Distance(spawn.origin, bubbleCenter) > bubbleRadius)
        bubbleRadius = Distance(spawn.origin, bubbleCenter)
    }

    bubbleRadius += GetCurrentPlaylistVarFloat("bubble_radius_padding", 800)

    CTF.bubbleCenter = bubbleCenter
    CTF.bubbleRadius = bubbleRadius

    entity bubbleShield = CreateEntity( "prop_dynamic" )
	bubbleShield.SetValueForModelKey( BUBBLE_BUNKER_SHIELD_COLLISION_MODEL )
    bubbleShield.SetOrigin(bubbleCenter)
    bubbleShield.SetModelScale(bubbleRadius / 235)
    bubbleShield.kv.CollisionGroup = 0
    bubbleShield.kv.rendercolor = "150 150 150"
    DispatchSpawn( bubbleShield )



    thread MonitorBubbleBoundary(bubbleShield, bubbleCenter, bubbleRadius)


    return bubbleShield

}


void function MonitorBubbleBoundary(entity bubbleShield, vector bubbleCenter, float bubbleRadius)
{
    while(IsValid(bubbleShield))
    {

        foreach(player in GetPlayerArray_Alive())
        {
            if(!IsValid(player)) continue
            if(Distance(player.GetOrigin(), bubbleCenter) > bubbleRadius)
            {
				Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
                player.TakeDamage( int( CTF_GetOOBDamagePercent() / 100 * float( player.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
            }
        }
        wait 1
    }

}


void function PlayerRestoreHP(entity player, float health, float shields)
{
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

void function GrantSpawnImmunity(entity player, float duration)
{
    if(!IsValid(player)) return;
    MakeInvincible(player)
    wait duration
    if(!IsValid(player)) return;
    ClearInvincible(player)
}


LocPairCTF function _GetAppropriateSpawnLocation(entity player)
{
    int ourTeam = player.GetTeam()

    LocPairCTF selectedSpawn = _GetVotingLocation()

    switch(GetGameState())
    {
    case eGameState.MapVoting:
        selectedSpawn = _GetVotingLocation()
        break
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

    }
    return selectedSpawn
}

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

void function TpPlayerToSpawnPoint(entity player)
{
    array<vector> playerspawnpointorg
    array<vector> playerspawnpointang
    switch(GetGameState())
    {

    case eGameState.WaitingForPlayers:
    case eGameState.WaitingForPlayers:
        LocPairCTF loc = _GetVotingLocation()

        player.SetOrigin(loc.origin)
        player.SetAngles(loc.angles)
        break
    case eGameState.Playing:
            playerspawnpointorg = GetRandomPlayerSpawnOrigin(file.selectedLocation, player)
            playerspawnpointang = GetRandomPlayerSpawnAngles(file.selectedLocation, player)

            int ri = RandomIntRange( 0, 4 )

            player.SetOrigin(playerspawnpointorg[ri])
            player.SetAngles(playerspawnpointang[ri])

        break
    default:
        break
    }
	//LocPairCTF loc = _GetAppropriateSpawnLocation(player)


    PutEntityInSafeSpot( player, null, null, player.GetOrigin() + <0,0,128>, player.GetOrigin() )
}
