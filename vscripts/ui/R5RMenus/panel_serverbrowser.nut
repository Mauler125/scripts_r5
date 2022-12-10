untyped
// Only way to get Hud_GetPos(sliderButton) working was to use untyped

global function InitR5RServerBrowserPanel
global function InitR5RConnectingPanel

global function ServerBrowser_RefreshServerListing
global function RegisterServerBrowserButtonPressedCallbacks
global function UnRegisterServerBrowserButtonPressedCallbacks
global function ServerBrowser_UpdateFilterLists

//Used for max items for page
//Changing this requires a bit of work to get more to show correctly
//So keep at 19
const SB_MAX_SERVER_PER_PAGE = 15

// Stores mouse delta used for scroll bar
struct {
	int deltaX = 0
	int deltaY = 0
} mouseDeltaBuffer

struct
{
	int Offset = 0
	int Start = 0
	int End = 0
} m_vScroll

//Struct for selected server
struct SelectedServerInfo
{
	int svServerID = -1
	string svServerName = ""
	string svMapName = ""
	string svPlaylist = ""
	string svDescription
}

//Struct for server listing
struct ServerListing
{
	int	svServerID
	string svServerName
	string svMapName
	string svPlaylist
	string svDescription
	int svMaxPlayers
	int svCurrentPlayers
}

struct {
	bool hideEmpty = false
	bool useSearch = false
	string searchTerm
	array<string> filterMaps
	string filterMap = "Any"
	array<string> filterGamemodes
	string filterGamemode = "Any"
} filterArguments

struct
{
	var menu
	var panel
	var connectingpanel

	bool IsFiltered = false

	int m_vAllPlayers
	int m_vAllServers

	SelectedServerInfo m_vSelectedServer
	array<ServerListing> m_vServerList
	array<ServerListing> m_vFilteredServerList
} file

void function InitR5RConnectingPanel( var panel )
{
	file.connectingpanel = panel
}

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddMouseMovementCaptureHandler( Hud_GetChild(file.panel, "MouseMovementCapture"), UpdateMouseDeltaBuffer )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "ConnectButton" ), UIE_CLICK, ServerBrowser_ConnectBtnClicked )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "RefreshServers" ), UIE_CLICK, ServerBrowser_RefreshBtnClicked )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "ClearFliters" ), UIE_CLICK, FilterServer_Activate )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListDownArrow" ), UIE_CLICK, OnScrollDown )
	Hud_AddEventHandler( Hud_GetChild( file.panel, "BtnServerListUpArrow" ), UIE_CLICK, OnScrollUp )
	AddButtonEventHandler( Hud_GetChild( file.panel, "BtnServerSearch"), UIE_CHANGE, ServerBrowser_FilterTextChanged )

	Hud_AddEventHandler( Hud_GetChild( Hud_GetChild( file.panel, "SwtBtnHideEmpty" ), "LeftButton" ), UIE_CLICK, FilterServer_Activate )
	Hud_AddEventHandler( Hud_GetChild( Hud_GetChild( file.panel, "SwtBtnHideEmpty" ), "RightButton" ), UIE_CLICK, FilterServer_Activate )
	Hud_AddEventHandler( Hud_GetChild( Hud_GetChild( file.panel, "SwtBtnSelectGamemode" ), "LeftButton" ), UIE_CLICK, FilterServer_Activate )
	Hud_AddEventHandler( Hud_GetChild( Hud_GetChild( file.panel, "SwtBtnSelectGamemode" ), "RightButton" ), UIE_CLICK, FilterServer_Activate )
	Hud_AddEventHandler( Hud_GetChild( Hud_GetChild( file.panel, "SwtBtnSelectMap" ), "LeftButton" ), UIE_CLICK, FilterServer_Activate )
	Hud_AddEventHandler( Hud_GetChild( Hud_GetChild( file.panel, "SwtBtnSelectMap" ), "RightButton" ), UIE_CLICK, FilterServer_Activate )

	//Add event handlers for the server buttons
	//Clear buttontext
	//No need to remove them as they are hidden if not in use
	array<var> serverbuttons = GetElementsByClassname( file.menu, "ServBtn" )
	foreach ( var elem in serverbuttons ) {
		RuiSetString( Hud_GetRui( elem ), "buttonText", "")
		Hud_AddEventHandler( elem, UIE_CLICK, ServerBrowser_ServerBtnClicked )
		Hud_AddEventHandler( elem, UIE_DOUBLECLICK, ServerBrowser_ServerBtnDoubleClicked )
	}

	//Reset Server Panel
	ServerBrowser_NoServers(false)
	ServerBrowser_SelectServer(-1)
	ServerBrowser_ResetLabels()

	file.m_vSelectedServer.svServerID = -1
	file.m_vSelectedServer.svServerName = "Please select a server from the list"
	file.m_vSelectedServer.svMapName = "error"
	file.m_vSelectedServer.svPlaylist = "error"
	file.m_vSelectedServer.svDescription = ""
	ServerBrowser_UpdateSelectedServerUI()
	ServerBrowser_UpdateServerPlayerCount()

	ServerBrowser_UpdateFilterLists()
	OnBtnFiltersClear()
}

