// Credits
// AyeZee#6969 -- ctf gamemode and ui
// sal#3261 -- base custom_tdm mode to work off
// Retículo Endoplasmático#5955 -- giving me the ctf sound names
// everyone else -- advice

global function Cl_CustomCTF_Init

//Server Callbacks
global function ServerCallback_CTF_DoAnnouncement
global function ServerCallback_CTF_PointCaptured
global function ServerCallback_CTF_TeamText
global function ServerCallback_CTF_FlagCaptured
global function ServerCallback_CTF_CustomMessages
global function ServerCallback_CTF_PlayerDied
global function ServerCallback_CTF_PlayerSpawning
global function ServerCallback_CTF_OpenCTFRespawnMenu
global function ServerCallback_CTF_SetSelectedLocation
global function ServerCallback_CTF_TeamWon
global function ServerCallback_CTF_SetObjectiveText
global function ServerCallback_CTF_AddPointIcon
global function ServerCallback_CTF_RecaptureFlag
global function ServerCallback_CTF_EndRecaptureFlag
global function ServerCallback_CTF_ResetFlagIcons
global function ServerCallback_CTF_SetPointIconHint
global function ServerCallback_CTF_SetCorrectTime
// Voting
global function ServerCallback_CTF_SetVoteMenuOpen
global function ServerCallback_CTF_UpdateVotingMaps
global function ServerCallback_CTF_UpdateMapVotesClient
global function ServerCallback_CTF_SetScreen

//Ui callbacks
global function UI_To_Client_VoteForMap
global function UI_To_Client_UpdateSelectedClass

global function Cl_CTFRegisterLocation
global function Cl_CTFRegisterCTFClass

struct {

    LocationSettingsCTF &selectedLocation
    array choices
    array<LocationSettingsCTF> locationSettings
    array<CTFClasses> ctfclasses
    var scoreRui
    var teamRui
} file;

var IMCpointicon = null
var MILITIApointicon = null
var FlagReturnRUI = null
bool hasvoted = false;
bool isvoting = false;
bool roundover = false

int gamestarttime
int endingtime
int seconds

entity backgroundModelSmoke
entity backgroundModelGeo
entity votecamera

entity Deathcam
entity cameraMover

array<var> teamicons

int ClassID = 0

void function Cl_CustomCTF_Init()
{
    AddClientCallback_OnResolutionChanged( UpdateTimeLeftTimer )
}

void function ServerCallback_CTF_SetCorrectTime(int serverseconds)
{
    seconds = serverseconds
}

void function UpdateTimeLeftTimer()
{
    entity player = GetLocalClientPlayer()
    player.ClientCommand("GetTimeFromServer")
}

void function Cl_CTFRegisterLocation(LocationSettingsCTF locationSettings)
{
    file.locationSettings.append(locationSettings)
}

void function Cl_CTFRegisterCTFClass(CTFClasses ctfclass)
{
    file.ctfclasses.append(ctfclass)
}

void function ServerCallback_CTF_SetSelectedLocation(int sel)
{
    file.selectedLocation = file.locationSettings[sel]
}

vector function GetDeathcamHeight()
{
    vector height
    switch(file.selectedLocation.name)
    {
        case "Relay":
            height = <0,0,6000> // Done
            break
        case "Wetlands":
            height = <0,0,7000> // Done
            break
        case "Repulsor":
            height = <0,0,7000> // Done
            break
        case "Skull Town":
            height = <0,0,7000> // Done
            break
        case "Refinery":
            height = <0,0,7000> // Done
            break
        case "Capitol City":
            height = <0,0,7000> // Done
            break
        case "Sorting Factory":
            height = <0,0,7000> // Done
            break
        default:
            height = <0,0,5000>
            break
    }

    return height
}

