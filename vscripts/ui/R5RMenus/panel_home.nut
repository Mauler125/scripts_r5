global function InitR5RHomePanel

struct
{
	var menu
	var panel
} file

void function InitR5RHomePanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, Home_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, Home_OnHide )
}

void function Home_OnShow( var panel )
{
	
}

void function Home_OnHide( var panel )
{
	
}