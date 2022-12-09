untyped
// Only way to get Hud_GetPos(sliderButton) working was to use untyped

global function InitR5RServerBrowserPanel
global function InitR5RConnectingPanel

global function ServerBrowser_EnableRefreshButton
global function ServerBrowser_RefreshServerListing
global function ServerBrowser_JoinServer
global function ServerBrowser_RefreshServersForEveryone

//Used for max items for page
//Changing this requires a bit of work to get more to show correctly
//So keep at 19
const SB_MAX_SERVER_PER_PAGE = 19

// Stores mouse delta used for scroll bar
struct {
	int deltaX = 0
	int deltaY = 0
} mouseDeltaBuffer

struct
{
	var menu
	var panel
	var connectingpanel

	bool IsFiltered = false
} file

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

//Arrays for server listing
array<ServerListing> m_vServerList
array<ServerListing> m_vFilteredServerList
//Used for what server you selected
SelectedServerInfo m_vSelectedServer
//Used for all player count
int m_vAllPlayers

void function InitR5RConnectingPanel( var panel )
{
	file.connectingpanel = panel
}

void function InitR5RServerBrowserPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	AddMouseMovementCaptureHandler( Hud_GetChild(file.panel, "MouseMovementCapture"), UpdateMouseDeltaBuffer )

	//Setup Connect Button
	Hud_AddEventHandler( Hud_GetChild( file.panel, "ConnectButton" ), UIE_CLICK, ServerBrowser_ConnectBtnClicked )
	//Setup Refresh Button
	Hud_AddEventHandler( Hud_GetChild( file.panel, "RefreshServers" ), UIE_CLICK, ServerBrowser_RefreshBtnClicked )

	AddButtonEventHandler( Hud_GetChild( file.panel, "BtnFilterServers"), UIE_CHANGE, ServerBrowser_FilterTextChanged )

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
	ServerBrowser_SelectServer(-1, "", "", "", "")
	ServerBrowser_ResetLabels()

	// Set servercount, playercount
	Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: 0")
	Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: 0")

	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentPlaylist" ), "" )
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentMap" ), "" )

	RegisterButtonPressedCallback( MOUSE_WHEEL_UP , OnScrollUp )
	RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN , OnScrollDown )
}

////////////////////////////////////
//
//		Button Functions
//
////////////////////////////////////

void function ServerBrowser_RefreshBtnClicked(var button)
{
	RunClientScript("UICallback_RefreshServer")
}

void function ServerBrowser_FilterTextChanged( var button )
{
	string filter = Hud_GetUTF8Text( Hud_GetChild( file.panel, "BtnFilterServers" ) )

	if(filter != "") {
		file.IsFiltered = true
		ServerBrowser_FilterServerList(filter)
	} else {
		file.IsFiltered = false
		ServerBrowser_RefreshServerListing(false)
	}
}

void function ServerBrowser_ConnectBtnClicked(var button)
{
	//If server isnt selected return
	if(m_vSelectedServer.svServerID == -1)
		return

	//Connect to server
	printf("Connecting to server: (Server ID: " + m_vSelectedServer.svServerID + " | Server Name: " + m_vSelectedServer.svServerName + " | Map: " + m_vSelectedServer.svMapName + " | Playlist: " + m_vSelectedServer.svPlaylist + ")")
	//SetEncKeyAndConnect(m_vSelectedServer.svServerID)
	RunClientScript("UICallback_ServerBrowserJoinServer", m_vSelectedServer.svServerID)
}

void function ServerBrowser_ServerBtnClicked(var button)
{
	//Get the button id and add it to the scroll offset to get the correct server id
	int id = Hud_GetScriptID( button ).tointeger() + m_vScroll.Offset

	if(file.IsFiltered)
		ServerBrowser_SelectServer(m_vFilteredServerList[id].svServerID, m_vFilteredServerList[id].svServerName, m_vFilteredServerList[id].svMapName, m_vFilteredServerList[id].svPlaylist, m_vFilteredServerList[id].svDescription)
	else
		ServerBrowser_SelectServer(m_vServerList[id].svServerID, m_vServerList[id].svServerName, m_vServerList[id].svMapName, m_vServerList[id].svPlaylist, m_vServerList[id].svDescription)
}

void function ServerBrowser_ServerBtnDoubleClicked(var button)
{
	//Get the button id and add it to the scroll offset to get the correct server id
	int id = Hud_GetScriptID( button ).tointeger() + m_vScroll.Offset

	if(file.IsFiltered)
		ServerBrowser_SelectServer(m_vFilteredServerList[id].svServerID, m_vFilteredServerList[id].svServerName, m_vFilteredServerList[id].svMapName, m_vFilteredServerList[id].svPlaylist, m_vFilteredServerList[id].svDescription)
	else
		ServerBrowser_SelectServer(m_vServerList[id].svServerID, m_vServerList[id].svServerName, m_vServerList[id].svMapName, m_vServerList[id].svPlaylist, m_vServerList[id].svDescription)

	ServerBrowser_JoinServer(id)
}

