global function InitR5RServerBrowserPanel
global function RefreshServerListing

global const SB_MAX_SERVER_PER_PAGE = 19

struct R5RServer
{
	int ServerID
	string Name
	string Playlist
	string Map
	string Desc
	int maxplayers
	int currentplayers
}

global struct ServerInfo
{
	int ServerID = -1
	string ServerName = ""
	string Map = ""
	string Playlist = ""
}

struct
{
	var menu
	var panel

	array<R5RServer> Servers

	int pages
	int currentpage
	int pageoffset
} file

global ServerInfo SelectedServerInfo

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, ServerBrowser_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, ServerBrowser_OnHide )

	//Setup Page Nav Buttons
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListRightArrow" ), UIE_CLICK, NextPage )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListLeftArrow" ), UIE_CLICK, PrevPage )
	//Setup Connect Button
	Hud_AddEventHandler( Hud_GetChild( file.panel, "ConnectButton" ), UIE_CLICK, ConnectToServer )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "ConnectButton" ) ), "buttonText", "Connect")

	array<var> serverbuttons = GetElementsByClassname( file.menu, "ServBtn" )
	foreach ( var elem in serverbuttons )
	{
		RuiSetString( Hud_GetRui( elem ), "buttonText", "")
		Hud_AddEventHandler( elem, UIE_CLICK, SelectServer )
	}

	//Clear Server List Text
	ResetServerLabels()

	//Refresh Server Browser
	thread RefreshServerListing()
}

void function ConnectToServer(var button)
{
	//If server isnt selected return
	if(SelectedServerInfo.ServerID == -1)
		return

	//Connect to server
	thread StartServerConnection()
	printf("Debug (Server ID: " + SelectedServerInfo.ServerID + " | Server Name: " + SelectedServerInfo.ServerName + " | Map: " + SelectedServerInfo.Map + " | Playlist: " + SelectedServerInfo.Playlist + ")")
}

void function StartServerConnection()
{
	//Currently crashes due to being in lobby, waiting on Amos to fix
	//SetEncKeyAndConnect(SelectedServerInfo.ServerID)
}

void function SetSideBarElems(string servername, string playlistname, string desc, asset map)
{
	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), servername )
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlistname )
	Hud_SetText(Hud_GetChild( file.panel, "ServerDesc" ), desc )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", map )
}

void function SetSelectedServer(int id, string name, string map, string playlist)
{
	SelectedServerInfo.ServerID = id
	SelectedServerInfo.ServerName = name
	SelectedServerInfo.Map = map
	SelectedServerInfo.Playlist = playlist
}

string function GetUIPlaylistName(string playlist)
{
	string finalplaylistname = playlist

	try{
		//If playlist is in table use better playlistname
		finalplaylistname = playlisttoname[playlist]
	} catch(e1) {}

	return finalplaylistname
}

string function GetUIMapName(string map)
{
	string mapname = map

	try{
		mapname = maptoname[map]
	} catch(e2) {}

	return mapname
}

void function SelectServer(var button)
{
	int buttonid = Hud_GetScriptID( button ).tointeger()
	int finalid = buttonid + file.pageoffset
	string playlistname = GetUIPlaylistName(file.Servers[finalid].Playlist)

	SetSelectedServer(finalid, file.Servers[finalid].Name, file.Servers[finalid].Map, file.Servers[finalid].Playlist)

	asset mapimg
	try{
		mapimg = maptoasset[file.Servers[finalid].Map]
	} catch(e0) {
		mapimg = $"rui/menu/maps/map_not_found"
	}

	SetSideBarElems(file.Servers[finalid].Name, playlistname, file.Servers[finalid].Desc, mapimg)
}

