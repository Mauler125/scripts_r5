global function InitR5RLobbyMenu
global function GetUIPlaylistName
global function GetUIMapName
global function GetUIMapAsset
global function GetUIVisibilityName

struct
{
	var menu
	array<var> buttons
	array<var> panels

	int currentpanel = 0

	var HomePanel
	var CreateServerPanel
	var ServerBrowserPanel

	bool initialisedHomePanel = false

	int CurrentNavIndex = 0
	array<var> TopButtons
} file

// do not change this enum without modifying it in code at gameui/IBrowser.h
global enum eServerVisibility
{
	OFFLINE,
	HIDDEN,
	PUBLIC
}

global int CurrentPresentationType = ePresentationType.PLAY

//Map to asset
global table<string, asset> MapAssets = {
	[ "mp_rr_canyonlands_staging" ] = $"rui/menu/maps/mp_rr_canyonlands_staging",
	[ "mp_rr_aqueduct" ] = $"rui/menu/maps/mp_rr_aqueduct",
	[ "mp_rr_aqueduct_night" ] = $"rui/menu/maps/mp_rr_aqueduct_night",
	[ "mp_rr_ashs_redemption" ] = $"rui/menu/maps/mp_rr_ashs_redemption",
	[ "mp_rr_canyonlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_canyonlands_64k_x_64k",
	[ "mp_rr_canyonlands_mu1" ] = $"rui/menu/maps/mp_rr_canyonlands_mu1",
	[ "mp_rr_canyonlands_mu1_night" ] = $"rui/menu/maps/mp_rr_canyonlands_mu1_night",
	[ "mp_rr_desertlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k",
	[ "mp_rr_desertlands_64k_x_64k_nx" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k_nx",
	[ "mp_rr_desertlands_64k_x_64k_tt" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k_tt",
	[ "mp_rr_arena_composite" ] = $"rui/menu/maps/mp_rr_arena_composite",
	[ "mp_rr_arena_skygarden" ] = $"rui/menu/maps/mp_rr_arena_skygarden",
	[ "mp_rr_party_crasher" ] = $"rui/menu/maps/mp_rr_party_crasher",
	[ "mp_lobby" ] = $"rui/menu/maps/mp_lobby"
}

//Map to readable name
global table<string, string> MapNames = {
	[ "mp_rr_canyonlands_staging" ] = "Firing Range",
	[ "mp_rr_aqueduct" ] = "Overflow",
	[ "mp_rr_aqueduct_night" ] = "Overflow After Dark",
	[ "mp_rr_ashs_redemption" ] = "Ash's Redemption",
	[ "mp_rr_canyonlands_64k_x_64k" ] = "Kings Canyon S1",
	[ "mp_rr_canyonlands_mu1" ] = "Kings Canyon S2",
	[ "mp_rr_canyonlands_mu1_night" ] = "Kings Canyon S2 After Dark",
	[ "mp_rr_desertlands_64k_x_64k" ] = "Worlds Edge",
	[ "mp_rr_desertlands_64k_x_64k_nx" ] = "Worlds Edge After Dark",
	[ "mp_rr_desertlands_64k_x_64k_tt" ] = "Worlds Edge Mirage Voyage",
	[ "mp_rr_arena_composite" ] = "Drop Off",
	[ "mp_rr_arena_skygarden" ] = "Encore",
	[ "mp_rr_party_crasher" ] = "Party Crasher",
	[ "mp_lobby" ] = "Lobby"
}

//Vis to readable name
global table<int, string> VisibilityNames = {
	[ eServerVisibility.OFFLINE ] = "Offline",
	[ eServerVisibility.HIDDEN ] = "Hidden",
	[ eServerVisibility.PUBLIC ] = "Public"
}

void function InitR5RLobbyMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RLobbyMenu" )
	file.menu = menu

	//Add menu event handlers
    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RLobby_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RLobby_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RLobby_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RLobby_Back )

	CreateNavButtons()
	ToolTips_AddMenu( menu )
}

void function OnR5RLobby_Open()
{
	ToolTips_MenuOpened( file.menu )
	RegisterServerBrowserButtonPressedCallbacks()
}

void function OnR5RLobby_Close()
{
	ToolTips_MenuClosed( file.menu )
	UnRegisterServerBrowserButtonPressedCallbacks()
}

void function OnR5RLobby_Show()
{
	ServerBrowser_UpdateFilterLists()
	SetupLobby()

	//Set back to default for next time
	g_isAtMainMenu = false

	if(g_InLegendsMenu || g_InLoutoutPanel)
	{
		g_InLegendsMenu = false
		g_InLoutoutPanel = false
		return
	}

	//Show Home Panel
	OpenSelectedPanel( file.buttons[0] )
	UI_SetPresentationType( ePresentationType.PLAY )
	CurrentPresentationType = ePresentationType.PLAY
}

void function OnR5RLobby_Back()
{
	if(PMMenusOpen.maps_open || PMMenusOpen.playlists_open || PMMenusOpen.vis_open || PMMenusOpen.name_open || PMMenusOpen.desc_open)
    {
		var pmpanel = GetPanel( "CreatePanel" )
        Hud_SetVisible( Hud_GetChild(pmpanel, "R5RMapPanel"), false )
        Hud_SetVisible( Hud_GetChild(pmpanel, "R5RPlaylistPanel"), false )
        Hud_SetVisible( Hud_GetChild(pmpanel, "R5RVisPanel"), false )
        Hud_SetVisible( Hud_GetChild(file.menu, "R5RNamePanel"), false )
        Hud_SetVisible( Hud_GetChild(file.menu, "R5RDescPanel"), false )

        PMMenusOpen.maps_open = false
        PMMenusOpen.playlists_open = false
        PMMenusOpen.vis_open = false
        PMMenusOpen.name_open = false
        PMMenusOpen.desc_open = false
		return
    }

	if(file.currentpanel != 0)
	{
		OpenSelectedPanel( file.buttons[0] )
		UI_SetPresentationType( ePresentationType.PLAY )
		CurrentPresentationType = ePresentationType.PLAY
		return
	}

	AdvanceMenu( GetMenu( "SystemMenu" ) )
}

void function CreateNavButtons()
{
	file.CurrentNavIndex = 0
	file.TopButtons = GetElementsByClassname( file.menu, "TopButtons" )
		foreach ( elem in file.TopButtons )
			Hud_SetVisible( elem, false )

	AddNavButton("Play", Hud_GetChild(file.menu, "HomePanel"), void function( var button ) {
		Play_SetupUI()
		UI_SetPresentationType( ePresentationType.PLAY )
		CurrentPresentationType = ePresentationType.PLAY
	} )

	AddNavButton("Legends", Hud_GetChild(file.menu, "LegendsPanel"), void function( var button ) {
		SetTopLevelCustomizeContext( null )
		RunMenuClientFunction( "ClearAllCharacterPreview" )
		R5RCharactersPanel_Show()
		UI_SetPresentationType( ePresentationType.CHARACTER_SELECT )
		CurrentPresentationType = ePresentationType.CHARACTER_SELECT
	} )

	//Item flavor bugged, disable for now
	/*AddNavButton("Loadout", Hud_GetChild(file.menu, "LoadoutPanel"), void function( var button ) {
		ShowLoadoutPanel()
		UI_SetPresentationType( ePresentationType.WEAPON_CATEGORY )
		CurrentPresentationType = ePresentationType.WEAPON_CATEGORY
	} )*/

	AddNavButton("Create", Hud_GetChild(file.menu, "CreatePanel"), void function( var button ) {
		OnCreateMatchOpen()
		UI_SetPresentationType( ePresentationType.CHARACTER_SELECT )
		CurrentPresentationType = ePresentationType.CHARACTER_SELECT
	} )

	AddNavButton("Servers", Hud_GetChild(file.menu, "ServerBrowserPanel"), void function( var button ) {
		UI_SetPresentationType( ePresentationType.COLLECTION_EVENT )
		CurrentPresentationType = ePresentationType.COLLECTION_EVENT
	} )

	/*AddNavButton("Settings", null, void function( var button ) {
		AdvanceMenu( GetMenu( "MiscMenu" ) )
	} )*/
}

void function AddNavButton(string title, var panel, void functionref(var button) Click = null)
{
	
	Hud_SetVisible( file.TopButtons[file.CurrentNavIndex], true )
	RuiSetString( Hud_GetRui(file.TopButtons[file.CurrentNavIndex]), "buttonText", title )
	Hud_AddEventHandler( file.TopButtons[file.CurrentNavIndex], UIE_CLICK, OpenSelectedPanel )
	Hud_AddEventHandler( file.TopButtons[file.CurrentNavIndex], UIE_CLICK, Click )

	file.panels.append(panel)
	file.buttons.append(file.TopButtons[file.CurrentNavIndex])
	file.CurrentNavIndex++
}

void function SetupLobby()
{
	// Setup Lobby Stuff
	UI_SetPresentationType( CurrentPresentationType )
	thread TryRunDialogFlowThread()

	Play_SetupUI()

	if ( !file.initialisedHomePanel )
	{
		ItemFlavor character = GetItemFlavorByHumanReadableRef( GetCurrentPlaylistVarString( "set_legend", "character_wraith" ) )
		RequestSetItemFlavorLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), character )

		file.initialisedHomePanel = true
	}

}

