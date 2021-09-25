global function InitGamemodeSelectV2Dialog
global function GamemodeSelectV2_IsEnabled
global function GamemodeSelectV2_UpdateSelectButton
global function GamemodeSelectV2_PlayVideo
global function GamemodeSelectV2_PlaylistIsDefaultSlot

struct {
	var menu
	var closeButton
	var selectionPanel

	int   videoChannel = -1
	asset currentVideoAsset = $""

	array<var>         modeSelectButtonList
	table<var, string> selectButtonPlaylistNameMap
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


bool function GamemodeSelectV2_IsEnabled()
{
	return true
}


//
const int DRAW_NONE = 0
const int DRAW_IMAGE = 1
const int DRAW_RANK = 2

void function GamemodeSelectV2_UpdateSelectButton( var button, string playlistName )
{
	var rui = Hud_GetRui( button )

	//string nameText = GetPlaylistVarString( playlistName, "name", "#PLAYLIST_UNAVAILABLE" )
	RuiSetString( rui, "modeNameText", playlistName )

	RuiSetString( rui, "modeDescText", "Quickly goto firing range, find a server, or create a server" )

	RuiSetString( rui, "modeLockedReason", "" )

	RuiSetBool( rui, "alwaysShowDesc", false )

	RuiSetBool( rui, "isPartyLeader", false )
	RuiSetBool( rui, "showLockedIcon", false )

	RuiSetBool( rui, "isLimitedTime", false )

	string imageKey  = "duos"
	asset imageAsset = $"white"
	if ( imageKey != "" )
	{
		if ( imageKey in GAMEMODE_IMAGE_MAP )
			imageAsset = GAMEMODE_IMAGE_MAP[imageKey]
		else
			Warning( "Playlist '%s' has invalid value for 'image': %s", playlistName, imageKey )
	}
	RuiSetImage( Hud_GetRui( button ), "modeImage", imageAsset )
}

void function GamemodeSelectV2_UpdateSelectButton2( var button, string playlistName, string imagekey, string desc, string lockreason, bool locked )
{
	var rui = Hud_GetRui( button )

	//string nameText = GetPlaylistVarString( playlistName, "name", "#PLAYLIST_UNAVAILABLE" )
	RuiSetString( rui, "modeNameText", playlistName )

	RuiSetString( rui, "modeDescText", desc )

	RuiSetString( rui, "modeLockedReason", lockreason )

	RuiSetBool( rui, "alwaysShowDesc", false )

	RuiSetBool( rui, "isPartyLeader", false )
	RuiSetBool( rui, "showLockedIcon", locked )

	if (locked)
	{
		Hud_SetLocked( button, true )
	}
	else
	{
		Hud_SetLocked( button, false )
	}

	RuiSetBool( rui, "isLimitedTime", false )

	string imageKey  = imagekey
	asset imageAsset = $"white"
	if ( imageKey != "" )
	{
		if ( imageKey in GAMEMODE_IMAGE_MAP )
			imageAsset = GAMEMODE_IMAGE_MAP[imageKey]
		else
			Warning( "Playlist '%s' has invalid value for 'image': %s", playlistName, imageKey )
	}
	RuiSetImage( Hud_GetRui( button ), "modeImage", imageAsset )
}

void function GamemodeSelectV2_PlayVideo( var button, string playlistName )
{
	string videoKey         = playlistName
	asset desiredVideoAsset = $""

	desiredVideoAsset = GAMEMODE_BINK_MAP[videoKey]

	Assert( file.currentVideoAsset == GAMEMODE_BINK_MAP[videoKey] )

	if ( file.videoChannel == -1 )
		file.videoChannel = ReserveVideoChannel()

	StartVideoOnChannel( file.videoChannel, GAMEMODE_BINK_MAP[videoKey], true, 0.0 )
	file.currentVideoAsset = desiredVideoAsset

	var rui = Hud_GetRui( button )
	RuiSetBool( rui, "hasVideo", false )
	RuiSetInt( rui, "channel", -1 )
}


void function VideoStopThread( var button )
{

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

		Hud_AddEventHandler( button, UIE_GET_FOCUS, GamemodeButton_OnGetFocus )
		Hud_AddEventHandler( button, UIE_LOSE_FOCUS, GamemodeButton_OnLoseFocus )
		file.modeSelectButtonList.append( button )
	}

