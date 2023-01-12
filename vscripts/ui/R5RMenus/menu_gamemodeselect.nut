global function InitR5RGamemodeSelectDialog

struct TopServer {
	int	svServerID
	string svServerName
	string svMapName
	string svPlaylist
	string svDescription
	int svMaxPlayers
	int svCurrentPlayers
}

global struct SelectedTopServer {
	int	svServerID
	string svServerName
	string svMapName
	string svPlaylist
	string svDescription
	int svMaxPlayers
	int svCurrentPlayers
}

struct {
	var menu
	var closeButton
	var freeroam

	bool showfreeroam = false
	int freeroamscroll = 0

	array<TopServer> m_vTopServers

	int pageoffset = 0

	array<string> m_vPlaylists
} file

global SelectedTopServer g_SelectedTopServer
global string g_SelectedPlaylist
global string g_SelectedQuickPlay
global string g_SelectedQuickPlayMap
global asset g_SelectedQuickPlayImage

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

void function InitR5RGamemodeSelectDialog( var newMenuArg ) //
{
	var menu = GetMenu( "R5RGamemodeSelectV2Dialog" )
	file.menu = menu

	var prevPageButton = Hud_GetChild( menu, "PrevPageButton" )
	HudElem_SetRuiArg( prevPageButton, "flipHorizontal", true )

	var topserver0 = Hud_GetChild( menu, "TopServerButton0" )
	var topserver1 = Hud_GetChild( menu, "TopServerButton1" )
	var topserver2 = Hud_GetChild( menu, "TopServerButton2" )
	Hud_AddEventHandler( topserver0, UIE_CLICK, TopServerButton_Activated )
	Hud_AddEventHandler( topserver1, UIE_CLICK, TopServerButton_Activated )
	Hud_AddEventHandler( topserver2, UIE_CLICK, TopServerButton_Activated )

	var nextpage = Hud_GetChild( menu, "NextPageButton" )
	var prevpage = Hud_GetChild( menu, "PrevPageButton" )
	Hud_AddEventHandler( nextpage, UIE_CLICK, NextPage_Activated )
	Hud_AddEventHandler( prevpage, UIE_CLICK, PrevPage_Activated )

	var playlistbtn0 = Hud_GetChild( menu, "GameModeButton0" )
	var playlistbtn1 = Hud_GetChild( menu, "GameModeButton1" )
	var playlistbtn2 = Hud_GetChild( menu, "GameModeButton2" )
	var playlistbtn3 = Hud_GetChild( menu, "GameModeButton3" )
	var playlistbtn4 = Hud_GetChild( menu, "GameModeButton4" )
	Hud_AddEventHandler( playlistbtn0, UIE_CLICK, PlaylistButton_Activated )
	Hud_AddEventHandler( playlistbtn1, UIE_CLICK, PlaylistButton_Activated )
	Hud_AddEventHandler( playlistbtn2, UIE_CLICK, PlaylistButton_Activated )
	Hud_AddEventHandler( playlistbtn3, UIE_CLICK, PlaylistButton_Activated )
	Hud_AddEventHandler( playlistbtn4, UIE_CLICK, PlaylistButton_Activated )

	var firingrange = Hud_GetChild( menu, "FiringRangeButton" )
	Hud_AddEventHandler( firingrange, UIE_CLICK, FiringRange_Activated )

	var freeroam = Hud_GetChild( menu, "FreeRoamButton" )
	Hud_AddEventHandler( freeroam, UIE_CLICK, FreeRoam_Activated )
	
	array<var> buttons = GetElementsByClassname( menu, "FreeRoamUI" )
	foreach ( button in buttons )
	{
		Hud_Hide( button )
		Hud_AddEventHandler( button, UIE_CLICK, FreeRoamButton_Activated )
	}

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenModeSelectDialog )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnCloseModeSelectDialog )

	file.closeButton = Hud_GetChild( menu, "CloseButton" )
	Hud_AddEventHandler( file.closeButton, UIE_CLICK, OnCloseButton_Activate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#CLOSE" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT" )
}

void function FreeRoam_Activated(var button)
{
	array<var> uielems = GetElementsByClassname( file.menu, "FreeRoamUI" )

	if(file.showfreeroam)
	{
		foreach ( var uielem in uielems )
		{
			Hud_Hide( uielem )
		}

		RemoveCallback_OnMouseWheelUp( FreeRoam_ScrollUp )
        RemoveCallback_OnMouseWheelDown( FreeRoam_ScrollDown )

		file.showfreeroam = false
	}
	else
	{
		foreach ( var uielem in uielems )
		{
			Hud_Show( uielem )
		}

		AddCallback_OnMouseWheelUp( FreeRoam_ScrollUp )
        AddCallback_OnMouseWheelDown( FreeRoam_ScrollDown )

		file.showfreeroam = true
	}

	file.freeroamscroll = 0
}

void function FreeRoam_ScrollUp()
{
	if(file.freeroamscroll > 0)
		file.freeroamscroll -= 1

	SetupFreeRoamButtons()
}

