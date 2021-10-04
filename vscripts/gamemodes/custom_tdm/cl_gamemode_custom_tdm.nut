global function Cl_CustomTDM_Init

global function ServerCallback_TDM_DoAnnouncement
global function ServerCallback_TDM_SetSelectedLocation
global function ServerCallback_TDM_DoLocationIntroCutscene
global function ServerCallback_TDM_PlayerKilled
global function ServerCallback_ShowChat
global function ServerCallback_BuildClientMessage

global function Cl_RegisterLocation

const int WRAP_BREAK_COUNT = 63
const int MAX_CHAT_LINE_COUNT = 6

global int currentChatLine = 0
global string currentChat = ""
global string clientMessageString

struct {

    LocationSettings &selectedLocation
    array choices
    array<LocationSettings> locationSettings
    var chatRui
	var chatOverFlowRui
    var scoreRui
} file;

bool isFuncRegister = false
bool isChatOverFlowRui = false

//Add Chat Handler
void function ChatEvent_Handler()
{
	while(true)
	{
		if(isChatShow && !isFuncRegister)
		{
			RegisterButtonPressedCallback(KEY_ENTER, SendChat);
			isFuncRegister = true
		}
		else if(!isChatShow && isFuncRegister)
		{
			DeregisterButtonPressedCallback(KEY_ENTER, SendChat)
			isFuncRegister = false
		}

		wait 0.5
	}
	
}

bool function IsChatOverflow(int len)
{
	if(len > WRAP_BREAK_COUNT + WRAP_BREAK_COUNT - (int(GetLocalClientPlayer().GetPlayerName().len() * 2.5) + 1))
		return true
	return false
}

void function SendChat(var button)
{
	
	var chat = HudElement( "IngameTextChat" )
	var chatTextEntry = Hud_GetChild( Hud_GetChild( chat, "ChatInputLine" ), "ChatInputTextEntry" )
	if(chatText != "" && !IsChatOverflow(chatText.len()))
	{
		string text = "say " + "\"" + chatText + "\""
		GetLocalClientPlayer().ClientCommand(text)
	}	
}

void function chatOverFlow_Handler()
{
	while(true)
	{
		if(isChatShow && IsChatOverflow(chatText.len()))
		{
			if(file.chatOverFlowRui && !isChatOverFlowRui)
			{
				RuiSetVisible( file.chatOverFlowRui, true )
				isChatOverFlowRui = true
			}
				
		}
		else
		{
			if(file.chatOverFlowRui && isChatOverFlowRui)
			{
				RuiSetVisible( file.chatOverFlowRui, false )
				isChatOverFlowRui = false
			}
				
		}

		wait 0.5
	}
}

void function Cl_CustomTDM_Init()
{
    //Add handler
    thread ChatEvent_Handler()
	thread chatOverFlow_Handler()
}

void function Cl_RegisterLocation(LocationSettings locationSettings)
{
    file.locationSettings.append(locationSettings)
}


string function MakeFlatLineText(int len)
{
	string msg = ""
	for(int i = 0; i < len ; i++)
		msg = msg + " "
	return msg
}

int function GetWrapBreakIndex(string str)
{
	int charCount = 0;

	for(int i = 0; i < WRAP_BREAK_COUNT; i++)
	{
		if(format("%d", str[i]).tointeger() > 0)
			charCount += 1;
	}

	printt("char count" + charCount);

	//calculate chinese or not
	int chineseLen = WRAP_BREAK_COUNT - charCount
	if(chineseLen % 3 != 0)
	{
		return WRAP_BREAK_COUNT + (3 - chineseLen % 3)
	}
	else
	{
		return WRAP_BREAK_COUNT
	}

	return -1
}

