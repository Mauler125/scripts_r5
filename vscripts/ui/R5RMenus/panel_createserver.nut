global function InitR5RCreateServerPanel

global function SetSelectedServerMap
global function SetSelectedServerPlaylist
global function SetSelectedServerVis
global function HideAllCreateServerPanels

struct
{
	var menu
	var panel

	array<var> panels
} file

struct
{
	string name
	string map
	string playlist
	int vis
} NewServer

void function InitR5RCreateServerPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Setup Button EventHandlers
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )
	AddButtonEventHandler( Hud_GetChild( file.panel, "BtnServerName"), UIE_CHANGE, UpdateServerName )
	array<var> buttons = GetElementsByClassname( file.menu, "createserverbuttons" )
	foreach ( var elem in buttons ) {
		Hud_AddEventHandler( elem, UIE_CLICK, OpenSelectedPanel )
	}

	//Setup panel array
	file.panels.append(Hud_GetChild(file.panel, "R5RMapPanel"))
	file.panels.append(Hud_GetChild(file.panel, "R5RPlaylistPanel"))
	file.panels.append(Hud_GetChild(file.panel, "R5RVisPanel"))

	//Setup Default Server Config
	NewServer.name = "R5Reloaded Server"
	NewServer.map = "mp_rr_aqueduct"
	NewServer.playlist = "custom_tdm"
	NewServer.vis = eServerVisibility.OFFLINE

	//Set selected ui
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname[NewServer.playlist])
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[NewServer.map] )
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), vistoname[NewServer.vis])
	Hud_SetText( Hud_GetChild( file.panel, "BtnServerName" ), "A R5Reloaded Server" )
}

void function OpenSelectedPanel( var button )
{
	int scriptid = Hud_GetScriptID( button ).tointeger()
	ShowSelectedPanel( file.panels[scriptid] )
}

void function StartNewGame( var button )
{
	//Start new server with selected options
	CreateServer(NewServer.name, NewServer.map, NewServer.playlist, NewServer.vis)
}

void function SetSelectedServerMap( string map )
{
	//set map
	NewServer.map = map

	//Get map asset
	asset mapasset = $"rui/menu/maps/map_not_found"
	try {
		//if mapname is in tabel then get the correct asset from it
		mapasset = maptoasset[map]
	} catch(e1) { }
	//Set the panel to not visible
	Hud_SetVisible( file.panels[0], false )

	//Set the new map image
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", mapasset )
}

void function SetSelectedServerPlaylist( string playlist )
{
	//set playlist
	NewServer.playlist = playlist

	//Get playlist name
	string playlistname = playlist
	try {
		//if mapname is in tabel then get the correct asset from it
		playlistname = playlisttoname[playlist]
	} catch(e1) { }

	//Set the panel to not visible
	Hud_SetVisible( file.panels[1], false )

	//Set the new playlist text
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlistname)
}

void function SetSelectedServerVis( int vis )
{
	//set visibility
	NewServer.vis = vis

	//Set the panel to not visible
	Hud_SetVisible( file.panels[2], false )

	//Set the new visibility text
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), vistoname[vis])
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

void function HideAllCreateServerPanels()
{
	//Hide all panels
	foreach ( p in file.panels ) {
		Hud_SetVisible( p, false )
	}
}

void function UpdateServerName( var button )
{
    //Update the servername when the text is changed
    NewServer.name = Hud_GetUTF8Text( Hud_GetChild( file.menu, "BtnServerName" ) )
}