global function InitR5RPrivateMatchMenu
global function InitR5RNamePanel
global function InitR5RDescPanel
global function InitR5RKickPanel

global function SetSelectedServerMap
global function SetSelectedServerPlaylist
global function SetSelectedServerVis

global function UpdatePlayersList
global function AddPlayerToUIArray
global function ClearPlayerUIArray
global function EnableCreateMatchUI
global function UI_SetServerInfo
global function UpdateHostName

struct
{
	var menu
    var listPanel

    var namepanel
	var descpanel
    var kickpanel

	array<var> panels

    string tempservername
    string tempserverdesc
    string tempplayertokick

    bool maps_open = false
    bool playlists_open = false
    bool vis_open = false
    bool name_open = false
    bool desc_open = false
    bool kick_open = false
} file

enum eServerUpdateSelection
{
	MAP,
	PLAYLIST,
	NAME,
    VIS
}

struct PM_PlayerData
{
    string name
}

array<PM_PlayerData> playerdata

global struct ServerStruct
{
	string svServerName
	string svServerDesc
	string svMapName
	string svPlaylist
	int svVisibility
}

global ServerStruct ServerSettings

global string server_host_name = ""

void function InitR5RNamePanel( var panel )
{
	file.namepanel = panel

	AddButtonEventHandler( Hud_GetChild( panel, "BtnSaveName"), UIE_CLICK, UpdateServerName )
	AddButtonEventHandler( Hud_GetChild( panel, "BtnServerName"), UIE_CHANGE, TempSaveNameChanges )
}

void function UpdateServerName( var button )
{
    ServerSettings.svServerName = file.tempservername
    RunClientScript("UICodeCallback_UpdateServerInfo", eServerUpdateSelection.NAME, file.tempservername)

    Hud_SetVisible( file.namepanel, false )
	Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )

    file.name_open = false
}

void function TempSaveNameChanges( var button )
{
	file.tempservername = Hud_GetUTF8Text( Hud_GetChild( file.namepanel, "BtnServerName" ) )
}

void function InitR5RDescPanel( var panel )
{
	file.descpanel = panel

	AddButtonEventHandler( Hud_GetChild( panel, "BtnSaveDesc"), UIE_CLICK, UpdateServerDesc )
	AddButtonEventHandler( Hud_GetChild( panel, "BtnServerDesc"), UIE_CHANGE, TempSaveDescChanges )
}

void function UpdateServerDesc( var button )
{
    ServerSettings.svServerDesc = file.tempserverdesc

	Hud_SetVisible( file.descpanel, false )
	Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )

    file.desc_open = false
}

void function TempSaveDescChanges( var button )
{
	file.tempserverdesc = Hud_GetUTF8Text( Hud_GetChild( file.descpanel, "BtnServerDesc" ) )
}

void function InitR5RKickPanel( var panel )
{
	file.kickpanel = panel

	AddButtonEventHandler( Hud_GetChild( panel, "BtnKick"), UIE_CLICK, KickPlayer )
    AddButtonEventHandler( Hud_GetChild( panel, "BtnBan"), UIE_CLICK, BanPlayer )
	AddButtonEventHandler( Hud_GetChild( panel, "BtnCancel"), UIE_CLICK, DontKickOrBanPlayer )
}

void function KickPlayer(var button)
{
    RunClientScript("UICodeCallback_KickOrBanPlayer", 0, file.tempplayertokick)
    file.tempplayertokick = ""
    Hud_SetVisible( file.kickpanel, false )
	Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )
    file.kick_open = false
}

void function BanPlayer(var button)
{
    RunClientScript("UICodeCallback_KickOrBanPlayer", 1, file.tempplayertokick)
    file.tempplayertokick = ""
    Hud_SetVisible( file.kickpanel, false )
	Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )
    file.kick_open = false
}

void function DontKickOrBanPlayer(var button)
{
    file.tempplayertokick = ""
    Hud_SetVisible( file.kickpanel, false )
	Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )
    file.kick_open = false
}

