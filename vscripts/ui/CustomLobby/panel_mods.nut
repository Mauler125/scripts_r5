global function InitModsPanel
global function Mods_SetupUI

struct
{
	var menu
	var panel

} file

global bool g_isInModsMenu = false

void function InitModsPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	Hud_AddEventHandler( Hud_GetChild( panel, "BrowseModsButton" ), UIE_CLICK, BrowseModsButton_Activated )
}

void function BrowseModsButton_Activated(var button)
{
	g_isInModsMenu = true
	RunClientScript("BrowesModsMoveCamera")
}

void function Mods_SetupUI()
{

}