global function Cl_LobbyVM_Init

global function ServerCallback_LobbyVM_UpdateUI
global function ServerCallback_LobbyVM_SelectionUpdated
global function ServerCallback_LobbyVM_BuildClientString
global function ServerCallback_LobbyVM_StartingMatch
global function ServerCallback_ServerBrowser_JoinServer
global function ServerCallback_ServerBrowser_RefreshServers

global function UICodeCallback_UpdateServerInfo
global function UICodeCallback_KickOrBanPlayer
global function UICallback_CheckForHost
global function UICallback_StartMatch
global function UICallback_ServerBrowserJoinServer
global function UICallback_RefreshServer
global function UICallback_SetHostName

string tempstring = ""

void function Cl_LobbyVM_Init()
{
    AddClientCallback_OnResolutionChanged( OnResolutionChanged_UpdateClientUI )

    PakHandle earlypak = RequestPakFile( "common_early" )
}

void function OnResolutionChanged_UpdateClientUI()
{
    GetLocalClientPlayer().ClientCommand("lobby_updateclient")
}

////////////////////////////////////////////////
//
//    UI CallBacks
//
////////////////////////////////////////////////

void function UICallback_SetHostName(string name)
{
    
}

void function UICallback_RefreshServer()
{
    if(GetLocalClientPlayer() == GetPlayerArray()[0])
        GetLocalClientPlayer().ClientCommand("lobby_refreshservers")
}

void function UICallback_StartMatch()
{
   
}

void function UICallback_CheckForHost()
{
    
}

void function UICodeCallback_UpdateServerInfo(int type, string text)
{
    
}

void function UICodeCallback_KickOrBanPlayer(int type, string player)
{
    
}

void function UICallback_ServerBrowserJoinServer(int id)
{
    if(GetLocalClientPlayer() == GetPlayerArray()[0])
        GetLocalClientPlayer().ClientCommand("lobby_joinserver " + id)
}

////////////////////////////////////////////////
//
//    Server CallBacks
//
////////////////////////////////////////////////

void function ServerCallback_ServerBrowser_RefreshServers()
{
    RunUIScript( "ServerBrowser_RefreshServerListing")
}

void function ServerCallback_ServerBrowser_JoinServer(int id)
{
    RunUIScript( "ServerBrowser_JoinServer", id)
}

void function ServerCallback_LobbyVM_StartingMatch()
{
    
}

void function ServerCallback_LobbyVM_UpdateUI()
{
    
}

void function ServerCallback_LobbyVM_SelectionUpdated(int type)
{
    
}

void function ServerCallback_LobbyVM_BuildClientString( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempstring += format("%c", vargv[i] )
}