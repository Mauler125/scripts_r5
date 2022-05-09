global function InitCTFRespawnMenu
global function OpenCTFRespawnMenu
global function CloseCTFRespawnMenu
global function UpdateRespawnTimer
global function UpdateKillerName
global function SetEnemyScore
global function SetTeamScore
global function UpdateObjectiveText
global function UpdateSelectedClass
global function DisableClassSelect
global function EnableClassSelect

struct
{
	var menu
} file

void function OpenCTFRespawnMenu()
{
	CloseAllMenus()
	AdvanceMenu( file.menu )
}

void function CloseCTFRespawnMenu()
{
	CloseAllMenus()
}

void function UpdateObjectiveText(int score)
{
	var rui = Hud_GetChild( file.menu, "ObjectiveText" )
	Hud_SetText(rui, "Capture " + score.tostring() + " Flags To Win!")
}

void function UpdateRespawnTimer(int timeleft)
{
	var rui = Hud_GetChild( file.menu, "TimerText" )
	Hud_SetText(rui, timeleft.tostring())
}

void function UpdateKillerName(string name)
{
	var rui = Hud_GetChild( file.menu, "KilledByText" )
	Hud_SetText(rui, name)
}

void function SetEnemyScore(int score)
{
	var rui = Hud_GetChild( file.menu, "EnemyScoreText" )
	Hud_SetText(rui, score.tostring() + " Captures")
}

void function SetTeamScore(int score)
{
	var rui = Hud_GetChild( file.menu, "TeamScoreText" )
	Hud_SetText(rui, score.tostring() + " Captures")
}

void function InitCTFRespawnMenu( var newMenuArg )
{
	var menu = GetMenu( "CTFRespawnMenu" )
	file.menu = menu

	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )

	AddButtonEventHandler( Hud_GetChild( menu, "Class1" ), UIE_CLICK, OnClickClass )
	AddButtonEventHandler( Hud_GetChild( menu, "Class2" ), UIE_CLICK, OnClickClass )
	AddButtonEventHandler( Hud_GetChild( menu, "Class3" ), UIE_CLICK, OnClickClass )
	AddButtonEventHandler( Hud_GetChild( menu, "Class4" ), UIE_CLICK, OnClickClass )
	AddButtonEventHandler( Hud_GetChild( menu, "Class5" ), UIE_CLICK, OnClickClass )

	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class1" )), "buttonText", "Close-Quarters" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class2" )), "buttonText", "Heavy" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class3" )), "buttonText", "Assault" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class4" )), "buttonText", "Marksman" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class5" )), "buttonText", "Sniper" )
}

//Button event handlers
void function OnClickClass( var button )
{
	for(int i = 1; i < 6; i++ ) {
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + i )), "status", eFriendStatus.OFFLINE )
	}

	RuiSetInt( Hud_GetRui( button ), "status", eFriendStatus.ONLINE_AWAY )

	int buttonId = Hud_GetScriptID( button ).tointeger()
	SetWeaponIcons(buttonId)
	RunClientScript("UI_To_Client_UpdateSelectedClass", buttonId )
}

void function UpdateSelectedClass(int classid)
{
	for(int i = 1; i < 6; i++ ) {
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + i )), "status", eFriendStatus.OFFLINE )
	}

	int finalclassid = classid + 1

	RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + finalclassid )), "status", eFriendStatus.ONLINE_AWAY )

	SetWeaponIcons(classid)
}

void function DisableClassSelect()
{
	for(int i = 1; i < 6; i++ ) {
		Hud_SetEnabled( Hud_GetChild( file.menu, "Class" + i ), false )
	}
}

void function EnableClassSelect()
{
	for(int i = 1; i < 6; i++ ) {
		Hud_SetEnabled( Hud_GetChild( file.menu, "Class" + i ), true )
	}
}

//used to set weapon icons
//plan is to change all of this once i get time to allow classes to be set via playlist
void function SetWeaponIcons(int id)
{
	switch(id)
	{
		case 0: // Close-Quarters
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon1Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_r97" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_r45" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability1Img" )), "basicImage", $"rui/hud/tactical_icons/tactical_bloodhound" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability2Img" )), "basicImage", $"rui/hud/ultimate_icons/ultimate_octane" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon1Text" ), "Primary: R99" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon2Text" ), "Secondary: Re-45" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability2Text" ), "Ultimate: Octane" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability1Text" ), "Tactical: Bloodhound" )
			break
		case 1: // Heavy
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon1Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_spitfire" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_peacekeeper" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability1Img" )), "basicImage", $"rui/hud/tactical_icons/tactical_gibraltar" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability2Img" )), "basicImage", $"rui/hud/ultimate_icons/ultimate_caustic" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon1Text" ), "Primary: Spitfire" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon2Text" ), "Secondary: Peacekeeper" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability2Text" ), "Ultimate: Caustic" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability1Text" ), "Tactical: Gibraltar" )
			break
		case 2: // Assault
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon1Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_flatline" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_wingman" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability1Img" )), "basicImage", $"rui/hud/tactical_icons/tactical_bloodhound" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability2Img" )), "basicImage", $"rui/hud/ultimate_icons/ultimate_octane" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon1Text" ), "Primary: Flatline")
			Hud_SetText( Hud_GetChild( file.menu, "Weapon2Text" ), "Secondary: Wingman" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability2Text" ), "Ultimate: Octane" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability1Text" ), "Tactical: Bloodhound" )
			break
		case 3: // Marksman
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon1Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_g7" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_alternator" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability1Img" )), "basicImage", $"rui/hud/tactical_icons/tactical_caustic" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability2Img" )), "basicImage", $"rui/hud/ultimate_icons/ultimate_gibraltar" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon1Text" ), "Primary: G7 Scout" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon2Text" ), "Secondary: Alternator" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability2Text" ), "Ultimate: Gibraltar" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability1Text" ), "Tactical: Caustic" )
			break
		case 4: // Sniper
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon1Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_triple_take" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", $"rui/weapon_icons/r5/weapon_eva8" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability2Img" )), "basicImage", $"rui/hud/tactical_icons/tactical_pathfinder" )
			RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "Ability1Img" )), "basicImage", $"rui/hud/ultimate_icons/ultimate_octane" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon1Text" ), "Primary: Triple Take" )
			Hud_SetText( Hud_GetChild( file.menu, "Weapon2Text" ), "Secondary: Eva 8" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability1Text" ), "Ultimate: Octane" )
			Hud_SetText( Hud_GetChild( file.menu, "Ability2Text" ), "Tactical: Pathfinder" )
			break
	}
}

void function ChangeLegend(var button)
{
    RunClientScript("OpenCharacterSelectNewMenu", true)
}

void function OnR5RSB_NavigateBack()
{
    //
}