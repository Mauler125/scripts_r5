global function InitR5RCreateMatch

const MAX_BUTTONS_PER_ROW = 3
const MAX_BUTTON_ROWS = 3
const MAX_BUTTONS_PER_PAGE = 9

global struct PrivateMatchSettings {
    string pm_Servername = "Enter a Server Name"
    string pm_Serverdesc = ""
    string pm_Playlist = "custom_tdm"
    string pm_Map = "mp_rr_canyonlands_64k_x_64k"
    int pm_Vis = 0
}

struct {
	var menu

    int mapscrolloffset = 0
    int playlistscrollOffset = 0
	
	array<string> m_vPlaylists
	array<string> m_vMaps
} file

global PrivateMatchSettings p_ServerSettings

void function InitR5RCreateMatch( var newMenuArg ) //
{
	var menu = GetMenu( "R5RCreateMatch" )
	file.menu = menu

    foreach ( button in GetElementsByClassname( menu, "MapButton" ) ) {
		Hud_AddEventHandler( button, UIE_CLICK, MapButton_Activated )
	}

    foreach ( button in GetElementsByClassname( menu, "PlaylistButton" ) ) {
		Hud_AddEventHandler( button, UIE_CLICK, PlaylistButton_Activated )
	}

    AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenModeSelectDialog )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnCloseModeSelectDialog )

    var privatematchbutton = Hud_GetChild( menu, "GamemodesBtn" )
	Hud_AddEventHandler( privatematchbutton, UIE_CLICK, Gamemodes_Activated )

    AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnNavBack )

	Hud_AddEventHandler( Hud_GetChild( menu, "BtnPlaylistListDownArrow" ), UIE_CLICK, OnScrollDown_Playlist )
	Hud_AddEventHandler( Hud_GetChild( menu, "BtnPlaylistListUpArrow" ), UIE_CLICK, OnScrollUp_Playlist )

	Hud_AddEventHandler( Hud_GetChild( menu, "BtnMapListDownArrow" ), UIE_CLICK, OnScrollDown_Map )
	Hud_AddEventHandler( Hud_GetChild( menu, "BtnMapListUpArrow" ), UIE_CLICK, OnScrollUp_Map )

	Hud_AddEventHandler( Hud_GetChild( menu, "SaveBtn" ), UIE_CLICK, CreateMatch_Activated )

	AddButtonEventHandler( Hud_GetChild( menu, "BtnServerName"), UIE_CHANGE, SaveServerName )
	AddButtonEventHandler( Hud_GetChild( menu, "BtnServerDesc"), UIE_CHANGE, SaveServerDesc )
}

void function SaveServerName(var button)
{
	p_ServerSettings.pm_Servername = Hud_GetUTF8Text( button )
}

void function SaveServerDesc(var button)
{
	p_ServerSettings.pm_Serverdesc = Hud_GetUTF8Text( button )
}

void function CreateMatch_Activated( var button )
{
	if(p_ServerSettings.pm_Servername.len() == 0)
		return
	
	if(p_ServerSettings.pm_Playlist.len() == 0)
		return
	
	if(p_ServerSettings.pm_Map.len() == 0)
		return

	CreateServer(p_ServerSettings.pm_Servername, p_ServerSettings.pm_Serverdesc, p_ServerSettings.pm_Map, p_ServerSettings.pm_Playlist, p_ServerSettings.pm_Vis)
}

void function OnScrollDown_Playlist(var button)
{
	if(file.playlistscrollOffset > (file.m_vPlaylists.len() - 4))
		return

	file.playlistscrollOffset += MAX_BUTTONS_PER_ROW

	SetupPlaylistButtons()
}

void function OnScrollUp_Playlist(var button)
{
	file.playlistscrollOffset -= MAX_BUTTONS_PER_ROW
	if(file.playlistscrollOffset < 0)
		file.playlistscrollOffset = 0

	SetupPlaylistButtons()
}

void function OnScrollDown_Map(var button)
{
	if(file.mapscrolloffset > (file.m_vMaps.len() - 4))
		return

	file.mapscrolloffset += MAX_BUTTONS_PER_ROW

	SetupMapButtons()
}

