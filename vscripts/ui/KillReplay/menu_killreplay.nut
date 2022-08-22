global function InitKillReplayHud
global function OpenKillReplayHud
global function CloseKillReplayHud

struct
{
	var menu
} file

void function OpenKillReplayHud(string killedby)
{
    Hud_SetText(Hud_GetChild( file.menu, "KillReplayPlayerName" ), killedby)

	CloseAllMenus()
	AdvanceMenu( file.menu )
}

void function CloseKillReplayHud()
{
	CloseAllMenus()
}

void function InitKillReplayHud( var newMenuArg )
{
	var menu = GetMenu( "KillReplayHud" )
	file.menu = menu

	//AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )
}

void function OnR5RSB_NavigateBack()
{
	//
}