void function InitR5RPrivateMatchMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RPrivateMatch" )
	file.menu = menu

    file.listPanel = Hud_GetChild( menu, "PlayerList" )

	//Add menu event handlers
    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RLobby_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RLobby_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RLobby_Back )

    //Setup Button EventHandlers
	Hud_AddEventHandler( Hud_GetChild( file.menu, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	
	array<var> buttons = GetElementsByClassname( menu, "createserverbuttons" )
	foreach ( var elem in buttons ) {
		Hud_AddEventHandler( elem, UIE_CLICK, OpenSelectedPanel )
	}

	//Setup panel array
	file.panels.append(Hud_GetChild(menu, "R5RMapPanel"))
	file.panels.append(Hud_GetChild(menu, "R5RPlaylistPanel"))
	file.panels.append(Hud_GetChild(menu, "R5RVisPanel"))
	file.panels.append(Hud_GetChild(menu, "R5RNamePanel"))
	file.panels.append(Hud_GetChild(menu, "R5RDescPanel"))
}

void function OpenSelectedPanel( var button )
{
    //Refresh Maps
    RefreshUIMaps()
    RefreshUIPlaylists()

	//Show panel depending on script id
	ShowSelectedPanel( file.panels[Hud_GetScriptID( button ).tointeger()] )

    switch (Hud_GetScriptID( button ).tointeger())
    {
        case 0:
                file.maps_open = true
            break;
        case 1:
                file.playlists_open = true
            break;
        case 2:
                file.vis_open = true
            break;
        case 3:
                file.name_open = true
                Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), true )
                Hud_SetText( Hud_GetChild( file.namepanel, "BtnServerName" ), ServerSettings.svServerName )
            break;
        case 4:
                file.desc_open = true
                Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), true )
                Hud_SetText( Hud_GetChild( file.descpanel, "BtnServerDesc" ), ServerSettings.svServerDesc )
            break;
        
    }
}

void function StartNewGame( var button )
{
	CreateServer(ServerSettings.svServerName, ServerSettings.svServerDesc, ServerSettings.svMapName, ServerSettings.svPlaylist, ServerSettings.svVisibility)
}

void function SetSelectedServerMap( string map )
{
	ServerSettings.svMapName = map

    RunClientScript("UICodeCallback_UpdateServerInfo", eServerUpdateSelection.MAP, map)
	Hud_SetVisible( file.panels[0], false )

    file.maps_open = false
}

void function SetSelectedServerPlaylist( string playlist )
{
	ServerSettings.svPlaylist = playlist

    RunClientScript("UICodeCallback_UpdateServerInfo", eServerUpdateSelection.PLAYLIST, playlist)

    array<string> playlist_maps = GetPlaylistMaps(ServerSettings.svPlaylist)
	//This should ever really be triggered but here just incase
	if(playlist_maps.len() == 0) {
		SetSelectedServerMap("mp_rr_canyonlands_64k_x_64k")
        RefreshUIMaps()
		return
	}

	//Check to see if the current map is allowed on the new selected playlist
	if(!playlist_maps.contains(ServerSettings.svMapName))
		SetSelectedServerMap(playlist_maps[0])

    RefreshUIMaps()
    Hud_SetVisible( file.panels[1], false )

    file.playlists_open = false
}

void function SetSelectedServerVis( int vis )
{
    ServerSettings.svVisibility = vis

    RunClientScript("UICodeCallback_UpdateServerInfo", eServerUpdateSelection.VIS, vis.tostring())
	Hud_SetVisible( file.panels[2], false )
	Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )

    file.vis_open = false
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

void function OnR5RLobby_Open()
{
    UI_SetPresentationType( ePresentationType.COLLECTION_EVENT )
    CurrentPresentationType = ePresentationType.COLLECTION_EVENT

    array<var> privatematchui = GetElementsByClassname( file.menu, "CreateServerUI" )
	foreach ( var elem in privatematchui ) {
		Hud_SetVisible(elem, false)
	}

    array<var> buttons = GetElementsByClassname( file.menu, "createserverbuttons" )
	foreach ( var elem in buttons ) {
		Hud_SetVisible(elem, false)
	}

    RunClientScript("ServerCallback_PrivateMatch_UpdateUI")

	g_isAtMainMenu = false
}

