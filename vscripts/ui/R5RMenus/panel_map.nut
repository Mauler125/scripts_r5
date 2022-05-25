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

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, Map_OnShow )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, Map_OnHide )

	int i = 0
	int items = 0
	int width = 350
	foreach ( string map in availablemaps )
	{
		Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), maptoname[map])
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "MapImg" + i ) ), "loadscreenImage", maptoasset[map] )

		Hud_SetVisible( Hud_GetChild( file.panel, "MapText" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapImg" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapBtn" + i ), true )

		Hud_AddEventHandler( Hud_GetChild( file.panel, "MapBtn" + i ), UIE_CLICK, SelectServerMap )

		file.buttonmap[Hud_GetChild( file.panel, "MapBtn" + i )] <- map

		if(items >= 4)
		{
			width = width + 335
			items = 0
		}

		items++
		i++
	}

	Hud_SetWidth( Hud_GetChild( file.panel, "DarkenBackground" ), width )

}

void function SelectServerMap( var button )
{
	printf("Debug Map Selected: " + file.buttonmap[button])
	SetSelectedServerMap(file.buttonmap[button])
}

void function Map_OnShow( var panel )
{
	
}

void function Map_OnHide( var panel )
{
	
}