//make chat rui
void function MakeChatRUI(entity player, string text, float duration)
{

	string finalChat = player.GetPlayerName() + ": " + clientMessageString

	if(finalChat.len() > WRAP_BREAK_COUNT)
	{
		int sliceIndex = GetWrapBreakIndex(finalChat)
		if(sliceIndex != -1)
		{
			string origLineText = finalChat.slice(0,sliceIndex)
			string newLineText = finalChat.slice(sliceIndex)
			//Fill new line with blank
			string blank = MakeFlatLineText(int(player.GetPlayerName().len() * 2.5) + 1)

			finalChat = origLineText + "\n" + blank + newLineText + "\n"
		}
	}
	else
	{
		finalChat += "\n"
	}

	if(currentChatLine < MAX_CHAT_LINE_COUNT)
	{
		currentChat = currentChat + finalChat
	}
	else
	{
		currentChat =  finalChat
		currentChatLine = 0
	}

	currentChatLine++
	clientMessageString = ""

	if ( file.chatRui != null)
    {
		RuiSetString(file.chatRui, "messageText", currentChat)
        return
    }

    UISize screenSize = GetScreenSize()
    var screenAlignmentTopo = RuiTopology_CreatePlane( <( screenSize.width * -0.525 ),( screenSize.height * 0.0 ), 0>, <float( screenSize.width ), 0, 0>, <0, float( screenSize.height ), 0>, false )
    var rui = RuiCreate( $"ui/announcement_quick_right.rpak", screenAlignmentTopo, RUI_DRAW_HUD, RUI_SORT_SCREENFADE + 1 )

    RuiSetGameTime( rui, "startTime", Time() )

    RuiSetString( rui, "messageText", currentChat)
    RuiSetFloat( rui, "duration", duration )
	RuiSetFloat3(rui, "eventColor", <RandomFloatRange(0.0, 1.0), RandomFloatRange(0.0, 1.0), RandomFloatRange(0.0, 1.0)>)

    file.chatRui = rui

    OnThreadEnd(
		function() : ( rui )
		{
			RuiDestroy( rui )
			file.chatRui = null
		}
	)
	wait duration
}

