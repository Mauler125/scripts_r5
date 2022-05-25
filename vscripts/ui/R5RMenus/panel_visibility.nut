global function InitR5RVisPanel

struct
{
	var menu
	var panel
} file

void function InitR5RVisPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )
}