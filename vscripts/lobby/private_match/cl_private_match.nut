global function Cl_PrivateMatch_Init

global function ServerCallback_PrivateMatch_UpdateUI
global function ServerCallback_PrivateMatch_SelectionUpdated
global function ServerCallback_PrivateMatch_BuildClientName
global function ServerCallback_PrivateMatch_BuildClientMap
global function ServerCallback_PrivateMatch_BuildClientPlaylist

global function UICallback_CheckForHost
global function UICodeCallback_UpdateName
global function UICodeCallback_UpdateMap
global function UICodeCallback_UpdatePlaylist
global function UICodeCallback_UpdateVis
global function UICodeCallback_KickPlayer
global function UICodeCallback_BanPlayer

string currentmap = ""
string currentplaylist = ""
string currentname = ""

void function Cl_PrivateMatch_Init()
{
    AddClientCallback_OnResolutionChanged( UpdateClientUI )
}

void function UpdateClientUI()
{
    GetLocalClientPlayer().ClientCommand("pm_updateclient")
}

void function UICallback_CheckForHost()
{
    if(GetLocalClientPlayer().GetPlayerName() == gp()[0].GetPlayerName())
        RunUIScript( "EnableCreateMatchUI" )
}

void function UICodeCallback_UpdateName(string name)
{
    GetLocalClientPlayer().ClientCommand("pm_name " + name)
}

void function UICodeCallback_UpdateMap(string map)
{
    GetLocalClientPlayer().ClientCommand("pm_map " + map)
}

void function UICodeCallback_UpdatePlaylist(string playlist)
{
    GetLocalClientPlayer().ClientCommand("pm_playlist " + playlist)
}

void function UICodeCallback_UpdateVis(int vis)
{
    GetLocalClientPlayer().ClientCommand("pm_vis " + vis)
}

void function UICodeCallback_KickPlayer(string player)
{
    GetLocalClientPlayer().ClientCommand("pm_kick " + player)
}

void function UICodeCallback_BanPlayer(string player)
{
    GetLocalClientPlayer().ClientCommand("pm_ban " + player)
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

void function ServerCallback_PrivateMatch_SelectionUpdated(int selection, int vis)
{
    switch( selection )
    {
        case eServerUpdateSelection.NAME:
                RunUIScript("PM_SetName", currentname)
                currentname = ""
            break;
        case eServerUpdateSelection.MAP:
                RunUIScript("PM_SetMap", currentmap)
                currentmap = ""
            break;
        case eServerUpdateSelection.PLAYLIST:
                RunUIScript("PM_SetPlaylist", currentplaylist)
                currentplaylist = ""
            break;
        case eServerUpdateSelection.VIS:
                RunUIScript("PM_SetVis", vis)
            break;
    }
}

void function ServerCallback_PrivateMatch_BuildClientName( ... )
{
	for ( int i = 0; i < vargc; i++ )
		currentname += format("%c", vargv[i] )
}

void function ServerCallback_PrivateMatch_BuildClientMap( ... )
{
	for ( int i = 0; i < vargc; i++ )
		currentmap += format("%c", vargv[i] )
}

void function ServerCallback_PrivateMatch_BuildClientPlaylist( ... )
{
	for ( int i = 0; i < vargc; i++ )
		currentplaylist += format("%c", vargv[i] )
}