void function RegisterServerBrowserButtonPressedCallbacks()
{
	RegisterButtonPressedCallback( MOUSE_WHEEL_UP , OnScrollUp )
	RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN , OnScrollDown )
}

void function UnRegisterServerBrowserButtonPressedCallbacks()
{
	DeregisterButtonPressedCallback( MOUSE_WHEEL_UP , OnScrollUp )
	DeregisterButtonPressedCallback( MOUSE_WHEEL_DOWN , OnScrollDown )
}

void function ServerBrowser_UpdateFilterLists()
{
	if(!IsLobby())
		return

	if(Hud_GetDialogListItemCount(Hud_GetChild( file.panel, "SwtBtnSelectMap" )) == 0)
	{
		array<string> maps = ["Any"]
		maps.extend(GetAvailableMaps())
		filterArguments.filterMaps = maps
		int id = 0
		foreach ( string map in maps )
		{
			Hud_DialogList_AddListItem( Hud_GetChild( file.panel, "SwtBtnSelectMap" ) , map, string( id ) )
			id++
		}
	}

	if(Hud_GetDialogListItemCount(Hud_GetChild( file.panel, "SwtBtnSelectGamemode" )) == 0)
	{
		array<string> playlists = ["Any"]
		playlists.extend(GetVisiblePlaylists())
		filterArguments.filterGamemodes = playlists
		int id = 0
		foreach( string mode in playlists )
		{
			Hud_DialogList_AddListItem( Hud_GetChild( file.panel, "SwtBtnSelectGamemode" ) , mode, string( id ) )
			id++
		}
	}
}

array<string> function GetVisiblePlaylists()
{
	array<string> m_vPlaylists

	//Setup available playlists array
	foreach( string playlist in GetAvailablePlaylists())
	{
		//Check playlist visibility
		if(!GetPlaylistVarBool( playlist, "visible", false ))
			continue

		//Add playlist to the array
		m_vPlaylists.append(playlist)
	}

	return m_vPlaylists
}

void function OnBtnFiltersClear()
{
	Hud_SetText( Hud_GetChild( file.panel, "BtnServerSearch" ), "" )
	filterArguments.useSearch = false
	filterArguments.searchTerm = ""
	filterArguments.filterGamemode = "Any"
	filterArguments.filterMap = "Any"
	filterArguments.hideEmpty = false

	SetConVarBool( "grx_hasUnknownItems", false )
	SetConVarInt( "match_rankedSwitchETA", 0 )
	SetConVarInt( "match_rankedMaxPing", 0 )
}

////////////////////////////////////
//
//		Button Functions
//
////////////////////////////////////

void function FilterServer_Activate(var button)
{
	OnBtnFiltersClear()
	thread ServerBrowser_FilterServerList()
}

