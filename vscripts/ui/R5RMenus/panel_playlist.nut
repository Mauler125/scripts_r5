global function InitR5RPlaylistPanel

struct
{
	var menu
	var panel
} file

void function InitR5RPlaylistPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )
}