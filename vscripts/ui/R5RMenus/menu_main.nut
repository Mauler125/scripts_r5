global function InitR5RMainMenu

struct
{
	var menu

	var titleArt
	var subtitle
	var versionDisplay
	var signedInDisplay
} file

void function InitR5RMainMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RMainMenu" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	file.titleArt = Hud_GetChild( file.menu, "TitleArt" )
	var titleArtRui = Hud_GetRui( file.titleArt )
	RuiSetImage( titleArtRui, "basicImage", $"ui/menu/title_screen/title_art" )

	file.subtitle = Hud_GetChild( file.menu, "Subtitle" )
	var subtitleRui = Hud_GetRui( file.subtitle )
	RuiSetString( subtitleRui, "subtitleText", Localize( "#SEASON_N", 3 ).toupper() )

	file.versionDisplay = Hud_GetChild( menu, "VersionDisplay" )
	file.signedInDisplay = Hud_GetChild( menu, "SignInDisplay" )
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

void function OnR5RSB_Show()
{
	int width = int( Hud_GetHeight( file.titleArt ) * 1.77777778 )
	Hud_SetWidth( file.titleArt, width )
	Hud_SetWidth( file.subtitle, width )

	Hud_SetText( file.versionDisplay, GetPublicGameVersion() )
	Hud_Show( file.versionDisplay )

	ActivatePanel( GetPanel( "R5RMainMenuPanel" ) )

	Chroma_MainMenu()
}

void function OnR5RSB_Open()
{
	
}

void function OnR5RSB_Close()
{
	HidePanel( GetPanel( "R5RMainMenuPanel" ) )
}

void function OnR5RSB_NavigateBack()
{
    OpenConfirmExitToDesktopDialog()
}