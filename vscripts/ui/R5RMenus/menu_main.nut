global function InitR5RMainMenu

struct
{
	var menu
	array<var> buttons

	var HomePanel
	var CreateServerPanel
	var ServerBrowserPanel
} file

void function InitR5RMainMenu( var newMenuArg )
{
	var menu = GetMenu( "R5RMainMenu" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	var Home = Hud_GetChild(menu, "HomeBtn")
	var CreateServer = Hud_GetChild(menu, "CreateServerBtn")
	var ServerBrowser = Hud_GetChild(menu, "ServerBrowserBtn")
	var Settings = Hud_GetChild(menu, "SettingsBtn")
	var Quit = Hud_GetChild(menu, "QuitBtn")

	file.HomePanel = Hud_GetChild(menu, "R5RHomePanel")
	file.CreateServerPanel = Hud_GetChild(menu, "R5RCreateServerPanel")
	file.ServerBrowserPanel = Hud_GetChild(menu, "R5RServerBrowserPanel")

	file.buttons.append(Home)
	file.buttons.append(CreateServer)
	file.buttons.append(ServerBrowser)

	Hud_AddEventHandler( Home, UIE_CLICK, HomePressed )
	Hud_AddEventHandler( CreateServer, UIE_CLICK, CreateServerPressed )
	Hud_AddEventHandler( ServerBrowser, UIE_CLICK, ServerBrowserPressed )
	Hud_AddEventHandler( Settings, UIE_CLICK, SettingsPressed )
	Hud_AddEventHandler( Quit, UIE_CLICK, QuitPressed )

	RuiSetString( Hud_GetRui( Home ), "buttonText", "Home" )
	RuiSetString( Hud_GetRui( CreateServer ), "buttonText", "Create Server" )
	RuiSetString( Hud_GetRui( ServerBrowser ), "buttonText", "Server Browser" )
	RuiSetString( Hud_GetRui( Settings ), "buttonText", "Settings" )
	RuiSetString( Hud_GetRui( Quit ), "buttonText", "Quit" )

	ClientCommand("pak_requestload common_r5r.rpak")
}

void function HomePressed(var button)
{
	SetSelectedButton(button)

	Hud_SetVisible( file.HomePanel, true )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, false )
}

void function CreateServerPressed(var button)
{
	SetSelectedButton(button)

	Hud_SetVisible( file.HomePanel, false )
	Hud_SetVisible( file.CreateServerPanel, true )
	Hud_SetVisible( file.ServerBrowserPanel, false )
}

void function ServerBrowserPressed(var button)
{
	SetSelectedButton(button)

	Hud_SetVisible( file.HomePanel, false )
	Hud_SetVisible( file.CreateServerPanel, false )
	Hud_SetVisible( file.ServerBrowserPanel, true )
}

void function SettingsPressed(var button)
{
	AdvanceMenu( GetMenu( "MiscMenu" ) )
}

void function QuitPressed(var button)
{
	
}

void function SetSelectedButton(var button)
{
	foreach ( btn in file.buttons )
	{
		RuiSetBool( Hud_GetRui( btn ) ,"isSelected", false )
	}

	RuiSetBool( Hud_GetRui( button ) ,"isSelected", true )
}

void function OnR5RSB_Show()
{
    //
}

void function OnR5RSB_Open()
{
	//
}

void function OnR5RSB_Close()
{
	//
}

void function OnR5RSB_NavigateBack()
{
    //
}