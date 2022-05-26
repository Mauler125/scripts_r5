global function InitR5RPlaylistPanel

struct
{
	var menu
	var panel

	table<var, string> buttonplaylist
} file

//Get these from detours when amos adds it
array<string> playlists = [
	"survival_firingrange",
	"survival",
	"FallLTM",
	"custom_tdm",
	"custom_ctf",
	"tdm_gg",
	"tdm_gg_double",
	"survival_dev"
]

void function InitR5RPlaylistPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Get number of playlists
	int number_of_playlists = playlists.len()

	//Currently supports upto 18 playlists
	//Amos and I talked and will setup a page system when needed
	if(number_of_playlists > 18)
		number_of_playlists = 18

	int height = 10

	for( int i=0; i < number_of_playlists; i++ ) {
		//Get playlist name
		string playlistname
		try{
			//If playlist is in tabel then use the tables name
			playlistname = playlisttoname[playlists[i]]
		} catch(e0) {
			//If not then use original name
			playlistname = playlists[i]
		}
		//Set playlist text
		Hud_SetText( Hud_GetChild( file.panel, "PlaylistText" + i ), playlistname)

		//Set the map ui visibility to true
		Hud_SetVisible( Hud_GetChild( file.panel, "PlaylistText" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "PlaylistBtn" + i ), true )
		Hud_SetVisible( Hud_GetChild( file.panel, "PlaylistPanel" + i ), true )

		//Add the Even handler for the button
		Hud_AddEventHandler( Hud_GetChild( file.panel, "PlaylistBtn" + i ), UIE_CLICK, SelectServerPlaylist )

		//Add the button and map to a table
		file.buttonplaylist[Hud_GetChild( file.panel, "PlaylistBtn" + i )] <- playlists[i]

		//For getting panel height
		height = height + 45
	}

	//Set panels height
	Hud_SetHeight( Hud_GetChild( file.panel, "PanelBG" ), height )
}

void function SelectServerPlaylist( var button )
{
	//printf("Debug Playlist Selected: " + file.buttonplaylist[button])
	SetSelectedServerPlaylist(file.buttonplaylist[button])
}