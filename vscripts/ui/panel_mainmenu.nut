
global function InitMainMenuPanel
global function StartSearchForPartyServer
global function StopSearchForPartyServer
global function IsSearchingForPartyServer
global function SetLaunchState
global function PrelaunchValidateAndLaunch


global function UICodeCallback_GetOnPartyServer

const bool SPINNER_DEBUG_INFO = PC_PROG

struct
{
	var                menu
	var                panel
	var                status
	var                launchButton
	void functionref() launchButtonActivateFunc = null
	var                statusDetails
	bool               statusDetailsVisiblity = false
	//bool               autoConnect = true
	bool               working = false
	bool               searching = false
	bool               isNucleusProcessActive = false
	var				   serverSearchMessage
	var				   serverSearchError


	float startTime = 0
} file

#if SPINNER_DEBUG_INFO
void function SetSpinnerDebugInfo( string message )
{
	if ( GetConVarBool( "spinner_debug_info" ) )
	{
		Assert( file.working )
		SetLaunchState( eLaunchState.WORKING, message )
	}
}
#endif

void function InitMainMenuPanel( var panel )
{
	RegisterSignal( "EndPrelaunchValidation" )
	RegisterSignal( "EndSearchForPartyServerTimeout" )
	RegisterSignal( "SetLaunchState" )
	RegisterSignal( "MainMenu_Think" )

	file.panel = GetPanel( "MainMenuPanel" )
	file.menu = GetParentMenu( file.panel )

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, OnMainMenuPanel_Show )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, OnMainMenuPanel_Hide )

	file.launchButton = Hud_GetChild( panel, "LaunchButton" )
	Hud_AddEventHandler( file.launchButton, UIE_CLICK, LaunchButton_OnActivate )

	file.status = Hud_GetRui( Hud_GetChild( panel, "Status" ) )
	file.statusDetails = Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) )
	file.serverSearchMessage = Hud_GetChild( file.panel, "ServerSearchMessage" )
	file.serverSearchError = Hud_GetChild( file.panel, "ServerSearchError" )

	//file.autoConnect = GetConVarInt( "ui_lobby_noautostart" ) == 0 // TEMP, need code to add convar which defaults to 1

	#if PC_PROG
		AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_EXIT_TO_DESKTOP", "#B_BUTTON_EXIT_TO_DESKTOP", null, IsExitToDesktopFooterValid )
	AddPanelFooterOption( panel, LEFT, KEY_TAB, false, "", "#DATACENTER_DOWNLOADING", OpenDataCenterDialog, IsDataCenterFooterVisible, UpdateDataCenterFooter )
	#endif // PC_PROG
	AddPanelFooterOption( panel, LEFT, BUTTON_STICK_RIGHT, false, "#DATACENTER_DOWNLOADING", "", OpenDataCenterDialog, IsDataCenterFooterVisible, UpdateDataCenterFooter )
	AddPanelFooterOption( panel, LEFT, BUTTON_START, true, "#START_BUTTON_ACCESSIBLITY", "#BUTTON_ACCESSIBLITY", Accessibility_OnActivate, IsAccessibilityFooterValid )


}


#if PC_PROG
bool function IsExitToDesktopFooterValid()
{
	return !IsWorking() && !IsSearchingForPartyServer()
}
#endif // PC_PROG


bool function IsAccessibilityFooterValid()
{
	return !IsWorking() && !IsSearchingForPartyServer()
}

bool function IsDataCenterFooterVisible()
{
	return !IsWorking() && !IsSearchingForPartyServer()
}


bool function IsDataCenterFooterClickable()
{
#if R5DEV
	bool hideDurationElapsed = true
#else //
	bool hideDurationElapsed = Time() - file.startTime > 10.0
#endif //
		return !IsWorking() && !IsSearchingForPartyServer() && hideDurationElapsed
}

