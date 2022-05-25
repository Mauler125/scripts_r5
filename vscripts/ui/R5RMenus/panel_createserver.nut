global function InitR5RCreateServerPanel
global function SetSelectedServerMap

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

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, CreateServer_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, CreateServer_OnHide )

	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnPlaylist" ), UIE_CLICK, OpenPlaylistUI )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnMap" ), UIE_CLICK, OpenMapUI )

	file.PlaylistPanel = Hud_GetChild(file.panel, "R5RPlaylistPanel")
	file.MapPanel = Hud_GetChild(file.panel, "R5RMapPanel")

	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname["custom_tdm"])
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset["mp_rr_aqueduct"] )
}

void function OpenPlaylistUI( var button )
{
	Hud_SetVisible( file.PlaylistPanel, true )
	Hud_SetVisible( file.MapPanel, false )
}

void function OpenMapUI( var button )
{
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, true )
}

void function StartNewGame( var button )
{

}

void function SetSelectedServerMap( string map )
{
	NewServer.map = map
	Hud_SetVisible( file.MapPanel, false )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[map] )
}

void function CreateServer_OnShow( var panel )
{
	
}

void function CreateServer_OnHide( var panel )
{
	
}