global function InitGamemodeSelectV2Dialog
global function GamemodeSelectV2_IsEnabled
global function GamemodeSelectV2_UpdateSelectButton
global function GamemodeSelectV2_PlayVideo

struct {
	var menu
	var closeButton
	var selectionPanel

	int   videoChannel = -1
	asset currentVideoAsset = $""

	array<var>         modeSelectButtonList
	table<var, string> selectButtonPlaylistNameMap
} file


const int MAX_DISPLAYED_MODES = 4

const table<string, asset> GAMEMODE_IMAGE_MAP = {
	play_apex = $"rui/menu/gamemode/play_apex",
	apex_elite = $"rui/menu/gamemode/apex_elite",
	training = $"rui/menu/gamemode/training",
	generic_01 = $"rui/menu/gamemode/generic_01",
	generic_02 = $"rui/menu/gamemode/generic_02",
	ranked_1 = $"rui/menu/gamemode/ranked_1",
	ranked_2 = $"rui/menu/gamemode/ranked_2",
	solo_iron_crown = $"rui/menu/gamemode/solo_iron_crown",
	#if(true)
		shotguns_and_snipers = $"rui/menu/gamemode/shotguns_and_snipers",
	#endif
	#if(false)

#endif
}

const table<string, asset> GAMEMODE_BINK_MAP = {
	play_apex = $"media/gamemodes/play_apex.bik",
	apex_elite = $"media/gamemodes/apex_elite.bik",
	training = $"media/gamemodes/training.bik",
	generic_01 = $"media/gamemodes/generic_01.bik",
	generic_02 = $"media/gamemodes/generic_02.bik",
	ranked_1 = $"media/gamemodes/ranked_1.bik",
	ranked_2 = $"media/gamemodes/ranked_2.bik",
	solo_iron_crown = $"media/gamemodes/solo_iron_crown.bik",
	#if(true)
		shotguns_and_snipers = $"media/gamemodes/shotguns_and_snipers.bik",
	#endif
	#if(false)

#endif
}


bool function GamemodeSelectV2_IsEnabled()
{
	return GetCurrentPlaylistVarBool( "gamemode_select_v2_enable", true )
}


//
const int DRAW_NONE = 0
const int DRAW_IMAGE = 1
const int DRAW_RANK = 2

void function GamemodeSelectV2_UpdateSelectButton( var button, string playlistName )
{
	var rui = Hud_GetRui( button )

	string nameText = GetPlaylistVarString( playlistName, "name", "#PLAYLIST_UNAVAILABLE" )
	RuiSetString( rui, "modeNameText", nameText )

	string descText = GetPlaylistVarString( playlistName, "description", "#HUD_UNKNOWN" )
	RuiSetString( rui, "modeDescText", descText )

	RuiSetString( rui, "modeLockedReason", "" )

	RuiSetBool( rui, "alwaysShowDesc", false )

	RuiSetBool( rui, "isPartyLeader", false )
	RuiSetBool( rui, "showLockedIcon", true )

	RuiSetBool( rui, "isLimitedTime", GetPlaylistVarBool( playlistName, "is_limited_time", false ) )

	string imageKey  = GetPlaylistVarString( playlistName, "image", "" )
	asset imageAsset = $"white"
	if ( imageKey != "" )
	{
		if ( imageKey in GAMEMODE_IMAGE_MAP )
			imageAsset = GAMEMODE_IMAGE_MAP[imageKey]
		else
			Warning( "Playlist '%s' has invalid value for 'image': %s", playlistName, imageKey )
	}
	RuiSetImage( Hud_GetRui( button ), "modeImage", imageAsset )


	bool isPlaylistAvailable = Lobby_IsPlaylistAvailable( playlistName )
	Hud_SetLocked( button, !isPlaylistAvailable )
	RuiSetString( rui, "modeLockedReason", Lobby_GetPlaylistStateString( Lobby_GetPlaylistState( playlistName ) ) )

	int emblemMode = DRAW_NONE
	if ( IsRankedPlaylist( playlistName ) )
	{
		/*emblemMode = DRAW_RANK
		int rankScore = GetPlayerRankScore( GetUIPlayer() )
		PopulateRuiWithRankedBadgeDetails( rui, rankScore, Ranked_GetDisplayNumberForRuiBadge( GetUIPlayer() ) )*/
	}
	else
	{
		asset emblemImage = GetModeEmblemImage( playlistName )
		if ( emblemImage != $"" )
		{
			emblemMode = DRAW_IMAGE
			RuiSetImage( rui, "emblemImage", emblemImage )
		}
	}
	RuiSetInt( rui, "emblemMode", emblemMode )

	file.selectButtonPlaylistNameMap[button] <- playlistName
}


void function GamemodeSelectV2_PlayVideo( var button, string playlistName )
{
	string videoKey         = GetPlaylistVarString( playlistName, "video", "" )
	asset desiredVideoAsset = $""
	if ( videoKey != "" )
	{
		if ( videoKey in GAMEMODE_BINK_MAP )
			desiredVideoAsset = GAMEMODE_BINK_MAP[videoKey]
		else
			Warning( "Playlist '%s' has invalid value for 'video': %s", playlistName, videoKey )
	}

	if ( desiredVideoAsset != $"" )
		file.currentVideoAsset = $"" //
	Signal( uiGlobal.signalDummy, "GamemodeSelectV2_EndVideoStopThread" )
	Assert( file.currentVideoAsset == $"" )

	if ( desiredVideoAsset != $"" )
	{
		if ( file.videoChannel == -1 )
			file.videoChannel = ReserveVideoChannel()

		StartVideoOnChannel( file.videoChannel, desiredVideoAsset, true, 0.0 )
		file.currentVideoAsset = desiredVideoAsset
	}

	var rui = Hud_GetRui( button )
	RuiSetBool( rui, "hasVideo", videoKey != "" )
	RuiSetInt( rui, "channel", file.videoChannel )
	if ( file.currentVideoAsset != $"" )
		thread VideoStopThread( button )
}


