global function InitR5RCreateServerPanel

global function SetSelectedServerMap
global function SetSelectedServerPlaylist
global function SetSelectedServerVis
global function HideAllCreateServerPanels

struct
{
	var menu
	var panel

	array<var> panels
} file

global struct ServerStruct
{
	string name = "R5Reloaded Server"
	string map = "mp_rr_aqueduct"
	string playlist = "custom_tdm"
	int vis = eServerVisibility.OFFLINE
}

global ServerStruct ServerSettings

void function InitR5RCreateServerPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Setup Button EventHandlers
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	AddButtonEventHandler( Hud_GetChild( file.panel, "BtnServerName"), UIE_CHANGE, UpdateServerName )
	array<var> buttons = GetElementsByClassname( file.menu, "createserverbuttons" )
	foreach ( var elem in buttons ) {
		Hud_AddEventHandler( elem, UIE_CLICK, OpenSelectedPanel )
	}

	//Setup panel array
	file.panels.append(Hud_GetChild(file.panel, "R5RMapPanel"))
	file.panels.append(Hud_GetChild(file.panel, "R5RPlaylistPanel"))
	file.panels.append(Hud_GetChild(file.panel, "R5RVisPanel"))

	//Setup Default Server Config
	ServerSettings.name = "R5Reloaded Server"
	ServerSettings.map = "mp_rr_aqueduct"
	ServerSettings.playlist = "custom_tdm"
	ServerSettings.vis = eServerVisibility.OFFLINE

	//Setup Default Server Config
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname[ServerSettings.playlist])
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset( ServerSettings.map ) )
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), vistoname[ServerSettings.vis])
	Hud_SetText( Hud_GetChild( file.panel, "BtnServerName" ), "A R5Reloaded Server" )
}

void function OpenSelectedPanel( var button )
{
	int scriptid = Hud_GetScriptID( button ).tointeger()
	ShowSelectedPanel( file.panels[scriptid] )
}

void function StartNewGame( var button )
{
	//if(!CheckPlaylistAndMapCompatibility())
		//return

	thread StartServer()
}

bool function CheckPlaylistAndMapCompatibility()
{
	array<string> playlistmaps = GetPlaylistMaps( ServerSettings.playlist )

	if(!playlistmaps.contains(ServerSettings.map))
		return false

	return true
}

void function StartServer()
{
	//Shutdown the lobby vm
	ShutdownHostGame()

	//Set the main menus blackscreen visibility to true
	SetMainMenuBlackScreenVisible(true)

	//wait for lobby vm to be actually shut down and back at the main menu
	while(!AtMainMenu) {
		WaitFrame()
	}

	//Create new server with selected settings
	CreateServer(ServerSettings.name, ServerSettings.map, ServerSettings.playlist, ServerSettings.vis)

	//No longer at main menu
	AtMainMenu = false
}

void function SetSelectedServerMap( string map )
{
	//set map
	ServerSettings.map = map

	//Set the panel to not visible
	Hud_SetVisible( file.panels[0], false )

	//Set the new map image
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset( ServerSettings.map ) )
}

void function SetSelectedServerPlaylist( string playlist )
{
	//set playlist
	ServerSettings.playlist = playlist

	//Set the panel to not visible
	Hud_SetVisible( file.panels[1], false )

	//Set the new playlist text
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), GetUIPlaylistName( ServerSettings.playlist ) )

	//Get the maps of the new playlist
	array<string> playlistmaps = GetPlaylistMaps(ServerSettings.playlist)

	//Check to see if the current map is allowed on the new selected playlist
	if(!playlistmaps.contains(ServerSettings.map))
		SetSelectedServerMap(playlistmaps[0]) //if not then set it to a map that is

	//Refresh Maps
	RefreshUIMaps()
}

void function SetSelectedServerVis( int vis )
{
	//set visibility
	ServerSettings.vis = vis

	//Set the panel to not visible
	Hud_SetVisible( file.panels[2], false )

	//Set the new visibility text
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), vistoname[ServerSettings.vis])
}

void function ShowSelectedPanel(var panel)
{
	//Hide all panels
	foreach ( p in file.panels ) {
		Hud_SetVisible( p, false )
	}

	//Show selected panel
	Hud_SetVisible( panel, true )
}

void function HideAllCreateServerPanels()
{
	//Hide all panels
	foreach ( p in file.panels ) {
		Hud_SetVisible( p, false )
	}
}

void function UpdateServerName( var button )
{
    //Update the servername when the text is changed
    ServerSettings.name = Hud_GetUTF8Text( Hud_GetChild( file.panel, "BtnServerName" ) )
}