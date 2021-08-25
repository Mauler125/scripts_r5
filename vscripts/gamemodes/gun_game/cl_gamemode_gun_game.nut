// GUN GAME GAMEMODE
//  Made by @Pebbers#9558, @TheyCallMeSpy#1337, @sal#3261 and @Edorion#1761
//
//  This is a modified version of the TDM made so we can have weapon upgrade, balancing when you're not good enough, etc
//  Have fun !!


global function Cl_Gun_Game_Init

global function ServerCallback_Gun_Game_DoAnnouncement
global function ServerCallback_Gun_Game_SetSelectedLocation
global function ServerCallback_Gun_Game_DoLocationIntroCutscene
global function ServerCallback_Gun_Game_DoVictory
global function ServerCallback_Gun_Game_PlayerKilled
global function ServerCallback_Gun_Game_DoCountDown

global function Cl_RegisterLocation_Gun_Game


//Victory related
global function ServerCallback_Gun_Game_AddWinningSquadData
global function ServerCallback_Gun_Game_MatchEndAnnouncement

var BLACKBAR_RUI






struct {
    //Game related
    LocationSettings_Gun_Game &selectedLocation
    array choices
    array<LocationSettings_Gun_Game> LocationSettings_Gun_Game
    var scoreRui


    //Victory related
    SquadSummaryData squadSummaryData
    SquadSummaryData winnerSquadSummaryData
    vector victorySequencePosition = < 0, 0, 10000 >
  	vector victorySequenceAngles = < 0, 0, 0 >
  	float  victorySunIntensity = 1.0
  	float  victorySkyIntensity = 1.0
  	var    victoryRui = null
  	bool IsShowingVictorySequence = false
} file;



void function Cl_Gun_Game_Init()
{
}

void function Cl_RegisterLocation_Gun_Game(LocationSettings_Gun_Game LocationSettings_Gun_Game)
{
    file.LocationSettings_Gun_Game.append(LocationSettings_Gun_Game)
}


void function MakeScoreRUI()
{
    if ( file.scoreRui != null)
    {
        RuiSetString( file.scoreRui, "messageText", "Best player: None" )
        return
    }
    clGlobal.levelEnt.EndSignal( "CloseScoreRUI" )

    UISize screenSize = GetScreenSize()
    var screenAlignmentTopo = RuiTopology_CreatePlane( <( screenSize.width * 0.25),( screenSize.height * 0.31 ), 0>, <float( screenSize.width ), 0, 0>, <0, float( screenSize.height ), 0>, false )
    var rui = RuiCreate( $"ui/announcement_quick_right.rpak", screenAlignmentTopo, RUI_DRAW_HUD, RUI_SORT_SCREENFADE + 1 )

    RuiSetGameTime( rui, "startTime", Time() )
    RuiSetString( rui, "messageText", "Best player: None")
    RuiSetString( rui, "messageSubText", "Text 2")
    RuiSetFloat( rui, "duration", 9999999 )
    RuiSetFloat3( rui, "eventColor", SrgbToLinear( <128, 188, 255> ) )

    file.scoreRui = rui

    OnThreadEnd(
		function() : ( rui )
		{
			RuiDestroy( rui )
			file.scoreRui = null
		}
	)

    WaitForever()
}

void function ServerCallback_Gun_Game_DoAnnouncement(float duration, int type)
{
    string message = ""
    string subtext = ""
    switch(type)
    {

        case eGUNGAMEAnnounce.ROUND_START:
        {
            thread MakeScoreRUI();
            message = "Round start"
			subtext = ""
            break
        }
        case eGUNGAMEAnnounce.VOTING_PHASE:
        {
            clGlobal.levelEnt.Signal( "CloseScoreRUI" )
            message = "Welcome To Gun Game"
			subtext = ""
            break
        }
        case eGUNGAMEAnnounce.MAP_FLYOVER:
        {

            if(file.LocationSettings_Gun_Game.len())
                message = file.selectedLocation.name
			subtext = "First to reach the last weapon wins"
            break
        }
    }
	AnnouncementData announcement = Announcement_Create( message )
    Announcement_SetSubText(announcement, subtext)
	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_CIRCLE_WARNING )
	Announcement_SetPurge( announcement, true )
	Announcement_SetOptionalTextArgsArray( announcement, [ "true" ] )
	Announcement_SetPriority( announcement, 200 ) //Be higher priority than Titanfall ready indicator etc
	announcement.duration = duration
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}