void function VideoStopThread( var button )
{
	EndSignal( uiGlobal.signalDummy, "GamemodeSelectV2_EndVideoStopThread" )

	OnThreadEnd( function() : ( button ) {
		if ( IsValid( button ) )
		{
			var rui = Hud_GetRui( button )
			RuiSetInt( rui, "channel", -1 )
		}
		if ( file.currentVideoAsset != $"" )
		{
			StopVideoOnChannel( file.videoChannel )
			file.currentVideoAsset = $""
		}
	} )

	while ( GetFocus() == button )
		WaitFrame()

	wait 0.3
}


void function InitGamemodeSelectV2Dialog( var newMenuArg ) //
{
	var menu = GetMenu( "GamemodeSelectV2Dialog" )
	file.menu = menu

	file.selectionPanel = Hud_GetChild( menu, "GamemodeSelectPanel" )

	SetDialog( menu, true )
	SetClearBlur( menu, false )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenModeSelectDialog )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnCloseModeSelectDialog )

	file.closeButton = Hud_GetChild( menu, "CloseButton" )
	Hud_AddEventHandler( file.closeButton, UIE_CLICK, OnCloseButton_Activate )

	for ( int buttonIdx = 0; buttonIdx < MAX_DISPLAYED_MODES; buttonIdx++ )
	{
		var button = Hud_GetChild( file.menu, format( "GamemodeButton%d", buttonIdx ) )
		Hud_AddEventHandler( button, UIE_CLICK, GamemodeButton_Activate )
		Hud_AddEventHandler( button, UIE_GET_FOCUS, GamemodeButton_OnGetFocus )
		Hud_AddEventHandler( button, UIE_LOSE_FOCUS, GamemodeButton_OnLoseFocus )
		file.modeSelectButtonList.append( button )
	}

	RegisterSignal( "GamemodeSelectV2_EndVideoStopThread" )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#CLOSE" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT" )
}


void function OnOpenModeSelectDialog()
{
	Hud_SetAboveBlur( GetMenu( "LobbyMenu" ), false )

	file.selectButtonPlaylistNameMap.clear()

	table<string, string> slotToPlaylistNameMap = {
		training = "",
		regular_1 = "",
		regular_2 = "",
		ltm = "",
	}

	foreach ( string candidatePlaylistName in GetVisiblePlaylistNames() )
	{
		string uiSlot = GetPlaylistVarString( candidatePlaylistName, "ui_slot", "" )
		if ( uiSlot != "" )
		{
			if ( uiSlot in slotToPlaylistNameMap )
			{
				if ( slotToPlaylistNameMap[uiSlot] == "" )
					slotToPlaylistNameMap[uiSlot] = candidatePlaylistName
				else
					Warning( "Playlist '%s' and '%s' specify the same 'ui_slot': %s", candidatePlaylistName, slotToPlaylistNameMap[uiSlot], uiSlot )
			}
			else
				Warning( "Playlist '%s' has invalid value for 'ui_slot': %s", candidatePlaylistName, uiSlot )
		}
	}

	table<string, var> slotToButtonMap = {
		training = Hud_GetChild( file.menu, "GamemodeButton0" ),
		regular_1 = Hud_GetChild( file.menu, "GamemodeButton1" ),
		regular_2 = Hud_GetChild( file.menu, "GamemodeButton2" ),
		ltm = Hud_GetChild( file.menu, "GamemodeButton3" ),
	}

	int totalButtonWidth = 0

	printt( GetScreenSize().width )
	float scale = float( GetScreenSize().width ) / 1920.0
	printt( totalButtonWidth )
	printt( scale )

	foreach ( string slot, var button in slotToButtonMap )
	{
		string playlistName = slotToPlaylistNameMap[slot]
		if ( playlistName == "" )
		{
			Hud_Hide( button )
			continue
		}

		Hud_Show( button )
		totalButtonWidth += Hud_GetWidth( button ) + int(48*scale)

		GamemodeSelectV2_UpdateSelectButton( button, playlistName )
	}

	bool hasLimitedMode = (slotToPlaylistNameMap["ltm"] != "")
	RuiSetBool( Hud_GetRui( file.selectionPanel ), "hasLimitedMode", hasLimitedMode )
	int w = hasLimitedMode ? Hud_GetBaseWidth( file.selectionPanel ) : ( totalButtonWidth + int(48*scale) )
	Hud_SetWidth( file.selectionPanel, w )
}


void function OnCloseModeSelectDialog()
{
	Hud_SetAboveBlur( GetMenu( "LobbyMenu" ), true )

	var modeSelectButton = GetModeSelectButton()
	Hud_SetSelected( modeSelectButton, false )
	Hud_SetFocused( modeSelectButton )

	Lobby_OnGamemodeSelectV2Close()
}


void function GamemodeButton_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	string playlistName = file.selectButtonPlaylistNameMap[button]
	Lobby_SetSelectedPlaylist( playlistName )

	CloseAllDialogs()
}


void function GamemodeButton_OnGetFocus( var button )
{
	//

	string playlistName = file.selectButtonPlaylistNameMap[button]
	GamemodeSelectV2_PlayVideo( button, playlistName )
}


void function GamemodeButton_OnLoseFocus( var button )
{
	//
}


void function OnCloseButton_Activate( var button )
{
	CloseAllDialogs()
}