void function UpdateDataCenterFooter( InputDef footerData )
{
	string label = "#DATACENTER_DOWNLOADING"
	if ( !IsDatacenterMatchmakingOk() )
	{
		if ( IsSendingDatacenterPings() )
			label = Localize( "#DATACENTER_CALCULATING" )
		else
			label = Localize( label, GetDatacenterDownloadStatusCode() )
	}
	else
	{
		label = Localize( "#DATACENTER_INFO", GetDatacenterName(), GetDatacenterMinPing(), GetDatacenterPing(), GetDatacenterPacketLoss(), GetDatacenterSelectedReasonSymbol() )
		if ( IsDataCenterFooterClickable() )
			footerData.clickable = true
	}

	var elem = footerData.vguiElem
	Hud_SetText( elem, label )
	Hud_Show( elem )
}

void function OnMainMenuPanel_Show( var panel )
{
	file.startTime = Time()

	AccessibilityHintReset()
	EnterLobbySurveyReset()

	thread MainMenu_Think()

	thread PrelaunchValidation()

	ExecCurrentGamepadButtonConfig()
	ExecCurrentGamepadStickConfig()
}

void function MainMenu_Think()
{
	Signal( uiGlobal.signalDummy, "MainMenu_Think" )
	EndSignal( uiGlobal.signalDummy, "MainMenu_Think" )

	while ( true )
	{
		UpdateFooterOptions()

		WaitFrame()
	}
}


void function PrelaunchValidateAndLaunch()
{
	thread PrelaunchValidation( true )
}


void function PrelaunchValidation( bool autoContinue = false )
{
	EndSignal( uiGlobal.signalDummy, "EndPrelaunchValidation" )

	SetLaunchState( eLaunchState.WORKING )

#if SPINNER_DEBUG_INFO
	SetSpinnerDebugInfo( "PrelaunchValidation" )
#endif
	#if PC_PROG
		bool isOriginEnabled = true//Origin_IsEnabled()
		PrintLaunchDebugVal( "isOriginEnabled", isOriginEnabled )
		if ( !isOriginEnabled )
		{
			#if R5DEV
				if ( autoContinue )
					LaunchMP()
				else
					SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, "", Localize( "#MAINMENU_CONTINUE" ) )

				return
			#endif // DEV

			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#ORIGIN_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isOriginConnected = true//isOriginEnabled ? Origin_IsOnline() : true
		PrintLaunchDebugVal( "isOriginConnected", isOriginConnected )
		if ( !isOriginConnected )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#ORIGIN_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isOriginLatest = true//Origin_IsUpToDate()
		PrintLaunchDebugVal( "isOriginLatest", isOriginLatest )
		if ( !isOriginLatest )
		{
			SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#TITLE_UPDATE_AVAILABLE" ) )
			return
		}
	#endif // PC_PROG

	bool hasLatestPatch = HasLatestPatch()
	PrintLaunchDebugVal( "hasLatestPatch", hasLatestPatch )
	if ( !hasLatestPatch )
	{
		SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#TITLE_UPDATE_AVAILABLE" ) )
		return
	}

	#if PC_PROG
		bool isOriginAccountAvailable = true // ???
		PrintLaunchDebugVal( "isOriginAccountAvailable", isOriginAccountAvailable )
		if ( !isOriginAccountAvailable )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#ORIGIN_ACCOUNT_IN_USE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isOriginLoggedIn = true // ???
		PrintLaunchDebugVal( "isOriginLoggedIn", isOriginLoggedIn )
		if ( !isOriginLoggedIn )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#ORIGIN_NOT_LOGGED_IN" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isOriginAgeApproved = MeetsAgeRequirements()
		PrintLaunchDebugVal( "isOriginAgeApproved", isOriginAgeApproved )
		if ( !isOriginAgeApproved )
		{
			SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#MULTIPLAYER_AGE_RESTRICTED" ) )
			return
		}

#if SPINNER_DEBUG_INFO
		SetSpinnerDebugInfo( "isOriginReady" )
#endif
		while ( true )
		{
			bool isOriginReady = true//Origin_IsReady()
			PrintLaunchDebugVal( "isOriginReady", isOriginReady )
			if ( isOriginReady )
				break
			WaitFrame()
		}
	#endif // PC_PROG

	bool hasPermission = HasPermission()
	PrintLaunchDebugVal( "hasPermission", hasPermission )
	if ( !hasPermission )
	{
			SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#MULTIPLAYER_NOT_AVAILABLE" ) )
		return
	}

#if SPINNER_DEBUG_INFO
	SetSpinnerDebugInfo( "isAuthenticatedByStryder" )
#endif
	float startTime = Time()
	while ( true )
	{
		bool isAuthenticatedByStryder = IsStryderAuthenticated()
		//PrintLaunchDebugVal( "isAuthenticatedByStryder", isAuthenticatedByStryder )

		if ( isAuthenticatedByStryder )
			break
		if ( Time() - startTime > 10.0 )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#ORIGIN_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		WaitFrame()
	}

	bool isMPAllowedByStryder = IsStryderAllowingMP()
	PrintLaunchDebugVal( "isMPAllowedByStryder", isMPAllowedByStryder )
	if ( !isMPAllowedByStryder )
	{
		SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#MULTIPLAYER_NOT_AVAILABLE" ), Localize( "#MAINMENU_RETRY" ) )
		return
	}

	if ( autoContinue )
		LaunchMP()
	else
		SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, "", Localize( "#MAINMENU_CONTINUE" ) )
}


