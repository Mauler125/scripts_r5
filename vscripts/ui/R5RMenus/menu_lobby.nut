global function InitR5RLobbyMenu

struct
{
	var menu
	array<var> buttons
	array<var> panels

	var HomePanel
	var CreateServerPanel
	var ServerBrowserPanel
} file

// do not change this enum without modifying it in code at gameui/IBrowser.h
global enum eServerVisibility
{
	OFFLINE,
	HIDDEN,
	PUBLIC
}

//Map name to asset
global table<string, asset> maptoasset = {
	[ "mp_rr_canyonlands_staging" ] = $"rui/menu/maps/mp_rr_canyonlands_staging",
	[ "mp_rr_aqueduct" ] = $"rui/menu/maps/mp_rr_aqueduct",
	[ "mp_rr_ashs_redemption" ] = $"rui/menu/maps/mp_rr_ashs_redemption",
	[ "mp_rr_canyonlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_canyonlands_64k_x_64k",
	[ "mp_rr_canyonlands_mu1" ] = $"rui/menu/maps/mp_rr_canyonlands_mu1",
	[ "mp_rr_canyonlands_mu1_night" ] = $"rui/menu/maps/mp_rr_canyonlands_mu1_night",
	[ "mp_rr_desertlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k",
	[ "mp_rr_desertlands_64k_x_64k_nx" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k_nx"
}

//Map name to readable name
global table<string, string> maptoname = {
	[ "mp_rr_canyonlands_staging" ] = "Firing Range",
	[ "mp_rr_aqueduct" ] = "Overflow",
	[ "mp_rr_ashs_redemption" ] = "Ash's Redemption",
	[ "mp_rr_canyonlands_64k_x_64k" ] = "Kings Canyon S1",
	[ "mp_rr_canyonlands_mu1" ] = "Kings Canyon S2",
	[ "mp_rr_canyonlands_mu1_night" ] = "Kings Canyon S2 After Dark",
	[ "mp_rr_desertlands_64k_x_64k" ] = "Worlds Edge",
	[ "mp_rr_desertlands_64k_x_64k_nx" ] = "Worlds Edge After Dark"
}

//Playlist to readable name
global table<string, string> playlisttoname = {
	[ "survival_staging_baseline" ] = "survival_staging_baseline",
	[ "sutvival_training" ] = "Training",
	[ "survival_firingrange" ] = "Firing Range",
	[ "survival" ] = "Survival",
	[ "defaults" ] = "defaults",
	[ "ranked" ] = "Ranked",
	[ "FallLTM" ] = "ShadowFall",
	[ "duos" ] = "Duos",
	[ "iron_crown" ] = "Iron Crown",
	[ "elite" ] = "Elite",
	[ "armed_and_dangerous" ] = "Armed and Dangerous",
	[ "wead" ] = "wead",
	[ "custom_tdm" ] = "Team Deathmatch",
	[ "custom_ctf" ] = "Capture The Flag",
	[ "tdm_gg" ] = "Gun Game",
	[ "tdm_gg_double" ] = "Team Gun Game",
	[ "survival_dev" ] = "Survival Dev",
	[ "dev_default" ] = "dev_default"
}

//Vis int to readable name
global table<int, string> vistoname = {
	[ eServerVisibility.OFFLINE ] = "Offline",
	[ eServerVisibility.HIDDEN ] = "Hidden",
	[ eServerVisibility.PUBLIC ] = "Public"
}

void function InitR5RLobbyMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RLobbyMenu" )
	file.menu = menu

	//Add menu event handlers
    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RLobby_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RLobby_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RLobby_Back )

	//Button event handlers
	Hud_AddEventHandler( Hud_GetChild(menu, "SettingsBtn"), UIE_CLICK, SettingsPressed )
	Hud_AddEventHandler( Hud_GetChild(menu, "QuitBtn"), UIE_CLICK, QuitPressed )
	array<var> buttons = GetElementsByClassname( file.menu, "TopButtons" )
	foreach ( var elem in buttons ) {
		Hud_AddEventHandler( elem, UIE_CLICK, OpenSelectedPanel )
	}

	//Setup panel array
	file.panels.append(Hud_GetChild(menu, "R5RHomePanel"))
	file.panels.append(Hud_GetChild(menu, "R5RCreateServerPanel"))
	file.panels.append(Hud_GetChild(menu, "R5RServerBrowserPanel"))

	//Setup Button Vars
	file.buttons.append(Hud_GetChild(menu, "HomeBtn"))
	file.buttons.append(Hud_GetChild(menu, "CreateServerBtn"))
	file.buttons.append(Hud_GetChild(menu, "ServerBrowserBtn"))

	//Show Home Panel
	ShowSelectedPanel( file.panels[0], file.buttons[0] )
}

void function OpenSelectedPanel(var button)
{
	int scriptid = Hud_GetScriptID( button ).tointeger()
	ShowSelectedPanel( file.panels[scriptid], button )

	if(scriptid == 1)
		HideAllCreateServerPanels()
}

void function SettingsPressed(var button)
{
	AdvanceMenu( GetMenu( "MiscMenu" ) )
}

void function QuitPressed(var button)
{
	OpenConfirmExitToDesktopDialog()
}

void function OnR5RLobby_Open()
{
	//needed on both show and open
	SetupLobby()
}

void function SetupLobby()
{
	ClientCommand( "ViewingMainLobbyPage" )
	UI_SetPresentationType( ePresentationType.PLAY )
	thread TryRunDialogFlowThread()
	SetUIPlayerName()
}

void function ShowSelectedPanel(var panel, var button)
{
	//Hide all panels
	foreach ( p in file.panels ) {
		Hud_SetVisible( p, false )
	}

	//Unselect all buttons
	foreach ( btn in file.buttons )
	{
		RuiSetBool( Hud_GetRui( btn ) ,"isSelected", false )
	}

	//Select button
	RuiSetBool( Hud_GetRui( button ) ,"isSelected", true )

	//Show selected panel
	Hud_SetVisible( panel, true )
}

void function OnR5RLobby_Back()
{
	// Do nothing so it dosnt hide the menu
}