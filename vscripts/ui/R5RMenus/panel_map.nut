global function InitR5RMapPanel

struct
{
	var menu
	var panel
	var picture
	table<var, string> buttonmap
} file

//Maybe get these from detours?
//Can Support up to 16 maps for now
array<string> availablemaps = [ 
	"mp_rr_canyonlands_staging", 
	"mp_rr_aqueduct", 
	"mp_rr_ashs_redemption", 
	"mp_rr_canyonlands_64k_x_64k", 
	"mp_rr_canyonlands_mu1", 
	"mp_rr_canyonlands_mu1_night", 
	"mp_rr_desertlands_64k_x_64k", 
	"mp_rr_desertlands_64k_x_64k_nx"
	];

void function InitR5RMapPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Currently supports upto 16 maps
	//If needed in the future i will add pages for it
	//Just didnt think it was needed as of now
	int number_of_maps = availablemaps.len()
	if(number_of_maps > 16)
		number_of_maps = 16

	int current_row_items = 0
	int map_bg_width = 350

	for( int i=0; i < number_of_maps; i++ )
	{
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
		if(current_row_items >= 4)
		{
			map_bg_width = map_bg_width + 335
			current_row_items = 0
		}

		current_row_items++
	}

	//Set the map selection background width
	Hud_SetWidth( Hud_GetChild( file.panel, "DarkenBackground" ), map_bg_width )
}

void function SelectServerMap( var button )
{
	//printf("Debug Map Selected: " + file.buttonmap[button])
	SetSelectedServerMap(file.buttonmap[button])
}