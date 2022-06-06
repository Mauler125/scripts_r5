global function InitR5RMapPanel
global function RefreshUIMaps

struct
{
	var menu
	var panel

	table<var, string> map_button_table
} file

void function InitR5RMapPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )
}

void function RefreshUIMaps()
{
	//Reset all map ui
	ResetMapsUI()

	//Get maps array
	array<string> availablemaps = GetPlaylistMaps(ServerSettings.playlist)

	//Get number of maps
	int number_of_maps = availablemaps.len()

	//Currently supports upto 16 maps
	//Amos and I talked and will setup a page system for maps when needed
	//Also note that all maps wont always be showed depending on the playlist
	if(number_of_maps > 16)
		number_of_maps = 16
	
	for( int i=0; i < number_of_maps; i++ ) {
		//Set Map Text
		Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), GetUIMapName(availablemaps[i]))

		//Set Map Asset
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "MapImg" + i ) ), "loadscreenImage", GetUIMapAsset(availablemaps[i]) )

		//Set the map ui visibility to true
		Hud_SetVisible( Hud_GetChild( file.panel, "MapText" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapImg" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapBtn" + i ), true )

		//If button already has a evenhandler remove it
		var button = Hud_GetChild( file.panel, "MapBtn" + i )
		if ( button in file.map_button_table ) {
			Hud_RemoveEventHandler( button, UIE_CLICK, SelectServerMap )
			delete file.map_button_table[button]
		}

		//Add the Even handler for the button
		Hud_AddEventHandler( Hud_GetChild( file.panel, "MapBtn" + i ), UIE_CLICK, SelectServerMap )

		//Add the button and map to a table
		file.map_button_table[Hud_GetChild( file.panel, "MapBtn" + i )] <- availablemaps[i]
	}
}

void function ResetMapsUI()
{
	//Reset all map ui
	for( int i=0; i < 16; i++ ) {
		Hud_SetText( Hud_GetChild( file.panel, "MapText" + i ), "")
		RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "MapImg" + i ) ), "loadscreenImage", $"" )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapText" + i ), false )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapImg" + i ), false )
		Hud_SetVisible( Hud_GetChild( file.panel, "MapBtn" + i ), false )
	}
}

void function SelectServerMap( var button )
{
	//Set selected server map
	SetSelectedServerMap(file.map_button_table[button])
}