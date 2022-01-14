global function InitR5RGamemodeMenu

struct
{
	var menu

    var gm1
    var gm2
    var gm3
    var gm4
    var gm5
    var gm6
    var gm7
    var gm8
    var gm9
    var gm10
    var gm11
    var gm12
} file

void function InitR5RGamemodeMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RChangeGamemode" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	SetGamepadCursorEnabled( menu, false )

    //Set RUI/GUI

    file.gm1 = Hud_GetChild(menu, "Gamemodebtn1")
    Hud_AddEventHandler( file.gm1, UIE_CLICK, SetGamemode1 )
    var gm1rui = Hud_GetRui( file.gm1 )
    RuiSetString( gm1rui, "buttonText", "survival_staging_baseline" )

    file.gm2 = Hud_GetChild(menu, "Gamemodebtn2")
    Hud_AddEventHandler( file.gm2, UIE_CLICK, SetGamemode2 )
    var gm2rui = Hud_GetRui( file.gm2 )
    RuiSetString( gm2rui, "buttonText", "survival_training" )

    file.gm3 = Hud_GetChild(menu, "Gamemodebtn3")
    Hud_AddEventHandler( file.gm3, UIE_CLICK, SetGamemode3 )
    var gm3rui = Hud_GetRui( file.gm3 )
    RuiSetString( gm3rui, "buttonText", "survival_firingrange" )

    file.gm4 = Hud_GetChild(menu, "Gamemodebtn4")
    Hud_AddEventHandler( file.gm4, UIE_CLICK, SetGamemode4 )
    var gm4rui = Hud_GetRui( file.gm4 )
    RuiSetString( gm4rui, "buttonText", "survival" )

    file.gm5 = Hud_GetChild(menu, "Gamemodebtn5")
    Hud_AddEventHandler( file.gm5, UIE_CLICK, SetGamemode5 )
    var gm5rui = Hud_GetRui( file.gm5 )
    RuiSetString( gm5rui, "buttonText", "ranked" )

    file.gm6 = Hud_GetChild(menu, "Gamemodebtn6")
    Hud_AddEventHandler( file.gm6, UIE_CLICK, SetGamemode6 )
    var gm6rui = Hud_GetRui( file.gm6 )
    RuiSetString( gm6rui, "buttonText", "FallLTM" )

    file.gm7 = Hud_GetChild(menu, "Gamemodebtn7")
    Hud_AddEventHandler( file.gm7, UIE_CLICK, SetGamemode7 )
    var gm7rui = Hud_GetRui( file.gm7 )
    RuiSetString( gm7rui, "buttonText", "duos" )

    file.gm8 = Hud_GetChild(menu, "Gamemodebtn8")
    Hud_AddEventHandler( file.gm8, UIE_CLICK, SetGamemode8 )
    var gm8rui = Hud_GetRui( file.gm8 )
    RuiSetString( gm8rui, "buttonText", "custom_tdm" )

    file.gm9 = Hud_GetChild(menu, "Gamemodebtn9")
    Hud_AddEventHandler( file.gm9, UIE_CLICK, SetGamemode9 )
    var gm9rui = Hud_GetRui( file.gm9 )
    RuiSetString( gm9rui, "buttonText", "custom_tdm_tps" )

    file.gm10 = Hud_GetChild(menu, "Gamemodebtn10")
    Hud_AddEventHandler( file.gm10, UIE_CLICK, SetGamemode10 )
    var gm10rui = Hud_GetRui( file.gm10 )
    RuiSetString( gm10rui, "buttonText", "survival_dev" )

    file.gm11 = Hud_GetChild(menu, "Gamemodebtn11")
    Hud_AddEventHandler( file.gm11, UIE_CLICK, SetGamemode11 )
    var gm11rui = Hud_GetRui( file.gm11 )
    RuiSetString( gm11rui, "buttonText", "dev_default" )

    file.gm12 = Hud_GetChild(menu, "Gamemodebtn12")
    Hud_AddEventHandler( file.gm12, UIE_CLICK, SetGamemode12 )
    var gm12rui = Hud_GetRui( file.gm12 )
    RuiSetString( gm12rui, "buttonText", "menufall" )
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

void function SetGamemode1(var button)
{
    SetGamemode( "survival_staging_baseline" )
    CloseActiveMenu()
}

void function SetGamemode2(var button)
{
    SetGamemode( "survival_training" )
    CloseActiveMenu()
}

void function SetGamemode3(var button)
{
    SetGamemode( "survival_firingrange" )
    CloseActiveMenu()
}

void function SetGamemode4(var button)
{
    SetGamemode( "survival" )
    CloseActiveMenu()
}

void function SetGamemode5(var button)
{
    SetGamemode( "ranked" )
    CloseActiveMenu()
}

void function SetGamemode6(var button)
{
    SetGamemode( "FallLTM" )
    CloseActiveMenu()
}

void function SetGamemode7(var button)
{
    SetGamemode( "duos" )
    CloseActiveMenu()
}

void function SetGamemode8(var button)
{
    SetGamemode( "custom_tdm" )
    CloseActiveMenu()
}

void function SetGamemode9(var button)
{
    SetGamemode( "custom_tdm_tps" )
    CloseActiveMenu()
}

void function SetGamemode10(var button)
{
    SetGamemode( "survival_dev" )
    CloseActiveMenu()
}

void function SetGamemode11(var button)
{
    SetGamemode( "dev_default" )
    CloseActiveMenu()
}

void function SetGamemode12(var button)
{
    SetGamemode( "menufall" )
    CloseActiveMenu()
}