//make chat overflow rui
void function MakeChatOverFlowRUI()
{
    if ( file.chatOverFlowRui != null)
    {
        RuiSetString( file.chatOverFlowRui, "messageText", "over the input count limit" )
		RuiSetVisible( file.chatOverFlowRui, false )
        return
    }

    UISize screenSize = GetScreenSize()
    var screenAlignmentTopo = RuiTopology_CreatePlane( <( screenSize.width * -0.3),( screenSize.height * 0.1 ), 0>, <float( screenSize.width ), 0, 0>, <0, float( screenSize.height ), 0>, false )
    var rui = RuiCreate( $"ui/announcement_quick_right.rpak", screenAlignmentTopo, RUI_DRAW_HUD, RUI_SORT_SCREENFADE + 1 )

    RuiSetGameTime( rui, "startTime", Time() )

	string msg = "over the input count limit"
    RuiSetString( rui, "messageText", msg)
    RuiSetFloat( rui, "duration", 9999999 )
    RuiSetFloat3( rui, "eventColor", SrgbToLinear( <128, 188, 255> ) )

    file.chatOverFlowRui = rui

	RuiSetVisible( file.chatOverFlowRui, false )

    OnThreadEnd(
		function() : ( rui )
		{
			RuiDestroy( rui )
			file.chatOverFlowRui = null
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
    
    RuiSetGameTime( rui, "startTime", Time() )
    RuiSetString( rui, "messageText", "Team IMC: 0  ||  Team MIL: 0" )
    RuiSetString( rui, "messageSubText", "Text 2")
    RuiSetFloat( rui, "duration", 9999999 )
    RuiSetFloat3( rui, "eventColor", SrgbToLinear( <128, 188, 255> ) )
	
    file.scoreRui = rui
    
    OnThreadEnd(
		function() : ( rui )
		{
			RuiDestroy( rui )
			file.scoreRui = null
		}
	)
    
    WaitForever()
}

void function ServerCallback_TDM_DoAnnouncement(float duration, int type)
{
    string message = ""
    string subtext = ""
    switch(type)
    {

        case eTDMAnnounce.ROUND_START:
        {
            thread MakeScoreRUI()
            thread MakeChatOverFlowRUI()
            message = "Round start"
            break
        }
        case eTDMAnnounce.VOTING_PHASE:
        {
            clGlobal.levelEnt.Signal( "CloseScoreRUI" )
            message = "Welcome To Team Deathmatch"
            subtext = "Made by sal (score UI by shrugtal)"
            break
        }
        case eTDMAnnounce.MAP_FLYOVER:
        {
            
            if(file.locationSettings.len())
                message = file.selectedLocation.name
            break
        }
    }
	AnnouncementData announcement = Announcement_Create( message )
    Announcement_SetSubText(announcement, subtext)
	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_CIRCLE_WARNING )
	Announcement_SetPurge( announcement, true )
	Announcement_SetOptionalTextArgsArray( announcement, [ "true" ] )
	Announcement_SetPriority( announcement, 200 ) //Be higher priority than Titanfall ready indicator etc
	announcement.duration = duration
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}

void function ServerCallback_TDM_DoLocationIntroCutscene()
{
    thread ServerCallback_TDM_DoLocationIntroCutscene_Body()
}

void function ServerCallback_TDM_DoLocationIntroCutscene_Body()
{
    float desiredSpawnSpeed = Deathmatch_GetIntroSpawnSpeed()
    float desiredSpawnDuration = Deathmatch_GetIntroCutsceneSpawnDuration()
    float desireNoSpawns = Deathmatch_GetIntroCutsceneNumSpawns()
    

    entity player = GetLocalClientPlayer()
    
    if(!IsValid(player)) return
    

    EmitSoundOnEntity( player, "music_skyway_04_smartpistolrun" )
     
    float playerFOV = player.GetFOV()
    
    entity camera = CreateClientSidePointCamera(file.selectedLocation.spawns[0].origin + file.selectedLocation.cinematicCameraOffset, <90, 90, 0>, 17)
    camera.SetFOV(90)

    entity cutsceneMover = CreateClientsideScriptMover($"mdl/dev/empty_model.rmdl", file.selectedLocation.spawns[0].origin + file.selectedLocation.cinematicCameraOffset, <90, 90, 0>)
    camera.SetParent(cutsceneMover)
	GetLocalClientPlayer().SetMenuCameraEntity( camera )

    ////////////////////////////////////////////////////////////////////////////////
    ///////// EFFECTIVE CUTSCENE CODE START


    array<LocPair> cutsceneSpawns
    for(int i = 0; i < desireNoSpawns; i++)
    {
        if(!cutsceneSpawns.len())
            cutsceneSpawns = clone file.selectedLocation.spawns

        LocPair spawn = cutsceneSpawns.getrandom()
        cutsceneSpawns.fastremovebyvalue(spawn)

        cutsceneMover.SetOrigin(spawn.origin)
        camera.SetAngles(spawn.angles)



        cutsceneMover.NonPhysicsMoveTo(spawn.origin + AnglesToForward(spawn.angles) * desiredSpawnDuration * desiredSpawnSpeed, desiredSpawnDuration, 0, 0)
        wait desiredSpawnDuration
    }

    ///////// EFFECTIVE CUTSCENE CODE END
    ////////////////////////////////////////////////////////////////////////////////

    GetLocalClientPlayer().ClearMenuCameraEntity()
    cutsceneMover.Destroy()

    if(IsValid(player))
    {
        FadeOutSoundOnEntity( player, "music_skyway_04_smartpistolrun", 1 )
    }
    if(IsValid(camera))
    {
        camera.Destroy()
    }
    
    
}

void function ServerCallback_TDM_SetSelectedLocation(int sel)
{
    file.selectedLocation = file.locationSettings[sel]
}

void function ServerCallback_TDM_PlayerKilled()
{
    if(file.scoreRui)
        RuiSetString( file.scoreRui, "messageText", "Team IMC: " + GameRules_GetTeamScore(TEAM_IMC) + "  ||  Team MIL: " + GameRules_GetTeamScore(TEAM_MILITIA) );
}


//chat callback
void function ServerCallback_BuildClientMessage(...)
{
	for ( int i = 0; i < vargc; i++ )
		clientMessageString += format("%c", vargv[i] )
			
}

void function ServerCallback_ShowChat(entity player)
{
    thread MakeChatRUI(player, clientMessageString, 10)
}

var function CreateTemporarySpawnRUI(entity parentEnt, float duration)
{
	var rui = AddOverheadIcon( parentEnt, RESPAWN_BEACON_ICON, false, $"ui/overhead_icon_respawn_beacon.rpak" )
	RuiSetFloat2( rui, "iconSize", <80,80,0> )
	RuiSetFloat( rui, "distanceFade", 50000 )
	RuiSetBool( rui, "adsFade", true )
	RuiSetString( rui, "hint", "SPAWN POINT" )

    wait duration

    parentEnt.Destroy()
}