void function OnMainMenuPanel_Hide( var panel )
{
	Signal( uiGlobal.signalDummy, "MainMenu_Think" )
	Signal( uiGlobal.signalDummy, "EndPrelaunchValidation" )
	file.working = false
	file.searching = false
}


void function SetLaunchState( int launchState, string details = "", string prompt = "" )
{
	printt( "*** SetLaunchState *** launchState: " + GetEnumString( "eLaunchState", launchState ) + " details: \"" + details + "\" prompt: \"" + prompt + "\"" )

	if ( launchState == eLaunchState.WAIT_TO_CONTINUE )
	{
		file.launchButtonActivateFunc = PrelaunchValidateAndLaunch
		AccessibilityHint( eAccessibilityHint.LAUNCH_TO_LOBBY )
	}
	else
	{
		file.launchButtonActivateFunc = null
	}

	Hud_SetVisible( file.launchButton, launchState == eLaunchState.WAIT_TO_CONTINUE )

	RuiSetString( file.status, "prompt", prompt )
	RuiSetBool( file.status, "showPrompt", prompt != "" )

	file.working = launchState == eLaunchState.WORKING
	RuiSetBool( file.status, "showSpinner", file.working )

	thread ShowStatusMessagesAfterDelay()

	if ( details == "" )
		details = GetConVarString( "rspn_motd" )

	if ( details != "" )
		RuiSetString( file.statusDetails, "details", details )

	bool lastStatusDetailsVisiblity = file.statusDetailsVisiblity
	file.statusDetailsVisiblity = details != ""

	if ( file.statusDetailsVisiblity == true || ( file.statusDetailsVisiblity == false && lastStatusDetailsVisiblity != false ) )
	{
		RuiSetBool( file.statusDetails, "isVisible", file.statusDetailsVisiblity )
		RuiSetGameTime( file.statusDetails, "initTime", Time() )
	}

	UpdateSignedInState()
	UpdateFooterOptions()
}


void function ShowStatusMessagesAfterDelay()
{
	Signal( uiGlobal.signalDummy, "SetLaunchState" )
	EndSignal( uiGlobal.signalDummy, "SetLaunchState" )

	if ( !IsWorking() )
		return

	wait 5.0

	if ( !IsWorking() )
		return

	OnThreadEnd(
		function() : (  )
		{
			Hud_SetVisible( file.serverSearchMessage, false )
			Hud_SetVisible( file.serverSearchError, false )
		}
	)

	Hud_SetVisible( file.serverSearchMessage, true )
	Hud_SetVisible( file.serverSearchError, true )

	WaitForever()
}