vector function GetDeathcamAng()
{
    vector angles
    switch(file.selectedLocation.name)
    {
        case "Firing Range":
            angles = <90,180,0>
            break
        case "Artillery":
            angles = <90,90,0> // Done
            break
        case "Airbase":
            angles = <90,0,0> // Done
            break
        case "Relay":
            angles = <90,-90,0> // Done
            break
        case "Wetlands":
            angles = <90,90,0> // Done
            break
        case "Repulsor":
            angles = <90,90,0> // Done
            break
        case "Skull Town":
            angles = <90,-45,0> // Done
            break
        case "Overlook":
            angles = <90,27,0> // Done
            break
        case "Refinery":
            angles = <90,-165,0> // Done
            break
        case "Capitol City":
            angles = <90,-85,0> // Done
            break
        case "Sorting Factory":
            angles = <90,-45,0> // Done
            break
        case "Overflow":
            angles = <90,-90,0> // Done
            break
        default:
            angles = <90,0,0> // Done
            break
    }

    return angles
}

void function ServerCallback_CTF_RecaptureFlag(int team, float starttime, float endtime)
{
    FlagReturnRUI = CreateFullscreenRui( $"ui/health_use_progress.rpak" )
    RuiSetBool( FlagReturnRUI, "isVisible", true )
	RuiSetImage( FlagReturnRUI, "icon", $"rui/hud/gametype_icons/survival/survey_beacon_only_pathfinder" )
	RuiSetGameTime( FlagReturnRUI, "startTime", starttime )
	RuiSetGameTime( FlagReturnRUI, "endTime", endtime )
    RuiSetString( FlagReturnRUI, "hintKeyboardMouse", "Returning Flag To Base" )
	RuiSetString( FlagReturnRUI, "hintController", "Returning Flag To Base" )
}

void function ServerCallback_CTF_EndRecaptureFlag()
{
    if (FlagReturnRUI != null)
    {
        try { RuiDestroy(FlagReturnRUI) } catch (pe1){ }
        FlagReturnRUI = null
    }
}

void function ServerCallback_CTF_ResetFlagIcons()
{
    try { RuiDestroy(IMCpointicon) } catch (pe1){  }
    try { RuiDestroy(MILITIApointicon) } catch (pe2){ }

    IMCpointicon = null
    MILITIApointicon = null
}

void function ServerCallback_CTF_AddPointIcon(entity imcflag, entity milflag, int team)
{
    if (team == TEAM_IMC)
    {
        if (IMCpointicon == null)
        {
            asset icon = $"rui/hud/gametype_icons/survival/survey_beacon_only_pathfinder"
            bool pinToEdge = true
            asset ruiFile = $"ui/overhead_icon_generic.rpak"

            IMCpointicon = AddCaptureIcon( imcflag, icon, pinToEdge, ruiFile)
		    RuiSetFloat2( IMCpointicon, "iconSize", <40,40,0> )
		    RuiSetFloat( IMCpointicon, "distanceFade", 100000 )
		    RuiSetBool( IMCpointicon, "adsFade", false )
		    RuiSetString( IMCpointicon, "hint", "Defend" )
        }

        if (MILITIApointicon == null)
        {
            asset icon = $"rui/hud/gametype_icons/survival/survey_beacon_only_pathfinder"
            bool pinToEdge = true
            asset ruiFile = $"ui/overhead_icon_generic.rpak"

            MILITIApointicon = AddCaptureIcon( milflag, icon, pinToEdge, ruiFile)
		    RuiSetFloat2( MILITIApointicon, "iconSize", <40,40,0> )
		    RuiSetFloat( MILITIApointicon, "distanceFade", 100000 )
		    RuiSetBool( MILITIApointicon, "adsFade", false )
		    RuiSetString( MILITIApointicon, "hint", "Capture" )
        }
    }

    if (team == TEAM_MILITIA)
    {
        if (IMCpointicon == null)
        {
            asset icon = $"rui/hud/gametype_icons/survival/survey_beacon_only_pathfinder"
            bool pinToEdge = true
            asset ruiFile = $"ui/overhead_icon_generic.rpak"

            IMCpointicon = AddCaptureIcon( imcflag, icon, pinToEdge, ruiFile)
		    RuiSetFloat2( IMCpointicon, "iconSize", <40,40,0> )
		    RuiSetFloat( IMCpointicon, "distanceFade", 100000 )
		    RuiSetBool( IMCpointicon, "adsFade", false )
		    RuiSetString( IMCpointicon, "hint", "Capture" )
        }

        if (MILITIApointicon == null)
        {
            asset icon = $"rui/hud/gametype_icons/survival/survey_beacon_only_pathfinder"
            bool pinToEdge = true
            asset ruiFile = $"ui/overhead_icon_generic.rpak"

            MILITIApointicon = AddCaptureIcon( milflag, icon, pinToEdge, ruiFile)
		    RuiSetFloat2( MILITIApointicon, "iconSize", <40,40,0> )
		    RuiSetFloat( MILITIApointicon, "distanceFade", 100000 )
		    RuiSetBool( MILITIApointicon, "adsFade", false )
		    RuiSetString( MILITIApointicon, "hint", "Defend" )
        }
    }
}

