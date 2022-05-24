global function InitR5RCreateServerPanel

struct
{
	var menu
	var panel
} file

void function InitR5RCreateServerPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, CreateServer_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, CreateServer_OnHide )

	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnPlaylist" ), UIE_CLICK, OpenPlaylistUI )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnMap" ), UIE_CLICK, OpenMapUI )

	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname["custom_tdm"])
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset["mp_rr_aqueduct"] )
}

void function StartNewGame( var button )
{

}

void function CreateServer_OnShow( var panel )
{
	
}

void function CreateServer_OnHide( var panel )
{
	
}