void function FreeRoam_ScrollDown()
{
	array<string> m_vMaps = GetPlaylistMaps("survival_dev")
	int max = m_vMaps.len()

	if(file.freeroamscroll + 6 < max)
		file.freeroamscroll += 1

    SetupFreeRoamButtons()
}

void function FreeRoamButton_Activated(var button)
{
	int id = Hud_GetScriptID( button ).tointeger()
	array<string> m_vMaps = GetPlaylistMaps("survival_dev")
	g_SelectedQuickPlay = m_vMaps[id + file.freeroamscroll]
	g_SelectedQuickPlayImage = GetUIMapAsset( g_SelectedQuickPlay )

	g_SelectedQuickPlay = "survival_dev"
	g_SelectedQuickPlayMap = m_vMaps[id + file.freeroamscroll]
	g_SelectedQuickPlayImage = GetUIMapAsset( g_SelectedQuickPlayMap )
	R5RPlay_SetSelectedPlaylist(JoinType.QuickPlay)
	DiagCloseing()
	CloseActiveMenu()
}

void function NextPage_Activated(var button)
{
	file.pageoffset += 1
	SetupPlaylistQuickSearch()
}

void function PrevPage_Activated(var button)
{
	file.pageoffset -= 1
	SetupPlaylistQuickSearch()
}

void function FiringRange_Activated(var button)
{
	g_SelectedQuickPlay = "survival_firingrange"
	g_SelectedQuickPlayMap = "mp_rr_canyonlands_staging"
	g_SelectedQuickPlayImage = $"rui/menu/gamemode/firing_range"
	R5RPlay_SetSelectedPlaylist(JoinType.QuickPlay)
	DiagCloseing()
	CloseActiveMenu()
}

void function PlaylistButton_Activated(var button)
{
	int id = Hud_GetScriptID( button ).tointeger()
	g_SelectedPlaylist = file.m_vPlaylists[id + file.pageoffset]
	R5RPlay_SetSelectedPlaylist(JoinType.QuickServerJoin)
	DiagCloseing()
	CloseActiveMenu()
}

void function TopServerButton_Activated(var button)
{
	int id = Hud_GetScriptID( button ).tointeger()

	g_SelectedTopServer.svServerID = file.m_vTopServers[id].svServerID
	g_SelectedTopServer.svServerName = file.m_vTopServers[id].svServerName
	g_SelectedTopServer.svMapName = file.m_vTopServers[id].svMapName
	g_SelectedTopServer.svPlaylist = file.m_vTopServers[id].svPlaylist
	g_SelectedTopServer.svDescription = file.m_vTopServers[id].svDescription
	g_SelectedTopServer.svMaxPlayers = file.m_vTopServers[id].svMaxPlayers
	g_SelectedTopServer.svCurrentPlayers = file.m_vTopServers[id].svCurrentPlayers

	R5RPlay_SetSelectedPlaylist(JoinType.TopServerJoin)

	DiagCloseing()
	CloseActiveMenu()
}

void function OnOpenModeSelectDialog()
{
	Servers_GetCurrentServerListing()
	SetupTopServers()
	SetupPlaylistQuickSearch()
	SetupFreeRoamButtons()
}

void function OnCloseModeSelectDialog()
{

}

void function OnCloseButton_Activate( var button )
{
	DiagCloseing()
}

void function DiagCloseing()
{
	if(file.showfreeroam)
	{
		array<var> uielems = GetElementsByClassname( file.menu, "FreeRoamUI" )
		foreach ( var uielem in uielems )
		{
			Hud_Hide( uielem )
		}

		RemoveCallback_OnMouseWheelUp( FreeRoam_ScrollUp )
        RemoveCallback_OnMouseWheelDown( FreeRoam_ScrollDown )

		file.showfreeroam = false

		file.freeroamscroll = 0
	}
}

void function SetupFreeRoamButtons()
{
	array<string> m_vMaps = GetPlaylistMaps("survival_dev")

	for(int i = 0; i < 6; i++)
	{
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "FreeRoamButton" + i ) ), "modeNameText", GetUIMapName(m_vMaps[i + file.freeroamscroll]) )
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "FreeRoamButton" + i ) ), "modeDescText", "" )
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "FreeRoamButton" + i ) ), "modeImage", GetUIMapAsset(m_vMaps[i + file.freeroamscroll]) )
	}
}