void function ServerCallback_Gun_Game_DoCountDown(int timeToWait)
{
    string message = ""
    string subtext = ""

    message = "Game starting in " + timeToWait
	subtext = ""


	AnnouncementData announcement = Announcement_Create( message )
    Announcement_SetSubText(announcement, subtext)
	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_QUICK )
	Announcement_SetPurge( announcement, true )
	Announcement_SetOptionalTextArgsArray( announcement, [ "true" ] )
	Announcement_SetPriority( announcement, 200 ) //Be higher priority than Titanfall ready indicator etc
	announcement.duration = 0.9
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}


void function ServerCallback_Gun_Game_DoLocationIntroCutscene()
{
    thread ServerCallback_Gun_Game_DoLocationIntroCutscene_Body()
}

void function ServerCallback_Gun_Game_DoLocationIntroCutscene_Body()
{
	//Get the local player to play cinematics on
    entity player = GetLocalClientPlayer()

    if(IsValid(player))
        EmitSoundOnEntity( player, "music_skyway_04_smartpistolrun" )

    float playerFOV = player.GetFOV()

	//Creates the camera that will be used for cinematic
    entity camera = CreateClientSidePointCamera(file.selectedLocation.spawns[0].origin + file.selectedLocation.cinematicCameraOffset, <90, 90, 0>, 17)
    camera.SetFOV(90)

	//Anchor point of the camera
    entity cutsceneMover = CreateClientsideScriptMover($"mdl/dev/empty_model.rmdl", file.selectedLocation.spawns[0].origin + file.selectedLocation.cinematicCameraOffset, <90, 90, 0>)
    camera.SetParent(cutsceneMover)
    wait 1

	GetLocalClientPlayer().SetMenuCameraEntity( camera )

	//Create temporary UI during the cutscene
    for(int i = 0; i < file.selectedLocation.spawns.len(); i++)
    {
        entity spawn = CreateClientSidePropDynamic(OriginToGround(file.selectedLocation.spawns[i].origin), <0, 0, 0>, $"mdl/dev/empty_model.rmdl" )
        thread CreateTemporarySpawnRUI(spawn, LOCATION_CUTSCENE_DURATION_GUN_GAME + 2)
    }

	//For each point, interpolate the camera above it
    for(int i = 1; i < file.selectedLocation.spawns.len(); i++)
    {

        float duration = LOCATION_CUTSCENE_DURATION_GUN_GAME / max(1, file.selectedLocation.spawns.len() - 1)
        cutsceneMover.NonPhysicsMoveTo(file.selectedLocation.spawns[i].origin + file.selectedLocation.cinematicCameraOffset, duration, 1, 1)
        wait duration
    }

    wait 1

	//Moves the camera on the eyes of the player
    cutsceneMover.NonPhysicsMoveTo(GetLocalClientPlayer().GetOrigin() + <0, 0, 100>, 2, 1, 1)
    cutsceneMover.NonPhysicsRotateTo(GetLocalClientPlayer().GetAngles(), 2, 1, 1)
	camera.SetTargetFOV(playerFOV, true, EASING_CUBIC_INOUT, 2 )

    wait 2

	//Delete anchor point and reset camera
    GetLocalClientPlayer().ClearMenuCameraEntity()
    cutsceneMover.Destroy()

	//Plays sounds
    player = GetLocalClientPlayer()
    if(IsValid(player))
        FadeOutSoundOnEntity( player, "music_skyway_04_smartpistolrun", 1 )

	//Delete camera
    camera.Destroy()
}

