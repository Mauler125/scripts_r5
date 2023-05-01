global function InitCreatePanel
global function InitR5RNamePanel
global function InitR5RDescPanel

global function SetSelectedServerMap
global function SetSelectedServerPlaylist
global function SetSelectedServerVis
global function OnCreateMatchOpen

struct
{
	var menu
	var panel
	var namepanel
	var descpanel
	array<var> panels
} file

global struct ServerStruct
{
	string svServerName
	string svServerDesc
	string svMapName
	string svPlaylist
	int svVisibility
}

global struct PrivateMatchMenusOpen
{
    bool maps_open = false
    bool playlists_open = false
    bool vis_open = false
    bool name_open = false
    bool desc_open = false
}

global ServerStruct ServerSettings
global PrivateMatchMenusOpen PMMenusOpen

void function InitR5RNamePanel( var panel )
{
	file.namepanel = panel
	AddButtonEventHandler( Hud_GetChild( panel, "BtnSaveName"), UIE_CLICK, UpdateServerName )
}

void function InitR5RDescPanel( var panel )
{
	file.descpanel = panel
	AddButtonEventHandler( Hud_GetChild( panel, "BtnSaveDesc"), UIE_CLICK, UpdateServerDesc )
}

void function InitCreatePanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Setup Button EventHandlers
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	
	array<var> buttons = GetElementsByClassname( file.menu, "createserverbuttons" )
	foreach ( var elem in buttons ) {
		Hud_AddEventHandler( elem, UIE_CLICK, OpenSelectedPanel )
	}

	//Setup panel array
	file.panels.append(Hud_GetChild(file.panel, "R5RMapPanel"))
	file.panels.append(Hud_GetChild(file.panel, "R5RPlaylistPanel"))
	file.panels.append(Hud_GetChild(file.panel, "R5RVisPanel"))
	file.panels.append(Hud_GetChild(file.menu, "R5RNamePanel"))
	file.panels.append(Hud_GetChild(file.menu, "R5RDescPanel"))

	//Setup Default Server Config
	ServerSettings.svServerName = "My custom server"
	ServerSettings.svServerDesc = "A R5Reloaded server"
	ServerSettings.svMapName = "mp_rr_canyonlands_64k_x_64k"
	ServerSettings.svPlaylist = "survival_dev"
	ServerSettings.svVisibility = eServerVisibility.OFFLINE
}

void function OpenSelectedPanel( var button )
{
	//Show panel depending on script id
	ShowSelectedPanel( file.panels[Hud_GetScriptID( button ).tointeger()] )

	switch (Hud_GetScriptID( button ).tointeger())
    {
        case 0:
                PMMenusOpen.maps_open = true
            break;
        case 1:
                PMMenusOpen.playlists_open = true
            break;
        case 2:
                PMMenusOpen.vis_open = true
            break;
        case 3:
                PMMenusOpen.name_open = true
                Hud_SetText( Hud_GetChild( file.namepanel, "BtnServerName" ), ServerSettings.svServerName )
            break;
        case 4:
                PMMenusOpen.desc_open = true
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
	PMMenusOpen.maps_open = false

	//set map
	ServerSettings.svMapName = map

	//Set the panel to not visible
	Hud_SetVisible( file.panels[0], false )

	//Set the new map image
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset( ServerSettings.svMapName ) )
}

void function SetSelectedServerPlaylist( string playlist )
{
	PMMenusOpen.playlists_open = false

	//set playlist
	ServerSettings.svPlaylist = playlist

	//Get the maps of the new playlist
	array<string> playlist_maps = GetPlaylistMaps(ServerSettings.svPlaylist)
	
	//Set the panel to not visible
	Hud_SetVisible( file.panels[1], false )

	//Set the new playlist text
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), GetUIPlaylistName( ServerSettings.svPlaylist ) )

	//This should never really be triggered but here just incase
	if(playlist_maps.len() == 0) {
		SetSelectedServerMap("mp_rr_canyonlands_64k_x_64k")
		RefreshUIMaps()
		return
	}

	//Check to see if the current map is allowed on the new selected playlist
	if(!playlist_maps.contains(ServerSettings.svMapName))
		SetSelectedServerMap(playlist_maps[0])

	//Refresh Maps
	RefreshUIMaps()
}

void function SetSelectedServerVis( int vis )
{
	PMMenusOpen.vis_open = false

	//set visibility
	ServerSettings.svVisibility = vis

	//Set the panel to not visible
	Hud_SetVisible( file.panels[2], false )

	//Set the new visibility text
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), GetUIVisibilityName(ServerSettings.svVisibility))
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

void function OnCreateMatchOpen()
{
	RefreshUIPlaylists()
	RefreshUIMaps()

	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), GetUIPlaylistName(ServerSettings.svPlaylist))
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset( ServerSettings.svMapName ) )
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), GetUIVisibilityName(ServerSettings.svVisibility))
	Hud_SetText(Hud_GetChild( file.panel, "MapServerNameInfoEdit" ), ServerSettings.svServerName)
}

void function UpdateServerName( var button )
{
	PMMenusOpen.name_open = false

    ServerSettings.svServerName = Hud_GetUTF8Text( Hud_GetChild( file.namepanel, "BtnServerName" ) )

	Hud_SetVisible( file.namepanel, false )

	Hud_SetText(Hud_GetChild( file.panel, "MapServerNameInfoEdit" ), ServerSettings.svServerName)
}

void function UpdateServerDesc( var button )
{
	PMMenusOpen.desc_open = false

    ServerSettings.svServerDesc = Hud_GetUTF8Text( Hud_GetChild( file.descpanel, "BtnServerDesc" ) )

	Hud_SetVisible( file.descpanel, false )
}