bool function IsWorking()
{
	return file.working
}


void function StartSearchForPartyServer()
{
	SearchForPartyServer()
	SetLaunchState( eLaunchState.WORKING )
	file.searching = true

#if SPINNER_DEBUG_INFO
	SetSpinnerDebugInfo( "SearchForPartyServer" )
#endif

	UpdateSignedInState()
	UpdateFooterOptions()

	thread SearchForPartyServerTimeout()
}


void function SearchForPartyServerTimeout()
{
	EndSignal( uiGlobal.signalDummy, "EndSearchForPartyServerTimeout" )

	Hud_SetAutoText( file.serverSearchMessage, "", HATT_MATCHMAKING_EMPTY_SERVER_SEARCH_STATE, 0 )
	Hud_SetAutoText( file.serverSearchError, "", HATT_MATCHMAKING_EMPTY_SERVER_SEARCH_ERROR, 0 )

	string noServers              = Localize( "#MATCHMAKING_NOSERVERS" )
	string serverError            = Localize( "#MATCHMAKING_SERVERERROR" )
	string localError             = Localize( "#MATCHMAKING_LOCALERROR" )
	string lastValidSearchMessage = ""
	string lastValidSearchError   = ""
	float startTime               = Time()

	while ( Time() - startTime < 30.0 )
	{
		string searchMessage = Hud_GetUTF8Text( file.serverSearchMessage )
		string searchError = Hud_GetUTF8Text( file.serverSearchError )
		//printt( "searchMessage:", searchMessage, "searchError:", searchError )

		if ( searchMessage == noServers || searchMessage == serverError || searchMessage == localError )
		{
			lastValidSearchMessage = searchMessage
			lastValidSearchError = searchError
		}

		WaitFrame()
	}
	//printt( "lastValidSearchMessage:", lastValidSearchMessage, "lastValidSearchError:", lastValidSearchError )

	string details
	if ( (lastValidSearchMessage == serverError || lastValidSearchMessage == localError) && lastValidSearchError != "" )
		details = Localize( "#UNABLE_TO_CONNECT_ERRORCODE", lastValidSearchError )
	else
		details = Localize( "#UNABLE_TO_CONNECT" )

	thread StopSearchForPartyServer( details, Localize( "#MAINMENU_RETRY" ) )
}


void function StopSearchForPartyServer( string details, string prompt )
{
	Signal( uiGlobal.signalDummy, "EndSearchForPartyServerTimeout" )

	MatchmakingCancel()
	ClientCommand( "party_leave" )
	SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, details, prompt )
	file.searching = false

	UpdateSignedInState()
	UpdateFooterOptions()
}


bool function IsSearchingForPartyServer()
{
	return file.searching
}



void function LaunchButton_OnActivate( var button )
{
	if ( file.launchButtonActivateFunc == null )
		return

	printt( "*** LaunchButton_OnActivate ***", string( file.launchButtonActivateFunc ) )
	thread file.launchButtonActivateFunc()
}


void function UICodeCallback_GetOnPartyServer()
{
	uiGlobal.launching = eLaunching.MULTIPLAYER_INVITE
	PrelaunchValidateAndLaunch()
}


bool function IsStryderAuthenticated()
{
	return GetConVarInt( "mp_allowed" ) != -1
}


bool function IsStryderAllowingMP()
{
	return GetConVarInt( "mp_allowed" ) == 1
}


bool function HasLatestPatch()
{
	return true
}


bool function HasPermission()
{
	return true
}


void function Accessibility_OnActivate( var button )
{

	if ( IsDialog( GetActiveMenu() ) )
		return

	if ( !IsAccessibilityAvailable() )
		return

	AdvanceMenu( GetMenu( "AccessibilityDialog" ) )
}


void function OnConfirmDialogResult( int result )
{
	printt( result )
}


void function PrintLaunchDebugVal( string name, bool val )
{
	#if R5DEV
		printt( "*** PrelaunchValidation *** " + name + ": " + val )
	#endif // DEV
}