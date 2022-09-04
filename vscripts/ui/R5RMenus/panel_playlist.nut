global function InitR5RPlaylistPanel
global function RefreshUIPlaylists

struct
{
	var menu
	var panel
	var listPanel

	table<var, string> playlist_button_table
} file

void function InitR5RPlaylistPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	file.listPanel = Hud_GetChild( panel, "PlaylistList" )
}

table<var, void functionref(var)> WORKAROUND_PlaylistButtonToClickHandlerMap = {}
void function RefreshUIPlaylists()
{
	//Get Playlists Array
	array<string> m_vPlaylists = GetPlaylists()

	//Get Number Of Playlists
	int m_vPlaylists_count = m_vPlaylists.len()

	var scrollPanel = Hud_GetChild( file.listPanel, "ScrollPanel" )

	Hud_InitGridButtons( file.listPanel, m_vPlaylists_count )

	foreach ( int id, string playlist in m_vPlaylists )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + id )
        var rui = Hud_GetRui( button )
	    RuiSetString( rui, "buttonText", GetUIPlaylistName(playlist) )

        //If button already has a evenhandler remove it
		if ( button in file.playlist_button_table ) {
			Hud_RemoveEventHandler( button, UIE_CLICK, SelectServerPlaylist )
			delete file.playlist_button_table[button]
		}

		//Add the Even handler for the button
		Hud_AddEventHandler( button, UIE_CLICK, SelectServerPlaylist )

		//Add the button and playlist to a table
		file.playlist_button_table[button] <- playlist
	}
}

array<string> function GetPlaylists()
{
	array<string> m_vPlaylists

	//Setup available playlists array
	foreach( string playlist in GetAvailablePlaylists())
	{
		//Check playlist visibility
		if(!GetPlaylistVarBool( playlist, "visible", false ))
			continue

		//Add playlist to the array
		m_vPlaylists.append(playlist)
	}

	return m_vPlaylists
}

void function SelectServerPlaylist( var button )
{
	//Set selected server playlist
	thread SetSelectedServerPlaylist(file.playlist_button_table[button])
}