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

struct Abilitys
{
    string name
    asset icon
}

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
	//SetWeaponIcons(buttonId)
	RunClientScript("UI_To_Client_UpdateSelectedClass", buttonId )
}

void function UpdateSelectedClass(int classid, string primary, string secondary, string tactical, string ult)
{
	for(int i = 1; i < 6; i++ ) {
		RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + i )), "status", eFriendStatus.OFFLINE )
	}

	int finalclassid = classid + 1

	RuiSetInt( Hud_GetRui( Hud_GetChild( file.menu, "Class" + finalclassid )), "status", eFriendStatus.ONLINE_AWAY )

	SetWeaponIcons(primary, secondary, tactical, ult)
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
void function SetWeaponIcons(string primary, string secondary, string tactical, string ult)
{
	LootData primaryData = SURVIVAL_Loot_GetLootDataByRef( primary )
	LootData secondaryData = SURVIVAL_Loot_GetLootDataByRef( secondary )
	Abilitys tacticalData = GetAbilityData(tactical)
	Abilitys ultData = GetAbilityData(ult)

	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "Weapon1Img")), "basicImage", primaryData.hudIcon)
	RuiSetImage(Hud_GetRui(Hud_GetChild( file.menu, "Weapon2Img" )), "basicImage", secondaryData.hudIcon)
	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "Ability1Img")), "basicImage", tacticalData.icon)
	RuiSetImage(Hud_GetRui(Hud_GetChild(file.menu, "Ability2Img")), "basicImage", ultData.icon)
	Hud_SetText(Hud_GetChild(file.menu, "Weapon1Text"), "Primary: " + GetWeaponInfoFileKeyField_GlobalString(primaryData.baseWeapon, "shortprintname"))
	Hud_SetText(Hud_GetChild(file.menu, "Weapon2Text"), "Secondary: " + GetWeaponInfoFileKeyField_GlobalString(secondaryData.baseWeapon, "shortprintname"))
	Hud_SetText(Hud_GetChild(file.menu, "Ability2Text"), "Ultimate: " + ultData.name)
	Hud_SetText(Hud_GetChild(file.menu, "Ability1Text"), "Tactical: " + tacticalData.name)
}

//There has to be a way to get ult and tac data the same way as weapons right?
//LootData secondaryData = SURVIVAL_Loot_GetLootDataByRef( secondary )
Abilitys function GetAbilityData(string name)
{
	Abilitys abilitys
	switch(name)
	{
		case "mp_weapon_grenade_bangalore":
			abilitys.name = Localize( "#WPN_GRENADE_ELECTRIC_SMOKE_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_bangalore"
			break
		case "mp_weapon_grenade_creeping_bombardment":
			abilitys.name = Localize( "#WPN_CREEPING_BOMBARDMENT_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_bangalore"
			break
		case "mp_ability_area_sonar_scan":
			abilitys.name = Localize( "#WPN_AREA_SONAR_SCAN_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_bloodhound"
			break
		case "mp_ability_hunt_mode":
			abilitys.name = Localize( "#WPN_HUNT_MODE" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_bloodhound"
			break
		case "mp_weapon_dirty_bomb":
			abilitys.name = Localize( "#WPN_DIRTY_BOMB_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_caustic"
			break
		case "mp_weapon_grenade_gas":
			abilitys.name = Localize( "#WPN_GRENADE_ELECTRIC_SMOKE_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_caustic"
			break
		case "mp_ability_crypto_drone":
			abilitys.name = Localize( "#WPN_AERIAL_DRONE_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_crypto"
			break
		case "mp_ability_crypto_drone_emp":
			abilitys.name = Localize( "#WPN_DRONE_EMP" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_crypto"
			break
		case "mp_weapon_bubble_bunker":
			abilitys.name = Localize( "#WPN_BUBBLE_BUNKER_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_gibraltar"
			break
		case "mp_weapon_grenade_defensive_bombardment":
			abilitys.name = Localize( "#WPN_DEFENSIVE_BOMBARDMENT_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_gibraltar"
			break
		case "mp_weapon_deployable_medic":
			abilitys.name = Localize( "#WPN_DEPLOYABLE_MEDIC_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_lifeline"
			break
		case "mp_ability_care_package":
			abilitys.name = Localize( "#WPN_CARE_PACKAGE_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_lifeline"
			break
		case "mp_ability_holopilot":
			abilitys.name = Localize( "#WPN_HOLOPILOT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_mirage"
			break
		case "mp_ability_mirage_ultimate":
			abilitys.name = Localize( "#WPN_DISGUISE_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_mirage"
			break
		case "mp_ability_heal":
			abilitys.name = Localize( "#WPN_OCTANE_STIM" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_octane"
			break
		case "mp_weapon_jump_pad":
			abilitys.name = Localize( "#WPN_JUMP_PAD_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_octane"
			break
		case "mp_ability_grapple":
			abilitys.name = Localize( "#WPN_GRAPPLE" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_pathfinder"
			break
		case "mp_weapon_zipline":
			abilitys.name = "Zipline Gun" //Why the fuck dosnt this have a localized shortnname?
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_pathfinder"
			break
		case "mp_weapon_tesla_trap":
			abilitys.name = Localize( "#WPN_TESLA_TRAP_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_wattson"
			break
		case "mp_weapon_trophy_defense_system":
			abilitys.name = Localize( "#WPN_TROPHY_SYSTEM_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_wattson"
			break
		case "mp_ability_phase_walk":
			abilitys.name = Localize( "#WPN_PHASE_WALK_SHORT" )
			abilitys.icon = $"rui/hud/tactical_icons/tactical_wraith"
			break
		case "mp_weapon_phase_tunnel":
			abilitys.name = Localize( "#WPN_PHASE_TUNNEL_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_wraith"
			break
		case "mp_ability_3dash":
			abilitys.name = Localize( "#WPN_3DASH_SHORT" )
			abilitys.icon = $"rui/hud/ultimate_icons/ultimate_wraith"
			break
	}

	return abilitys
}

void function ChangeLegend(var button)
{
    RunClientScript("OpenCharacterSelectNewMenu", true)
}

void function OnR5RSB_NavigateBack()
{
    //
}