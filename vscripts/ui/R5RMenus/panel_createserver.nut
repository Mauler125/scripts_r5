global function InitR5RCreateServerPanel

global function SetSelectedServerMap
global function SetSelectedServerPlaylist
global function SetSelectedServerVis

struct
{
	var menu
	var panel

	var PlaylistPanel
	var MapPanel
} file

struct
{
	string name
	string map
	string playlist
	int vis
} NewServer

void function InitR5RCreateServerPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Setup EventHandlers
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnPlaylist" ), UIE_CLICK, OpenPlaylistUI )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnVis" ), UIE_CLICK, OpenVisUI )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnMap" ), UIE_CLICK, OpenMapUI )

	//Setup Panels
	file.PlaylistPanel = Hud_GetChild(file.panel, "R5RPlaylistPanel")
	file.MapPanel = Hud_GetChild(file.panel, "R5RMapPanel")

	//Setup Default Server Config
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname["custom_tdm"])
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset["mp_rr_aqueduct"] )

	NewServer.name = "R5Reloaded Server"
	NewServer.map = "mp_rr_aqueduct"
	NewServer.playlist = "custom_tdm"
	NewServer.vis = eServerVisibility.OFFLINE
}

void function OpenPlaylistUI( var button )
{
	Hud_SetVisible( file.PlaylistPanel, true )
	Hud_SetVisible( file.MapPanel, false )
	//Hud_SetVisible( file.VisPanel, false )
}

void function OpenMapUI( var button )
{
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, true )
	//Hud_SetVisible( file.VisPanel, false )
}

void function OpenVisUI( var button )
{
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, false )
	//Hud_SetVisible( file.VisPanel, true )
}

void function StartNewGame( var button )
{
	CreateServer(NewServer.name, NewServer.map, NewServer.playlist, NewServer.vis)
}

void function SetSelectedServerMap( string map )
{
	NewServer.map = map
	Hud_SetVisible( file.MapPanel, false )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[map] )
}

void function SetSelectedServerPlaylist( string playlist )
{
	NewServer.playlist = playlist
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname[playlist])
}

void function SetSelectedServerVis( int vis )
{
	NewServer.vis = vis
	//Hud_SetVisible( file.VisPanel, false )
	//Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), vistoname[vis])
}