void function ServerCallback_Gun_Game_SetSelectedLocation(int sel)
{
    file.selectedLocation = file.LocationSettings_Gun_Game[sel]
}

void function ServerCallback_Gun_Game_PlayerKilled(entity bestPlayer, int bestPlayerScore)
{
    if(file.scoreRui) {
      if (!IsValid(bestPlayer)) return
		printt("---------------------" + "Best player: " + bestPlayer.GetPlayerName() + " (" + bestPlayerScore + " kills)" )
        RuiSetString( file.scoreRui, "messageText", "Best player: " + bestPlayer.GetPlayerName() + " (" + bestPlayerScore + " kills)");
	}
}

var function CreateTemporarySpawnRUI(entity parentEnt, float duration)
{
	var rui = AddOverheadIcon( parentEnt, RESPAWN_BEACON_ICON, false, $"ui/overhead_icon_respawn_beacon.rpak" )
	RuiSetFloat2( rui, "iconSize", <80,80,0> )
	RuiSetFloat( rui, "distanceFade", 50000 )
	RuiSetBool( rui, "adsFade", true )
	RuiSetString( rui, "hint", "SPAWN POINT" )

    wait duration

    parentEnt.Destroy()
}

void function CreateBlackBars() {
    BLACKBAR_RUI = CreateFullscreenRui( $"ui/death_screen_black_bar.rpak", 1000 )
}

void function DestroyBlackBars() {
    if (BLACKBAR_RUI != null) RuiDestroyIfAlive(BLACKBAR_RUI)
    BLACKBAR_RUI = null
}








//
//
// VICTORY SCREEN
//
//

//Thanks to @Pebbers#9558 for extracting this code from br !!!


struct VictorySoundPackage
{
	string youAreChampPlural
	string youAreChampSingular
	string theyAreChampPlural
	string theyAreChampSingular
}

struct VictoryCameraPackage
{
	vector camera_offset_start
	vector camera_offset_end
	vector camera_focus_offset
	float  camera_fov
}

array<void functionref( bool )> s_callbacks_OnUpdateShowButtonHints
array<void functionref( entity, ItemFlavor, int )> s_callbacks_OnVictoryCharacterModelSpawned

void function ServerCallback_Gun_Game_AddWinningSquadData( int index, int eHandle)
{
	if ( index == -1 )
	{
		file.winnerSquadSummaryData.playerData.clear()
		file.winnerSquadSummaryData.squadPlacement = -1
		return
	}

	SquadSummaryPlayerData data
	data.eHandle = eHandle
	file.winnerSquadSummaryData.playerData.append( data )
	file.winnerSquadSummaryData.squadPlacement = 1
}

void function ServerCallback_Gun_Game_DoVictory() {
  thread ShowVictorySequence()
}

void function ServerCallback_Gun_Game_MatchEndAnnouncement( bool victory, int winningTeam )
{
	clGlobal.levelEnt.Signal( "SquadEliminated" )

	CreateBlackBars()
	entity clientPlayer = GetLocalClientPlayer()
	Assert( IsValid( clientPlayer ) )

	Gun_Game_ShowChampionVictoryScreen( winningTeam )
}

void function Gun_Game_ShowChampionVictoryScreen( int winningTeam )
{
	if ( file.victoryRui != null )
		return

	entity clientPlayer = GetLocalClientPlayer()

	//
	HideGladiatorCardSidePane( true )

	asset ruiAsset = GetChampionScreenRuiAsset()
	file.victoryRui = CreateFullscreenRui( ruiAsset )
    printl("VICTORY RUI " + file.victoryRui)
	RuiSetBool( file.victoryRui, "onWinningTeam", GetLocalClientPlayer().GetTeam() == winningTeam )

	EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_ChampionVictory" )

	Chroma_VictoryScreen()
}

asset function GetChampionScreenRuiAsset()
{
	return $"ui/champion_screen.rpak"
}