void function ServerBrowser_RefreshBtnClicked(var button)
{
	ServerBrowser_RefreshServerListing()

	string filter = Hud_GetUTF8Text( Hud_GetChild( file.panel, "BtnServerSearch" ) )
	if(filter != "") {
		filterArguments.useSearch = true
		thread ServerBrowser_FilterServerList()
	}
}

void function ServerBrowser_FilterTextChanged( var button )
{
	string filter = Hud_GetUTF8Text( Hud_GetChild( file.panel, "BtnServerSearch" ) )

	if(filter != "")
		filterArguments.useSearch = true
	else
		filterArguments.useSearch = false

	filterArguments.searchTerm = filter
	thread ServerBrowser_FilterServerList()
}

void function ServerBrowser_ConnectBtnClicked(var button)
{
	//If server isnt selected return
	if(file.m_vSelectedServer.svServerID == -1)
		return

	//Connect to server
	printf("Connecting to server: (Server ID: " + file.m_vSelectedServer.svServerID + " | Server Name: " + file.m_vSelectedServer.svServerName + " | Map: " + file.m_vSelectedServer.svMapName + " | Playlist: " + file.m_vSelectedServer.svPlaylist + ")")
	thread ServerBrowser_StartConnection(file.m_vSelectedServer.svServerID)
}

void function ServerBrowser_ServerBtnClicked(var button)
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()
	//Get the button id and add it to the scroll offset to get the correct server id
	int id = Hud_GetScriptID( button ).tointeger() + m_vScroll.Offset

	ServerBrowser_SelectServer(PageServerList[id].svServerID)
}

void function ServerBrowser_ServerBtnDoubleClicked(var button)
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()
	//Get the button id and add it to the scroll offset to get the correct server id
	int id = Hud_GetScriptID( button ).tointeger() + m_vScroll.Offset

	ServerBrowser_SelectServer(PageServerList[id].svServerID)

	thread ServerBrowser_StartConnection(id)
}

////////////////////////////////////
//
//		General Functions
//
////////////////////////////////////

void function ServerBrowser_FilterServerList()
{
	if(!IsLobby())
		return

	wait 0.1

	filterArguments.hideEmpty = GetConVarBool( "grx_hasUnknownItems" )
	filterArguments.filterMap = filterArguments.filterMaps[GetConVarInt( "match_rankedMaxPing" )]
	filterArguments.filterGamemode = filterArguments.filterGamemodes[GetConVarInt( "match_rankedSwitchETA" )]

	file.m_vFilteredServerList.clear()

	for ( int i = 0; i < file.m_vServerList.len(); i++ )
	{
		// Filters
		if ( filterArguments.hideEmpty && file.m_vServerList[i].svCurrentPlayers == 0 )
			continue;

		if ( filterArguments.filterMap != "Any" && filterArguments.filterMap != file.m_vServerList[i].svMapName )
			continue;

		if ( filterArguments.filterGamemode != "Any" && filterArguments.filterGamemode != file.m_vServerList[i].svPlaylist )
			continue;
		
		// Search
		if ( filterArguments.useSearch )
		{	
			array<string> sName
			sName.append( file.m_vServerList[i].svServerName.tolower() )
			sName.append( file.m_vServerList[i].svMapName.tolower() )
			sName.append( GetUIMapName(file.m_vServerList[i].svMapName).tolower() )
			sName.append( file.m_vServerList[i].svPlaylist.tolower() )
			sName.append( GetUIPlaylistName(file.m_vServerList[i].svPlaylist).tolower() )

			string sTerm = filterArguments.searchTerm.tolower()
			
			bool found = false
			for( int j = 0; j < sName.len(); j++ )
			{
				if ( sName[j].find( sTerm ) >= 0 )
					found = true
			}
			
			if ( !found )
				continue;
		}
		
		// Server fits our requirements, add it to the list
		file.m_vFilteredServerList.append(file.m_vServerList[i])
	}

	UpdateListSliderHeight( float( file.m_vFilteredServerList.len() ) )
	UpdateListSliderPosition( file.m_vFilteredServerList.len() )

	//Clear Server List Text, Hide no servers found ui, Reset pages
	ServerBrowser_ResetLabels()
	ServerBrowser_NoServers(false)
	m_vScroll.Offset = 0

	// Get Server Count
	int svServerCount = file.m_vFilteredServerList.len()

	// If no servers then set no servers found ui and return
	if(svServerCount == 0) {
		ServerBrowser_NoServers(true)
		ServerBrowser_SelectServer(-1)
		Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: 0")
		Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: 0")
		return
	}

	// Setup Buttons and labels
	for( int i=0; i < file.m_vFilteredServerList.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), file.m_vFilteredServerList[i].svServerName)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), GetUIPlaylistName(file.m_vFilteredServerList[i].svPlaylist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), GetUIMapName(file.m_vFilteredServerList[i].svMapName))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), file.m_vFilteredServerList[i].svCurrentPlayers + "/" + file.m_vFilteredServerList[i].svMaxPlayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)
	}

	// Select first server in the list
	ServerBrowser_SelectServer(file.m_vFilteredServerList[0].svServerID)
}

