global function InitR5RLobbyMenu

struct
{
	var menu
	array<var> buttons
	array<var> panels

	var HomePanel
	var CreateServerPanel
	var ServerBrowserPanel
	var PlaylistPanel
	var MapPanel
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

void function InitR5RLobbyMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RLobbyMenu" )
	file.menu = menu

	//Add menu event handlers
    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )

	//Setup Button Vars
	var Home = Hud_GetChild(menu, "HomeBtn")
	var CreateServer = Hud_GetChild(menu, "CreateServerBtn")
	var ServerBrowser = Hud_GetChild(menu, "ServerBrowserBtn")
	var Settings = Hud_GetChild(menu, "SettingsBtn")
	var Quit = Hud_GetChild(menu, "QuitBtn")
	file.buttons.append(Home)
	file.buttons.append(CreateServer)
	file.buttons.append(ServerBrowser)

	//Setup Panel Array
	file.panels.append(Hud_GetChild(menu, "R5RHomePanel"))
	file.panels.append(Hud_GetChild(menu, "R5RCreateServerPanel"))
	file.panels.append(Hud_GetChild(menu, "R5RServerBrowserPanel"))

	//Setup Event Handlers
	Hud_AddEventHandler( Home, UIE_CLICK, HomePressed )
	Hud_AddEventHandler( CreateServer, UIE_CLICK, CreateServerPressed )
	Hud_AddEventHandler( ServerBrowser, UIE_CLICK, ServerBrowserPressed )
	Hud_AddEventHandler( Settings, UIE_CLICK, SettingsPressed )
	Hud_AddEventHandler( Quit, UIE_CLICK, QuitPressed )

	//Setup Button Text
	RuiSetString( Hud_GetRui( Home ), "buttonText", "Home" )
	RuiSetString( Hud_GetRui( CreateServer ), "buttonText", "Create Server" )
	RuiSetString( Hud_GetRui( ServerBrowser ), "buttonText", "Server Browser" )
	RuiSetString( Hud_GetRui( Settings ), "buttonText", "Settings" )
	RuiSetString( Hud_GetRui( Quit ), "buttonText", "Quit" )

	//Show Home Panel
	ShowSelectedPanel(file.HomePanel)
}

void function HomePressed(var button)
{
	SetSelectedButton(button)
	ShowSelectedPanel(file.HomePanel)
}

void function CreateServerPressed(var button)
{
	SetSelectedButton( button )
	ShowSelectedPanel( file.CreateServerPanel )
}

void function ServerBrowserPressed(var button)
{
	SetSelectedButton(button)
	ShowSelectedPanel( file.ServerBrowserPanel )
}

void function SettingsPressed(var button)
{
	AdvanceMenu( GetMenu( "MiscMenu" ) )
}

void function QuitPressed(var button)
{
	OpenConfirmExitToDesktopDialog()
}

void function OnR5RSB_Show()
{
	SetupLobby()
}

void function OnR5RSB_Open()
{
	SetupLobby()
}

void function SetupLobby()
{
	//needed on both show and open
	ClientCommand( "ViewingMainLobbyPage" )
	UI_SetPresentationType( ePresentationType.PLAY )
	thread TryRunDialogFlowThread()
	SetUIPlayerName()
}

void function SetSelectedButton(var button)
{
	//Unselect all buttons
	foreach ( btn in file.buttons )
	{
		RuiSetBool( Hud_GetRui( btn ) ,"isSelected", false )
	}

	//Select button
	RuiSetBool( Hud_GetRui( button ) ,"isSelected", true )
}

void function ShowSelectedPanel(var panel)
{
	//Hide all panels
	foreach ( p in file.panels ) {
		Hud_SetVisible( p, false )
	}

	//Show selected panel
	Hud_SetVisible( panel, true )
}