	var gandlergmbutton1 = Hud_GetChild( file.menu, "GamemodeButton0" )
	Hud_AddEventHandler( gandlergmbutton1, UIE_CLICK, GamemodeButton0_Activate )

	var gandlergmbutton2 = Hud_GetChild( file.menu, "GamemodeButton1" )
	Hud_AddEventHandler( gandlergmbutton2, UIE_CLICK, GamemodeButton1_Activate )

	var gandlergmbutton3 = Hud_GetChild( file.menu, "GamemodeButton2" )
	Hud_AddEventHandler( gandlergmbutton3, UIE_CLICK, GamemodeButton2_Activate )

	var gandlergmbutton4 = Hud_GetChild( file.menu, "GamemodeButton3" )
	Hud_AddEventHandler( gandlergmbutton4, UIE_CLICK, GamemodeButton3_Activate )

	var gandlergmbutton5 = Hud_GetChild( file.menu, "GamemodeButton4" )
	Hud_AddEventHandler( gandlergmbutton5, UIE_CLICK, GamemodeButton4_Activate )

	//RegisterSignal( "GamemodeSelectV2_EndVideoStopThread" )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#CLOSE" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT" )
}

const string DEFAULT_PLAYLIST_UI_SLOT_NAME = "regular_1"
bool function GamemodeSelectV2_PlaylistIsDefaultSlot( string playlist )
{
	string uiSlot = GetPlaylistVarString( playlist, "ui_slot", "" )
	return (uiSlot == DEFAULT_PLAYLIST_UI_SLOT_NAME)
}