void function VictorySequenceOrderLocalPlayerFirst( entity player )
{
	int playerEHandle = player.GetEncodedEHandle()
	bool hadLocalPlayer = false
	array<SquadSummaryPlayerData> playerDataArray
	SquadSummaryPlayerData localPlayerData

	foreach( SquadSummaryPlayerData data in file.winnerSquadSummaryData.playerData )
	{
		if ( data.eHandle == playerEHandle )
		{
			localPlayerData = data
			hadLocalPlayer = true
			continue
		}

		playerDataArray.append( data )
	}

	file.winnerSquadSummaryData.playerData = playerDataArray
	if ( hadLocalPlayer )
		file.winnerSquadSummaryData.playerData.insert( 0, localPlayerData )
}


void function ShowVictorySequence( bool placementMode = false )
{
    printl("RUI: " + file.victoryRui)
    if ( file.victoryRui != null ) {
        printl("DESTROYING RUI")
    	RuiDestroyIfAlive( file.victoryRui )
    }

    file.victoryRui = null

	#if(!DEV)
		placementMode = false
	#endif

	entity player = GetLocalClientPlayer()

	player.EndSignal( "OnDestroy" )

	#if(true)
		array<int> offsetArray = [90, 78, 78, 90, 90, 78, 78, 90, 90, 78]
	#endif

	//
	ScreenFade( player, 255, 255, 255, 255, 0.4, 2.0, FFADE_OUT | FFADE_PURGE )

	EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_ChampionMountain_Whoosh" )

	wait 0.4

	file.IsShowingVictorySequence = true
    DestroyBlackBars()
	DeathScreenUpdate()


	HideGladiatorCardSidePane( true )
	Signal( player, "Bleedout_StopBleedoutEffects" )

	ScreenFade( player, 255, 255, 255, 255, 0.4, 0.0, FFADE_IN | FFADE_PURGE )

	//
	asset defaultModel                = GetGlobalSettingsAsset( DEFAULT_PILOT_SETTINGS, "bodyModel" )
	LoadoutEntry loadoutSlotCharacter = Loadout_CharacterClass()
	vector characterAngles            = < file.victorySequenceAngles.x / 2.0, file.victorySequenceAngles.y, file.victorySequenceAngles.z >

	array<entity> cleanupEnts
	array<var> overHeadRuis

	//
	VictoryPlatformModelData victoryPlatformModelData = GetVictorySequencePlatformModel()
	entity platformModel
	int maxPlayersToShow = -1
	if ( victoryPlatformModelData.isSet )
	{
		platformModel = CreateClientSidePropDynamic( file.victorySequencePosition + victoryPlatformModelData.originOffset, victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )
		#if(true)
			entity platformModel2 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, -284, 1000, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )
			entity platformModel3 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, -284, 0, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )					//
			entity platformModel4 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, -500, 200, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )
			entity platformModel5 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, -284, 500, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )
			entity platformModel6 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, 0, 500, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )					//
			entity platformModel7 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, 300, 300, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )
			entity platformModel8 = CreateClientSidePropDynamic( PositionOffsetFromEnt( platformModel, 0, 1000, 0 ), victoryPlatformModelData.modelAngles, victoryPlatformModelData.modelAsset )
			cleanupEnts.append( platformModel2 )
			cleanupEnts.append( platformModel3 )
			cleanupEnts.append( platformModel4 )
			cleanupEnts.append( platformModel5 )
			cleanupEnts.append( platformModel6 )
			cleanupEnts.append( platformModel7 )
			cleanupEnts.append( platformModel8 )
			maxPlayersToShow = 16
		#endif //

		cleanupEnts.append( platformModel )
		int playersOnPodium = 0

		//
		VictorySequenceOrderLocalPlayerFirst( player )

		foreach( int i, SquadSummaryPlayerData data in file.winnerSquadSummaryData.playerData )
		{
			if ( maxPlayersToShow > 0 && i > maxPlayersToShow )
				break

			string playerName = ""
			if ( EHIHasValidScriptStruct( data.eHandle ) )
				playerName = EHI_GetName( data.eHandle )

			if ( !LoadoutSlot_IsReady( data.eHandle, loadoutSlotCharacter ) )
				continue

			ItemFlavor character = LoadoutSlot_GetItemFlavor( data.eHandle, loadoutSlotCharacter )

			if ( !LoadoutSlot_IsReady( data.eHandle, Loadout_CharacterSkin( character ) ) )
				continue

			ItemFlavor characterSkin = LoadoutSlot_GetItemFlavor( data.eHandle, Loadout_CharacterSkin( character ) )

			vector pos = GetVictorySquadFormationPosition( file.victorySequencePosition, file.victorySequenceAngles, i )

			//
			entity characterNode = CreateScriptRef( pos, characterAngles )
			characterNode.SetParent( platformModel, "", true )
			entity characterModel = CreateClientSidePropDynamic( pos, characterAngles, defaultModel )
			SetForceDrawWhileParented( characterModel, true )
			characterModel.MakeSafeForUIScriptHack()
			CharacterSkin_Apply( characterModel, characterSkin )
			cleanupEnts.append( characterModel )

			//
			foreach( func in s_callbacks_OnVictoryCharacterModelSpawned )
				func( characterModel, character, data.eHandle )

			//
			characterModel.SetParent( characterNode, "", false )
			string victoryAnim = GetVictorySquadFormationActivity( i, characterModel )
			characterModel.Anim_Play( victoryAnim )
			characterModel.Anim_EnableUseAnimatedRefAttachmentInsteadOfRootMotion()


			#if R5DEV
				if ( GetBugReproNum() == 1111 || GetBugReproNum() == 2222 )
				{
					playersOnPodium++
					continue
				}
			#endif

			//
			bool createOverheadRui = true
			if ( createOverheadRui )
			{
				int offset = 78

				entity overheadEnt = CreateClientSidePropDynamic( pos + (AnglesToUp( file.victorySequenceAngles ) * offset), <0, 0, 0>, $"mdl/dev/empty_model.rmdl" )
				overheadEnt.Hide()
				var overheadRui = RuiCreate( $"ui/winning_squad_member_overhead_name.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
				RuiSetString( overheadRui, "playerName", playerName )
				RuiTrackFloat3( overheadRui, "position", overheadEnt, RUI_TRACK_ABSORIGIN_FOLLOW )
				overHeadRuis.append( overheadRui )
			}

			playersOnPodium++
		}

		//
		VictorySoundPackage victorySoundPackage = GetVictorySoundPackage()
		string dialogueApexChampion
		if ( player.GetTeam() == GetWinningTeam() )
		{
			//
			if ( playersOnPodium > 1 )
				dialogueApexChampion = victorySoundPackage.youAreChampPlural
			else
				dialogueApexChampion = victorySoundPackage.youAreChampSingular
		}
		else
		{
			if ( playersOnPodium > 1 )
				dialogueApexChampion = victorySoundPackage.theyAreChampPlural
			else
				dialogueApexChampion = victorySoundPackage.theyAreChampSingular
		}

		EmitSoundOnEntityAfterDelay( platformModel, dialogueApexChampion, 0.5 )

		//
		VictoryCameraPackage victoryCameraPackage = GetVictoryCameraPackage()

		vector camera_offset_start = victoryCameraPackage.camera_offset_start
		vector camera_offset_end   = victoryCameraPackage.camera_offset_end
		vector camera_focus_offset = victoryCameraPackage.camera_focus_offset
		float camera_fov           = victoryCameraPackage.camera_fov

		vector camera_start_pos = OffsetPointRelativeToVector( file.victorySequencePosition, camera_offset_start, AnglesToForward( file.victorySequenceAngles ) )
		vector camera_end_pos   = OffsetPointRelativeToVector( file.victorySequencePosition, camera_offset_end, AnglesToForward( file.victorySequenceAngles ) )
		vector camera_focus_pos = OffsetPointRelativeToVector( file.victorySequencePosition, camera_focus_offset, AnglesToForward( file.victorySequenceAngles ) )

		vector camera_start_angles = VectorToAngles( camera_focus_pos - camera_start_pos )
		vector camera_end_angles   = VectorToAngles( camera_focus_pos - camera_end_pos )

		entity cameraMover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", camera_start_pos, camera_start_angles )
		entity camera      = CreateClientSidePointCamera( camera_start_pos, camera_start_angles, camera_fov )
		player.SetMenuCameraEntity( camera )
		camera.SetTargetFOV( camera_fov, true, EASING_CUBIC_INOUT, 0.0 )
		camera.SetParent( cameraMover, "", false )
		cleanupEnts.append( camera )

		//
		GetLightEnvironmentEntity().ScaleSunSkyIntensity( file.victorySunIntensity, file.victorySkyIntensity )

		//
		float camera_move_duration = 6.5
		cameraMover.NonPhysicsMoveTo( camera_end_pos, camera_move_duration, 0.0, camera_move_duration / 2.0 )
		cameraMover.NonPhysicsRotateTo( camera_end_angles, camera_move_duration, 0.0, camera_move_duration / 2.0 )
		cleanupEnts.append( cameraMover )

		wait camera_move_duration - 0.5
	}

	file.IsShowingVictorySequence = false

	Assert( !IsSquadDataPersistenceEmpty(), "Persistence didn't get transmitted to the client in time!" )
	SetSquadDataToLocalTeam()    //

	wait 1.0

    ScreenFade( player, 255, 255, 255, 255, 0.4, 2.0, FFADE_OUT | FFADE_PURGE )
	foreach( rui in overHeadRuis )
		RuiDestroyIfAlive( rui )

	foreach( entity ent in cleanupEnts )
		ent.Destroy()

	wait 1
	ScreenFade( player, 255, 255, 255, 255, 0.4, 0.0, FFADE_IN | FFADE_PURGE )
}



