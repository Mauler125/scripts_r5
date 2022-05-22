global function InitR5RHomePanel

struct
{
	var menu
	var panel
	var picture
} file

void function InitR5RHomePanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, Home_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, Home_OnHide )

	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "R5RPicBox" ) ), "basicImage", $"rui/menu/gamemode/solo_iron_crown" )
}

void function Home_OnShow( var panel )
{
	
}

void function Home_OnHide( var panel )
{
	
}