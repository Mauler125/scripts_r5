global function InitR5RNews

struct
{
	var menu
    var prevPageButton
    var nextPageButton
    var activePageRui
    var lastPageRui
    
    int pages
    int activePageIndex
} file

void function InitR5RNews( var newMenuArg ) //
{
	var menu = GetMenu( "R5RNews" )
	file.menu = menu

	file.prevPageButton = Hud_GetChild( menu, "PrevPageButton" )
	HudElem_SetRuiArg( file.prevPageButton, "flipHorizontal", true )
	//Hud_AddEventHandler( file.prevPageButton, UIE_CLICK, Page_NavLeft )

	file.nextPageButton = Hud_GetChild( menu, "NextPageButton" )
	//Hud_AddEventHandler( file.nextPageButton, UIE_CLICK, Page_NavRight )

	file.lastPageRui = Hud_GetRui( Hud_GetChild( menu, "LastPage" ) )
	file.activePageRui = Hud_GetRui( Hud_GetChild( menu, "ActivePage" ) )

	SetDialog( menu, true )
	SetGamepadCursorEnabled( menu, false )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PromoDialog_OnOpen )
	//AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, PromoDialog_OnClose )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, PromoDialog_OnNavigateBack )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#B_BUTTON_CLOSE" )
}

void function PromoDialog_OnNavigateBack()
{
	CloseActiveMenu()
}

void function PromoDialog_OnOpen()
{
	file.pages = 1
	file.activePageIndex = 0

	UpdatePageRui( file.activePageRui, 0 )
	UpdatePromoButtons()
	//RegisterPageChangeInput()
}

void function UpdatePageRui( var rui, int pageIndex )
{
    RuiSetImage( rui, "imageAsset", $"rui/promo/S3_General_3" )
	RuiSetString( rui, "titleText", "R5Reloaded News" )
	RuiSetString( rui, "descText", "News stuff will be here" )
	RuiSetInt( rui, "activePageIndex", file.activePageIndex )
	RuiSetInt( rui, "pageIndex", pageIndex )
	RuiSetInt( rui, "pageCount", 1 )

	PIN_Message( "R5Reloaded News", "News stuff will be here" )
}

void function UpdatePromoButtons()
{
	if ( file.activePageIndex == 0 )
		Hud_Hide( file.prevPageButton )
	else
		Hud_Show( file.prevPageButton )

	if ( file.activePageIndex == 0 )
		Hud_Hide( file.nextPageButton )
	else
		Hud_Show( file.nextPageButton )

	var panel = Hud_GetChild( file.menu, "FooterButtons" )
	int width = 200
	Hud_SetWidth( panel, ContentScaledXAsInt( width ) )
}