void function ServerBrowser_RefreshServerListing(bool refresh = true)
{
	if (refresh)
		RefreshServerList()

	//Clear Server List Text, Hide no servers found ui
	ServerBrowser_ResetLabels()
	ServerBrowser_NoServers(false)
	file.m_vAllPlayers = 0
	file.m_vAllServers = 0
	m_vScroll.Offset = 0

	// Get Server Count
	file.m_vAllServers = GetServerCount()
	if(file.m_vAllServers == 0) {
		ServerBrowser_NoServers(true)
		ServerBrowser_SelectServer(-1)
		Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: 0")
		Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: 0")
		return
	}

	// Get Server Array
	file.m_vServerList = ServerBrowser_GetArray(file.m_vAllServers)
	UpdateListSliderHeight( float( file.m_vServerList.len() ) )
	UpdateListSliderPosition( file.m_vServerList.len() )

	// Setup Buttons and labels
	for( int i=0; i < file.m_vServerList.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), file.m_vServerList[i].svServerName)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), GetUIPlaylistName(file.m_vServerList[i].svPlaylist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), GetUIMapName(file.m_vServerList[i].svMapName))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), file.m_vServerList[i].svCurrentPlayers + "/" + file.m_vServerList[i].svMaxPlayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)

		file.m_vAllPlayers += file.m_vServerList[i].svCurrentPlayers
	}

	// Select first server in the list
	ServerBrowser_SelectServer(file.m_vServerList[0].svServerID)
	ServerBrowser_UpdateServerPlayerCount()

	ServerBrowser_UpdateFilterLists()
	OnBtnFiltersClear()
	thread ServerBrowser_FilterServerList()
}

//Used scroll code from northstar.
void function OnScrollDown( var button )
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()

	m_vScroll.Offset += 1
	if (m_vScroll.Offset + SB_MAX_SERVER_PER_PAGE > PageServerList.len()) {
		m_vScroll.Offset = PageServerList.len() - SB_MAX_SERVER_PER_PAGE
	}

	if ( m_vScroll.Offset < 0 ) {
		m_vScroll.Offset = 0
	}

	UpdateShownPage()
	UpdateListSliderPosition( PageServerList.len() )
}

void function OnScrollUp( var button )
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()

	m_vScroll.Offset -= 1
	if ( m_vScroll.Offset < 0 ) {
		m_vScroll.Offset = 0
	}

	UpdateShownPage()
	UpdateListSliderPosition( PageServerList.len() )
}

void function UpdateShownPage()
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()

	if(PageServerList.len() == 0)
		return

	// Reset Server Labels
	ServerBrowser_ResetLabels()

	m_vScroll.End = m_vScroll.Offset + SB_MAX_SERVER_PER_PAGE

	if(PageServerList.len() < SB_MAX_SERVER_PER_PAGE)
		m_vScroll.End = PageServerList.len()

	// "id" is diffrent from "i" and is used for setting UI elements
	// "i" is used for server id
	int id = 0
	for( int i=m_vScroll.Offset; i < m_vScroll.End; i++ ) {
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + id ), PageServerList[i].svServerName)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + id ), GetUIPlaylistName(PageServerList[i].svPlaylist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + id ), GetUIMapName(PageServerList[i].svMapName))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + id ), PageServerList[i].svCurrentPlayers + "/" + PageServerList[i].svMaxPlayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + id ), true)
		id++
	}

	UpdateListSliderHeight( float( PageServerList.len() ) )
}