void function ServerCallback_CTF_SetPointIconHint(int teamflag, int messageid)
{
    try {

    if(teamflag == TEAM_IMC)
    {
        if(IMCpointicon == null)
            return

        if (messageid == eCTFFlag.Defend)
            RuiSetString( IMCpointicon, "hint", "Defend" )
        else if(messageid == eCTFFlag.Capture)
            RuiSetString( IMCpointicon, "hint", "Capture" )
        else if(messageid == eCTFFlag.Attack)
            RuiSetString( IMCpointicon, "hint", "Attack" )
        else if(messageid == eCTFFlag.Escort)
            RuiSetString( IMCpointicon, "hint", "Escort" )
        else if(messageid == eCTFFlag.Return)
            RuiSetString( IMCpointicon, "hint", "Return" )

    }
    else if (teamflag == TEAM_MILITIA)
    {
        if(MILITIApointicon == null)
            return

        if(messageid == eCTFFlag.Defend)
            RuiSetString( MILITIApointicon, "hint", "Defend" )
        else if(messageid == eCTFFlag.Capture)
            RuiSetString( MILITIApointicon, "hint", "Capture" )
        else if(messageid == eCTFFlag.Attack)
            RuiSetString( MILITIApointicon, "hint", "Attack" )
        else if(messageid == eCTFFlag.Escort)
            RuiSetString( MILITIApointicon, "hint", "Escort" )
        else if(messageid == eCTFFlag.Return)
            RuiSetString( MILITIApointicon, "hint", "Return" )
    }

    } catch (pe3){

    }
}

var function AddCaptureIcon( entity prop, asset icon, bool pinToEdge = true, asset ruiFile = $"ui/overhead_icon_generic.rpak" )
{
	var rui = CreateFullscreenRui( ruiFile, HUD_Z_BASE - 20 )
	RuiSetImage( rui, "icon", icon )
	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "pinToEdge", pinToEdge )
	RuiTrackFloat3( rui, "pos", prop, RUI_TRACK_OVERHEAD_FOLLOW )

    thread AddCaptureIconThread( prop, rui )
	return rui
}

void function AddCaptureIconThread( entity prop, var rui )
{
	prop.EndSignal( "OnDestroy" )

	prop.e.overheadRui = rui

	OnThreadEnd(
		function() : ( prop, rui )
		{
            if ( IsValid( rui ) )
                try { RuiDestroy( rui ) } catch (pe3){ }

			if ( IsValid( prop ) )
				prop.e.overheadRui = null
		}
	)

	WaitForever()
}