void function OpenSelectedPanel(var button)
{
	int scriptid = Hud_GetScriptID( button ).tointeger()
	ShowSelectedPanel( file.panels[scriptid], button )
	file.currentpanel = scriptid
}

void function ShowSelectedPanel(var panel, var button)
{
	if(panel == null)
		return
	
	//Hide all panels
	foreach ( p in file.panels ) {
		if(p != null)
			Hud_SetVisible( p, false )
	}

	//Unselect all buttons
	foreach ( btn in file.buttons ) {
		RuiSetBool( Hud_GetRui( btn ) ,"isSelected", false )
	}

	//Select button
	RuiSetBool( Hud_GetRui( button ) ,"isSelected", true )

	//Show selected panel
	Hud_SetVisible( panel, true )
}

////////////////////////////////////////////////////////////////////////////////////////
//
// Extra Functions
//
////////////////////////////////////////////////////////////////////////////////////////

string function GetUIPlaylistName(string playlist)
{
	if(!IsLobby() || !IsConnected())
		return ""

	return GetPlaylistVarString( playlist, "name", playlist )
}

string function GetUIMapName(string map)
{
	if(map in MapNames)
		return MapNames[map]

	return map
}

string function GetUIVisibilityName(int vis)
{
	if(vis in VisibilityNames)
		return VisibilityNames[vis]

	return ""
}

asset function GetUIMapAsset(string map)
{
	if(map in MapAssets)
		return MapAssets[map]

	return $"rui/menu/maps/map_not_found"
}