void function UpdateListSliderPosition( int servers )
{
	var sliderButton = Hud_GetChild( file.panel , "BtnServerListSlider" )
	var sliderPanel = Hud_GetChild( file.panel , "BtnServerListSliderPanel" )
	var movementCapture = Hud_GetChild( file.panel , "MouseMovementCapture" )

	float minYPos = 0.0 * ( GetScreenSize().height / 1080.0 )
	float useableSpace = (550.0 * ( GetScreenSize().height / 1080.0 ) - Hud_GetHeight( sliderPanel ) )

	float jump = minYPos - ( useableSpace / ( float( servers ) - SB_MAX_SERVER_PER_PAGE ) * m_vScroll.Offset )

	if ( jump > minYPos ) jump = minYPos

	Hud_SetPos( sliderButton , -1, jump )
	Hud_SetPos( sliderPanel , -1, jump )
	Hud_SetPos( movementCapture , -1, jump )
}


void function UpdateListSliderHeight( float servers )
{
	var sliderButton = Hud_GetChild( file.panel , "BtnServerListSlider" )
	var sliderPanel = Hud_GetChild( file.panel , "BtnServerListSliderPanel" )
	var movementCapture = Hud_GetChild( file.panel , "MouseMovementCapture" )

	float maxHeight = 550.0 * ( GetScreenSize().height / 1080.0 )
	float minHeight = 80.0 * ( GetScreenSize().height / 1080.0 )

	float height = maxHeight * ( SB_MAX_SERVER_PER_PAGE / servers )

	if ( height > maxHeight ) height = maxHeight
	if ( height < minHeight ) height = minHeight

	Hud_SetHeight( sliderButton , height )
	Hud_SetHeight( sliderPanel , height )
	Hud_SetHeight( movementCapture , height )
}

void function UpdateMouseDeltaBuffer( int x, int y )
{
	mouseDeltaBuffer.deltaX += x
	mouseDeltaBuffer.deltaY += y

	SliderBarUpdate()
}

void function FlushMouseDeltaBuffer()
{
	mouseDeltaBuffer.deltaX = 0
	mouseDeltaBuffer.deltaY = 0
}


void function SliderBarUpdate()
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()

	if ( PageServerList.len() <= SB_MAX_SERVER_PER_PAGE )
	{
		FlushMouseDeltaBuffer()
		return
	}

	var sliderButton = Hud_GetChild( file.panel , "BtnServerListSlider" )
	var sliderPanel = Hud_GetChild( file.panel , "BtnServerListSliderPanel" )
	var movementCapture = Hud_GetChild( file.panel , "MouseMovementCapture" )

	Hud_SetFocused( sliderButton )

	float minYPos = 0.0 * ( GetScreenSize().height / 1080.0 )
	float maxHeight = 550.0  * ( GetScreenSize().height / 1080.0 )
	float maxYPos = minYPos - ( maxHeight - Hud_GetHeight( sliderPanel ) )
	float useableSpace = ( maxHeight - Hud_GetHeight( sliderPanel ) )

	float jump = minYPos - ( useableSpace / ( float( PageServerList.len() ) ) )

	// got local from official respaw scripts, without untyped throws an error
	local pos =	Hud_GetPos( sliderButton )[1]
	local newPos = pos - mouseDeltaBuffer.deltaY
	FlushMouseDeltaBuffer()

	if ( newPos < maxYPos ) newPos = maxYPos
	if ( newPos > minYPos ) newPos = minYPos

	Hud_SetPos( sliderButton , 0, newPos )
	Hud_SetPos( sliderPanel , 0, newPos )
	Hud_SetPos( movementCapture , 0, newPos )

	m_vScroll.Offset = -int( ( ( newPos - minYPos ) / useableSpace ) * ( PageServerList.len() - SB_MAX_SERVER_PER_PAGE ) )
	UpdateShownPage()
}