////////////////////////////////////
//
//		General Functions
//
////////////////////////////////////

void function ServerBrowser_FilterServerList(string filter)
{
	m_vFilteredServerList.clear()

	for( int i=0; i < m_vServerList.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		if(m_vServerList[i].svServerName.tolower().find( filter.tolower() ) >= 0)
			m_vFilteredServerList.append(m_vServerList[i])
	}

	//Clear Server List Text, Hide no servers found ui, Reset pages
	ServerBrowser_ResetLabels()
	ServerBrowser_NoServers(false)
	m_vScroll.Offset = 0

	// Get Server Count
	int svServerCount = m_vFilteredServerList.len()

	// If no servers then set no servers found ui and return
	if(svServerCount == 0) {
		// Show no servers found ui
		ServerBrowser_NoServers(true)

		// Set selected server to none
		ServerBrowser_SelectServer(-1, "", "", "", "")

		// Set servercount, playercount, pages to none
		Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: 0")
		Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: 0")

		// Return as it dosnt need togo past this if no servers are found
		return
	}

	// Setup Buttons and labels
	for( int i=0; i < m_vFilteredServerList.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), m_vFilteredServerList[i].svServerName)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), GetUIPlaylistName(m_vFilteredServerList[i].svPlaylist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), GetUIMapName(m_vFilteredServerList[i].svMapName))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), m_vFilteredServerList[i].svCurrentPlayers + "/" + m_vFilteredServerList[i].svMaxPlayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)
	}

	// Select first server in the list
	ServerBrowser_SelectServer(m_vFilteredServerList[0].svServerID, m_vFilteredServerList[0].svServerName, m_vFilteredServerList[0].svMapName, m_vFilteredServerList[0].svPlaylist, m_vFilteredServerList[0].svDescription)

	UpdateListSliderHeight( float( m_vFilteredServerList.len() ) )
	UpdateListSliderPosition( m_vFilteredServerList.len() )
	// Set UI Labels
	Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: " + m_vAllPlayers)
	Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: " + m_vServerList.len())
}

void function ServerBrowser_RefreshServerListing(bool refresh = true)
{
	if (refresh)
		RefreshServerList()

	//Clear Server List Text, Hide no servers found ui
	ServerBrowser_ResetLabels()
	ServerBrowser_NoServers(false)
	m_vAllPlayers = 0
	m_vScroll.Offset = 0

	// Get Server Count
	int svServerCount = GetServerCount()

	// If no servers then set no servers found ui and return
	if(svServerCount == 0) {
		// Show no servers found ui
		ServerBrowser_NoServers(true)

		// Set selected server to none
		ServerBrowser_SelectServer(-1, "", "", "", "")

		// Set servercount, playercount
		Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: 0")
		Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: 0")

		// Return as it dosnt need togo past this if no servers are found
		return
	}

	// Get Server Array
	m_vServerList = ServerBrowser_GetArray(svServerCount)

	UpdateListSliderHeight( float( m_vServerList.len() ) )
	UpdateListSliderPosition( m_vServerList.len() )

	// Setup Buttons and labels
	for( int i=0; i < m_vServerList.len() && i < SB_MAX_SERVER_PER_PAGE; i++ )
	{
		Hud_SetText( Hud_GetChild( file.panel, "ServerName" + i ), m_vServerList[i].svServerName)
		Hud_SetText( Hud_GetChild( file.panel, "Playlist" + i ), GetUIPlaylistName(m_vServerList[i].svPlaylist))
		Hud_SetText( Hud_GetChild( file.panel, "Map" + i ), GetUIMapName(m_vServerList[i].svMapName))
		Hud_SetText( Hud_GetChild( file.panel, "PlayerCount" + i ), m_vServerList[i].svCurrentPlayers + "/" + m_vServerList[i].svMaxPlayers)
		Hud_SetVisible(Hud_GetChild( file.panel, "ServerButton" + i ), true)

		m_vAllPlayers += m_vServerList[i].svCurrentPlayers
	}

	// Select first server in the list
	ServerBrowser_SelectServer(m_vServerList[0].svServerID, m_vServerList[0].svServerName, m_vServerList[0].svMapName, m_vServerList[0].svPlaylist, m_vServerList[0].svDescription)

	// Set UI Labels
	Hud_SetText( Hud_GetChild( file.panel, "PlayersCount"), "Players: " + m_vAllPlayers)
	Hud_SetText( Hud_GetChild( file.panel, "ServersCount"), "Servers: " + svServerCount)

	string filter = Hud_GetUTF8Text( Hud_GetChild( file.panel, "BtnFilterServers" ) )
	if(filter != "") {
		file.IsFiltered = true
		ServerBrowser_FilterServerList(filter)
	}
}