void function MakeScoreRUI()
{
    if ( file.scoreRui != null)
    {
        RuiSetString( file.scoreRui, "messageText", "Team IMC: 0  ||  Team MIL: 0" )
        return
    }
    clGlobal.levelEnt.EndSignal( "CloseScoreRUI" )

    UISize screenSize = GetScreenSize()
    var screenAlignmentTopo = RuiTopology_CreatePlane( <( screenSize.width * 0.25),( screenSize.height * 0.31 ), 0>, <float( screenSize.width ), 0, 0>, <0, float( screenSize.height ), 0>, false )
    var rui = RuiCreate( $"ui/announcement_quick_right.rpak", screenAlignmentTopo, RUI_DRAW_HUD, RUI_SORT_SCREENFADE + 1 )

    var screenAlignmentTopo2 = RuiTopology_CreatePlane( <( screenSize.width * 0.25),( screenSize.height * 0.31 ), 0>, <float( screenSize.width ), 0, 0>, <0, float( screenSize.height - 100 ), 0>, false )
    var rui2 = RuiCreate( $"ui/announcement_quick_right.rpak", screenAlignmentTopo2, RUI_DRAW_HUD, RUI_SORT_SCREENFADE + 1 )

    RuiSetGameTime( rui, "startTime", Time() )
    RuiSetString( rui, "messageText", "Team IMC: 0  ||  Team MIL: 0" )
    RuiSetFloat( rui, "duration", 9999999 )
    RuiSetFloat3( rui, "eventColor", SrgbToLinear( <128, 188, 255> ) )

    RuiSetGameTime( rui2, "startTime", Time() )
    RuiSetString( rui2, "messageText", "Team: " )
    RuiSetFloat( rui2, "duration", 9999999 )
    RuiSetFloat3( rui2, "eventColor", SrgbToLinear( <128, 188, 255> ) )

    file.scoreRui = rui
    file.teamRui = rui2

    OnThreadEnd(
		function() : ( rui, rui2 )
		{
            if ( IsValid( rui ) )
			    try { RuiDestroy( rui ) } catch (pe3){ }

            if ( IsValid( rui2 ) )
			    try { RuiDestroy( rui2 ) } catch (pe4){ }

			file.scoreRui = null
            file.teamRui = null
		}
	)

    WaitForever()
}

void function ServerCallback_CTF_DoAnnouncement(float duration, int type, float starttime)
{
    string message = ""
    string subtext = ""
    switch(type)
    {

        case eCTFAnnounce.ROUND_START:
        {
            thread MakeScoreRUI();
            //message = "Round start"
            message = "Match Start"
            subtext = "Score 5 points to win!"

            //Timer Stuff
            roundover = false
            gamestarttime = starttime.tointeger()
            endingtime = gamestarttime + CTF_ROUNDTIME
            seconds = 60
            thread StartGameTimer()
            break
        }
        case eCTFAnnounce.VOTING_PHASE:
        {
            clGlobal.levelEnt.Signal( "CloseScoreRUI" )
            break
        }
    }
	AnnouncementData announcement = Announcement_Create( message )
    Announcement_SetSubText(announcement, subtext)
	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_CIRCLE_WARNING )
	Announcement_SetPurge( announcement, true )
	Announcement_SetOptionalTextArgsArray( announcement, [ "true" ] )
	Announcement_SetPriority( announcement, 200 )
	announcement.duration = duration
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}

void function StartGameTimer()
{
    //Filler for when time is < 10
    string secondsfiller = ""
    string minsfiller = ""

	while (!roundover)
	{
        //Calculate Elapsed Time
        int elapsedtime = endingtime - Time().tointeger()

        //Calculate Seconds To Minutes
		int minutes = floor( elapsedtime / 60 ).tointeger()

        //If Seconds is < 1 Set Back To 60
        if(seconds < 1)
            seconds = 60

        //This isnt neede but is there to make the time left counter look nicer when the timer is < 10
        if(seconds < 10)
            secondsfiller = "0"
        else
            secondsfiller = ""

        //This isnt neede but is there to make the time left counter look nicer when the timer is < 10
        if(minutes < 10)
            minsfiller = "0"
        else
            minsfiller = ""

        //Update the counter on the UI
        RunUIScript("SetGameTimer", minsfiller + minutes + ":" + secondsfiller + seconds)

		wait 1
        seconds--
	}
}

