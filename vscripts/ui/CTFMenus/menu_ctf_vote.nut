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

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), teamwon)

}

void function SetCTFVotingScreen()
{
	var rui = Hud_GetRui( Hud_GetChild( file.menu, "MapVote1" ))
	RuiSetString( rui, "statusText", "Votes: 0" )
	RuiSetString( rui, "presenseText", "" )

	var rui2 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote2" ))
	RuiSetString( rui2, "statusText", "Votes: 0" )
	RuiSetString( rui2, "presenseText", "" )

	var rui3 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote3" ))
	RuiSetString( rui3, "statusText", "Votes: 0" )
	RuiSetString( rui3, "presenseText", "" )

	var rui4 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote4" ))
	RuiSetString( rui4, "statusText", "Votes: 0")
	RuiSetString( rui4, "presenseText", "" )

	Hud_SetText(Hud_GetChild( file.menu, "TimerText2" ), "Voting Ends In")
	Hud_SetText(Hud_GetChild( file.menu, "TimerText" ), "15")

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), true)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), true )

	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote1" ), true )
	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote2" ), true )
	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote3" ), true )
	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote4" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), false )
}

void function SetCTFVoteMenuNextRound()
{
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), false)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), "Starting Next Round!")
}

void function UpdateMapsForVoting(string map1, string map2, string map3, string map4)
{
	var rui = Hud_GetRui( Hud_GetChild( file.menu, "MapVote1" ))
	RuiSetString( rui, "buttonText", "" + map1 )

	var rui2 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote2" ))
	RuiSetString( rui2, "buttonText", "" + map2 )

	var rui3 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote3" ))
	RuiSetString( rui3, "buttonText", "" + map3 )

	var rui4 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote4" ))
	RuiSetString( rui4, "buttonText", "" + map4 )

}

void function CloseCTFVoteMenu()
{
	CloseAllMenus()
}

void function UpdateVoteTimer(int timeleft)
{
	var rui = Hud_GetChild( file.menu, "TimerText" )
	Hud_SetText(rui, timeleft.tostring())
}

void function UpdateVotesUI(int map1, int map2, int map3, int map4)
{
	var rui = Hud_GetRui( Hud_GetChild( file.menu, "MapVote1" ))
	RuiSetString( rui, "statusText", "Votes: " + map1 )

	var rui2 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote2" ))
	RuiSetString( rui2, "statusText", "Votes: " + map2 )

	var rui3 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote3" ))
	RuiSetString( rui3, "statusText", "Votes: " + map3 )

	var rui4 = Hud_GetRui( Hud_GetChild( file.menu, "MapVote4" ))
	RuiSetString( rui4, "statusText", "Votes: " + map4 )
}

void function UpdateVotedFor(int id)
{
	var rui = Hud_GetRui( Hud_GetChild( file.menu, "MapVote" + id ))
	RuiSetString( rui, "presenseText", "Voted!" )

	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote1" ), false )
	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote2" ), false )
	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote3" ), false )
	Hud_SetEnabled( Hud_GetChild( file.menu, "MapVote4" ), false )
}

void function UpdateVotedLocation(string map)
{
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), false)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), "Next Location: " + map)
}

void function InitCTFVoteMenu( var newMenuArg )
{
	var menu = GetMenu( "CTFVoteMenu" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	var map1 = Hud_GetChild( menu, "MapVote1" )
	AddButtonEventHandler( map1, UIE_CLICK, OnClickMap1 )

	var map2 = Hud_GetChild( menu, "MapVote2" )
	AddButtonEventHandler( map2, UIE_CLICK, OnClickMap2 )

	var map3 = Hud_GetChild( menu, "MapVote3" )
	AddButtonEventHandler( map3, UIE_CLICK, OnClickMap3 )

	var map4 = Hud_GetChild( menu, "MapVote4" )
	AddButtonEventHandler( map4, UIE_CLICK, OnClickMap4 )
}

void function OnClickMap1( var button )
{
	RunClientScript("VoteForMap", 0 )
}

void function OnClickMap2( var button )
{
	RunClientScript("VoteForMap", 1 )
}

void function OnClickMap3( var button )
{
	RunClientScript("VoteForMap", 2 )
}

void function OnClickMap4( var button )
{
	RunClientScript("VoteForMap", 3 )
}

void function OnR5RSB_Show()
{
    //
}

void function OnR5RSB_Open()
{
	//
}

void function OnR5RSB_Close()
{
	//
}

void function OnR5RSB_NavigateBack()
{
    //
}