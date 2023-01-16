global function InitModsPanel
global function Mods_SetupUI

struct
{
	var menu
	var panel

} file

void function InitModsPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )
}

void function Mods_SetupUI()
{
	
}