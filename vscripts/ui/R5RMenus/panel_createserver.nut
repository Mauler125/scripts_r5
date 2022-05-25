global function InitR5RCreateServerPanel

global function SetSelectedServerMap
global function SetSelectedServerPlaylist
global function SetSelectedServerVis

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

	//Setup EventHandlers
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnStartGame" ), UIE_CLICK, StartNewGame )

	array<var> buttons = GetElementsByClassname( file.menu, "createserverbuttons" )
	foreach ( var elem in buttons )
	{
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

	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname[NewServer.playlist])
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[NewServer.map] )
	Hud_SetText(Hud_GetChild( file.panel, "VisInfoEdit" ), vistoname[NewServer.vis])
}

void function OpenSelectedPanel( var button )
{
	int scriptid = Hud_GetScriptID( button ).tointeger()
	ShowSelectedPanel( file.panels[scriptid] )
}

void function StartNewGame( var button )
{
	CreateServer(NewServer.name, NewServer.map, NewServer.playlist, NewServer.vis)
}

void function SetSelectedServerMap( string map )
{
	NewServer.map = map
	Hud_SetVisible( file.panels[0], false )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[map] )
}

void function SetSelectedServerPlaylist( string playlist )
{
	NewServer.playlist = playlist
	Hud_SetVisible( file.panels[1], false )
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname[playlist])
}

void function SetSelectedServerVis( int vis )
{
	NewServer.vis = vis
	Hud_SetVisible( file.panels[2], false )
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