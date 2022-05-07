global function InitCTFVoteMenu
global function OpenCTFVoteMenu
global function CloseCTFVoteMenu
global function UpdateVoteTimer
global function UpdateVotesUI
global function UpdateMapsForVoting
global function UpdateVotedFor
global function UpdateVotedLocation
global function SetCTFVoteMenuNextRound
global function SetCTFVotingScreen
global function SetCTFTeamWonScreen
global function UpdateVotedLocationTied

struct
{
	var menu
} file

void function OpenCTFVoteMenu()
{
	CloseAllMenus()
	AdvanceMenu( file.menu )
}

void function SetCTFTeamWonScreen(string teamwon)
{
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), false)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	for(int i = 1; i < 5; i++ ) {
		Hud_SetVisible( Hud_GetChild( file.menu, "MapVote" + i ), false )
	}

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), teamwon)

}

void function SetCTFVotingScreen()
{
	for(int i = 1; i < 5; i++ ) {
		Hud_SetVisible( Hud_GetChild( file.menu, "MapVote" + i ), true )
		Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote" + i ), true )
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "MapVote" + i )), "status", eFriendStatus.ONLINE_INGAME )
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote" + i )), "statusText", "Votes: 0")
		RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote" + i )), "presenseText", "" )
	}

	Hud_SetText(Hud_GetChild( file.menu, "TimerText2" ), "Voting Ends In")
	Hud_SetText(Hud_GetChild( file.menu, "TimerText" ), "15")

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), true)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), false )
}

void function SetCTFVoteMenuNextRound()
{
	for(int i = 1; i < 5; i++ ) {
		Hud_SetVisible( Hud_GetChild( file.menu, "MapVote" + i ), false )
	}

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), false)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), "Starting Next Round!")
}

void function UpdateMapsForVoting(string map1, string map2, string map3, string map4)
{
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote1" )), "buttonText", "" + map1 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote2" )), "buttonText", "" + map2 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote3" )), "buttonText", "" + map3 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote4" )), "buttonText", "" + map4 )
}

void function CloseCTFVoteMenu()
{
	CloseAllMenus()
}

void function UpdateVoteTimer(int timeleft)
{
	Hud_SetText(Hud_GetChild( file.menu, "TimerText" ), timeleft.tostring())
}

void function UpdateVotesUI(int map1, int map2, int map3, int map4)
{
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote1" )), "statusText", "Votes: " + map1 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote2" )), "statusText", "Votes: " + map2 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote3" )), "statusText", "Votes: " + map3 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "MapVote4" )), "statusText", "Votes: " + map4 )
}

void function UpdateVotedFor(int id)
{
	for(int i = 1; i < 5; i++ ) {
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "MapVote" + i )), "status", eFriendStatus.OFFLINE )
		Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote" + i ), false )
	}

	var rui = Hud_GetRui( Hud_GetChild( file.menu, "MapVote" + id ))
	RuiSetString( rui, "presenseText", "Voted!" )
	RuiSetInt( rui, "status", eFriendStatus.ONLINE_AWAY )
}

void function UpdateVotedLocation(string map)
{
	for(int i = 1; i < 5; i++ ) {
		Hud_SetVisible( Hud_GetChild( file.menu, "MapVote" + i ), false )
	}

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), false)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )

	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), "Next Location: " + map)
}

void function UpdateVotedLocationTied(string map)
{
	for(int i = 1; i < 5; i++ ) {
		Hud_SetVisible( Hud_GetChild( file.menu, "MapVote" + i ), false )
	}

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), true)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "TimerText" ), "Picking a random location from tied locations")
	Hud_SetText( Hud_GetChild( file.menu, "TimerText2" ), "Votes Tied!")
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), map)
}

void function InitCTFVoteMenu( var newMenuArg )
{
	var menu = GetMenu( "CTFVoteMenu" )
	file.menu = menu

	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnCTF_NavigateBack )

	AddButtonEventHandler( Hud_GetChild( menu, "MapVote1" ), UIE_CLICK, OnClickMap )
	AddButtonEventHandler( Hud_GetChild( menu, "MapVote2" ), UIE_CLICK, OnClickMap )
	AddButtonEventHandler( Hud_GetChild( menu, "MapVote3" ), UIE_CLICK, OnClickMap )
	AddButtonEventHandler( Hud_GetChild( menu, "MapVote4" ), UIE_CLICK, OnClickMap )
}

void function OnClickMap( var button )
{
	int buttonId = Hud_GetScriptID( button )
	RunClientScript("VoteForMap", buttonId )
}

void function OnCTF_NavigateBack()
{
	// gotta have NavigateBack blank so that you cant close the menu
}