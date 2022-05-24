global function InitR5RLobbyMenu

global function OpenPlaylistUI
global function OpenMapUI

struct
{
	var menu
	array<var> buttons

	var HomePanel
	var CreateServerPanel
	var ServerBrowserPanel
	var PlaylistPanel
	var MapPanel
} file

global const table<string, asset> maptoasset = {
	[ "mp_rr_aqueduct" ] = $"rui/menu/maps/mp_rr_aqueduct",
	[ "mp_rr_canyonlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_canyonlands_64k_x_64k",
	[ "mp_rr_canyonlands_mu1" ] = $"rui/menu/maps/mp_rr_canyonlands_mu1",
	[ "mp_rr_desertlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k"
}

global const table<string, string> maptoname = {
	[ "mp_rr_aqueduct" ] = "Overflow",
	[ "mp_rr_canyonlands_64k_x_64k" ] = "Kings Canyon S1",
	[ "mp_rr_canyonlands_mu1" ] = "Kings Canyon S2",
	[ "mp_rr_desertlands_64k_x_64k" ] = "Worlds Edge"
}

global const table<string, string> playlisttoname = {
	[ "custom_tdm" ] = "Team Deathmatch",
	[ "custom_ctf" ] = "Capture The Flag",
	[ "tdm_gg" ] = "Gun Game",
	[ "tdm_gg_double" ] = "Team Gun Game"
}

void function InitR5RLobbyMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RLobbyMenu" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	var Home = Hud_GetChild(menu, "HomeBtn")
	var CreateServer = Hud_GetChild(menu, "CreateServerBtn")
	var ServerBrowser = Hud_GetChild(menu, "ServerBrowserBtn")
	var Settings = Hud_GetChild(menu, "SettingsBtn")
	var Quit = Hud_GetChild(menu, "QuitBtn")

	file.HomePanel = Hud_GetChild(menu, "R5RHomePanel")
	file.CreateServerPanel = Hud_GetChild(menu, "R5RCreateServerPanel")
	file.ServerBrowserPanel = Hud_GetChild(menu, "R5RServerBrowserPanel")
	file.PlaylistPanel = Hud_GetChild(menu, "R5RPlaylistPanel")
	file.MapPanel = Hud_GetChild(menu, "R5RMapPanel")

	file.buttons.append(Home)
	file.buttons.append(CreateServer)
	file.buttons.append(ServerBrowser)

	Hud_AddEventHandler( Home, UIE_CLICK, HomePressed )
	Hud_AddEventHandler( CreateServer, UIE_CLICK, CreateServerPressed )
	Hud_AddEventHandler( ServerBrowser, UIE_CLICK, ServerBrowserPressed )
	Hud_AddEventHandler( Settings, UIE_CLICK, SettingsPressed )
	Hud_AddEventHandler( Quit, UIE_CLICK, QuitPressed )

	RuiSetString( Hud_GetRui( Home ), "buttonText", "Home" )
	RuiSetString( Hud_GetRui( CreateServer ), "buttonText", "Create Server" )
	RuiSetString( Hud_GetRui( ServerBrowser ), "buttonText", "Server Browser" )
	RuiSetString( Hud_GetRui( Settings ), "buttonText", "Settings" )
	RuiSetString( Hud_GetRui( Quit ), "buttonText", "Quit" )

	Hud_SetVisible( file.HomePanel, true )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, false )
}

void function HomePressed(var button)
{
	SetSelectedButton(button)

	Hud_SetVisible( file.HomePanel, true )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, false )
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, false )
}

void function CreateServerPressed(var button)
{
	SetSelectedButton(button)

	Hud_SetVisible( file.HomePanel, false )
	Hud_SetVisible( file.CreateServerPanel, true )
	Hud_SetVisible( file.ServerBrowserPanel, false )
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, false )
}

void function ServerBrowserPressed(var button)
{
	SetSelectedButton(button)

	Hud_SetVisible( file.HomePanel, false )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, true )
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, false )
}

void function OpenPlaylistUI( var button )
{
	Hud_SetVisible( file.HomePanel, false )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, false )
	Hud_SetVisible( file.PlaylistPanel, true )
	Hud_SetVisible( file.MapPanel, false )
}

void function OpenMapUI( var button )
{
	Hud_SetVisible( file.HomePanel, false )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, false )
	Hud_SetVisible( file.PlaylistPanel, false )
	Hud_SetVisible( file.MapPanel, true )
}

void function SettingsPressed(var button)
{
	AdvanceMenu( GetMenu( "MiscMenu" ) )
}

void function QuitPressed(var button)
{
	
}

void function SetSelectedButton(var button)
{
	foreach ( btn in file.buttons )
	{
		RuiSetBool( Hud_GetRui( btn ) ,"isSelected", false )
	}

	RuiSetBool( Hud_GetRui( button ) ,"isSelected", true )
}

void function OnR5RSB_Show()
{
	//needed on both show and open
    ClientCommand( "ViewingMainLobbyPage" )
	UI_SetPresentationType( ePresentationType.PLAY )
	thread TryRunDialogFlowThread()
}

void function OnR5RSB_Open()
{
	//needed on both show and open
	ClientCommand( "ViewingMainLobbyPage" )
	UI_SetPresentationType( ePresentationType.PLAY )
	thread TryRunDialogFlowThread()
}

void function OnR5RSB_Close()
{
	//
}

void function OnR5RSB_NavigateBack()
{
    //
}