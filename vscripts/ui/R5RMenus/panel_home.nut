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

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, Home_OnShow )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, Home_OnHide )

	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "R5RPicBox" ) ), "basicImage", $"rui/menu/home/bg" )
	Hud_SetText(Hud_GetChild( file.panel, "PlayerName" ), GetPlayerName())
}

void function Home_OnShow( var panel )
{
	Hud_SetText(Hud_GetChild( file.panel, "PlayerName" ), GetPlayerName())
}

void function Home_OnHide( var panel )
{
	
}