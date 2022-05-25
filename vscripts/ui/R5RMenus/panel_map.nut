global function InitR5RMapPanel

struct
{
	var menu
	var panel
	var picture
	table<var, string> buttonmap
} file

//Maybe get these from detours?
//Can Support up to 12 maps
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

	int i = 0
	int items = 0
	int width = 350

	foreach ( string map in availablemaps )
	{
		//Try catch was the best way i found for if the map isnt found in the table then it will just set the map name text ui
		try {
			Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), maptoname[map])
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "MapImg" + i ) ), "loadscreenImage", maptoasset[map] )
		} catch(e1) {
			Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), map)
		}

		//Set the map ui visibility to true
		Hud_SetVisible( Hud_GetChild( file.panel, "MapText" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapImg" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapBtn" + i ), true )

		//Add the Even handler for the button
		Hud_AddEventHandler( Hud_GetChild( file.panel, "MapBtn" + i ), UIE_CLICK, SelectServerMap )

		//Add the button and map to a table
		file.buttonmap[Hud_GetChild( file.panel, "MapBtn" + i )] <- map

		//For calculating map selection background width
		if(items >= 4)
		{
			width = width + 335
			items = 0
		}

		items++
		i++
	}

	//Set the map selection background width
	Hud_SetWidth( Hud_GetChild( file.panel, "DarkenBackground" ), width )
}

void function SelectServerMap( var button )
{
	printf("Debug Map Selected: " + file.buttonmap[button])
	SetSelectedServerMap(file.buttonmap[button])
}