void function OnR5RLobby_Back()
{
    if(file.maps_open || file.playlists_open || file.vis_open || file.name_open || file.desc_open || file.kick_open)
    {
        Hud_SetVisible( file.panels[0], false )
        Hud_SetVisible( file.panels[1], false )
        Hud_SetVisible( file.panels[2], false )
        Hud_SetVisible( file.namepanel, false )
        Hud_SetVisible( file.descpanel, false )
        Hud_SetVisible( file.kickpanel, false )
        Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), false )

        file.maps_open = false
        file.playlists_open = false
        file.vis_open = false
        file.name_open = false
        file.desc_open = false
        file.kick_open = false
    }
    else
    {
        AdvanceMenu( GetMenu( "SystemMenu" ) )
    }
}

/////////////////////////////////////////////////////
//
//   Client to UI
//
/////////////////////////////////////////////////////

void function EnableCreateMatchUI()
{
    array<var> privatematchui = GetElementsByClassname( file.menu, "CreateServerUI" )
	foreach ( var elem in privatematchui )
	{
		Hud_SetVisible(elem, true)
	}

    array<var> buttons = GetElementsByClassname( file.menu, "createserverbuttons" )
	foreach ( var elem in buttons ) {
		Hud_SetVisible(elem, true)
	}
}

void function AddPlayerToUIArray(string name)
{
    PM_PlayerData p
    p.name = name

    playerdata.append(p)
}

table<var, void functionref(var)> WORKAROUND_PlayerButtonToClickHandlerMap = {}
void function ClearPlayerUIArray()
{
    playerdata.clear()
}

void function UpdateHostName(string name)
{
    server_host_name = name
}

void function UpdatePlayersList()
{
    var scrollPanel = Hud_GetChild( file.listPanel, "ScrollPanel" )
    

    Hud_InitGridButtons( file.listPanel, playerdata.len() )
    foreach ( int id, PM_PlayerData p in playerdata )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + id )
        var rui = Hud_GetRui( button )
	    RuiSetString( rui, "buttonText", p.name )

        if ( button in WORKAROUND_PlayerButtonToClickHandlerMap )
		{
			Hud_RemoveEventHandler( button, UIE_DOUBLECLICK, WORKAROUND_PlayerButtonToClickHandlerMap[button] )
			delete WORKAROUND_PlayerButtonToClickHandlerMap[button]
		}

        void functionref(var) clickHandler = (void function( var button ) : ( p) {
            if(p.name != playerdata[0].name)
            {
                EmitUISound( "menu_accept" )
                Hud_SetText( Hud_GetChild( file.kickpanel, "SetPlayerKickMessage" ), "What do you want todo with " + p.name + "?" )
                Hud_SetVisible( file.kickpanel, true )
                Hud_SetVisible( Hud_GetChild(file.menu, "FadeBackground"), true )
                file.tempplayertokick = p.name
                file.kick_open = true
            }
		})

        if(server_host_name == GetPlayerName())
        {
            Hud_AddEventHandler( button, UIE_DOUBLECLICK, clickHandler )
            WORKAROUND_PlayerButtonToClickHandlerMap[button] <- clickHandler
        }
	}

    RunClientScript("UICallback_CheckForHost")
}

void function UI_SetServerInfo( int type, string text )
{
    switch( type )
    {
        case eServerUpdateSelection.NAME:
                ServerSettings.svServerName = text
	            Hud_SetText(Hud_GetChild( file.menu, "MapServerNameInfoEdit" ), text)
            break;
        case eServerUpdateSelection.MAP:
                ServerSettings.svMapName = text
	            RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset( text ) )
            break;
        case eServerUpdateSelection.PLAYLIST:
                ServerSettings.svPlaylist = text
	            Hud_SetText(Hud_GetChild( file.menu, "PlaylistInfoEdit" ), GetUIPlaylistName( text ) )
            break;
        case eServerUpdateSelection.VIS:
                ServerSettings.svVisibility = text.tointeger()
	            Hud_SetText(Hud_GetChild( file.menu, "VisInfoEdit" ), vistoname[text])
            break;
    }
}