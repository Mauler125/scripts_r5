global function InitReportPlayerDialog
global function InitReportReasonPopup
global function ClientToUI_ShowReportPlayerDialog

struct {
	var menu
	var reportReasonButton

	var reportReasonMenu

	var reportReasonPopup
	var reportReasonList

	var closeButton

	table<var, string> buttonToReason

	string selectedReportReason = ""

	string reportPlayerName = ""
	string reportPlayerHardware = ""
	string reportPlayerUID = ""
	string friendlyOrEnemy = "friendly"
} file

void function InitReportPlayerDialog()
{
	var menu = GetMenu( "ReportPlayerDialog" )
	file.menu = menu

	file.reportReasonButton = Hud_GetChild( menu, "ReportReasonButton" )
	Hud_AddEventHandler( file.reportReasonButton, UIE_CLICK, ReportReasonButton_OnActivate )

	var panel = Hud_GetChild( file.menu, "FooterButtons" )

	//

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, ReportPlayerDialog_OnOpen )

	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_REPORT", "#A_BUTTON_REPORT", ReportPlayerDialog_Yes )
	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CANCEL", "#B_BUTTON_CANCEL", ReportPlayerDialog_No )

	//
	//
}


void function ClientToUI_ShowReportPlayerDialog( string playerName, string playerHardware, string playerUID, string friendlyOrEnemy )
{
	file.friendlyOrEnemy = friendlyOrEnemy
	file.reportPlayerName = playerName
	file.reportPlayerHardware = playerHardware
	file.reportPlayerUID = playerUID

	int ver = GetCurrentPlaylistVarInt( "enable_report", 0 )
	#if(CONSOLE_PROG)
		ver = minint( ver, 1 )
	#endif

	if ( ver == 1 )
		ShowPlayerProfileCardForUID( file.reportPlayerUID )
	else if ( ver == 2 )
		AdvanceMenu( GetMenu( "ReportPlayerDialog" ) )
}


void function ReportPlayerDialog_OnOpen()
{
	var contentRui = Hud_GetRui( Hud_GetChild( file.menu, "ContentRui" ) )
	RuiSetString( contentRui, "headerText", "#REPORT_PLAYER" )
	RuiSetString( contentRui, "messageText", file.reportPlayerName )

	Hud_SetVisible( file.reportReasonButton, GetReportReasons( file.friendlyOrEnemy ).len() > 0 )

	HudElem_SetRuiArg( file.reportReasonButton, "buttonText", Localize( "#SELECT_REPORT_REASON" ) )
	file.selectedReportReason = ""
}


void function ReportPlayerDialog_Yes( var button )
{
	#if(PC_PROG)
		string pcOrConsole = "pc"
	#else
		string pcOrConsole = "console"
	#endif

	if ( file.selectedReportReason != "" )
	{
		if ( IsFullyConnected() )
			ClientCommand( "ReportPlayer " + file.reportPlayerHardware + " " + file.reportPlayerUID + " " + file.selectedReportReason )

		CloseAllToTargetMenu( file.menu )
		CloseActiveMenu()
	}

}

void function ReportPlayerDialog_No( var button )
{
	CloseAllToTargetMenu( file.menu )
	CloseActiveMenu()
}


void function ReportReasonButton_OnActivate( var button )
{
	AdvanceMenu( GetMenu( "ReportPlayerReasonPopup" ) )
	Hud_SetSelected( file.reportReasonButton, true )
}

array<string> function GetReportReasons( string friendlyOrEnemy )
{
	array<string> prefixes
	array<string> reportReasons = []

	#if(PC_PROG)
		prefixes.append( "report_player_reason_pc_" + friendlyOrEnemy + "_" )
	#else
		prefixes.append( "report_player_reason_console_" + friendlyOrEnemy + "_" )
	#endif

	foreach ( playlistVarPrefix in prefixes )
	{
		int numReasons = GetCurrentPlaylistVarInt( playlistVarPrefix + "count", 0 )
		for ( int index = 0; index < numReasons; index++ )
		{
			reportReasons.append( GetCurrentPlaylistVarString( playlistVarPrefix + (index + 1), "#UNAVAILABLE" ) )
		}
	}

	return reportReasons
}


