global function InitModsPanel
global function Mods_SetupUI
global function ReShowModsButtons

struct
{
	var menu
	var panel

} file

global bool g_isInModsMenu = false
global bool g_isInInstalledMenu = false

void function InitModsPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	Hud_AddEventHandler( Hud_GetChild( panel, "BrowseModsButton" ), UIE_CLICK, BrowseModsButton_Activated )
	Hud_AddEventHandler( Hud_GetChild( panel, "InstalledModsButton" ), UIE_CLICK, InstalledModsButton_Activated )
	Hud_AddEventHandler( Hud_GetChild( panel, "BackButton" ), UIE_CLICK, BackButton_Activated )

	Hud_SetX( Hud_GetChild( panel, "BrowseModsButton" ), -(Hud_GetWidth(Hud_GetChild( panel, "BrowseModsButton" ))/2) + 7.5 )
}

void function BackButton_Activated(var button)
{
	if( g_isInModsMenu )
	{
		g_isInModsMenu = false
		RunClientScript("BrowseModsToDefault")
		ReShowModsButtons()
	}
	else if( g_isInInstalledMenu )
	{
		g_isInInstalledMenu = false
		RunClientScript("InstalledModsToDefault")
		ReShowModsButtons()
	}
	else
	{
		ReShowModsButtons()
	}
}

void function InstalledModsButton_Activated(var button)
{
	g_isInModsMenu = true
	RunClientScript("DefaultToBrowseMods")

	Hud_SetVisible( Hud_GetChild( file.panel, "BrowseModsButton" ), false )
	Hud_SetVisible( Hud_GetChild( file.panel, "InstalledModsButton" ), false )
	Hud_SetVisible( Hud_GetChild( file.panel, "BackButton" ), true )
}

void function BrowseModsButton_Activated(var button)
{
	g_isInInstalledMenu = true
	RunClientScript("DefaultToInstalledMods")

	Hud_SetVisible( Hud_GetChild( file.panel, "BrowseModsButton" ), false )
	Hud_SetVisible( Hud_GetChild( file.panel, "InstalledModsButton" ), false )
	Hud_SetVisible( Hud_GetChild( file.panel, "BackButton" ), true )
}

void function ReShowModsButtons()
{
	Hud_SetVisible( Hud_GetChild( file.panel, "BrowseModsButton" ), true )
	Hud_SetVisible( Hud_GetChild( file.panel, "InstalledModsButton" ), true )
	Hud_SetVisible( Hud_GetChild( file.panel, "BackButton" ), false )
}

void function Mods_SetupUI()
{
	Hud_SetVisible( Hud_GetChild( file.panel, "BrowseModsButton" ), true )
	Hud_SetVisible( Hud_GetChild( file.panel, "InstalledModsButton" ), true )
	Hud_SetVisible( Hud_GetChild( file.panel, "BackButton" ), false )
}