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

struct ServerInfo
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

ServerInfo SelectedServerInfo

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Setup Page Nav Buttons
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListRightArrow" ), UIE_CLICK, NextPage )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListLeftArrow" ), UIE_CLICK, PrevPage )
	//Setup Connect Button
	Hud_AddEventHandler( Hud_GetChild( file.panel, "ConnectButton" ), UIE_CLICK, ConnectToServer )
	//Setup Refresh Button
	Hud_AddEventHandler( Hud_GetChild( file.panel, "RefreshServers" ), UIE_CLICK, RefreshServersClick )

	//Add event handlers for the server buttons
	//Clear buttontext
	//No need to remove them as they are hidden if not in use
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

void function RefreshServersClick(var button)
{
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
	//Set ui for selected server
	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), servername )
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlistname )
	Hud_SetText(Hud_GetChild( file.panel, "ServerDesc" ), desc )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", map )
}

void function SetSelectedServer(int id, string name, string map, string playlist)
{
	//Set selected server info
	SelectedServerInfo.ServerID = id
	SelectedServerInfo.ServerName = name
	SelectedServerInfo.Map = map
	SelectedServerInfo.Playlist = playlist
}

void function SelectServer(var button)
{
	//Get the button id and add it to the pageoffset to get the correct server id
	int finalid = Hud_GetScriptID( button ).tointeger() + file.pageoffset

	SetSelectedServer(finalid, file.Servers[finalid].Name, file.Servers[finalid].Map, file.Servers[finalid].Playlist)
	SetSideBarElems(file.Servers[finalid].Name, GetUIPlaylistName(file.Servers[finalid].Playlist), file.Servers[finalid].Desc, GetUIMapAsset(file.Servers[finalid].Map))
}

void function AddServer(int id, string name, string playlist, string map, string desc, int maxplayers, int currentplayers)
{
	//Setup new server
	R5RServer new
	new.ServerID = id
	new.Name = name
	new.Playlist = playlist
	new.Map = map
	new.Desc = desc
	new.maxplayers = maxplayers
	new.currentplayers = currentplayers

	//Add it to the array
	file.Servers.append(new)
}

void function ResetServerLabels()
{
	//Hide all server buttons
	array<var> serverbuttons = GetElementsByClassname( file.menu, "ServBtn" )
	foreach ( var elem in serverbuttons )
	{
		Hud_SetVisible(elem, false)
	}

	//Clear all server labels
	array<var> serverlabels = GetElementsByClassname( file.menu, "ServerLabels" )
	foreach ( var elem in serverlabels )
	{
		Hud_SetText(elem, "")
	}
}

void function RefreshServerListing()
{
	// Hide no servers found ui
	ShowNoServersFound(false)

	// Clear table and servers
	file.Servers.clear()

	// Reset pages
	file.pages = 0

	// For getting total players on all server
	int serverrow = 0

	// Add each server to the array
	for( int i=0; i < GetServerCount(); i++ )
	{
		// Descption and player count will come at a later date
		thread AddServer(i, GetServerName(i), GetServerPlaylist(i), GetServerMap(i), "Server description coming soon.", 32, 0)

		// If server is on final row add a new page
		if(serverrow == SB_MAX_SERVER_PER_PAGE)
		{
			file.pages++
			serverrow = 0
		}
		serverrow++
	}

	// Setup Buttons and labels
	for( int i=0; i < file.Servers.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), file.Servers[i].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), GetUIPlaylistName(file.Servers[i].Playlist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), GetUIMapName(file.Servers[i].Map))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), file.Servers[i].currentplayers + "/" + file.Servers[i].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)
	}

	if(file.Servers.len() > 0) {
		// Select first server in the list
		SetSelectedServer(0, file.Servers[0].Name, file.Servers[0].Map, file.Servers[0].Playlist)
		SetSideBarElems(file.Servers[0].Name, GetUIPlaylistName(file.Servers[0].Playlist), file.Servers[0].Desc, GetUIMapAsset(file.Servers[0].Map))
	} else {
		// Show no servers found ui
		ShowNoServersFound(true)
		SetSelectedServer(-1, "", "", "")
		SetSideBarElems("", "", "", $"")
	}

	// Set UI Labels
	Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: " + GetTotalPlayersAllServers())
	Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: " + GetServerCount())
	Hud_SetText (Hud_GetChild( file.panel, "Pages" ), "Page: 1/" + (file.pages + 1))
}

void function ShowNoServersFound(bool show)
{
	// Todo: Add No Servers Found UI
}

void function NextPage(var button)
{
	//If Pages is 0 then return
	//or if is on the last page
	if(file.pages == 0 || file.currentpage == file.pages )
		return

	// Reset Server Labels
	ResetServerLabels()

	// Set current page to next page
	file.currentpage++

	// If current page is greater then last page set to last page
	if(file.currentpage > file.pages)
		file.currentpage = file.pages

	// "startint" = starting server id
	int startint
	// "endint" = ending server id
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

	// Check if endint is greater then actual amount of servers
	if(endint > file.Servers.len())
		endint = file.Servers.len()

	// Set current page ui
	Hud_SetText(Hud_GetChild( file.panel, "Pages" ), "Page: " + (file.currentpage + 1) + "/" + (file.pages + 1))

	// "id" is diffrent from page offset
	// "id" is used for setting UI elements
	// "i" is used for server id
	int id = 0
	for( int i=startint; i < endint; i++ ) {
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), file.Servers[i].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), GetUIPlaylistName(file.Servers[i].Playlist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), GetUIMapName(file.Servers[i].Map))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), file.Servers[i].currentplayers + "/" + file.Servers[i].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		id++
	}
}

void function PrevPage(var button)
{
	//If Pages is 0 then return
	//or if is one the first page
	if(file.pages == 0 || file.currentpage == 0)
		return

	// Reset Server Labels
	ResetServerLabels()

	// Set current page to prev page
	file.currentpage--

	// If current page is less then first page set to first page
	if(file.currentpage < 0)
		file.currentpage = 0

	// "startint" = starting server id
	int startint
	// "endint" = ending server id
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

	// Check if endint is greater then actual amount of servers
	if(endint > file.Servers.len())
		endint = file.Servers.len()

	// Set current page ui
	Hud_SetText(Hud_GetChild( file.panel, "Pages" ), "Page: " + (file.currentpage + 1) + "/" + (file.pages + 1))

	// "id" is diffrent from page offset
	// "id" is used for setting UI elements
	// "i" is used for server id
	int id = 0
	for( int i=startint; i < endint; i++ ) {
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), file.Servers[i].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), GetUIPlaylistName(file.Servers[i].Playlist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), GetUIMapName(file.Servers[i].Map))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), file.Servers[i].currentplayers + "/" + file.Servers[i].maxplayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		id++
	}
}