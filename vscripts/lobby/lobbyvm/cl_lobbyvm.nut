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

global function ModsPanelShown

string tempstring = ""

entity loottick
entity dummyEnt

global bool IsLootTickRunning = false

void function Cl_LobbyVM_Init()
{
    AddClientCallback_OnResolutionChanged( OnResolutionChanged_UpdateClientUI )

    PakHandle earlypak = RequestPakFile( "common_early" )
    PakHandle earlypak2 = RequestPakFile( "common_mp" )
    
    AddCallback_EntitiesDidLoad( LobbyVM_EntitiesDidLoad )
}

void function LobbyVM_EntitiesDidLoad()
{
    PrecacheParticleSystem( $"P_bBomb_smoke" )
    PrecacheParticleSystem( $"P_loot_tick_beam_idle_flash")
    PrecacheModel( $"mdl/vehicle/goblin_dropship/goblin_dropship.rmdl")
    PrecacheModel( $"mdl/props/death_box/death_box_01.rmdl")

	StartParticleEffectInWorld( GetParticleSystemIndex( $"P_bBomb_smoke" ), <8100,-7557, -8129>, <0, 0, 0> )

	entity modsdropship = CreateClientSidePropDynamic( <8000,-7357, -8129>, <0, 120, 0>, $"mdl/vehicle/goblin_dropship/goblin_dropship.rmdl" )
	modsdropship.SetModelScale( 0.5 )
	thread PlayAnim( modsdropship, "s2s_rampdown_idle" )

    dummyEnt = CreateClientSidePropDynamic( <8100,-7457, -8129>, <0, -45, 0>, $"mdl/humans/class/medium/pilot_medium_bloodhound.rmdl" )
    dummyEnt.SetModelScale( 0.5 )
    thread PlayAnim( dummyEnt, "mp_pt_medium_training_blood_intro_idle" )

    entity deathbox1 = CreateClientSidePropDynamic( <8100,-7457, -8129>, <0, -60, 0>, $"mdl/props/death_box/death_box_01.rmdl" )
    deathbox1.SetModelScale( 0.5 )
    entity deathbox2 = CreateClientSidePropDynamic( <8125,-7457, -8129>, <0, 30, 0>, $"mdl/props/death_box/death_box_01.rmdl" )
    deathbox2.SetModelScale( 0.5 )
    entity deathbox3 = CreateClientSidePropDynamic( <8115,-7457, -8117>, <0, 90, 0>, $"mdl/props/death_box/death_box_01.rmdl" )
    deathbox3.SetModelScale( 0.5 )

    loottick = CreateClientSidePropDynamic( <8115,-7497, -8129>, <0, 0, 0>, $"mdl/robots/drone_frag/drone_frag_loot.rmdl")
    loottick.SetModelScale( 0.5 )
    thread PlayAnim( loottick, "sd_closed_idle" )
}

void function ModsPanelShown()
{
    if(IsLootTickRunning)
        IsLootTickRunning = false
        
    loottick.SetModel( GRXPack_GetTickModel( GetItemFlavorByHumanReadableRef( "pack_cosmetic_rare" ) ) )
	loottick.SetSkin( loottick.GetSkinIndexByName( GRXPack_GetTickModelSkin( GetItemFlavorByHumanReadableRef( "pack_cosmetic_rare" ) ) ) )

    if(IsValid(loottick))
        thread PlayLoottickOpenAnim()
}

void function PlayLoottickOpenAnim()
{
    waitthread PlayAnim( loottick, "sd_closed_to_open" )
    thread PlayAnim( loottick, "sd_search_idle" )
    
    thread StartLootTickLights()
}

void function StartLootTickLights()
{
    IsLootTickRunning = true
    while(IsLootTickRunning)
    {
        array<string> eyes = ["FX_L_EYE","FX_R_EYE","FX_C_EYE"]
        foreach(string eye in eyes)
        {
            int rarity  = 0
            int randInt = RandomInt( 1000 )

            if ( randInt > 995 )
                rarity = 4
            if ( randInt > 970 )
                rarity = 3
            else if ( randInt > 900 )
                rarity = 2
            else if ( randInt > 600 )
                rarity = 1

            int eyenum = RandomIntRange( 0, 2 )
            int attachID = loottick.LookupAttachment( eye )
            int fxIndex = StartParticleEffectOnEntity( loottick, GetParticleSystemIndex( $"P_loot_tick_beam_idle_flash" ), FX_PATTACH_POINT_FOLLOW, attachID )
            EffectSetControlPointVector( fxIndex, 1, GetFXRarityColorForUnlockable( rarity ) )

            wait 0.2
        }
    }
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