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

struct
{
	var menu
} file

struct Abilitys
{
    string name
    asset icon
}

void function OpenCTFRespawnMenu(string classname1, string classname2, string classname3, string classname4, string classname5)
{
	CloseAllMenus()
	AdvanceMenu( file.menu )

	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class1" )), "buttonText", classname1 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class2" )), "buttonText", classname2 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class3" )), "buttonText", classname3 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class4" )), "buttonText", classname4 )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "Class5" )), "buttonText", classname5 )

	for(int i = 1; i < 6; i++ ) {
		Hud_SetEnabled( Hud_GetChild( file.menu, "Class" + i ), true )
	}

	entity player = GetLocalClientPlayer()
	ItemFlavor character = LoadoutSlot_WaitForItemFlavor( ToEHI( player ), Loadout_CharacterClass() )
	asset classIcon      = CharacterClass_GetGalleryPortrait( character )
	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "PlayerImage")), "basicImage", classIcon)
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "ChangeLegend" )), "buttonText", "Change Legend" )
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
}

//Button event handlers
void function OnClickClass( var button )
{
	for(int i = 1; i < 6; i++ ) {
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + i )), "status", eFriendStatus.OFFLINE )
	}

	RuiSetInt( Hud_GetRui( button ), "status", eFriendStatus.ONLINE_INGAME )

	int buttonId = Hud_GetScriptID( button ).tointeger()
	RunClientScript("UI_To_Client_UpdateSelectedClass", buttonId )
}

void function UpdateSelectedClass(int classid, string primary, string secondary, string tactical, string ult)
{
	for(int i = 1; i < 6; i++ ) {
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + i )), "status", eFriendStatus.OFFLINE )
	}

	int finalclassid = classid + 1

	RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + finalclassid )), "status", eFriendStatus.ONLINE_INGAME )

	Set_CTF_Class(primary, secondary, tactical, ult)
}

void function DisableClassSelect()
{
	for(int i = 1; i < 6; i++ ) {
		Hud_SetEnabled( Hud_GetChild( file.menu, "Class" + i ), false )
	}
}

void function Set_CTF_Class(string primary, string secondary, string tactical, string ult)
{
	LootData primaryData = SURVIVAL_Loot_GetLootDataByRef( primary )
	LootData secondaryData = SURVIVAL_Loot_GetLootDataByRef( secondary )

	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "Weapon1Img")), "basicImage", primaryData.hudIcon)
	RuiSetImage(Hud_GetRui(Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", secondaryData.hudIcon)
	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "Ability1Img")), "basicImage", GetWeaponInfoFileKeyFieldAsset_Global(tactical, "hud_icon"))
	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "Ability2Img")), "basicImage", GetWeaponInfoFileKeyFieldAsset_Global(ult, "hud_icon"))
	Hud_SetText(Hud_GetChild(file.menu, "Weapon1Text"), GetWeaponInfoFileKeyField_GlobalString(primaryData.baseWeapon, "shortprintname"))
	Hud_SetText(Hud_GetChild(file.menu, "Weapon2Text"), GetWeaponInfoFileKeyField_GlobalString(secondaryData.baseWeapon, "shortprintname"))
	Hud_SetText(Hud_GetChild(file.menu, "Ability2Text"), GetWeaponInfoFileKeyField_GlobalString(ult, "shortprintname"))
	Hud_SetText(Hud_GetChild(file.menu, "Ability1Text"), GetWeaponInfoFileKeyField_GlobalString(tactical, "shortprintname"))
}

void function ChangeLegend(var button)
{
    RunClientScript("OpenCharacterSelectNewMenu", true)
}

void function OnR5RSB_NavigateBack()
{
    //
}