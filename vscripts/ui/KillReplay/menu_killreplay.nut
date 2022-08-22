global function InitKillReplayHud
global function OpenKillReplayHud
global function CloseKillReplayHud
global function ReplayHud_UpdatePlayerHealthAndSheild

struct
{
	var menu
    int basehealthwidth
    int basesheildwidth
} file

void function OpenKillReplayHud(asset image, string killedby, int tier)
{
    for(int i = 0; i < 5; i++) {
        Hud_SetVisible( Hud_GetChild( file.menu, "PlayerSheild" + i ), false )
    }

    Hud_SetVisible( Hud_GetChild( file.menu, "PlayerSheild" + tier ), true )
    Hud_SetText(Hud_GetChild( file.menu, "KillReplayPlayerName" ), killedby)
	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "PlayerImage")), "basicImage", image)

	CloseAllMenus()
	AdvanceMenu( file.menu )
}

void function ReplayHud_UpdatePlayerHealthAndSheild(float health, float sheild, int tier)
{
    Hud_SetWidth( Hud_GetChild( file.menu, "PlayerSheild" + tier ), file.basesheildwidth * sheild )
    Hud_SetWidth( Hud_GetChild( file.menu, "PlayerHealth" ), file.basehealthwidth * health )
}

void function CloseKillReplayHud()
{
	CloseAllMenus()
}

void function InitKillReplayHud( var newMenuArg )
{
	var menu = GetMenu( "KillReplayHud" )
	file.menu = menu

    file.basehealthwidth = Hud_GetWidth( Hud_GetChild( file.menu, "PlayerHealth" ) )
    file.basesheildwidth = Hud_GetWidth( Hud_GetChild( file.menu, "PlayerSheild1" ) )

	//AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )
}

void function OnR5RSB_NavigateBack()
{
	//
}