void function ServerCallback_CTF_PointCaptured(int IMC, int MIL)
{
    if(file.scoreRui)
        RuiSetString( file.scoreRui, "messageText", "Team IMC: " + IMC + "  ||  Team MIL: " + MIL )

    RunUIScript("SetCTFScores", IMC, MIL, CTF_SCORE_GOAL_TO_WIN)
}

void function ServerCallback_CTF_TeamText(int team)
{
    if(file.teamRui)
    {
        switch(team)
        {
            case TEAM_IMC:
                RuiSetString( file.teamRui, "messageText", "Your Team: IMC" )
                break
            case TEAM_MILITIA:
                RuiSetString( file.teamRui, "messageText", "Your Team: MILITIA")
                break
        }
    }
}

void function ServerCallback_CTF_TeamWon(int team)
{
    AnnouncementData announcement
    switch(team)
    {
        case TEAM_IMC:
            announcement = Announcement_Create( "IMC has won the round!" )
            break
        case TEAM_MILITIA:
            announcement = Announcement_Create( "MILITIA has won the round!" )
            break
        default:
            announcement = Announcement_Create( "Couldnt decide on the winner!" )
    }

    Announcement_SetSubText(announcement, "Starting vote for next location")
	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_CIRCLE_WARNING )
	Announcement_SetPurge( announcement, true )
	Announcement_SetOptionalTextArgsArray( announcement, [ "true" ] )
	Announcement_SetPriority( announcement, 200 ) //Be higher priority than Titanfall ready indicator etc
	announcement.duration = 5
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}

void function ServerCallback_CTF_FlagCaptured(entity player, int messageid)
{
    AnnouncementData announcement

    switch(messageid)
    {
        case 0:
            announcement = Announcement_Create( "Your team has captured the enemy flag!" )
            break
        case 1:
            announcement = Announcement_Create( "Enemy team has captured your flag!" )
            break
    }

	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_SWEEP )
	Announcement_SetPurge( announcement, true )
	Announcement_SetOptionalTextArgsArray( announcement, [ "true" ] )
	Announcement_SetPriority( announcement, 200 )
	announcement.duration = 3
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}

void function ServerCallback_CTF_CustomMessages(entity player, int messageid)
{
    string message;
    if (messageid == eCTFMessage.PickedUpFlag)
    {
        message = "You picked up the flag"
    }
    else if (messageid == eCTFMessage.EnemyPickedUpFlag)
    {
        message = "Enemy team picked up your flag"
    }
    else if (messageid == eCTFMessage.TeamReturnedFlag)
    {
        message = "Your teams flag has been returned to base"
    }

    AnnouncementData announcement = CreateAnnouncementMessageQuick( player, message, "", <100, 0, 0>, $"rui/hud/gametype_icons/survival/survey_beacon_only_pathfinder" )
	Announcement_SetPurge( announcement, true )
	Announcement_SetPriority( announcement, 200 )
	announcement.duration = 3
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}

void function UI_To_Client_UpdateSelectedClass(int selectedclass)
{
    ClassID = selectedclass;

    RunUIScript("UpdateSelectedClass", ClassID, file.ctfclasses[ClassID].primary, file.ctfclasses[ClassID].secondary, file.ctfclasses[ClassID].tactical, file.ctfclasses[ClassID].ult)

    entity player = GetLocalClientPlayer()
    // why does s3 not have remote server functions..?
    player.ClientCommand("SetPlayerClass " + selectedclass)
}

