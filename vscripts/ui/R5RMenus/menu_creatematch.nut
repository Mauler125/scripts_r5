global function InitR5RCreateMatch

struct {
	var menu
} file

void function InitR5RCreateMatch( var newMenuArg ) //
{
	var menu = GetMenu( "R5RCreateMatch" )
	file.menu = menu

    var privatematchbutton = Hud_GetChild( menu, "GamemodesBtn" )
	Hud_AddEventHandler( privatematchbutton, UIE_CLICK, Gamemodes_Activated )

    AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnNavBack )

    AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#CLOSE" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT" )
}

void function Gamemodes_Activated(var button)
{
    CloseActiveMenu()
}

void function OnNavBack()
{
    CloseAllMenus()
    AdvanceMenu( GetMenu( "R5RLobbyMenu" ) )
}