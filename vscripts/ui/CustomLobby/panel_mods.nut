global function InitModsPanel
global function Mods_SetupUI
global function ChangeModsPanel

global enum ModPanelType
{
	MAIN_TO_INSTALLED = 0,
	MAIN_TO_BROWSE = 1,
	INSTALLED_TO_MAIN = 2,
	BROWSE_TO_MAIN = 3
}

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

void function Mods_SetupUI()
{
	SetMainModsButtonVis(true)
}

void function BackButton_Activated(var button)
{
	if( g_isInModsMenu ) {
		ChangeModsPanel(ModPanelType.BROWSE_TO_MAIN, false)
		return
	}

	if( g_isInInstalledMenu ) {
		ChangeModsPanel(ModPanelType.INSTALLED_TO_MAIN, false)
		return
	}
}

void function InstalledModsButton_Activated(var button)
{
	ChangeModsPanel(ModPanelType.MAIN_TO_BROWSE, true)
}

void function BrowseModsButton_Activated(var button)
{
	ChangeModsPanel(ModPanelType.MAIN_TO_INSTALLED, true)
}

void function ChangeModsPanel(int paneltype, bool show)
{
	switch(paneltype)
	{
		case ModPanelType.MAIN_TO_INSTALLED:
			g_isInInstalledMenu = show
			RunClientScript("DefaultToInstalledMods")	
			break;
		case ModPanelType.MAIN_TO_BROWSE:
			g_isInModsMenu = show
			RunClientScript("DefaultToBrowseMods")
			break;
		case ModPanelType.INSTALLED_TO_MAIN:
			g_isInInstalledMenu = show
			RunClientScript( "InstalledModsToDefault")
			break;
		case ModPanelType.BROWSE_TO_MAIN:
			g_isInModsMenu = show
			RunClientScript( "BrowseModsToDefault")
			break;
	}

	SetMainModsButtonVis(!show)
}

void function SetMainModsButtonVis(bool vis)
{
	Hud_SetVisible( Hud_GetChild( file.panel, "BrowseModsButton" ), vis )
	Hud_SetVisible( Hud_GetChild( file.panel, "InstalledModsButton" ), vis )
	Hud_SetVisible( Hud_GetChild( file.panel, "BackButton" ), !vis )
}