void function ServerCallback_CTF_OpenCTFRespawnMenu(vector campos, int IMCscore, int MILscore, entity attacker, int selectedclassid)
{
    if(isvoting)
        return

    entity player = GetLocalClientPlayer()

    RunUIScript("OpenCTFRespawnMenu", file.ctfclasses[0].name, file.ctfclasses[1].name, file.ctfclasses[2].name, file.ctfclasses[3].name, file.ctfclasses[4].name)
    RunUIScript("UpdateSelectedClass", selectedclassid, file.ctfclasses[selectedclassid].primary, file.ctfclasses[selectedclassid].secondary, file.ctfclasses[selectedclassid].tactical, file.ctfclasses[selectedclassid].ult)

    if(attacker != null)
    {
        if (attacker == GetLocalClientPlayer())
            RunUIScript( "UpdateKillerName", "Suicide")
        else if(attacker.IsPlayer() && attacker != null)
            RunUIScript( "UpdateKillerName", attacker.GetPlayerName())
        else
            RunUIScript( "UpdateKillerName", "Mysterious Forces")
    }
    else
        RunUIScript( "UpdateKillerName", "Mysterious Forces")

    RunUIScript("SetCTFScores", IMCscore, MILscore, CTF_SCORE_GOAL_TO_WIN)

    thread UpdateUIRespawnTimer()
}

void function ServerCallback_CTF_PlayerDied(vector campos, int IMCscore, int MILscore, entity attacker)
{
    if(isvoting)
        return

    entity player = GetLocalClientPlayer()

    array<entity> players = GetPlayerArrayOfTeam( player.GetTeam() )
    foreach ( teamplayer in players )
    {
        if(teamplayer == player)
        {
            var newicon = AddCaptureIcon( teamplayer, $"rui/pilot_loadout/mods/hopup_skullpiercer", false, $"ui/overhead_icon_generic.rpak")
		    RuiSetFloat2( newicon, "iconSize", <25,25,0> )
		    RuiSetFloat( newicon, "distanceFade", 100000 )
		    RuiSetBool( newicon, "adsFade", false )
		    RuiSetString( newicon, "hint", "Death Location" )

            teamicons.append(newicon)
            continue
        }

        var newicon = AddCaptureIcon( teamplayer, $"rui/hud/gametype_icons/obj_foreground_diamond", false, $"ui/overhead_icon_generic.rpak")
		RuiSetFloat2( newicon, "iconSize", <15,15,0> )
		RuiSetFloat( newicon, "distanceFade", 100000 )
		RuiSetBool( newicon, "adsFade", false )
		RuiSetString( newicon, "hint", teamplayer.GetPlayerName() )

        teamicons.append(newicon)
    }

    cameraMover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", player.GetOrigin(), player.CameraAngles() )
    Deathcam = CreateClientSidePointCamera( player.GetOrigin(), player.CameraAngles(), 90 )
    Deathcam.SetParent( cameraMover, "", false )
    player.SetMenuCameraEntityWithAudio( Deathcam )
    Deathcam.SetTargetFOV( 90, true, EASING_CUBIC_INOUT, 0.50 )
    cameraMover.NonPhysicsMoveTo( campos + GetDeathcamHeight(), 0.60, 0, 0.30 )
    cameraMover.NonPhysicsRotateTo( GetDeathcamAng(), 0.60, 0, 0.30 )
}

void function UpdateUIRespawnTimer()
{
    int time = 10
    while(time > -1)
    {
        RunUIScript( "UpdateRespawnTimer", time)
        time--

        if (time == 1)
            RunUIScript( "DisableClassSelect")

        if(time == -1)
        {
            entity player = GetLocalClientPlayer()

            thread waitrespawn(player)
        }

        wait 1
    }
}

void function ServerCallback_CTF_PlayerSpawning()
{
    foreach ( iconvar in teamicons )
    {
        if(IsValid(iconvar))
            try { RuiDestroy(iconvar) } catch (exception2){ }
    }
}

void function ServerCallback_CTF_SetObjectiveText(int score)
{
    RunUIScript( "UpdateObjectiveText", score)
}

