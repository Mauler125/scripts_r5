
global function InitR5RMainMenuPanel

struct
{
	var                menu
	var                panel
	var                launchButton
	bool			   working = false
	bool			   hasinited = false
} file

// do not change this enum without modifying it in code at gameui/IBrowser.h
global enum eServerVisibility
{
	OFFLINE,
	HIDDEN,
	PUBLIC
}

void function InitR5RMainMenuPanel( var panel )
{
	file.panel = GetPanel( "R5RMainMenuPanel" )
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, OnMainMenuPanel_Show )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, OnMainMenuPanel_Hide )

	file.launchButton = Hud_GetChild( panel, "LaunchButton" )
	Hud_AddEventHandler( file.launchButton, UIE_CLICK, LaunchButton_OnActivate )

	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "details", "Press Enter to continue" )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "isVisible", true )
	RuiSetGameTime( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "initTime", Time() )

	//AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_EXIT_TO_DESKTOP", "#B_BUTTON_EXIT_TO_DESKTOP", null, true )
	//AddPanelFooterOption( panel, LEFT, BUTTON_START, true, "#START_BUTTON_ACCESSIBLITY", "#BUTTON_ACCESSIBLITY", Accessibility_OnActivate, true )
}

void function OnMainMenuPanel_Show( var panel )
{
	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "details", "Press Enter to continue" )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "isVisible", true )
	RuiSetGameTime( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "initTime", Time() )

	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "Status" ) ), "prompt", "" )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "Status" ) ), "showPrompt", false )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "Status" ) ), "showSpinner", false )

	file.working = false
}

void function OnMainMenuPanel_Hide( var panel )
{
	
}

void function LaunchButton_OnActivate( var button )
{
	if(file.working)
		return

	file.working = true
	file.hasinited = true
	thread launchlobby()
}

void function launchlobby()
{
	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "details", "Press Enter to continue" )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "isVisible", false )
	RuiSetGameTime( Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) ), "initTime", Time() )

	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "Status" ) ), "prompt", "" )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "Status" ) ), "showPrompt", false )
	RuiSetBool( Hud_GetRui( Hud_GetChild( file.panel, "Status" ) ), "showSpinner", true )

	wait 2

	CreateServer("Lobby", "mp_lobby", "menufall", eServerVisibility.OFFLINE)
}