void function OnOpenModeSelectDialog()
{
	Hud_SetAboveBlur( GetMenu( "LobbyMenu" ), false )

	file.selectButtonPlaylistNameMap.clear()

	table<string, string> slotToPlaylistNameMap = {
		training = "Enabled",
		firing_range = "Enabled",
		regular_1 = "Enabled",
		regular_2 = "Enabled",
		ltm = "Enabled",
	}

	table<string, var > slotToButtonMap = {
		training =		Hud_GetChild( file.menu, "GamemodeButton0" ),
		firing_range =	Hud_GetChild( file.menu, "GamemodeButton1" ),
		regular_1 =		Hud_GetChild( file.menu, "GamemodeButton2" ),
		regular_2 =		Hud_GetChild( file.menu, "GamemodeButton3" ),
		ltm =			Hud_GetChild( file.menu, "GamemodeButton4" ),
	}

	int drawWidth = 0
	foreach ( string slot, var button in slotToButtonMap )
	{
		string playlistName = slotToPlaylistNameMap[slot]
		if ( playlistName == "" )
		{
			Hud_Hide( button )
			Hud_SetWidth( button, 0 )
			Hud_SetX( button, 0 )
			continue
		}
	}



	var gamemodebutton0 = Hud_GetChild( file.menu, "GamemodeButton0" )

	Hud_SetX( gamemodebutton0, REPLACEHud_GetBasePos( gamemodebutton0 ).x )
	Hud_SetWidth( gamemodebutton0, 250 )
	Hud_Show( gamemodebutton0 )
	drawWidth += (REPLACEHud_GetPos( gamemodebutton0 ).x + Hud_GetWidth( gamemodebutton0 ))
	GamemodeSelectV2_UpdateSelectButton2( gamemodebutton0, "Firing Range", "training", "Mess around in the firing range", "", false )
	GamemodeSelectV2_PlayVideo( gamemodebutton0, "training" )

	var gamemodebutton1 = Hud_GetChild( file.menu, "GamemodeButton1" )

	Hud_SetX( gamemodebutton1, REPLACEHud_GetBasePos( gamemodebutton1 ).x )
	Hud_SetWidth( gamemodebutton1, 250 )
	Hud_Show( gamemodebutton1 )
	drawWidth += (REPLACEHud_GetPos( gamemodebutton1 ).x + Hud_GetWidth( gamemodebutton1 ))
	GamemodeSelectV2_UpdateSelectButton2( gamemodebutton1, "Quick Join", "generic_02", "Joins a random server", "Not Finished", true )
	GamemodeSelectV2_PlayVideo( gamemodebutton1, "generic_02" )

	var gamemodebutton2 = Hud_GetChild( file.menu, "GamemodeButton2" )

	Hud_SetX( gamemodebutton2, REPLACEHud_GetBasePos( gamemodebutton2 ).x )
	Hud_SetWidth( gamemodebutton2, 250 )
	Hud_Show( gamemodebutton2 )
	drawWidth += (REPLACEHud_GetPos( gamemodebutton2 ).x + Hud_GetWidth( gamemodebutton2 ))
	GamemodeSelectV2_UpdateSelectButton2( gamemodebutton2, "Create Server", "generic_01", "Quickly create a server", "Not Finished", true )
	GamemodeSelectV2_PlayVideo( gamemodebutton2, "generic_01" )

	var gamemodebutton3 = Hud_GetChild( file.menu, "GamemodeButton3" )

	Hud_SetX( gamemodebutton3, REPLACEHud_GetBasePos( gamemodebutton3 ).x )
	Hud_SetWidth( gamemodebutton3, 250 )
	Hud_Show( gamemodebutton3 )
	drawWidth += (REPLACEHud_GetPos( gamemodebutton3 ).x + Hud_GetWidth( gamemodebutton3 ))
	GamemodeSelectV2_UpdateSelectButton2( gamemodebutton3, "Worlds Edge", "worlds_edge", "Run around on Worlds Edge", "", false )
	GamemodeSelectV2_PlayVideo( gamemodebutton3, "worlds_edge" )

	var gamemodebutton4 = Hud_GetChild( file.menu, "GamemodeButton4" )

	Hud_SetX( gamemodebutton4, REPLACEHud_GetBasePos( gamemodebutton4 ).x )
	Hud_SetWidth( gamemodebutton4, 250 )
	Hud_Show( gamemodebutton4 )
	drawWidth += (REPLACEHud_GetPos( gamemodebutton4 ).x + Hud_GetWidth( gamemodebutton4 ))
	GamemodeSelectV2_UpdateSelectButton2( gamemodebutton4, "Kings Canyon", "ranked_1", "Run around on Kings Kanyon", "", false )
	GamemodeSelectV2_PlayVideo( gamemodebutton4, "ranked_1" )

	//
	float scale = float( GetScreenSize().width ) / 1920.0
	drawWidth += int( 48 * scale )

	bool hasLimitedMode = (slotToPlaylistNameMap["ltm"] != "")
	RuiSetBool( Hud_GetRui( file.selectionPanel ), "hasLimitedMode", false )
	RuiSetFloat( Hud_GetRui( file.selectionPanel ), "drawWidth", (drawWidth / scale) )
	Hud_SetWidth( file.selectionPanel, drawWidth )
}

void function OnCloseModeSelectDialog()
{
	Hud_SetAboveBlur( GetMenu( "LobbyMenu" ), true )

	var modeSelectButton = GetModeSelectButton()
	Hud_SetSelected( modeSelectButton, false )
	Hud_SetFocused( modeSelectButton )

	Lobby_OnGamemodeSelectV2Close()
}


void function GamemodeButton0_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	ClientCommand( "mmlaunchsolo mp_rr_canyonlands_staging survival_firingrange" )
}

void function GamemodeButton1_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	print("buttons!!!")
}

void function GamemodeButton2_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	print("buttons!!!")
}

void function GamemodeButton3_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	ClientCommand( "mmlaunchsolo mp_rr_desertlands_64k_x_64k survival_dev" )
}

void function GamemodeButton4_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	ClientCommand( "mmlaunchsolo mp_rr_canyonlands_64k_x_64k survival_dev" )
}

void function GamemodeButton_OnGetFocus( var button )
{
	GamemodeSelectV2_PlayVideo( button, "play_apex" )
}


void function GamemodeButton_OnLoseFocus( var button )
{
	//
}


void function OnCloseButton_Activate( var button )
{
	CloseAllDialogs()
}


