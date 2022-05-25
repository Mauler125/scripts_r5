global function InitR5RMapPanel

struct
{
	var menu
	var panel

	table<var, string> buttonmap
} file

void function InitR5RMapPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Get all available maps
	array<string> allmaps = GetAvailableMaps()
	array<string> availablemaps

	//Setup available maps array
	foreach( string map in allmaps)
	{
		//If is a lobby map dont add
		if(!IsValidMap(map))
			continue

		//Add map to the array
		availablemaps.append(map)
	}

	//Get number of maps
	int number_of_maps = availablemaps.len()

	//Currently supports upto 16 maps
	//Amos and I talked and will setup a page system for maps when needed
	if(number_of_maps > 16)
		number_of_maps = 16

	int current_row_items = 0
	int map_bg_width = 350

	for( int i=0; i < number_of_maps; i++ ) {
		//Try catch was the best way i found for if the map isnt found in the table then it will just set the map name text ui
		try {
			Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), maptoname[availablemaps[i]])
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "MapImg" + i ) ), "loadscreenImage", maptoasset[availablemaps[i]] )
		} catch(e1) {
			Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), availablemaps[i])
		}

		//Set the map ui visibility to true
		Hud_SetVisible( Hud_GetChild( file.panel, "MapText" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapImg" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapBtn" + i ), true )

		//Add the Even handler for the button
		Hud_AddEventHandler( Hud_GetChild( file.panel, "MapBtn" + i ), UIE_CLICK, SelectServerMap )

		//Add the button and map to a table
		file.buttonmap[Hud_GetChild( file.panel, "MapBtn" + i )] <- availablemaps[i]

		//For calculating map selection background width
		if(current_row_items > 3)
		{
			map_bg_width = map_bg_width + 335
			current_row_items = 0
		}

		current_row_items++
	}

	//Set the map selection background width
	Hud_SetWidth( Hud_GetChild( file.panel, "DarkenBackground" ), map_bg_width )
}

bool function IsValidMap(string map)
{
	if( map == "mp_lobby" || map == "mp_npe")
		return false

	return true
}

void function SelectServerMap( var button )
{
	//printf("Debug Map Selected: " + file.buttonmap[button])
	SetSelectedServerMap(file.buttonmap[button])
}