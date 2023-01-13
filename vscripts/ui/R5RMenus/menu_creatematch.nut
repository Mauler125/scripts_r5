global function InitR5RCreateMatch

const MAX_BUTTONS_PER_ROW = 3
const MAX_BUTTON_ROWS = 3
const MAX_BUTTONS_PER_PAGE = 9

global struct PrivateMatchSettings {
    string pm_Servername = ""
    string pm_Serverdesc = ""
    string pm_Playlist = "custom_tdm"
    string pm_Map = "mp_rr_canyonlands_64k_x_64k"
    int pm_Vis = 0
}

struct {
	var menu

    int mapscrolloffset = 0
    int playlistscrollOffset = 0
} file

global PrivateMatchSettings p_ServerSettings

void function InitR5RCreateMatch( var newMenuArg ) //
{
	var menu = GetMenu( "R5RCreateMatch" )
	file.menu = menu

    foreach ( button in GetElementsByClassname( menu, "MapButtons" ) ) {
		Hud_AddEventHandler( button, UIE_CLICK, MapButton_Activated )
	}

    foreach ( button in GetElementsByClassname( menu, "MapButtons" ) ) {
		Hud_AddEventHandler( button, UIE_CLICK, PlaylistButton_Activated )
	}

    AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenModeSelectDialog )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnCloseModeSelectDialog )

    var privatematchbutton = Hud_GetChild( menu, "GamemodesBtn" )
	Hud_AddEventHandler( privatematchbutton, UIE_CLICK, Gamemodes_Activated )

    AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnNavBack )
}

void function PlaylistButton_Activated(var button)
{

}

void function MapButton_Activated(var button)
{

}

void function OnOpenModeSelectDialog()
{
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

    array<string> m_vMaps = GetPlaylistMaps(p_ServerSettings.pm_Playlist)
	for(int i = 0; i < MAX_BUTTONS_PER_PAGE; i++)
	{
        if(i > m_vMaps.len())
            return

        Hud_Show(Hud_GetChild( file.menu, "MapButton" + i ))

        RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "modeNameText", GetUIMapName(m_vMaps[i + file.mapscrolloffset]) )
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "modeDescText", "" )
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "MapButton" + i ) ), "modeImage", GetUIMapAsset(m_vMaps[i + file.mapscrolloffset]) )
	}
}

void function SetupPlaylistButtons()
{
    foreach ( button in GetElementsByClassname( file.menu, "PlaylistButton" ) ) {
		Hud_Hide( button )
	}

    array<string> m_vPlaylists = GetPlaylists()
    for(int i = 0; i < MAX_BUTTONS_PER_PAGE; i++)
	{
        if(i > m_vPlaylists.len())
            return

        Hud_Show(Hud_GetChild( file.menu, "PlaylistButton" + i ))

        RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "modeNameText", GetUIPlaylistName(m_vPlaylists[i + file.playlistscrollOffset]) )
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "modeDescText", "" )
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "PlaylistButton" + i ) ), "modeImage", $"")
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