void function ServerBrowser_SelectServer(int id)
{
	array<ServerListing> PageServerList = ServerBrowser_GetCurrentServerListing()
	if(PageServerList.len() == 0)
		id = -1


	if(id == -1) {
		file.m_vSelectedServer.svServerID = -1
		file.m_vSelectedServer.svServerName = "Please select a server from the list"
		file.m_vSelectedServer.svMapName = "error"
		file.m_vSelectedServer.svPlaylist = "error"
		file.m_vSelectedServer.svDescription = ""
		ServerBrowser_UpdateSelectedServerUI()
		return
	}

	file.m_vSelectedServer.svServerID = file.m_vServerList[id].svServerID
	file.m_vSelectedServer.svServerName = file.m_vServerList[id].svServerName
	file.m_vSelectedServer.svMapName = file.m_vServerList[id].svMapName
	file.m_vSelectedServer.svPlaylist = file.m_vServerList[id].svPlaylist
	file.m_vSelectedServer.svDescription = file.m_vServerList[id].svDescription
	ServerBrowser_UpdateSelectedServerUI()
}

void function ServerBrowser_ResetLabels()
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

array<ServerListing> function ServerBrowser_GetArray(int svServerCount)
{
	//Create array for servers to be returned
	array<ServerListing> ServerList

	//No servers so just return
	if(svServerCount == 0)
		return ServerList

	// Add each server to the array
	for( int i=0; i < svServerCount; i++ ) {
		ServerListing Server
		Server.svServerID = i
		Server.svServerName = GetServerName(i)
		Server.svPlaylist = GetServerPlaylist(i)
		Server.svMapName = GetServerMap(i)
		Server.svDescription = GetServerDescription(i)
		Server.svMaxPlayers = GetServerMaxPlayers(i)
		Server.svCurrentPlayers = GetServerCurrentPlayers(i)
		ServerList.append(Server)
	}

	//Return Server Listing
	return ServerList
}

array<ServerListing> function ServerBrowser_GetCurrentServerListing()
{
	array<ServerListing> PageServerList = file.m_vServerList
	if(file.IsFiltered)
		PageServerList = file.m_vFilteredServerList

	return PageServerList
}

void function ServerBrowser_StartConnection(int id)
{
	Hud_SetVisible(Hud_GetChild( file.menu, "R5RConnectingPanel"), true)
	Hud_SetText(Hud_GetChild( GetPanel( "R5RConnectingPanel" ), "ServerName" ), file.m_vServerList[id].svServerName )

	wait 2

	Hud_SetVisible(Hud_GetChild( file.menu, "R5RConnectingPanel"), false)

	SetEncKeyAndConnect(id)
}

void function ServerBrowser_UpdateSelectedServerUI()
{
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentPlaylist" ), "Current Playlist" )
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentMap" ), "Current Map" )
	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), file.m_vSelectedServer.svServerName )
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentMapEdit" ), GetUIMapName(file.m_vSelectedServer.svMapName) )
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), GetUIPlaylistName(file.m_vSelectedServer.svPlaylist) )
	Hud_SetText(Hud_GetChild( file.panel, "ServerDesc" ), file.m_vSelectedServer.svDescription )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset(file.m_vSelectedServer.svMapName) )
}

void function ServerBrowser_NoServers(bool show)
{
	//Set no servers found ui based on bool
	Hud_SetVisible(Hud_GetChild( file.panel, "PlayerCountLine" ), !show )
	Hud_SetVisible(Hud_GetChild( file.panel, "PlaylistLine" ), !show )
	Hud_SetVisible(Hud_GetChild( file.panel, "MapLine" ), !show )
	Hud_SetVisible(Hud_GetChild( file.panel, "NoServersLbl" ), show )
}

void function ServerBrowser_UpdateServerPlayerCount()
{
	Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: " + file.m_vAllPlayers)
	Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: " + file.m_vAllServers)
}