void function InitReportReasonPopup()
{
	var reportReasonMenu = GetMenu( "ReportPlayerReasonPopup" )
	file.reportReasonMenu = reportReasonMenu

	SetPopup( reportReasonMenu, true )

	file.reportReasonPopup = Hud_GetChild( reportReasonMenu, "ReportReasonPopup" )
	AddMenuEventHandler( reportReasonMenu, eUIEvent.MENU_OPEN, OnOpenReportPlayerDialog )
	AddMenuEventHandler( reportReasonMenu, eUIEvent.MENU_CLOSE, OnCloseReportPlayerDialog )

	file.reportReasonList = Hud_GetChild( file.reportReasonPopup, "ReportReasonList" )

	file.closeButton = Hud_GetChild( reportReasonMenu, "CloseButton" )
	Hud_AddEventHandler( file.closeButton, UIE_CLICK, OnCloseButton_Activate )
}


void function OnCloseButton_Activate( var button )
{
	CloseAllToTargetMenu( file.menu )
	Hud_SetSelected( file.reportReasonButton, false )
}

void function OnOpenReportPlayerDialog()
{
	//
	foreach ( button, playlistName in file.buttonToReason )
	{
		Hud_RemoveEventHandler( button, UIE_CLICK, OnReasonButton_Activate )
	}
	file.buttonToReason.clear()
	//

	var ownerButton = file.reportReasonButton

	UIPos ownerPos   = REPLACEHud_GetAbsPos( ownerButton )
	UISize ownerSize = REPLACEHud_GetSize( ownerButton )

	array<string> reasons = GetReportReasons( file.friendlyOrEnemy )

	if ( reasons.len() == 0 )
		return

	Hud_Show( file.reportReasonButton )

	Hud_InitGridButtons( file.reportReasonList, reasons.len() )
	var scrollPanel = Hud_GetChild( file.reportReasonList, "ScrollPanel" )
	for ( int i = 0; i < reasons.len(); i++ )
	{
		var button = Hud_GetChild( scrollPanel, ("GridButton" + i) )
		if ( i == 0 )
		{
			int popupHeight = (Hud_GetHeight( button ) * reasons.len())
			Hud_SetPos( file.reportReasonPopup, ownerPos.x, ownerPos.y/**/)
			Hud_SetSize( file.reportReasonPopup, ownerSize.width, popupHeight )
			Hud_SetSize( file.reportReasonList, ownerSize.width, popupHeight )

			if ( GetDpadNavigationActive() )
			{
				Hud_SetFocused( button )
				Hud_SetSelected( button, true )
			}
		}

		ReasonButton_Init( button, reasons[i] )
	}
}


void function OnCloseReportPlayerDialog()
{
	Hud_SetSelected( file.reportReasonButton, false )

	if ( GetDpadNavigationActive() )
		Hud_SetFocused( file.reportReasonButton )
}


void function ReasonButton_Init( var button, string reason )
{
	Assert( Hud_GetWidth( file.reportReasonButton ) == Hud_GetWidth( button ), "" + Hud_GetWidth( file.reportReasonButton ) + " != " + Hud_GetWidth( button ) )

	InitButtonRCP( button )
	var rui = Hud_GetRui( button )

	RuiSetString( rui, "buttonText", Localize( reason ) )

	Hud_AddEventHandler( button, UIE_CLICK, OnReasonButton_Activate )
	file.buttonToReason[button] <- reason
}


void function OnReasonButton_Activate( var button )
{
	file.selectedReportReason = file.buttonToReason[button]
	HudElem_SetRuiArg( file.reportReasonButton, "buttonText", Localize( file.selectedReportReason ) )
	Hud_SetSelected( file.reportReasonButton, false )

	CloseAllToTargetMenu( file.menu )
}
