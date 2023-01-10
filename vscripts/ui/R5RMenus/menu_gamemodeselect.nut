global function InitR5RGamemodeSelectDialog
global function GamemodeSelectV22_UpdateSelectButton
global function GamemodeSelectV22_PlayVideo
global function GamemodeSelectV22_PlaylistIsDefaultSlot

struct {
	var menu
	var closeButton
	var selectionPanel

	int   videoChannel = -1
	asset currentVideoAsset = $""

	array<var>         modeSelectButtonList
	table<var, string> selectButtonPlaylistNameMap
    table<var, asset> selectButtonPlaylistAssetMap
} file


const int MAX_DISPLAYED_MODES = 5

const table<string, asset> GAMEMODE_IMAGE_MAP = {
	play_apex = $"rui/menu/gamemode/play_apex",
	apex_elite = $"rui/menu/gamemode/apex_elite",
	training = $"rui/menu/gamemode/training",
	firing_range = $"rui/menu/gamemode/firing_range",
	generic_01 = $"rui/menu/gamemode/generic_01",
	generic_02 = $"rui/menu/gamemode/generic_02",
	ranked_1 = $"rui/menu/gamemode/ranked_1",
	ranked_2 = $"rui/menu/gamemode/ranked_2",
	solo_iron_crown = $"rui/menu/gamemode/solo_iron_crown",
	duos = $"rui/menu/gamemode/duos",
	worlds_edge = $"rui/menu/gamemode/worlds_edge",
	shotguns_and_snipers = $"rui/menu/gamemode/shotguns_and_snipers",
	shadow_squad = $"rui/menu/gamemode/shadow_squad",
	worlds_edge_after_dark = $"rui/menu/gamemode/shadow_squad",
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
	duos = $"media/gamemodes/duos.bik",
	worlds_edge = $"media/gamemodes/worlds_edge.bik",
	shotguns_and_snipers = $"media/gamemodes/shotguns_and_snipers.bik",
	shadow_squad = $"media/gamemodes/shadow_squad.bik",
	worlds_edge_after_dark = $"media/gamemodes/wead.bik",
}

//
const int DRAW_NONE = 0
const int DRAW_IMAGE = 1
const int DRAW_RANK = 2

void function GamemodeSelectV22_UpdateSelectButton( var button, string playlistName )
{
	var rui = Hud_GetRui( button )

	string nameText = GetPlaylistVarString( playlistName, "name", "#PLAYLIST_UNAVAILABLE" )
	RuiSetString( rui, "modeNameText", playlistName )

	string descText = GetPlaylistVarString( playlistName, "description", "#HUD_UNKNOWN" )
	RuiSetString( rui, "modeDescText", descText )

    if(playlistName == "Random")
        RuiSetString( rui, "modeDescText", "Random Gamemode" )

	RuiSetString( rui, "modeLockedReason", "" )
	RuiSetBool( rui, "alwaysShowDesc", false )
	RuiSetBool( rui, "isPartyLeader", true )
	RuiSetBool( rui, "showLockedIcon", false )
	RuiSetBool( rui, "isLimitedTime", false )

	string imageKey  = GetPlaylistVarString( playlistName, "image", "" )
	asset imageAsset = $"white"
	if ( imageKey != "" )
	{
		if ( imageKey in GAMEMODE_IMAGE_MAP )
			imageAsset = GAMEMODE_IMAGE_MAP[imageKey]
		else
			Warning( "Playlist '%s' has invalid value for 'image': %s", playlistName, imageKey )
	}

    if(playlistName == "Random")
        imageAsset = $"rui/menu/gamemode/ranked_1"
    
	RuiSetImage( Hud_GetRui( button ), "modeImage", imageAsset )

	Hud_SetLocked( button, false )
	RuiSetString( rui, "modeLockedReason", "" )

	RuiSetInt( rui, "emblemMode", DRAW_NONE )

	file.selectButtonPlaylistNameMap[button] <- playlistName
    file.selectButtonPlaylistAssetMap[button] <- imageAsset
}


void function GamemodeSelectV22_PlayVideo( var button, string playlistName )
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


void function InitR5RGamemodeSelectDialog( var newMenuArg ) //
{
	var menu = GetMenu( "R5RGamemodeSelectV2Dialog" )
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

const string DEFAULT_PLAYLIST_UI_SLOT_NAME = "regular_1"
bool function GamemodeSelectV22_PlaylistIsDefaultSlot( string playlist )
{
	string uiSlot = GetPlaylistVarString( playlist, "ui_slot", "" )
	return (uiSlot == DEFAULT_PLAYLIST_UI_SLOT_NAME)
}

void function OnOpenModeSelectDialog()
{
	Hud_SetAboveBlur( GetMenu( "R5RLobbyMenu" ), false )

    array<string> playlistLists = Servers_GetActivePlaylists()
    playlistLists.insert( 0, "Random")

    for( int i = 0; i < 5; i++ )
    {
        Hud_Hide(Hud_GetChild( file.menu, "GamemodeButton" + i ))
    }

    int i = 0
    int drawWidth = 0
    foreach( string playlistName in playlistLists )
    {
        var button = Hud_GetChild( file.menu, "GamemodeButton" + i )
        Hud_SetX( button, REPLACEHud_GetBasePos( button ).x )
		Hud_SetWidth( button, Hud_GetBaseWidth( button ) )
		Hud_Show( button )
		drawWidth += (REPLACEHud_GetPos( button ).x + Hud_GetWidth( button ))

		GamemodeSelectV22_UpdateSelectButton( button, playlistName )

        float scale = float( GetScreenSize().width ) / 1920.0
	    drawWidth += int( 48 * scale )

        RuiSetBool( Hud_GetRui( file.selectionPanel ), "hasLimitedMode", false )
	    RuiSetFloat( Hud_GetRui( file.selectionPanel ), "drawWidth", (drawWidth / scale) )
	    Hud_SetWidth( file.selectionPanel, drawWidth )
        i++
        if( i > 4 )
            break
    }
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
    asset imageasset = file.selectButtonPlaylistAssetMap[button]
	R5RPlay_SetSelectedPlaylist( playlistName, imageasset )

	CloseAllDialogs()
}


void function GamemodeButton_OnGetFocus( var button )
{
	//

	//string playlistName = file.selectButtonPlaylistNameMap[button]
	//GamemodeSelectV2_PlayVideo( button, playlistName )
}


void function GamemodeButton_OnLoseFocus( var button )
{
	//
}


void function OnCloseButton_Activate( var button )
{
	CloseAllDialogs()
}


