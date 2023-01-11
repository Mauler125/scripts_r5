global function InitR5RNews

struct NewsPage
{
    string title
    string desc
    asset image
}

struct
{
	var menu
    var prevPageButton
    var nextPageButton
    var activePageRui
    var lastPageRui
    
    int activePageIndex

    array<NewsPage> newspages
    
} file

const MAX_NEWS_ITEMS = 9

void function InitR5RNews( var newMenuArg ) //
{
	var menu = GetMenu( "R5RNews" )
	file.menu = menu

	file.prevPageButton = Hud_GetChild( menu, "PrevPageButton" )
	HudElem_SetRuiArg( file.prevPageButton, "flipHorizontal", true )
	Hud_AddEventHandler( file.prevPageButton, UIE_CLICK, Page_NavLeft )

	file.nextPageButton = Hud_GetChild( menu, "NextPageButton" )
	Hud_AddEventHandler( file.nextPageButton, UIE_CLICK, Page_NavRight )

	file.lastPageRui = Hud_GetRui( Hud_GetChild( menu, "LastPage" ) )
	file.activePageRui = Hud_GetRui( Hud_GetChild( menu, "ActivePage" ) )

	SetDialog( menu, true )
	SetGamepadCursorEnabled( menu, false )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PromoDialog_OnOpen )
	//AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, PromoDialog_OnClose )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, PromoDialog_OnNavigateBack )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#B_BUTTON_CLOSE" )
}

void function Page_NavRight(var button)
{
    file.activePageIndex++
    if ( file.activePageIndex > file.newspages.len() - 1 )
        file.activePageIndex = 0

    UpdatePageRui( file.activePageRui, file.activePageIndex )
}

void function Page_NavLeft(var button)
{
    file.activePageIndex--
    if ( file.activePageIndex < 0 )
        file.activePageIndex = file.newspages.len() - 1

    UpdatePageRui( file.activePageRui, file.activePageIndex )
}

void function PromoDialog_OnNavigateBack()
{
	CloseActiveMenu()
}

void function PromoDialog_OnOpen()
{
    GetR5RNews()

	file.activePageIndex = 0

	UpdatePageRui( file.activePageRui, file.activePageIndex )
	UpdatePromoButtons()
}

void function GetR5RNews()
{
    //INFO FOR LATER
    //MAX PAGES = 9

    //TEMPOARY NEWS FOR TESTING
    //WILL BE REPLACED WITH A CALL TO THE NEWS ENDPOINT
    file.newspages.clear()

    for(int i = 0; i < 5; i++)
	{
		NewsPage page
		page.title = "Temp News " + (i + 1)
		page.desc = "Temp News Description " + (i + 1)
		page.image = GetAssetFromString( $"rui/promo/S3_General_" + (i + 1).tostring() )
		file.newspages.append(page)
	}
}

void function UpdatePageRui( var rui, int pageIndex )
{
    RuiSetImage( rui, "imageAsset", file.newspages[pageIndex].image )
	RuiSetString( rui, "titleText", file.newspages[pageIndex].title )
	RuiSetString( rui, "descText", file.newspages[pageIndex].desc )
	RuiSetInt( rui, "activePageIndex", file.activePageIndex )
	RuiSetInt( rui, "pageIndex", pageIndex )
	RuiSetInt( rui, "pageCount", file.newspages.len() )

	PIN_Message( file.newspages[pageIndex].title, file.newspages[pageIndex].desc )
}

void function UpdatePromoButtons()
{
	if ( file.newspages.len() <= 1 )
    {
		Hud_Hide( file.prevPageButton )
        Hud_Hide( file.nextPageButton )
    }
	else
    {
		Hud_Show( file.prevPageButton )
        Hud_Show( file.nextPageButton )
    }

	var panel = Hud_GetChild( file.menu, "FooterButtons" )
	int width = 200
	Hud_SetWidth( panel, ContentScaledXAsInt( width ) )
}