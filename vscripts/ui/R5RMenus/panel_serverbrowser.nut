global function InitR5RServerBrowserPanel

struct
{
	var menu
	var panel
} file

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, ServerBrowser_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, ServerBrowser_OnHide )
}

void function ServerBrowser_OnShow( var panel )
{
	
}

void function ServerBrowser_OnHide( var panel )
{
	
}