global function _PrivateMatch_Init

array<entity> playerarray

struct
{
    string servername
    string servermap
    string serverplaylist
    string servervis
} PrivateMatchSettings;

void function _PrivateMatch_Init()
{
    AddCallback_OnClientConnected( void function(entity player) { thread _OnPlayerConnected(player) } )

    AddClientCommandCallback("pm_map", ClientCommand_ChangeMap)
    AddClientCommandCallback("pm_name", ClientCommand_ChangeName)
    AddClientCommandCallback("pm_playlist", ClientCommand_ChangePlaylist)
    AddClientCommandCallback("pm_vis", ClientCommand_ChangeVis)
    AddClientCommandCallback("pm_updateclient", ClientCommand_UpdateClient)
    AddClientCommandCallback("pm_kick", ClientCommand_KickPlayer)
    AddClientCommandCallback("pm_ban", ClientCommand_BanPlayer)

    PrivateMatchSettings.servername = "Some Server"
    PrivateMatchSettings.servermap = "mp_rr_canyonlands_mu1"
    PrivateMatchSettings.serverplaylist = "custom_tdm"
    PrivateMatchSettings.servervis = "2"

    thread StartOfPrivateMatch()
}

/////////////////////////////////////////////
//                                         //
//             Client Commands             //
//                                         //
/////////////////////////////////////////////

bool function ClientCommand_KickPlayer(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    if( gp()[0].GetPlayerName() != player.GetPlayerName())
        return false

    if(args.len() < 1)
        return false

    if(args[0] == ("[Host]"))
        return false

    string playertokick

    foreach(int i, arg in args)
    {
        if(i == 0)
            playertokick += arg  
        else
            playertokick += arg
    }
    bool playerisvalid = false
    entity playertokickent = null

    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        if(p.GetPlayerName() == playertokick)
        {
            playerisvalid = true
            playertokickent = p
        }
    }

    if(playerisvalid)
    {
        printl("Kicking " + playertokick)
        ClientCommand(playertokickent, "disconnect")
    }
    else
    {
        printl("Error: Couldnt kick " + playertokick)
        return false
    }

    return true
}

bool function ClientCommand_BanPlayer(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    if( gp()[0].GetPlayerName() != player.GetPlayerName())
        return false

    if(args.len() < 1)
        return false

    if(args[0] == ("[Host]"))
        return false

    string playertoban

    foreach(int i, arg in args)
    {
            playertoban += arg
    }

    bool playerisvalid = false

    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        if(p.GetPlayerName() == playertoban)
            playerisvalid = true
    }

    if(playerisvalid) {
        printl("Banned " + playertoban)
        ClientCommand(gp()[0], "sv_ban " + playertoban)
    } else {
        printl("Error: Couldnt ban " + playertoban)
        return false
    }

    return true
}

bool function ClientCommand_UpdateClient(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    UpdateServerSettings(player)

    return true
}

bool function ClientCommand_ChangeMap(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    if( gp()[0].GetPlayerName() != player.GetPlayerName())
        return false

    if(args.len() < 1)
        return false

    string map = args[0]

    PrivateMatchSettings.servermap = map;

    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        UpdateServerSettings(p)
    }

    return true
}

bool function ClientCommand_ChangeName(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    if( gp()[0].GetPlayerName() != player.GetPlayerName())
        return false

    if(args.len() < 1)
        return false

    string servername

    foreach(int i, arg in args) {
        if(i == 0)
            servername += arg
        else
            servername += " " + arg
    }

    PrivateMatchSettings.servername = servername;

    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        UpdateServerSettings(p)
    }

    return true
}

bool function ClientCommand_ChangePlaylist(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    if( gp()[0].GetPlayerName() != player.GetPlayerName())
        return false

    if(args.len() < 1)
        return false

    string playlist = args[0]

    PrivateMatchSettings.serverplaylist = playlist;

    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        UpdateServerSettings(p)
    }

    return true
}

bool function ClientCommand_ChangeVis(entity player, array<string> args)
{
    if( !IsValid( player ) )
        return false

    if( gp()[0].GetPlayerName() != player.GetPlayerName())
        return false

    if(args.len() < 1)
        return false

    string vis = args[0]

    PrivateMatchSettings.servervis = vis;

    foreach( p in GetPlayerArray() )
    {
        if( !IsValid( p ) )
            continue

        UpdateServerSettings(p)
    }

    return true
}

/////////////////////////////////////////////
//                                         //
//            General Functions            //
//                                         //
/////////////////////////////////////////////

void function StartOfPrivateMatch()
{
    thread PlayerCheck()
}

void function PlayerCheck()
{
    //Kind of a hack way to check players, but onclientdisconnect was unreliable
    bool hasclientdisconnected = false
    while(true)
    {
        //Check to see if any player in the last array saved has become invalid
        foreach( p in playerarray ) {
            if( !IsValid( p ) ) {
                //if so set bool to true and update player array
                hasclientdisconnected = true
                playerarray = GetPlayerArray()
            }
        }

        //Player/Players have become invalid, update everyones UI
        if(hasclientdisconnected) {
            foreach( p in playerarray ) {
            if( IsValid( p ) )
                Remote_CallFunction_Replay( p, "ServerCallback_PrivateMatch_UpdateUI" )
            }

            hasclientdisconnected = false
        }

        wait 1;
    }
}

void function UpdateServerSettings(entity player)
{
    //Update Server Name
    for ( int i = 0; i < PrivateMatchSettings.servername.len(); i++ ) {
        Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_BuildClientName", PrivateMatchSettings.servername[i] )
    }
    Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_SelectionUpdated", eServerUpdateSelection.NAME )

    //Update Server Map
    for ( int i = 0; i < PrivateMatchSettings.servermap.len(); i++ ) {
        Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_BuildClientMap", PrivateMatchSettings.servermap[i] )
    }
    Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_SelectionUpdated", eServerUpdateSelection.MAP )

    //Update Server Name
    for ( int i = 0; i < PrivateMatchSettings.serverplaylist.len(); i++ ) {
        Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_BuildClientPlaylist", PrivateMatchSettings.serverplaylist[i] )
    }
    Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_SelectionUpdated", eServerUpdateSelection.PLAYLIST )

    //Update Server Vis
    for ( int i = 0; i < PrivateMatchSettings.servervis.len(); i++ ) {
        Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_BuildClientVis", PrivateMatchSettings.servervis[i] )
    }
    Remote_CallFunction_NonReplay( player, "ServerCallback_PrivateMatch_SelectionUpdated", eServerUpdateSelection.VIS )
}

void function _OnPlayerConnected(entity player)
{
    //Get current server settings and update players ui
    UpdateServerSettings(player)

    //Grab the latest player array
    playerarray = GetPlayerArray()

    //Update each players ui
    foreach( p in playerarray )
    {
        if( !IsValid( p ) )
            continue

        Remote_CallFunction_Replay( p, "ServerCallback_PrivateMatch_UpdateUI" )
    }
}