void function waitrespawn(entity player)
{
    try { Deathcam.ClearParent(); cameraMover.Destroy() } catch (exception){ }

    if(!isvoting)
    {
        try {
            cameraMover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", Deathcam.GetOrigin(), Deathcam.GetAngles() )
            Deathcam.SetParent( cameraMover, "", false )
            player.SetMenuCameraEntityWithAudio( Deathcam )
            cameraMover.NonPhysicsMoveTo( player.GetOrigin(), 0.40, 0, 0.20 )
            cameraMover.NonPhysicsRotateTo( player.CameraAngles(), 0.40, 0, 0.20 )
        } catch (exception2){ }

        wait 0.40

        RunUIScript( "CloseCTFRespawnMenu" )
        player.ClearMenuCameraEntity()
    }

    try { Deathcam.ClearParent(); Deathcam.Destroy(); cameraMover.Destroy() } catch (exceptio2n){ }
}

void function ServerCallback_CTF_SetVoteMenuOpen(bool shouldOpen)
{
    if( shouldOpen )
        thread CreateVotingUI()
    else
        thread DestroyVotingUI()
}

void function CreateVotingUI()
{
    hasvoted = false
    isvoting = true

    EmitSoundOnEntity( GetLocalClientPlayer(), "Music_CharacterSelect_Wattson" )
    wait 3;
    ScreenFade(GetLocalClientPlayer(), 0, 0, 0, 255, 0.4, 0.5, FFADE_OUT | FFADE_PURGE)
    wait 0.9;

    roundover = true

    entity targetBackground = GetEntByScriptName( "target_char_sel_bg_new" )
    entity targetCamera = GetEntByScriptName( "target_char_sel_camera_new" )

	backgroundModelGeo = CreateClientSidePropDynamic( targetBackground.GetOrigin() - <0, 0, 24>, targetBackground.GetAngles(), $"mdl/levels_terrain/mp_lobby/mp_character_select_geo.rmdl" )
	backgroundModelGeo.kv.solid = 0
	backgroundModelGeo.kv.disableshadows = 1
	backgroundModelGeo.kv.fadedist = -1
	backgroundModelGeo.MakeSafeForUIScriptHack()

	backgroundModelSmoke = CreateClientSidePropDynamic( targetBackground.GetOrigin() - <0, 0, 24>, targetBackground.GetAngles(), $"mdl/levels_terrain/mp_lobby/mp_character_select_smoke.rmdl" )
	backgroundModelSmoke.kv.solid = 0
	backgroundModelSmoke.kv.disableshadows = 1
	backgroundModelSmoke.kv.fadedist = -1
	backgroundModelSmoke.MakeSafeForUIScriptHack()

    backgroundModelGeo.SetSkin( 3 )
    backgroundModelSmoke.SetSkin( 3 )

    vector cameraOrigin = targetCamera.GetOrigin()
    votecamera = CreateClientSidePointCamera( cameraOrigin, targetCamera.GetAngles(), 35.5 )

    GetLocalClientPlayer().SetMenuCameraEntity( votecamera )
	votecamera.SetTargetFOV( 35.5, true, EASING_CUBIC_INOUT, 0.25 )

    RunUIScript( "OpenCTFVoteMenu" )

    ScreenFade(GetLocalClientPlayer(), 0, 0, 0, 255, 0.3, 0.0, FFADE_IN | FFADE_PURGE)
}

void function DestroyVotingUI()
{
    FadeOutSoundOnEntity( GetLocalClientPlayer(), "Music_CharacterSelect_Wattson", 0.2 )
    ScreenFade(GetLocalClientPlayer(), 0, 0, 0, 255, 0.4, 1, FFADE_OUT | FFADE_PURGE)
    wait 1;

    if ( IsValid( backgroundModelSmoke ) )
		backgroundModelSmoke.Destroy()
	if ( IsValid( backgroundModelGeo ) )
		backgroundModelGeo.Destroy()
    if ( IsValid( votecamera ) )
		votecamera.Destroy()

    GetLocalClientPlayer().ClearMenuCameraEntity()

    RunUIScript( "CloseCTFVoteMenu" )
    isvoting = false

    ScreenFade(GetLocalClientPlayer(), 0, 0, 0, 255, 0.3, 0.5, FFADE_IN | FFADE_PURGE)
}

