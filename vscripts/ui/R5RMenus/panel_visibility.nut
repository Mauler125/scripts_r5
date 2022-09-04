global function InitR5RVisPanel

struct
{
	var menu
	var panel
	var listPanel

	table<var, int> vis_button_table
} file

array<int> visibility = [
	eServerVisibility.OFFLINE,
	eServerVisibility.HIDDEN,
	eServerVisibility.PUBLIC
]

void function InitR5RVisPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	file.listPanel = Hud_GetChild( panel, "VisList" )

	var scrollPanel = Hud_GetChild( file.listPanel, "ScrollPanel" )

	int m_vis_count = visibility.len()

	Hud_InitGridButtons( file.listPanel, m_vis_count )

	foreach ( int id, int vis in visibility )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + id )
        var rui = Hud_GetRui( button )
	    RuiSetString( rui, "buttonText", vistoname[vis] )

		//Add the Even handler for the button
		Hud_AddEventHandler( button, UIE_CLICK, SelectServerVis )

		//Add the button and map to a table
		file.vis_button_table[button] <- vis
	}
}

void function SelectServerVis( var button )
{
	//Set selected server vis
	SetSelectedServerVis(file.vis_button_table[button])
}