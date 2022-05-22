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
}

void function CreateServer_OnShow( var panel )
{
	
}

void function CreateServer_OnHide( var panel )
{
	
}