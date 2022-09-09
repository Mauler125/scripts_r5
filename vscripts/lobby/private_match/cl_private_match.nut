global function Cl_PrivateMatch_Init

global function ServerCallback_PrivateMatch_UpdateUI
global function ServerCallback_PrivateMatch_SelectionUpdated
global function ServerCallback_PrivateMatch_BuildClientString
global function ServerCallback_PrivateMatch_StartingMatch
global function ServerCallback_ServerBrowser_JoinServer
global function ServerCallback_ServerBrowser_RefreshServers

global function UICodeCallback_UpdateServerInfo
global function UICodeCallback_KickOrBanPlayer
global function UICallback_CheckForHost
global function UICallback_StartMatch
global function UICallback_ServerBrowserJoinServer
global function UICallback_RefreshServer

string tempstring = ""

void function Cl_PrivateMatch_Init()
{
    AddClientCallback_OnResolutionChanged( OnResolutionChanged_UpdateClientUI )
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

void function UICallback_RefreshServer()
{
    GetLocalClientPlayer().ClientCommand("lobby_refreshservers")
}

void function UICallback_StartMatch()
{
    GetLocalClientPlayer().ClientCommand("lobby_startmatch")
}

void function UICallback_CheckForHost()
{
    if(GetLocalClientPlayer() == gp()[0])
        RunUIScript( "EnableCreateMatchUI" )
}

void function UICodeCallback_UpdateServerInfo(int type, string text)
{
    GetLocalClientPlayer().ClientCommand("lobby_updateserversetting " + type + " " + text)
}

void function UICodeCallback_KickOrBanPlayer(int type, string player)
{
    switch (type)
    {
        case 0:
            GetLocalClientPlayer().ClientCommand("lobby_kick " + player)
            break;
        case 1:
            GetLocalClientPlayer().ClientCommand("lobby_ban " + player)
            break;
    }
}

void function UICallback_ServerBrowserJoinServer(int id)
{
    if(GetLocalClientPlayer() == gp()[0])
        GetLocalClientPlayer().ClientCommand("lobby_joinserver " + id)
}

////////////////////////////////////////////////
//
//    Server CallBacks
//
////////////////////////////////////////////////

void function ServerCallback_ServerBrowser_RefreshServers()
{
    RunUIScript( "RefreshServerListing")
}

void function ServerCallback_ServerBrowser_JoinServer(int id)
{
    RunUIScript( "ServerBrowser_JoinServer", id)
}

void function ServerCallback_PrivateMatch_StartingMatch()
{
    RunUIScript( "ShowMatchStartingScreen")
}

void function ServerCallback_PrivateMatch_UpdateUI()
{
    array<string> playernames

    RunUIScript( "ClearPlayerUIArray" )

    foreach( player in GetPlayerArray() )
    {
        if(!IsValid(player))
            continue

        string playername = player.GetPlayerName()

        if(gp()[0].GetPlayerName() == playername)
        {
            playername = "[Host] " + player.GetPlayerName()
        }

        RunUIScript( "AddPlayerToUIArray", playername )
    }

    RunUIScript( "UpdateHostName", gp()[0].GetPlayerName() )

    RunUIScript( "UpdatePlayersList" )
}

void function ServerCallback_PrivateMatch_SelectionUpdated(int type)
{
    RunUIScript("UI_SetServerInfo", type, tempstring)
    tempstring = ""
}

void function ServerCallback_PrivateMatch_BuildClientString( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempstring += format("%c", vargv[i] )
}