vector function GetVictorySquadFormationPosition( vector mainPosition, vector angles, int index )
{
	if ( index == 0 )
		return mainPosition - <0, 0, 8>

	float offset_side = 48.0
	float offset_back = -28.0

	#if(false)
				if ( index < 7 )
				{
					offset_side = 48.0
					offset_back = -48.0
				}
				else if ( index == 7 )
					return OffsetPointRelativeToVector( mainPosition, <24, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 8 )
					return OffsetPointRelativeToVector( mainPosition, <48, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 9 )
					return OffsetPointRelativeToVector( mainPosition, <72, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 10 )
					return OffsetPointRelativeToVector( mainPosition, <96, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 11 )
					return OffsetPointRelativeToVector( mainPosition, <120, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 12 )
					return OffsetPointRelativeToVector( mainPosition, <-24, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 13 )
					return OffsetPointRelativeToVector( mainPosition, <-48, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 14 )
					return OffsetPointRelativeToVector( mainPosition, <-96, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 15 )
					return OffsetPointRelativeToVector( mainPosition, <-120, 16, -8>, AnglesToForward( angles ) )
				else if ( index == 16 )
					return OffsetPointRelativeToVector( mainPosition, <12, 32, -8>, AnglesToForward( angles ) )

			else
			{
				if ( index > 2 )
				{
					//
					offset_side = 56.0
					offset_back = -28.0

				}
			}


	#endif //

	int countBack = (index + 1) / 2
	vector offset = < offset_side, offset_back, 0 > * countBack

	if ( index % 2 == 0 )
		offset.x *= -1

	vector point = OffsetPointRelativeToVector( mainPosition, offset, AnglesToForward( angles ) )
	return point - <0, 0, 8>
}