void function SetupPlaylistQuickSearch()
{
	array<string> playlists = Servers_GetActivePlaylists()
	playlists.insert(0, "Random Server")

	file.m_vPlaylists = playlists

	if( file.pageoffset != 0 && playlists.len() > 4)
	{
		Hud_Show( Hud_GetChild( file.menu, "PrevPageButton" ) )
	}
	else
	{
		Hud_Hide( Hud_GetChild( file.menu, "PrevPageButton" ) )
	}

	if( file.pageoffset < playlists.len() - 5 && playlists.len() > 4)
	{
		Hud_Show( Hud_GetChild( file.menu, "NextPageButton" ) )
	}
	else
	{
		Hud_Hide( Hud_GetChild( file.menu, "NextPageButton" ) )
	}

	int offset = 0
    //Hide all items
    for(int j = 0; j < MAX_DISPLAYED_MODES; j++)
    {
        Hud_Hide( Hud_GetChild( file.menu, "GameModeButton" + j ) )
    }

    //Show only the ones we need
    for(int j = 0; j < playlists.len() + 1; j++)
    {
		if( j > playlists.len() - 1 )
			break

		if( j > MAX_DISPLAYED_MODES - 1 )
			break
		
        Hud_Show( Hud_GetChild( file.menu, "GameModeButton" + j ) )

		if(j != 0)
        	offset -= (Hud_GetWidth(Hud_GetChild( file.menu, "GameModeButton0" ))/2) + 5
    }

    Hud_SetX( Hud_GetChild( file.menu, "GameModeButton0" ), 0 )
    if( playlists.len() > 0 )
        Hud_SetX( Hud_GetChild( file.menu, "GameModeButton0" ), offset )

	int currentitem = 0
	for(int i = 0; i < MAX_DISPLAYED_MODES; i++)
	{
		if(currentitem + file.pageoffset >= playlists.len())
			break
		
		if(playlists[currentitem + file.pageoffset] == "Random Server")
		{
			RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i ) ), "modeNameText", "Random Server" )
			RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i ) ), "modeDescText", "Quickly Join any kind of server" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i ) ), "modeImage", $"rui/menu/gamemode/ranked_1" )
		}
		else
		{
			RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i ) ), "modeNameText", playlists[currentitem + file.pageoffset] )
			RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i ) ), "modeDescText", "" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i ) ), "modeImage", $"rui/menu/gamemode/play_apex" )
		}
	    RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, "GameModeButton" + i )), "alwaysShowDesc", false )
		currentitem++
	}
}

void function SetupTopServers()
{
	if(global_m_vServerList.len() < 3)
		return
		
	file.m_vTopServers.clear()
	for(int i = 0; i < 3; i++)
	{
		TopServer server
		server.svServerID = global_m_vServerList[i].svServerID
		server.svServerName = global_m_vServerList[i].svServerName
		server.svMapName = global_m_vServerList[i].svMapName
		server.svPlaylist = global_m_vServerList[i].svPlaylist
		server.svDescription = global_m_vServerList[i].svDescription
		server.svMaxPlayers = global_m_vServerList[i].svMaxPlayers
		server.svCurrentPlayers = global_m_vServerList[i].svCurrentPlayers
		file.m_vTopServers.append(server)
	}

	string servername1 = file.m_vTopServers[0].svServerName
	if(file.m_vTopServers[0].svServerName.len() > 30)
		servername1 = file.m_vTopServers[0].svServerName.slice(0, 30) + "..."
	var TopServer1 = Hud_GetChild( file.menu, "TopServerButton2" )
	RuiSetString( Hud_GetRui( TopServer1 ), "modeNameText", servername1 )
	RuiSetString( Hud_GetRui( TopServer1 ), "modeDescText", "Players " + file.m_vTopServers[0].svCurrentPlayers + "/" + file.m_vTopServers[0].svMaxPlayers )
	RuiSetBool( Hud_GetRui( TopServer1 ), "alwaysShowDesc", false )
	RuiSetImage( Hud_GetRui( TopServer1 ), "modeImage", GetUIMapAsset(file.m_vTopServers[0].svMapName ) )

	string servername2 = file.m_vTopServers[1].svServerName
	if(file.m_vTopServers[1].svServerName.len() > 30)
		servername2 = file.m_vTopServers[1].svServerName.slice(0, 30) + "..."
	var TopServer2 = Hud_GetChild( file.menu, "TopServerButton1" )
	RuiSetString( Hud_GetRui( TopServer2 ), "modeNameText", servername2 )
	RuiSetString( Hud_GetRui( TopServer2 ), "modeDescText", "Players " + file.m_vTopServers[1].svCurrentPlayers + "/" + file.m_vTopServers[1].svMaxPlayers )
	RuiSetBool( Hud_GetRui( TopServer2 ), "alwaysShowDesc", false )
	RuiSetImage( Hud_GetRui( TopServer2 ), "modeImage", GetUIMapAsset(file.m_vTopServers[1].svMapName ) )

	string servername3 = file.m_vTopServers[2].svServerName
	if(file.m_vTopServers[2].svServerName.len() > 30)
		servername3 = file.m_vTopServers[2].svServerName.slice(0, 30) + "..."
	var TopServer3 = Hud_GetChild( file.menu, "TopServerButton0" )
	RuiSetString( Hud_GetRui( TopServer3 ), "modeNameText", servername3 )
	RuiSetString( Hud_GetRui( TopServer3 ), "modeDescText", "Players " + file.m_vTopServers[2].svCurrentPlayers + "/" + file.m_vTopServers[2].svMaxPlayers )
	RuiSetBool( Hud_GetRui( TopServer3 ), "alwaysShowDesc", false )
	RuiSetImage( Hud_GetRui( TopServer3 ), "modeImage", GetUIMapAsset(file.m_vTopServers[2].svMapName ) )
}