void function AddServer(int id, string name, string playlist, string map, string desc, int maxplayers, int currentplayers)
{
	R5RServer new
	new.ServerID = id
	new.Name = name
	new.Playlist = playlist
	new.Map = map
	new.Desc = desc
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
	//Hide no servers found ui
	ShowNoServersFound(false)

	// Clear table and servers
	file.Servers.clear()

	//Get Servercount
	int serverCount = GetServerCount()

	//Reset pages
	file.pages = 0

	int getpages = 0
	//Add each server to the array
	for( int i=0; i < serverCount; i++ )
	{
		string servername = GetServerName(i)
		string playlistname = GetServerPlaylist(i)
		string mapname = GetServerMap(i)

		//Descption and player count will come at a later date
		string desc = "Server description coming soon."
		int maxplayers = 0
		int current = 0
		//

		thread AddServer(i, servername, playlistname, mapname, desc, maxplayers, current)

		if(getpages == SB_MAX_SERVER_PER_PAGE)
		{
			file.pages++
			getpages = 0
		}

		getpages++
	}

	//Setup Buttons and labels
	for( int i=0; i < file.Servers.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		string mapname = GetUIMapName(file.Servers[i].Map)
		string playlistname = GetUIPlaylistName(file.Servers[i].Playlist)

		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), file.Servers[i].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), playlistname)
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), mapname)
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), file.Servers[i].currentplayers + "/" + file.Servers[i].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)
	}

	Hud_SetText(Hud_GetChild( file.panel, "Pages" ), "Page: 0/" + file.pages)

	if(file.Servers.len() > 0) {
		string playlistname = GetUIPlaylistName(file.Servers[0].Playlist)
		SetSelectedServer(0, file.Servers[0].Name, file.Servers[0].Map, file.Servers[0].Playlist)
		SetSideBarElems(file.Servers[0].Name, playlistname, file.Servers[0].Desc, maptoasset[file.Servers[0].Map])
	} else {
		//Show no servers found ui
		ShowNoServersFound(true)
		SetSelectedServer(-1, "", "", "")
		SetSideBarElems("", "", "", $"")
	}
}

void function ShowNoServersFound(bool show)
{
	//Todo: Add No Servers UI
}

void function NextPage(var button)
{
	if(file.pages == 0)
		return

	ResetServerLabels()

	file.currentpage++

	if(file.currentpage > file.pages)
		file.currentpage = file.pages

	int startint
	int endint

	if(file.currentpage == 0){
		startint = 0
		endint = SB_MAX_SERVER_PER_PAGE
		file.pageoffset = 0
	} else {
		startint = file.currentpage * SB_MAX_SERVER_PER_PAGE
		endint = startint + SB_MAX_SERVER_PER_PAGE
		file.pageoffset = file.currentpage * SB_MAX_SERVER_PER_PAGE
	}

	if(endint > file.Servers.len())
		endint = file.Servers.len()

	Hud_SetText(Hud_GetChild( file.panel, "Pages" ), "Page: " + file.currentpage + "/" + file.pages)

	int id = 0
	for( int i=startint; i < endint; i++ )
	{
		string mapname = GetUIMapName(file.Servers[startint].Map)
		string playlistname = GetUIPlaylistName(file.Servers[startint].Playlist)

		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), file.Servers[startint].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), playlistname)
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), mapname)
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), file.Servers[startint].currentplayers + "/" + file.Servers[startint].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		startint++
		id++
	}
}

void function PrevPage(var button)
{
	if(file.pages == 0)
		return

	ResetServerLabels()

	file.currentpage--

	if(file.currentpage < 0)
		file.currentpage = 0

	int startint
	int endint

	if(file.currentpage == 0) {
		startint = 0
		endint = SB_MAX_SERVER_PER_PAGE
		file.pageoffset = 0
	} else {
		startint = file.currentpage * SB_MAX_SERVER_PER_PAGE
		endint = startint + SB_MAX_SERVER_PER_PAGE
		file.pageoffset = file.currentpage * SB_MAX_SERVER_PER_PAGE
	}

	if(endint > file.Servers.len())
		endint = file.Servers.len()

	Hud_SetText(Hud_GetChild( file.panel, "Pages" ), "Page: " + file.currentpage + "/" + file.pages)

	int id = 0
	for( int i=startint; i < endint; i++ )
	{
		string mapname = GetUIMapName(file.Servers[startint].Map)
		string playlistname = GetUIPlaylistName(file.Servers[startint].Playlist)

		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), file.Servers[startint].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), playlistname)
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), mapname)
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), file.Servers[startint].currentplayers + "/" + file.Servers[startint].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		startint++
		id++
	}
}

void function ServerBrowser_OnShow( var panel )
{

}

void function ServerBrowser_OnHide( var panel )
{
	
}