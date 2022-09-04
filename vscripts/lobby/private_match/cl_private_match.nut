global function Cl_PrivateMatch_Init

global function ServerCallback_PrivateMatch_UpdateUI
global function ServerCallback_PrivateMatch_SelectionUpdated

global function ServerCallback_PrivateMatch_BuildClientString

global function UICodeCallback_UpdateServerInfo
global function UICodeCallback_KickOrBanPlayer
global function UICallback_CheckForHost

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
        case 0:
                GetLocalClientPlayer().ClientCommand("lobby_updateserversetting 0 " + text)
            break;
        case 1:
                GetLocalClientPlayer().ClientCommand("lobby_updateserversetting 1 " + text)
            break;
        case 2:
                GetLocalClientPlayer().ClientCommand("lobby_updateserversetting 2 " + text)
            break;
        case 3:
                GetLocalClientPlayer().ClientCommand("lobby_updateserversetting 3 " + text)
            break;
    }
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
        case 0:
                RunUIScript("UI_SetServerInfo", 0, tempstring)
                tempstring = ""
            break;
        case 1:
                RunUIScript("UI_SetServerInfo", 1, tempstring)
                tempstring = ""
            break;
        case 2:
                RunUIScript("UI_SetServerInfo", 2, tempstring)
                tempstring = ""
            break;
        case 3:
                RunUIScript("UI_SetServerInfo", 3, tempstring.tointeger())
                tempstring = ""
            break;
    }
}

void function ServerCallback_PrivateMatch_BuildClientString( ... )
{
	for ( int i = 0; i < vargc; i++ )
		tempstring += format("%c", vargv[i] )
}