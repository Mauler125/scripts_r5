global function InitR5RMenu

struct
{
	var menu
    var serverbrowser
    var createserver
    var settings
    var exit
} file

void function InitR5RMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RMenu" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RMenu_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RMenu_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RMenu_NavigateBack )

	SetGamepadCursorEnabled( menu, false )

    //Setup RUI/VGUI
    file.serverbrowser = Hud_GetChild( menu, "Launchbtn1" )
	SetButtonRuiText( file.serverbrowser, "Server Browser" )
    Hud_AddEventHandler( file.serverbrowser, UIE_CLICK, ShowServerBrowser )

    file.createserver = Hud_GetChild( menu, "Launchbtn2" )
	SetButtonRuiText( file.createserver, "Create Server" )
    Hud_AddEventHandler( file.createserver, UIE_CLICK, ShowCreateServer )

    file.settings = Hud_GetChild( menu, "Launchbtn3" )
	SetButtonRuiText( file.settings, "Settings" )
    Hud_AddEventHandler( file.settings, UIE_CLICK, ShowSettings )

    file.exit = Hud_GetChild( menu, "Launchbtn4" )
	SetButtonRuiText( file.exit, "Quit" )
    Hud_AddEventHandler( file.exit, UIE_CLICK, Exit )

    var button1 = Hud_GetChild( menu, "Button0" )
    Hud_AddEventHandler( button1, UIE_CLICK, OpenLink1)
    var button2 = Hud_GetChild( menu, "Button1" )
    var button3 = Hud_GetChild( menu, "Button2" )

    //SetSpotlightButtonData( button0, "", 0, "title", "details" )
    var rui1 = Hud_GetRui( button1 )
    var rui2 = Hud_GetRui( button2 )
    var rui3 = Hud_GetRui( button3 )

    //PromoLargeTitle, PromoLargeDesc
    RuiSetImage( rui1, "modeImage", $"rui/menu/gamemode/shotguns_and_snipers" )
    RuiSetString( rui1, "modeNameText", GetPromoData("PromoLargeTitle"))
    RuiSetString( rui1, "modeDescText", GetPromoData("PromoLargeDesc"))

    //PromoLeftTitle, PromoLeftDesc
    RuiSetImage( rui2, "modeImage", $"rui/menu/gamemode/shadow_squad" )
    RuiSetString( rui2, "modeNameText", GetPromoData("PromoLeftTitle"))
    RuiSetString( rui2, "modeDescText", GetPromoData("PromoLeftDesc"))


    //PromoRightTitle, PromoRightDesc
    RuiSetImage( rui3, "modeImage", $"rui/menu/gamemode/ranked_2" )
    RuiSetString( rui3, "modeNameText", GetPromoData("PromoRightTitle"))
    RuiSetString( rui3, "modeDescText", GetPromoData("PromoRightDesc"))

    Hud_SetText( Hud_GetChild( file.menu, "VersionNumber" ), GetSDKVersion() )
}

void function OnR5RMenu_Show()
{
    //idk if i need this?
    Chroma_MainMenu()
}

void function OnR5RMenu_Close()
{
	//
}

void function OnR5RMenu_NavigateBack()
{
	//
}

void function ShowServerBrowser( var button )
{
    AdvanceMenu( GetMenu( "R5RServerBrowser" ) )
}

void function ShowCreateServer( var button )
{
    AdvanceMenu( GetMenu( "R5RCreateServer" ) )
}

void function ShowSettings( var button )
{
    AdvanceMenu( GetMenu( "MiscMenu" ) )
}

void function Exit( var button )
{
    AdvanceMenu( GetMenu( "ConfirmExitToDesktopDialog" ) )
}

void function OpenLink1(var button)
{

}