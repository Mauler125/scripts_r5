global function Cl_PrivateMatch_Init

global function ServerCallback_PrivateMatch_UpdateUI
global function ServerCallback_PrivateMatch_SelectionUpdated

global function ServerCallback_PrivateMatch_BuildClientName
global function ServerCallback_PrivateMatch_BuildClientMap
global function ServerCallback_PrivateMatch_BuildClientPlaylist
global function ServerCallback_PrivateMatch_BuildClientVis

global function UICodeCallback_UpdateServerInfo
global function UICodeCallback_KickOrBanPlayer
global function UICallback_CheckForHost

struct
{
    string currentmap = ""
    string currentplaylist = ""
    string currentname = ""
    string currentvis = ""
} tempStorage

void function Cl_PrivateMatch_Init()
{
    AddClientCallback_OnResolutionChanged( OnResolutionChanged_UpdateClientUI )
}

void function OnResolutionChanged_UpdateClientUI()
{
    GetLocalClientPlayer().ClientCommand("pm_updateclient")
}

////////////////////////////////////////////////
//
//    UI Call Backs
//
////////////////////////////////////////////////

void function UICallback_CheckForHost()
{
    if(GetLocalClientPlayer().GetPlayerName() == gp()[0].GetPlayerName())
        RunUIScript( "EnableCreateMatchUI" )
}

void function UICodeCallback_UpdateServerInfo(int type, string text)
{
    switch (type)
    {
        case eServerUpdateSelection.NAME:
                GetLocalClientPlayer().ClientCommand("pm_name " + text)
            break;
        case eServerUpdateSelection.MAP:
                GetLocalClientPlayer().ClientCommand("pm_map " + text)
            break;
        case eServerUpdateSelection.PLAYLIST:
                GetLocalClientPlayer().ClientCommand("pm_playlist " + text)
            break;
        case eServerUpdateSelection.VIS:
                GetLocalClientPlayer().ClientCommand("pm_vis " + text)
            break;
    }
}

void function UICodeCallback_KickOrBanPlayer(int type, string player)
{
    switch (type)
    {
        case 0:
            GetLocalClientPlayer().ClientCommand("pm_kick " + player)
            break;
        case 1:
            GetLocalClientPlayer().ClientCommand("pm_ban " + player)
            break;
    }
}

////////////////////////////////////////////////
//
//    Server Call Backs
//
////////////////////////////////////////////////

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
    switch( type )
    {
        case eServerUpdateSelection.NAME:
                RunUIScript("UI_SetServerInfo", eServerUpdateSelection.NAME, tempStorage.currentname)
                tempStorage.currentname = ""
            break;
        case eServerUpdateSelection.MAP:
                RunUIScript("UI_SetServerInfo", eServerUpdateSelection.MAP, tempStorage.currentmap)
                tempStorage.currentmap = ""
            break;
        case eServerUpdateSelection.PLAYLIST:
                RunUIScript("UI_SetServerInfo", eServerUpdateSelection.PLAYLIST, tempStorage.currentplaylist)
                tempStorage.currentplaylist = ""
            break;
        case eServerUpdateSelection.VIS:
                RunUIScript("UI_SetServerInfo", eServerUpdateSelection.VIS, tempStorage.currentvis.tointeger())
                tempStorage.currentvis = ""
            break;
    }
}

void function ServerCallback_PrivateMatch_BuildClientName( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempStorage.currentname += format("%c", vargv[i] )
}

void function ServerCallback_PrivateMatch_BuildClientMap( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempStorage.currentmap += format("%c", vargv[i] )
}

void function ServerCallback_PrivateMatch_BuildClientPlaylist( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempStorage.currentplaylist += format("%c", vargv[i] )
}

void function ServerCallback_PrivateMatch_BuildClientVis( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempStorage.currentvis += format("%c", vargv[i] )
}