global function InitR5RPlaylistPanel

struct
{
	var menu
	var panel
	var picture
} file

void function InitR5RPlaylistPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, Playlist_OnShow )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, Playlist_OnHide )
}

void function Playlist_OnShow( var panel )
{
	
}

void function Playlist_OnHide( var panel )
{
	
}