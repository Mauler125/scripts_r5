global function Cl_LobbyVM_Init
global function SetR5ReloadedBadgeOnStartup

void function Cl_LobbyVM_Init()
{
    
}

void function SetR5ReloadedBadgeOnStartup()
{
    GetLocalClientPlayer().ClientCommand("loadouts_set 0 268 6")
}