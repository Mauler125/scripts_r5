global function InitR5RMapPanel

struct
{
	var menu
	var panel
	var picture
} file

void function InitR5RMapPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, Map_OnShow )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, Map_OnHide )

}

void function Map_OnShow( var panel )
{
	
}

void function Map_OnHide( var panel )
{
	
}