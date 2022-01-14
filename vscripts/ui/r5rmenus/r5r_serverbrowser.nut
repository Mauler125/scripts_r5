global function InitR5RServerBrowser
global function SetCancelConnect

struct
{
	var menu
    var refreshbtn
    var listPanel
    var connectbtn
    var mapimg
    var infoservername
    var infoplaylist
    var infomap
    var privateserver
    var ipconnect

    var infoservernametext
    var infoplaylisttext
    var infomaptext

    var serverammount
    var connecting
    var connectinglbl


    int serverconnectid

    table<var, int> buttonToServerID
    table<var, bool> buttonEventHandlersAdded
    array<ItemFlavor> loadscreenList

    int currentservertext = 1
    int ammountofservers = -1
    bool firstclick = false
    bool iscancelconnect = false

    bool isrrefreshtimer = false
} file

void function InitR5RServerBrowser( var newMenuArg )
{
	var menu = GetMenu( "R5RServerBrowser" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	SetGamepadCursorEnabled( menu, false )

    //Setup RUI/VGUI

    file.refreshbtn = Hud_GetChild( menu, "RefreshButton" )
    Hud_AddEventHandler( file.refreshbtn, UIE_CLICK, RefreshBtnClick )

    file.privateserver = Hud_GetChild( menu, "PrivateServerButton" )
    Hud_AddEventHandler( file.privateserver, UIE_CLICK, PrivateServerBtnClick )

    file.ipconnect = Hud_GetChild( menu, "ConnectToIPButton" )
    Hud_AddEventHandler( file.ipconnect, UIE_CLICK, IPServerBtnClick )

    file.connectbtn = Hud_GetChild(menu, "ConnectButton")
    Hud_AddEventHandler( file.connectbtn, UIE_CLICK, Connect )
    var rui = Hud_GetRui( file.connectbtn )
    RuiSetString( rui, "buttonText", "Connect" )

    file.listPanel = Hud_GetChild( menu, "ServerListScrollPanel" )
    file.mapimg = Hud_GetChild( file.menu, "ServerMapImg" )
    file.infoservername = Hud_GetChild(file.menu, "ServerNameInfoEdit")
    file.infoplaylist = Hud_GetChild(file.menu, "ServerPlaylistInfoEdit")
    file.infomap = Hud_GetChild(file.menu, "ServerMapInfoEdit")

    file.serverammount = Hud_GetChild(file.menu, "LBLServers")
    Hud_SetText(file.serverammount, "# Of Servers: 0")

    file.isrrefreshtimer = false
}

void function RefreshBtnClick( var button )
{
    thread RefreshServerListing()
    thread RefreshWaitTime()
}

void function PrivateServerBtnClick( var button )
{
    AdvanceMenu( GetMenu( "PrivateServerConnect" ) )
}

void function IPServerBtnClick( var button )
{
    AdvanceMenu( GetMenu( "IPServerConnect" ) )
}

void function RefreshServerListing()
{
    //Clear table
    file.buttonToServerID.clear()

    //Get server ammount
    file.ammountofservers = GetServerAmmount()

    //Init the x amount of buttons depending on how many servers there are
    Hud_InitGridButtons( file.listPanel, file.ammountofservers + 1 )
    var scrollPanel = Hud_GetChild( file.listPanel, "ScrollPanel" )

    //Set max server count to 999
    //I feel like that should be plenty
    if(file.ammountofservers > 999)
    {
        file.ammountofservers = 999
    }

    //number of servers needs to add 1
    int servers2 = file.ammountofservers + 1

    //set server count label
    Hud_SetText(file.serverammount, "# Of Servers: " + servers2)

    //this way seems to be the best for the use case
    for ( int i = 0; i < file.ammountofservers + 1; i++ )
	{
        //get server stats
        string servername = GetServerName(i)
        string playlistname = GetServerPlaylist(i)
        string mapname = GetServerMap(i)
        
        var gridbutton = Hud_GetChild( scrollPanel, "GridButton" + i )
        file.buttonToServerID[gridbutton] <- i

        //remove old event handlers other wise it will cause a ui error if you refresh more then twice
        if ( gridbutton in file.buttonEventHandlersAdded )
		{
			Hud_RemoveEventHandler( gridbutton, UIE_CLICK, ServerInfo )
            Hud_RemoveEventHandler( gridbutton, UIE_GET_FOCUS, ServerInfo )
            Hud_RemoveEventHandler( gridbutton, UIE_DOUBLECLICK, Connect )
			delete file.buttonEventHandlersAdded[ gridbutton ]
		}

        //add event handlers for each button
        Hud_AddEventHandler( gridbutton, UIE_CLICK, ServerInfo )
        Hud_AddEventHandler( gridbutton, UIE_GET_FOCUS, ServerInfo )
        Hud_AddEventHandler( gridbutton, UIE_DOUBLECLICK, Connect )
        file.buttonEventHandlersAdded[ gridbutton ] <- true

        //set button rui
        var rui = Hud_GetRui( gridbutton )
        RuiSetString( rui, "buttonText", servername + " | " + playlistname + " | " + mapname )
    }
}

void function RefreshWaitTime()
{
    //this is only here to show a cool connecting to server screen
    //and give people just enogh time to cancel connecting to a server
    file.isrrefreshtimer = true
    Hud_SetEnabled( file.refreshbtn, false )
    int waittime = 10

    for ( int i = waittime; i > 0; i-- )
	{
        var refreshtext = Hud_GetChild(file.menu, "BtnRefresh")
        Hud_SetText(refreshtext, "Refresh Servers (" + i.tostring() + ")")
        wait 1
    }

    var refreshtext = Hud_GetChild(file.menu, "BtnRefresh")
    Hud_SetText(refreshtext, "Refresh Servers")

    Hud_SetEnabled( file.refreshbtn, true )
    file.isrrefreshtimer = false
}

void function Connect( var button )
{
    thread StartServerConnection()
}

void function StartServerConnection()
{
    string servername = GetServerName(file.serverconnectid)
    string playlistname = GetServerPlaylist(file.serverconnectid)
    //connecting box
    //still a WIP
    SendConnectMenuData(servername, playlistname)
    AdvanceMenu( GetMenu( "ConnectingToServer" ) )

    wait 2

    if (file.iscancelconnect)
    {
        file.iscancelconnect = false
    }
    else
    {
        SetEncKeyAndConnect(file.serverconnectid)
    }
}

void function SetCancelConnect()
{
    file.iscancelconnect = true
}

void function ServerInfo( var button )
{
    //Get server ID from table
    file.serverconnectid = file.buttonToServerID[button]

    //Make hud elems visible
    Hud_SetVisible( file.connectbtn, true )
    Hud_SetEnabled( file.connectbtn, true )
    Hud_SetVisible( file.mapimg, true )

    //Get selected server info from id
    string servername = GetServerName(file.buttonToServerID[button])
    string playlistname = GetServerPlaylist(file.buttonToServerID[button])
    string mapname = GetServerMap(file.buttonToServerID[button])

    string goodmapname = GetMapName(mapname)

    Hud_SetText(file.infoservername, servername)
    Hud_SetText(file.infoplaylist, "Current Playlist: " + playlistname)
    Hud_SetText(file.infomap, "Current Map: " + goodmapname)

    //there has to be a way to use loading screen images
    if(mapname == "mp_rr_canyonlands_64k_x_64k" || mapname == "mp_rr_canyonlands_mu1" || mapname == "mp_rr_canyonlands_mu1_night")
    {
        RuiSetImage( Hud_GetRui( file.mapimg ), "loadscreenImage", $"rui/menu/gamemode/play_apex" )
    }
    else if(mapname == "mp_rr_desertlands_64k_x_64k" || mapname == "mp_rr_desertlands_64k_x_64k_nx")
    {
        RuiSetImage( Hud_GetRui( file.mapimg ), "loadscreenImage", $"rui/menu/gamemode/worlds_edge" )
    }
    else if(mapname == "mp_rr_canyonlands_staging")
    {
        RuiSetImage( Hud_GetRui( file.mapimg ), "loadscreenImage", $"rui/menu/gamemode/firing_range" )
    }
    else
    {
        RuiSetImage( Hud_GetRui( file.mapimg ), "loadscreenImage", $"rui/menu/gamemode/generic_02" )
    }
}

string function GetMapName(string map)
{
    string mapname

    if(map == "mp_rr_canyonlands_64k_x_64k")
    {
        mapname = "Kings Canyon S0"
    }
    else if(map == "mp_rr_canyonlands_mu1")
    {
        mapname = "Kings Canyon S2"
    }
    else if(map == "mp_rr_canyonlands_mu1_night")
    {
        mapname = "Kings Canyon S2 After Dark"
    }
    else if(map == "mp_rr_desertlands_64k_x_64k")
    {
        mapname = "Worlds Edge S3"
    }
    else if(map == "mp_rr_desertlands_64k_x_64k_nx")
    {
        mapname = "Worlds Edge S3 AFter Dark"
    }
    else if(map == "mp_rr_canyonlands_staging")
    {
        mapname = "Firing Range"
    }
    else if(map == "mp_r5r_ashs_redemption")
    {
        mapname = "Ash's Redemption"
    }
    else
    {
        mapname = map
    }

    return mapname
}

void function OnR5RSB_Show()
{
    //set connect id to -1 to prevent connection to a server if once hasnt been selected
    file.serverconnectid = -1

    //hide hud elems
    Hud_SetVisible( file.connectbtn, true )
    Hud_SetEnabled( file.connectbtn, false )
    Hud_SetVisible( file.mapimg, true )

    //set server info labels
    Hud_SetText(file.infoservername, "")
    Hud_SetText(file.infoplaylist, "")
    Hud_SetText(file.infomap, "")

    //To prevent random ui errors caused by going in and out of refreshing the serverlist on show
    if(!file.isrrefreshtimer)
    {
        thread RefreshServerListing()
        thread RefreshWaitTime()
    }
}


void function OnR5RSB_Close()
{
	//nothing here
}

void function OnR5RSB_NavigateBack()
{
	CloseActiveMenu()
}