string function GetVictorySquadFormationActivity( int index, entity characterModel )
{
	#if(false)
		bool animExists = characterModel.LookupSequence( "ACT_VICTORY_DANCE" ) != -1
		if ( animExists )
			return "ACT_VICTORY_DANCE"
		else
		{
			Assert( characterModel.LookupSequence( "ACT_MP_MENU_LOBBY_SELECT_IDLE" ) != -1, "Unable to find victory idle for " + characterModel )
			return "ACT_MP_MENU_LOBBY_SELECT_IDLE"
		}
	#endif //

	return "ACT_MP_MENU_LOBBY_SELECT_IDLE"
}

VictoryCameraPackage function GetVictoryCameraPackage()
{
	VictoryCameraPackage victoryCameraPackage

	#if(false)

		if ( true )
		{
			victoryCameraPackage.camera_offset_start = <0, 725, 100>
			victoryCameraPackage.camera_offset_end = <0, 400, 48>
		}
		else
		{
			victoryCameraPackage.camera_offset_start = <0, 735, 68>
			victoryCameraPackage.camera_offset_end = <0, 625, 48>
		}

		victoryCameraPackage.camera_focus_offset = <0, 0, 36>
		victoryCameraPackage.camera_fov = 35.5

		return victoryCameraPackage

	#endif //

	victoryCameraPackage.camera_offset_start = <0, 320, 68>
	victoryCameraPackage.camera_offset_end = <0, 200, 48>
	victoryCameraPackage.camera_focus_offset = <0, 0, 36>
	victoryCameraPackage.camera_fov = 35.5

	return victoryCameraPackage
}