//Used scroll code from northstar.
void function OnScrollDown( var button )
{
	array<ServerListing> PageServerList = m_vServerList
	if(file.IsFiltered)
		PageServerList = m_vFilteredServerList

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
	array<ServerListing> PageServerList = m_vServerList
	if(file.IsFiltered)
		PageServerList = m_vFilteredServerList

	m_vScroll.Offset -= 1
	if ( m_vScroll.Offset < 0 ) {
		m_vScroll.Offset = 0
	}

	UpdateShownPage()
	UpdateListSliderPosition( PageServerList.len() )
}

void function UpdateShownPage()
{
	array<ServerListing> PageServerList = m_vServerList
	if(file.IsFiltered)
		PageServerList = m_vFilteredServerList

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
	float useableSpace = (760.0 * ( GetScreenSize().height / 1080.0 ) - Hud_GetHeight( sliderPanel ) )

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

	float maxHeight = 760.0 * ( GetScreenSize().height / 1080.0 )
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
	array<ServerListing> PageServerList = m_vServerList
	if(file.IsFiltered)
		PageServerList = m_vFilteredServerList

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
	float maxHeight = 760.0  * ( GetScreenSize().height / 1080.0 )
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

array<ServerListing> function ServerBrowser_GetArray(int svServerCount)
{
	//Create array for servers to be returned
	array<ServerListing> ServerList

	//No servers so just return
	if(svServerCount == 0)
		return ServerList

	// Add each server to the array
	for( int i=0; i < svServerCount; i++ ) {
		//Add Server to array
		ServerBrowser_AddServerToArray(i, GetServerName(i), GetServerPlaylist(i), GetServerMap(i), GetServerDescription(i), GetServerMaxPlayers(i), GetServerCurrentPlayers(i), ServerList)
	}

	//Return Server Listing
	return ServerList
}

void function ServerBrowser_NoServers(bool show)
{
	//Set no servers found ui based on bool
	Hud_SetVisible(Hud_GetChild( file.panel, "PlayerCountLine" ), !show )
	Hud_SetVisible(Hud_GetChild( file.panel, "PlaylistLine" ), !show )
	Hud_SetVisible(Hud_GetChild( file.panel, "MapLine" ), !show )
	Hud_SetVisible(Hud_GetChild( file.panel, "NoServersLbl" ), show )
}

void function ServerBrowser_SelectServer(int id, string name, string map, string playlist, string desc)
{
	//Set selected server info
	m_vSelectedServer.svServerID = id
	m_vSelectedServer.svServerName = name
	m_vSelectedServer.svMapName = map
	m_vSelectedServer.svPlaylist = playlist
	m_vSelectedServer.svDescription = desc

	//Set selected server ui
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentPlaylist" ), "Current Playlist" )
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentMap" ), "Current Map" )

	Hud_SetText(Hud_GetChild( file.panel, "ServerNameInfoEdit" ), name )
	Hud_SetText(Hud_GetChild( file.panel, "ServerCurrentMapEdit" ), GetUIMapName(map) )
	Hud_SetText(Hud_GetChild( file.panel, "PlaylistInfoEdit" ), GetUIPlaylistName(playlist) )
	Hud_SetText(Hud_GetChild( file.panel, "ServerDesc" ), desc )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "ServerMapImg" ) ), "loadscreenImage", GetUIMapAsset(map) )
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

void function ServerBrowser_AddServerToArray(int id, string name, string playlist, string map, string desc, int max, int current, array<ServerListing> ServerList)
{
	//Setup new server
	ServerListing Server
	Server.svServerID = id
	Server.svServerName = name
	Server.svPlaylist = playlist
	Server.svMapName = map
	Server.svDescription = desc
	Server.svMaxPlayers = max
	Server.svCurrentPlayers = current

	//Add new server to array
	ServerList.append(Server)
}

void function ServerBrowser_RefreshServersForEveryone()
{
	RunClientScript("UICallback_RefreshServer")
}

void function ServerBrowser_EnableRefreshButton( bool show)
{
	Hud_SetVisible(Hud_GetChild( file.panel, "RefreshServers" ), show)
	Hud_SetVisible(Hud_GetChild( file.panel, "RefreshServersText" ), show)
}

void function ServerBrowser_JoinServer(int id)
{
	thread ServerBrowser_StartConnection(id)
}

void function ServerBrowser_StartConnection(int id)
{
	Hud_SetVisible(Hud_GetChild( file.menu, "R5RConnectingPanel"), true)
	Hud_SetText(Hud_GetChild( GetPanel( "R5RConnectingPanel" ), "ServerName" ), m_vServerList[id].svServerName )

	wait 2

	Hud_SetVisible(Hud_GetChild( file.menu, "R5RConnectingPanel"), false)

	SetEncKeyAndConnect(id)
}