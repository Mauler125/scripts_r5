global function InitR5RMapMenu

struct
{
	var menu

    var map1
    var map2
    var map3
    var map4
    var map5
    var map6
    var map7

} file

void function InitR5RMapMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RChangeMap" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	SetGamepadCursorEnabled( menu, false )

    //Set VGUI/RUI
    file.map1 = Hud_GetChild(menu, "Mapbtn1")
    Hud_AddEventHandler( file.map1, UIE_CLICK, SetMap1 )
    var map1rui = Hud_GetRui( file.map1 )
    RuiSetString( map1rui, "buttonText", "Kings Canyon Season 0" )

    file.map2 = Hud_GetChild(menu, "Mapbtn2")
    Hud_AddEventHandler( file.map2, UIE_CLICK, SetMap2 )
    var map2rui = Hud_GetRui( file.map2 )
    RuiSetString( map2rui, "buttonText", "Kings Canyon Season 2" )

    file.map3 = Hud_GetChild(menu, "Mapbtn3")
    Hud_AddEventHandler( file.map3, UIE_CLICK, SetMap3 )
    var map3rui = Hud_GetRui( file.map3 )
    RuiSetString( map3rui, "buttonText", "Kings Canyon Season 2 After Dark" )

    file.map4 = Hud_GetChild(menu, "Mapbtn4")
    Hud_AddEventHandler( file.map4, UIE_CLICK, SetMap4 )
    var map4rui = Hud_GetRui( file.map4 )
    RuiSetString( map4rui, "buttonText", "Worlds Edge" )

    file.map5 = Hud_GetChild(menu, "Mapbtn5")
    Hud_AddEventHandler( file.map5, UIE_CLICK, SetMap5 )
    var map5rui = Hud_GetRui( file.map5 )
    RuiSetString( map5rui, "buttonText", "Wordgs Edge After Dark" )

    file.map6 = Hud_GetChild(menu, "Mapbtn6")
    Hud_AddEventHandler( file.map6, UIE_CLICK, SetMap6 )
    var map6rui = Hud_GetRui( file.map6 )
    RuiSetString( map6rui, "buttonText", "Ash's Redemption" )

    file.map7 = Hud_GetChild(menu, "Mapbtn7")
    Hud_AddEventHandler( file.map7, UIE_CLICK, SetMap7 )
    var map7rui = Hud_GetRui( file.map7 )
    RuiSetString( map7rui, "buttonText", "Firing Range" )
}

void function OnR5RSB_Show()
{
    Chroma_MainMenu()
}


void function OnR5RSB_Close()
{
	//
}

void function OnR5RSB_NavigateBack()
{
	CloseActiveMenu()
}

void function SetMap1(var button)
{
    SetMap( "mp_rr_canyonlands_64k_x_64k" )
    CloseActiveMenu()
}

void function SetMap2(var button)
{
    SetMap( "mp_rr_canyonlands_mu1" )
    CloseActiveMenu()
}

void function SetMap3(var button)
{
    SetMap( "mp_rr_canyonlands_mu1_night" )
    CloseActiveMenu()
}

void function SetMap4(var button)
{
    SetMap( "mp_rr_desertlands_64k_x_64k" )
    CloseActiveMenu()
}

void function SetMap5(var button)
{
    SetMap( "mp_rr_desertlands_64k_x_64k_nx" )
    CloseActiveMenu()
}

void function SetMap6(var button)
{
    SetMap( "mp_r5r_ashs_redemption" )
    CloseActiveMenu()
}

void function SetMap7(var button)
{
    SetMap( "mp_rr_canyonlands_staging" )
    CloseActiveMenu()
}