VictorySoundPackage function GetVictorySoundPackage()
{
	VictorySoundPackage victorySoundPackage

	#if(false)
		if ( true )
		{
			float randomFloat = RandomFloatRange( 0, 1 )
			if ( true )
			{
				string shadowsWinAlias
				if ( randomFloat < 0.33 )
					shadowsWinAlias = "diag_ap_nocNotify_shadowSquadWin_01_3p"
				else if ( randomFloat < 0.66 )
					shadowsWinAlias = "diag_ap_nocNotify_shadowSquadWin_02_3p"
				else
					shadowsWinAlias = "diag_ap_nocNotify_shadowSquadWin_03_3p"
				victorySoundPackage.youAreChampPlural = shadowsWinAlias
				victorySoundPackage.youAreChampSingular = shadowsWinAlias
				victorySoundPackage.theyAreChampPlural = shadowsWinAlias
				victorySoundPackage.theyAreChampSingular = shadowsWinAlias
			}
			else //
			{
				if ( randomFloat < 0.33 )
				{
					victorySoundPackage.youAreChampPlural = "diag_ap_nocNotify_victorySquad_01_3p" //
					victorySoundPackage.youAreChampSingular = "diag_ap_nocNotify_victorySolo_03_3p" //
					victorySoundPackage.theyAreChampSingular = "diag_ap_nocNotify_victorySolo_01_3p" //
				}
				else if ( randomFloat < 0.66 )
				{
					victorySoundPackage.youAreChampPlural = "diag_ap_nocNotify_victorySquad_02_3p" //
					victorySoundPackage.youAreChampSingular = "diag_ap_nocNotify_victorySolo_04_3p" //
					victorySoundPackage.theyAreChampSingular = "diag_ap_nocNotify_victorySolo_02_3p" //
				}
				else
				{
					victorySoundPackage.youAreChampPlural = "diag_ap_nocNotify_victorySquad_03_3p" //
					victorySoundPackage.youAreChampSingular = "diag_ap_nocNotify_victorySolo_05_3p" //
					victorySoundPackage.theyAreChampSingular = "diag_ap_nocNotify_victorySolo_01_3p" //
				}
				victorySoundPackage.theyAreChampPlural = "diag_ap_nocNotify_victorySquad_03_3p" //

			}

			return victorySoundPackage
		}
	#endif //

	victorySoundPackage.youAreChampPlural = "diag_ap_aiNotify_winnerFound_07" //
	victorySoundPackage.youAreChampSingular = "diag_ap_aiNotify_winnerFound_10" //
	victorySoundPackage.theyAreChampPlural = "diag_ap_aiNotify_winnerFound_08" //
	victorySoundPackage.theyAreChampSingular = "diag_ap_ainotify_introchampion_01_02" //

	return victorySoundPackage
}