void function UpdateUIVoteTimer()
{
    int time = 15
    while(time > -1)
    {
        RunUIScript( "UpdateVoteTimer", time)

        if (time <= 5 && time != 0)
            EmitSoundOnEntity( GetLocalClientPlayer(), "ui_ingame_markedfordeath_countdowntomarked" )

        if (time == 0)
            EmitSoundOnEntity( GetLocalClientPlayer(), "ui_ingame_markedfordeath_countdowntoyouaremarked" )

        time--

        wait 1
    }
}

void function UI_To_Client_VoteForMap(int mapid)
{
    if(hasvoted)
        return

    entity player = GetLocalClientPlayer()

    // why does s3 not have remote server functions..?
    player.ClientCommand("VoteForMap " + mapid)
    RunUIScript("UpdateVotedFor", mapid + 1)

    hasvoted = true
}

void function ServerCallback_CTF_UpdateMapVotesClient( int map1votes, int map2votes, int map3votes, int map4votes)
{
    RunUIScript("UpdateVotesUI", map1votes, map2votes, map3votes, map4votes)
}

void function ServerCallback_CTF_UpdateVotingMaps( int map1, int map2, int map3, int map4)
{
    RunUIScript("UpdateMapsForVoting", file.locationSettings[map1].name, file.locationSettings[map2].name, file.locationSettings[map3].name, file.locationSettings[map4].name)
}

void function ServerCallback_CTF_SetScreen(int screen, int team, int mapid, int done)
{
    switch(screen)
    {
        case eCTFScreen.WinnerScreen: //Sets the screen to the winners screen
            RunUIScript("SetCTFTeamWonScreen", GetWinningTeamText(team))
            break

        case eCTFScreen.VoteScreen: //Sets the screen to the vote screen
            EmitSoundOnEntity( GetLocalClientPlayer(), "UI_PostGame_CoinMove" )
            thread UpdateUIVoteTimer()
            RunUIScript("SetCTFVotingScreen")
            break

        case eCTFScreen.TiedScreen: //Sets the screen to the tied screen
            switch(done)
            {
            case 0:
                EmitSoundOnEntity( GetLocalClientPlayer(), "HUD_match_start_timer_tick_1P" )
                break
            case 1:
                EmitSoundOnEntity( GetLocalClientPlayer(),  "UI_PostGame_CoinMove" )
                break
            }

            if (mapid == 254)
                RunUIScript( "UpdateVotedLocationTied", "")
            else
                RunUIScript( "UpdateVotedLocationTied", file.locationSettings[mapid].name)
            break

        case eCTFScreen.SelectedScreen: //Sets the screen to the selected location screen
            EmitSoundOnEntity( GetLocalClientPlayer(), "UI_PostGame_Level_Up_Pilot" )
            RunUIScript( "UpdateVotedLocation", file.locationSettings[mapid].name)
            break

        case eCTFScreen.NextRoundScreen: //Sets the screen to the next round screen
            EmitSoundOnEntity( GetLocalClientPlayer(), "UI_PostGame_Level_Up_Pilot" )
            FadeOutSoundOnEntity( GetLocalClientPlayer(), "Music_CharacterSelect_Wattson", 0.2 )
            RunUIScript("SetCTFVoteMenuNextRound")
            break
    }
}

string function GetWinningTeamText(int team)
{
    string teamwon = ""
    switch(team)
    {
        case TEAM_IMC:
            teamwon = "IMC has won"
            break
        case TEAM_MILITIA:
            teamwon = "MILITIA has won"
            break
        case 69:
            teamwon = "Winner couldn't be decided"
            break
    }

    return teamwon
}

