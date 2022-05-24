global function InitR5RServerBrowserPanel

// arbitrary large number
global const SB_MAX_SERVER_COUNT = 999
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

global struct ServerInfo
{
	int ServerID = -1
	string ServerName = ""
	string Map = ""
	string Playlist = ""
}

global ServerInfo SelectedServerInfo

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, ServerBrowser_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, ServerBrowser_OnHide )

	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListRightArrow" ), UIE_CLICK, NextPage )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListLeftArrow" ), UIE_CLICK, PrevPage )

	array<var> serverbuttons = GetElementsByClassname( file.menu, "ServBtn" )

	foreach ( var elem in serverbuttons )
	{
		RuiSetString( Hud_GetRui( elem ), "buttonText", "")
		Hud_SetVisible(elem, false)
		Hud_AddEventHandler( elem, UIE_CLICK, SelectServer )
	}

	ResetServerLabels()
	thread RefreshServerListing()

	Hud_AddEventHandler( Hud_GetChild( file.panel, "ConnectButton" ), UIE_CLICK, ConnectToServer )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "ConnectButton" ) ), "buttonText", "Connect")
	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), file.Servers[0].Name)
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), file.Servers[0].Playlist)
}

void function ConnectToServer(var button)
{
	if(SelectedServerInfo.ServerID == -1)
		return

	//Connect Code Later
	printf("Debug (Server ID: " + SelectedServerInfo.ServerID + " | Server Name: " + SelectedServerInfo.ServerName + " | Map: " + SelectedServerInfo.Map + " | Playlist: " + SelectedServerInfo.Playlist + ")")
}

void function SelectServer(var button)
{
	int buttonid = Hud_GetScriptID( button ).tointeger()

	int finalid = buttonid + file.pageoffset

	SelectedServerInfo.ServerID = finalid
	SelectedServerInfo.ServerName = file.Servers[finalid].Name
	SelectedServerInfo.Map = file.Servers[finalid].Map
	SelectedServerInfo.Playlist = file.Servers[finalid].Playlist

	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), file.Servers[finalid].Name)
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), playlisttoname[file.Servers[finalid].Playlist])
	Hud_SetText(Hud_GetChild( file.panel, "ServerDesc" ), file.Servers[finalid].Desc)
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", maptoasset[file.Servers[finalid].Map] )
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
	// Clear table and servers
	file.buttonToServerID.clear()
	file.Servers.clear()

	//Get Servercount
	int serverCount = GetServerCount()

	int serverCount2 = 999999

	//Reset pages
	file.pages = 0

	int getpages = 0
	//Add each server to the array
	for( int i=0; i < serverCount2; i++ )
	{
		string servername = RandomServerName(RandomIntRange(0, 5))
		string playlistname = RandomPlaylistName(RandomIntRange(0, 4))
		string mapname = RandomMapName(RandomIntRange(0, 4))
		string desc = RandomDesc(RandomIntRange(0, 4))
		int maxplayers = 32
		int current = RandomIntRange(0, 32)
		AddServer(i, servername, playlistname, mapname, desc, maxplayers, current)

		if(getpages == SB_MAX_SERVER_PER_PAGE)
		{
			file.pages++
			getpages = 0
		}

		getpages++
	}

	Hud_SetText(Hud_GetChild( file.panel, "Pages" ), "Page: 0/" + file.pages)

	//Setup Buttons and labels/
	for( int i=0; i < file.Servers.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), file.Servers[i].Name)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), playlisttoname[file.Servers[i].Playlist])
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), maptoname[file.Servers[i].Map])
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

	if(file.currentpage == 0)
	{
		startint = 0
		endint = SB_MAX_SERVER_PER_PAGE
		file.pageoffset = 0
	}
	else
	{
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

string function RandomDesc(int rand)
{
	string servername

	switch(rand)
	{
		case 0:
			servername = "Some Cool Random Server Yo"
			break
		case 1:
			servername = "Join The Server Ok"
			break
		case 2:
			servername = "Ikd Man"
			break
		case 3:
			servername = "R5Reloaded Server For Cool People"
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