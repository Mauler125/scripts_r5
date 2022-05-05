global function InitCTFVoteMenu
global function OpenCTFVoteMenu
global function CloseCTFVoteMenu
global function UpdateVoteTimer
global function UpdateVotesUI
global function UpdateMapsForVoting
global function UpdateVotedFor
global function UpdateVotedLocation
global function OpenCTFVoteMenuAlt

struct
{
	var menu
} file

void function OpenCTFVoteMenu()
{
	CloseAllMenus()
	AdvanceMenu( file.menu )

	var rui = Hud_GetChild( file.menu, "MapVote1Votes" )
	Hud_SetText(rui, "Votes: 0")

	var rui2 = Hud_GetChild( file.menu, "MapVote2Votes" )
	Hud_SetText(rui2, "Votes: 0")

	var rui3 = Hud_GetChild( file.menu, "MapVote3Votes" )
	Hud_SetText(rui3, "Votes: 0")

	var rui4 = Hud_GetChild( file.menu, "MapVote4Votes" )
	Hud_SetText(rui4, "Votes: 0")

	Hud_SetText(Hud_GetChild( file.menu, "TimerText2" ), "Voting Ends In")
	Hud_SetText(Hud_GetChild( file.menu, "TimerText" ), "15")

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), true)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), true)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Voted" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Voted" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Voted" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Label" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Votes" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Label" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Votes" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Label" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Votes" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Label" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Votes" ), true )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), false )
}

void function OpenCTFVoteMenuAlt()
{
	CloseAllMenus()
	AdvanceMenu( file.menu )

	Hud_SetVisible(Hud_GetChild( file.menu, "TimerFrame"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText2"), false)
	Hud_SetVisible(Hud_GetChild( file.menu, "TimerText" ), false)

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "CTFBottomFrame" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "ObjectiveText" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVoteFrame2" ), true )
	Hud_SetVisible( Hud_GetChild( file.menu, "VotedForLbl" ), true )
	Hud_SetText( Hud_GetChild( file.menu, "VotedForLbl" ), "Starting Next Round!")
}

void function UpdateMapsForVoting(string map1, string map2, string map3, string map4)
{
	var rui = Hud_GetChild( file.menu, "MapVote1Label" )
	Hud_SetText(rui, "Location: " + map1)

	var rui2 = Hud_GetChild( file.menu, "MapVote2Label" )
	Hud_SetText(rui2, "Location: " + map2)

	var rui3 = Hud_GetChild( file.menu, "MapVote3Label" )
	Hud_SetText(rui3, "Location: " + map3)

	var rui4 = Hud_GetChild( file.menu, "MapVote4Label" )
	Hud_SetText(rui4, "Location: " + map4)
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
	var rui = Hud_GetChild( file.menu, "MapVote1Votes" )
	Hud_SetText(rui, "Votes: " + map1)

	var rui2 = Hud_GetChild( file.menu, "MapVote2Votes" )
	Hud_SetText(rui2, "Votes: " + map2)

	var rui3 = Hud_GetChild( file.menu, "MapVote3Votes" )
	Hud_SetText(rui3, "Votes: " + map3)

	var rui4 = Hud_GetChild( file.menu, "MapVote4Votes" )
	Hud_SetText(rui4, "Votes: " + map4)
}

void function UpdateVotedFor(int id)
{
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote" + id + "Voted" ), true )
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
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote1Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote2Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote3Voted" ), false )

	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Label" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Votes" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "MapVote4Voted" ), false )

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