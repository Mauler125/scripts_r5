global function InitMainMenu
global function LaunchMP
global function AttemptLaunch
global function GetUserSignInState
global function UpdateSignedInState

struct
{
	var menu
	var titleArt
	var subtitle
	var versionDisplay
	var signedInDisplay
} file


void function InitMainMenu( var newMenuArg )
{
	var menu = GetMenu( "MainMenu" )
	file.menu = menu

	SetGamepadCursorEnabled( menu, false )

	AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnMainMenu_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnMainMenu_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnMainMenu_NavigateBack )

	file.titleArt = Hud_GetChild( file.menu, "TitleArt" )
	var titleArtRui = Hud_GetRui( file.titleArt )
	RuiSetImage( titleArtRui, "basicImage", $"ui/menu/title_screen/title_art" )

	file.subtitle = Hud_GetChild( file.menu, "Subtitle" )
	var subtitleRui = Hud_GetRui( file.subtitle )
	RuiSetString( subtitleRui, "subtitleText", Localize( "#SEASON_N", 3 ).toupper() )

	file.versionDisplay = Hud_GetChild( menu, "VersionDisplay" )
	file.signedInDisplay = Hud_GetChild( menu, "SignInDisplay" )
}


void function OnMainMenu_Show()
{
	//
	int width = int( Hud_GetHeight( file.titleArt ) * 1.77777778 )
	Hud_SetWidth( file.titleArt, width )
	Hud_SetWidth( file.subtitle, width )

	Hud_SetText( file.versionDisplay, GetPublicGameVersion() )
	Hud_Show( file.versionDisplay )

	ActivatePanel( GetPanel( "MainMenuPanel" ) )

	Chroma_MainMenu()
}


void function OnMainMenu_Close()
{
	HidePanel( GetPanel( "MainMenuPanel" ) )
}


void function ActivatePanel( var panel )
{
	Assert( panel != null )

	array<var> elems = GetElementsByClassname( file.menu, "MainMenuPanelClass" )
	foreach ( elem in elems )
	{
		if ( elem != panel && Hud_IsVisible( elem ) )
			HidePanel( elem )
	}

	ShowPanel( panel )
}


void function OnMainMenu_NavigateBack()
{
	if ( IsSearchingForPartyServer() )
	{
		StopSearchForPartyServer( "", Localize( "#MAINMENU_CONTINUE" ) )
		return
	}

	#if PC_PROG
		OpenConfirmExitToDesktopDialog()
	#endif // PC_PROG
}


int function GetUserSignInState()
{
	return userSignInState.SIGNED_IN
}


void function UpdateSignedInState()
{
	Hud_SetText( file.signedInDisplay, "" )
}

void function LaunchMP()
{
	uiGlobal.launching = eLaunching.MULTIPLAYER
	AttemptLaunch()
}


void function AttemptLaunch()
{
	if ( uiGlobal.launching == eLaunching.FALSE )
		return
	Assert( uiGlobal.launching == eLaunching.MULTIPLAYER ||	uiGlobal.launching == eLaunching.MULTIPLAYER_INVITE )

	const int CURRENT_INTRO_VIDEO_VERSION = 3
	if ( (GetIntroViewedVersion() < CURRENT_INTRO_VIDEO_VERSION) || (InputIsButtonDown( KEY_LSHIFT ) && InputIsButtonDown( KEY_LCONTROL ))  || (InputIsButtonDown( BUTTON_TRIGGER_LEFT_FULL ) && InputIsButtonDown( BUTTON_TRIGGER_RIGHT_FULL )) )
	{
		if ( GetActiveMenu() == GetMenu( "PlayVideoMenu" ) )
			return

		if ( IsDialog( GetActiveMenu() ) )
			CloseActiveMenu( true )

		SetIntroViewedVersion( CURRENT_INTRO_VIDEO_VERSION )
		PlayVideoMenu( true, "intro", "Apex_Opening_Movie", eVideoSkipRule.HOLD, PrelaunchValidateAndLaunch )
		return
	}

	StartSearchForPartyServer()

	uiGlobal.launching = eLaunching.FALSE
}