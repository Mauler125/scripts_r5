global function InitR5RServerBrowserPanel

// arbitrary large number
global const SB_MAX_SERVER_COUNT = 999
global const SB_MAX_SERVER_PAGES = 3

struct R5RServer
{
	int ServerID
	string Name
	string Playlist
	string Map
	int maxplayers
	int currentplayers
}

struct
{
	var menu
	var panel

	var listPanel

	table<var, int> buttonToServerID
	table<var, bool> buttonEventHandlersAdded

	array<R5RServer> Servers
	int pages
	int currentpage
	int pageoffset
} file

const table<string, asset> maptoasset = {
	[ "mp_rr_aqueduct" ] = $"rui/menu/maps/mp_rr_aqueduct",
	[ "mp_rr_canyonlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_canyonlands_64k_x_64k",
	[ "mp_rr_canyonlands_mu1" ] = $"rui/menu/maps/mp_rr_canyonlands_mu1",
	[ "mp_rr_desertlands_64k_x_64k" ] = $"rui/menu/maps/mp_rr_desertlands_64k_x_64k"
}

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, ServerBrowser_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, ServerBrowser_OnHide )

	Hud_AddEventHandler( Hud_GetChild( file.panel, "RightPageButton" ), UIE_CLICK, NextPage )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "LeftPageButton" ), UIE_CLICK, PrevPage )

	array<var> serverbuttons = GetElementsByClassname( file.menu, "ServBtn" )

	foreach ( var elem in serverbuttons )
	{
		RuiSetString( Hud_GetRui( elem ), "buttonText", "")
		Hud_SetVisible(elem, false)
		Hud_AddEventHandler( elem, UIE_CLICK, SelectServer )
	}

	ResetServerLabels()
	thread RefreshServerListing()

	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "ConnectButton" ) ), "buttonText", "Connect")
}

void function SelectServer(var button)
{
	int buttonid = Hud_GetScriptID( button ).tointeger()

	int finalid = buttonid + file.pageoffset

	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), file.Servers[finalid].Name)
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[file.Servers[finalid].Map] )
}

void function AddServer(int id, string name, string playlist, string map, int maxplayers, int currentplayers)
{
	R5RServer new
	new.ServerID = id
	new.Name = name
	new.Playlist = playlist
	new.Map = map
	new.maxplayers = maxplayers
	new.currentplayers = currentplayers

	file.Servers.append(new)
}

void function ResetServerLabels()
{
	array<var> serverbuttons = GetElementsByClassname( file.menu, "ServBtn" )
	foreach ( var elem in serverbuttons )
	{
		Hud_SetVisible(elem, false)
	}

	array<var> serverlabels = GetElementsByClassname( file.menu, "ServerLabels" )
	foreach ( var elem in serverlabels )
	{
		Hud_SetText(elem, "")
	}
}

void function RefreshServerListing()
{
	// Clear table and servers
	file.buttonToServerID.clear()
	file.Servers.clear()

	//Get Servercount
	int serverCount = GetServerCount()

	int serverCount2 = 72

	//Reset pages
	file.pages = 0

	//Add each server to the array
	for( int i=0; i < serverCount2; i++ )
	{
		string servername = RandomServerName(RandomIntRange(0, 5))
		string playlistname = RandomPlaylistName(RandomIntRange(0, 4))
		string mapname = RandomMapName(RandomIntRange(0, 4))
		int maxplayers = 32
		int current = RandomIntRange(0, 32)
		AddServer(i, servername, playlistname, mapname, maxplayers, current)
	}

	//Setup Pages ( can be expaned if more servers are needed )
	if (serverCount2 > 20)
		file.pages = 1
	if (serverCount2 > 40)
		file.pages = 2
	if (serverCount2 > 60)
		file.pages = 3

	//Setup Buttons and labels
	for( int i=0; i < file.Servers.len() && i < 20; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), file.Servers[i].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), file.Servers[i].Playlist)
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), file.Servers[i].Map)
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), file.Servers[i].currentplayers + "/" + file.Servers[i].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)
	}
}

void function NextPage(var button)
{
	ResetServerLabels()

	file.currentpage++

	if(file.currentpage > file.pages)
		file.currentpage = file.pages

	int startint
	int endint

	switch(file.currentpage)
	{
		case 0:
			startint = 0
			endint = 20
			file.pageoffset = 0
			break
		case 1:
			startint = 20
			endint = 40
			file.pageoffset = 20
			break
		case 2:
			startint = 40
			endint = 60
			file.pageoffset = 40
			break
		case 3:
			startint = 60
			endint = 80
			file.pageoffset = 60
			break
	}

	if(endint > file.Servers.len())
		endint = file.Servers.len()

	int id = 0
	for( int i=startint; i < endint; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), file.Servers[startint].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), file.Servers[startint].Playlist)
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), file.Servers[startint].Map)
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), file.Servers[startint].currentplayers + "/" + file.Servers[startint].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		startint++
		id++
	}
}

void function PrevPage(var button)
{
	ResetServerLabels()

	file.currentpage--

	if(file.currentpage < 0)
		file.currentpage = 0

	int startint
	int endint

	switch(file.currentpage)
	{
		case 0:
			startint = 0
			endint = 20
			file.pageoffset = 0
			break
		case 1:
			startint = 20
			endint = 40
			file.pageoffset = 20
			break
		case 2:
			startint = 40
			endint = 60
			file.pageoffset = 40
			break
		case 3:
			startint = 60
			endint = 80
			file.pageoffset = 60
			break
	}

	if(endint > file.Servers.len())
		endint = file.Servers.len()

	int id = 0
	for( int i=startint; i < endint; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), file.Servers[startint].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), file.Servers[startint].Playlist)
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), file.Servers[startint].Map)
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), file.Servers[startint].currentplayers + "/" + file.Servers[startint].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		startint++
		id++
	}
}

string function RandomMapName(int rand)
{
	string servername

	switch(rand)
	{
		case 0:
			servername = "mp_rr_aqueduct"
			break
		case 1:
			servername = "mp_rr_canyonlands_64k_x_64k"
			break
		case 2:
			servername = "mp_rr_canyonlands_mu1"
			break
		case 3:
			servername = "mp_rr_desertlands_64k_x_64k"
			break
	}

	return servername
}

string function RandomPlaylistName(int rand)
{
	string servername

	switch(rand)
	{
		case 0:
			servername = "custom_tdm"
			break
		case 1:
			servername = "custom_ctf"
			break
		case 2:
			servername = "tdm_gg"
			break
		case 3:
			servername = "tdm_gg_double"
			break
	}

	return servername
}

string function RandomServerName(int rand)
{
	string servername

	switch(rand)
	{
		case 0:
			servername = "Super Random Server"
			break
		case 1:
			servername = "Apex Server Duh"
			break
		case 2:
			servername = "Wraiths Wingman Only"
			break
		case 3:
			servername = "Gibby Dance Party Come Have Fun"
			break
		case 4:
			servername = "Idk Some Server Name"
			break
	}

	return servername
}

void function ServerBrowser_OnShow( var panel )
{

}

void function ServerBrowser_OnHide( var panel )
{
	
}