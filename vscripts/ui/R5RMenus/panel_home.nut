global function InitR5RHomePanel
global function SetUIPlayerName

struct
{
	var menu
	var panel
} file

void function InitR5RHomePanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Set info box image
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "R5RPicBox" ) ), "basicImage", $"rui/menu/home/bg" )
}

void function SetUIPlayerName()
{
	Hud_SetText(Hud_GetChild( file.panel, "PlayerName" ), GetPlayerName())
	Hud_SetText( Hud_GetChild( file.panel, "VersionNumber" ), GetSDKVersion() )
}