void function OnScrollUp_Map(var button)
{
	file.mapscrolloffset -= MAX_BUTTONS_PER_ROW
	if(file.mapscrolloffset < 0)
		file.mapscrolloffset = 0

	SetupMapButtons()
}

void function PlaylistButton_Activated(var button)
{
	int id = Hud_GetScriptID( button ).tointeger()
	p_ServerSettings.pm_Playlist = file.m_vPlaylists[id + file.playlistscrollOffset]
	file.mapscrolloffset = 0

	array<string> playlist_maps = GetPlaylistMaps(p_ServerSettings.pm_Playlist)
	if(!playlist_maps.contains(p_ServerSettings.pm_Map))
		p_ServerSettings.pm_Map = playlist_maps[0]

	SetupMapButtons()
	SetupPlaylistButtons()
}

void function MapButton_Activated(var button)
{
	int id = Hud_GetScriptID( button ).tointeger()
	p_ServerSettings.pm_Map = file.m_vMaps[id + file.mapscrolloffset]
	SetupMapButtons()
}

void function OnOpenModeSelectDialog()
{
	Hud_SetText( Hud_GetChild( file.menu, "BtnServerName" ), p_ServerSettings.pm_Servername )
	Hud_SetText( Hud_GetChild( file.menu, "BtnServerDesc" ), p_ServerSettings.pm_Serverdesc )

	SetupMapButtons()
    SetupPlaylistButtons()
}

void function OnCloseModeSelectDialog()
{
	//DiagCloseing()
}

void function Gamemodes_Activated(var button)
{
    CloseActiveMenu()
}

void function OnNavBack()
{
    CloseAllMenus()
    AdvanceMenu( GetMenu( "R5RLobbyMenu" ) )
}

void function SetupMapButtons()
{
    foreach ( button in GetElementsByClassname( file.menu, "MapButton" ) ) {
		Hud_Hide( button )
	}

    file.m_vMaps = GetPlaylistMaps(p_ServerSettings.pm_Playlist)
	for(int i = 0; i < MAX_BUTTONS_PER_PAGE; i++)
	{
        if((i + file.mapscrolloffset) > (file.m_vMaps.len() - 1))
            break

        Hud_Show(Hud_GetChild( file.menu, "MapButton" + i ))

        RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "modeNameText", GetUIMapName(file.m_vMaps[i + file.mapscrolloffset]) )
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "modeDescText", "" )
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "modeImage", GetUIMapAsset(file.m_vMaps[i + file.mapscrolloffset]) )
		RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "alwaysShowDesc", false)

		if(p_ServerSettings.pm_Map == file.m_vMaps[i + file.mapscrolloffset])
			RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "alwaysShowDesc", true)
	}
}

void function SetupPlaylistButtons()
{
    foreach ( button in GetElementsByClassname( file.menu, "PlaylistButton" ) ) {
		Hud_Hide( button )
	}

    file.m_vPlaylists = GetPlaylists()
    for(int i = 0; i < MAX_BUTTONS_PER_PAGE; i++)
	{
        if((i + file.playlistscrollOffset) > (file.m_vPlaylists.len() - 1))
            break

        Hud_Show(Hud_GetChild( file.menu, "PlaylistButton" + i ))

        RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "modeNameText", GetUIPlaylistName(file.m_vPlaylists[i + file.playlistscrollOffset]) )
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "modeDescText", "" )
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "modeImage", $"rui/menu/store/feature_background_square")
		RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "alwaysShowDesc", false)

		if(p_ServerSettings.pm_Playlist == file.m_vPlaylists[i + file.playlistscrollOffset])
			RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "alwaysShowDesc", true)
	}
}

array<string> function GetPlaylists()
{
	array<string> m_vPlaylists

	//Setup available playlists array
	foreach( string playlist in GetAvailablePlaylists())
	{
		//Check playlist visibility
		if(!GetPlaylistVarBool( playlist, "visible", false ))
			continue

		//Add playlist to the array
		m_vPlaylists.append(playlist)
	}

	return m_vPlaylists
}