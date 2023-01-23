global function InitWeaponModsMenu
global function OpenWeaponModsMenu
global function SetCurrentModsMenuWeapon
global function OnWeaponsMenuOpen
global function UpdateBlacklistedWeaponMenuMods

const MAX_ATTACHMENT_ITEMS = 12

const array<string> ModsButtons = [ 
	"Optic", 
	"Barrel", 
	"Magazine", 
	"Stock", 
	"Bolt", 
	"HopUp" 
]

const array<string> catanames = [ 
	"OpticCata", 
	"BarrelCata", 
	"MagsCata", 
	"StocksCata", 
	"BoltsCata", 
	"HopUpCata" 
]

const array<string> ButtonNames = [
    "OpticsButton",
    "BarrelButton",
    "MagazineButton",
    "StockButton",
    "BoltButton",
    "HopupButton"
]

table <string, string> ModToName = {
	["optic_cq_hcog_classic"] = "x1 HCOG Classic",
	["optic_cq_hcog_bruiser"] = "x2 HCOG Bruiser",
	["optic_cq_holosight"] = "x1 Holosight",
	["optic_cq_threat"] = "x1 Digital Threat",
	["optic_cq_holosight_variable"] = "x1-2 Holosight Variable",
	["optic_ranged_hcog"] = "x3 HCOG Ranger",
	["optic_ranged_aog_variable"] = "x2-4 AOG Variable",
	["optic_sniper"] = "x6 Sniper",
	["optic_sniper_variable"] = "x4-8 Sniper Variable",
	["optic_sniper_threat"] = "x4-10 Sniper Digital Threat",
	["barrel_stabilizer_l1"] = "Barrel Stabilizer Lvl 1",
	["barrel_stabilizer_l2"] = "Barrel Stabilizer Lvl 2",
	["barrel_stabilizer_l3"] = "Barrel Stabilizer Lvl 3",
	["barrel_stabilizer_l4_flash_hider"] = "Barrel Stabilizer Lvl 4",
	["stock_tactical_l1"] = "Tactical Stock Lvl 1",
	["stock_tactical_l2"] = "Tactical Stock Lvl 2",
	["stock_tactical_l3"] = "Tactical Stock Lvl 3",
	["stock_sniper_l1"] = "Sniper Stock Lvl 1",
	["stock_sniper_l2"] = "Sniper Stock Lvl 2",
	["stock_sniper_l3"] = "Sniper Stock Lvl 3",
	["shotgun_bolt_l1"] = "Shotgun Bolt Lvl 1",
	["shotgun_bolt_l2"] = "Shotgun Bolt Lvl 2",
	["shotgun_bolt_l3"] = "Shotgun Bolt Lvl 3",
	["bullets_mag_l1"] = "Light Mag Lvl 1",
	["bullets_mag_l2"] = "Light Mag Lvl 2",
	["bullets_mag_l3"] = "Light Mag Lvl 3",
	["highcal_mag_l1"] = "Heavy Mag Lvl 1",
	["highcal_mag_l2"] = "Heavy Mag Lvl 2",
	["highcal_mag_l3"] = "Heavy Mag Lvl 3",
	["energy_mag_l1"] = "Energy Mag Lvl 1",
	["energy_mag_l2"] = "Energy Mag Lvl 2",
	["energy_mag_l3"] = "Energy Mag Lvl 3",
	["sniper_mag_l1"] = "Sniper Mag Lvl 1",
	["sniper_mag_l2"] = "Sniper Mag Lvl 2",
	["sniper_mag_l3"] = "Sniper Mag Lvl 3",
	["hopup_turbocharger"] = "Turbocharger",
	["hopup_selectfire"] = "Selectfire Receiver",
	["hopup_energy_choke"] = "Precision Choke",
	["hopup_unshielded_dmg"] = "Hammerpoint Rounds",
	["hopup_highcal_rounds"] = "Anvil Receiver",
	["hopup_double_tap"] = "Double Tap"
}

struct
{
	var menu

	string weaponclassname

	string OpenButtonName
	array<string> blacklistedmods
} file

array<string> weaponOptics
array<string> weaponBarrels
array<string> weaponMagazines
array<string> weaponStocks
array<string> weaponBolts
array<string> weaponHopup

struct
{
	string optic = ""
	string barrel = ""
	string magazine = ""
	string stock = ""
	string bolt = ""
	string hopup = ""
} selectedMods

struct
{
	int optic = 0
	int barrel = 0
	int magazine = 0
	int stock = 0
	int bolt = 0
	int hopup = 0
} modcount

//Opens vote menu
void function OpenWeaponModsMenu()
{
	if(GetActiveMenu() != file.menu)
		file.OpenButtonName = ""

	CloseAllMenus()
	AdvanceMenu( file.menu )
}

void function UpdateBlacklistedWeaponMenuMods(string mods)
{
	file.blacklistedmods = split( mods, " " )
}

void function SetCurrentModsMenuWeapon(string weaponclassname, string mods)
{
	file.weaponclassname = weaponclassname

	selectedMods.optic = ""
	selectedMods.barrel = ""
	selectedMods.magazine = ""
	selectedMods.stock = ""
	selectedMods.bolt = ""
	selectedMods.hopup = ""

	array<string> splitmods = split( mods, " " )
	foreach(string mod in splitmods)
	{
		if(mod.find( "optic" ) > -1)
			selectedMods.optic = mod

		if(mod.find( "barrel" ) > -1)
			selectedMods.barrel = mod

		if(mod.find( "_mag_" ) > -1)
			selectedMods.magazine = mod

		if(mod.find( "stock" ) > -1)
			selectedMods.stock = mod

		if(mod.find( "shotgun_bolt" ) > -1)
			selectedMods.bolt = mod

		if(mod.find( "hopup" ) > -1)
			selectedMods.hopup = mod
	}
}
//Inits vote menu
void function InitWeaponModsMenu( var newMenuArg )
{
	var menu = GetMenu( "WeaponMods" )
	file.menu = menu

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnWeaponsMenuOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnWeaponsMenuClose )

	table<string, void functionref( var ) > ButtonNameToFunction = {
		[ButtonNames[0]] = OpticButtonPressed,
		[ButtonNames[1]] = BarrelButtonPressed,
		[ButtonNames[2]] = MagazineButtonPressed,
		[ButtonNames[3]] = StockButtonPressed,
		[ButtonNames[4]] = BoltButtonPressed,
		[ButtonNames[5]] = HopupButtonPressed
	}

	foreach(name in ButtonNames)
	{
        foreach ( button in GetElementsByClassname( file.menu, name ) )
		{
            Hud_AddEventHandler( button, UIE_CLICK, ButtonNameToFunction[name] )
			Hud_SetVisible( button, false )
		}
	}

	foreach( button in GetElementsByClassname( file.menu, "CataButton" ) )
		Hud_AddEventHandler( button, UIE_CLICK, CataPressed )
}

void function OnWeaponsMenuClose()
{
	RunClientScript("CL_OnCloseWeaponModsMenu")
}

void function CataPressed(var button)
{
	int id = Hud_GetScriptID( button ).tointeger()

	table<int, int > ButtonToCount= {
		[0] = modcount.optic,
		[1] = modcount.barrel,
		[2] = modcount.magazine,
		[3] = modcount.stock,
		[4] = modcount.bolt,
		[5] = modcount.hopup
	}

	foreach(name in ButtonNames)
        foreach ( buttons in GetElementsByClassname( file.menu, name ) )
			Hud_SetVisible( buttons, false )

	foreach( int i, buttons in GetElementsByClassname( file.menu, ButtonNames[id] ) )
	{
		Hud_SetVisible( buttons, true )
		if(i > ButtonToCount[id])
			Hud_SetVisible( buttons, false )
	}

	file.OpenButtonName = ButtonNames[id]
}

void function HopupButtonPressed( var button )
{
	int id = Hud_GetScriptID( button ).tointeger()
	if(weaponHopup[id] == selectedMods.hopup)
		selectedMods.hopup = ""
	else
		selectedMods.hopup = weaponHopup[id]
	SendWeaponMods()
}

void function BoltButtonPressed( var button )
{
	int id = Hud_GetScriptID( button ).tointeger()
	if(weaponBolts[id] == selectedMods.bolt)
		selectedMods.bolt = ""
	else
		selectedMods.bolt = weaponBolts[id]
	SendWeaponMods()
}

void function StockButtonPressed( var button )
{
	int id = Hud_GetScriptID( button ).tointeger()
	if(weaponStocks[id] == selectedMods.stock)
		selectedMods.stock = ""
	else
		selectedMods.stock = weaponStocks[id]
	SendWeaponMods()
}

void function MagazineButtonPressed( var button )
{
	int id = Hud_GetScriptID( button ).tointeger()
	if(weaponMagazines[id] == selectedMods.magazine)
		selectedMods.magazine = ""
	else
		selectedMods.magazine = weaponMagazines[id]
	SendWeaponMods()
}

void function BarrelButtonPressed( var button )
{
	int id = Hud_GetScriptID( button ).tointeger()
	if(weaponBarrels[id] == selectedMods.barrel)
		selectedMods.barrel = ""
	else
		selectedMods.barrel = weaponBarrels[id]
	SendWeaponMods()
}

void function OpticButtonPressed( var button )
{
	int id = Hud_GetScriptID( button ).tointeger()
	if(weaponOptics[id] == selectedMods.optic)
		selectedMods.optic = ""
	else
		selectedMods.optic = weaponOptics[id]
	SendWeaponMods()
}

void function SendWeaponMods()
{
	string WeaponMods = ""

	WeaponMods += selectedMods.optic + " "
	WeaponMods += selectedMods.barrel + " " 
	WeaponMods += selectedMods.magazine + " "
	WeaponMods += selectedMods.stock + " "
	WeaponMods += selectedMods.bolt + " "
	WeaponMods += selectedMods.hopup + " "

	RunClientScript( "UpdateWeaponMods", rstrip( WeaponMods ) )
}

void function OnWeaponsMenuOpen()
{
	HideAllButtons()
	SetupModCatagorys()

	table<int, string > ButtonToSelected = {
		[0] = selectedMods.optic,
		[1] = selectedMods.barrel,
		[2] = selectedMods.magazine,
		[3] = selectedMods.stock,
		[4] = selectedMods.bolt,
		[5] = selectedMods.hopup
	}

	array<array<string> > allWeaponMods = [ weaponOptics, weaponBarrels, weaponMagazines, weaponStocks, weaponBolts, weaponHopup ]
	foreach(int i, array<string> modsarray in allWeaponMods)
	{
		foreach(int j, string mod in modsarray)
		{
			if(j > MAX_ATTACHMENT_ITEMS)
				break
			
			string modname = mod
			if(mod in ModToName)
				modname = ModToName[mod]
				
			RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, ModsButtons[i] + j ) ), "modeNameText", modname )

			if(file.OpenButtonName == ButtonNames[i])
				Hud_SetVisible( Hud_GetChild( file.menu, ModsButtons[i] + j ), true )

			RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, ModsButtons[i] + j ) ), "isPartyLeader", false )

			if(mod == ButtonToSelected[i])
				RuiSetBool( Hud_GetRui( Hud_GetChild( file.menu, ModsButtons[i] + j ) ), "isPartyLeader", true )

			switch(i)
			{
				case 0:
					modcount.optic = j
					break
				case 1:
					modcount.barrel = j
					break
				case 2:
					modcount.magazine = j
					break
				case 3:
					modcount.stock = j
					break
				case 4:
					modcount.bolt = j
					break
				case 5:
					modcount.hopup = j
					break
			}
		}
	}
}

void function HideAllButtons()
{
	array<array<var> > allbuttons = [ GetElementsByClassname( file.menu, "CataButton" ), GetElementsByClassname( file.menu, "OpticsButton" ), GetElementsByClassname( file.menu, "BarrelButton" ), GetElementsByClassname( file.menu, "MagazineButton" ), GetElementsByClassname( file.menu, "StockButton" ), GetElementsByClassname( file.menu, "BoltButton" ), GetElementsByClassname( file.menu, "HopUpButton" )]
	
	foreach(array<var> buttons in allbuttons)
		foreach(var button in buttons)
			Hud_SetVisible( button, false )
}

void function SetupModCatagorys()
{
	weaponOptics.clear()
	weaponBarrels.clear()
	weaponMagazines.clear()
	weaponStocks.clear()
	weaponBolts.clear()
	weaponHopup.clear()

	array<string> weaponMods = GetWeaponMods_Global( file.weaponclassname )
	foreach(string mod in weaponMods)
	{
		if(mod.find( "optic" ) > -1)
			weaponOptics.append( mod )

		if(mod.find( "barrel" ) > -1)
			weaponBarrels.append( mod )

		if(mod.find( "_mag_" ) > -1)
			weaponMagazines.append( mod )

		if(mod.find( "stock" ) > -1)
			weaponStocks.append( mod )

		if(mod.find( "shotgun_bolt" ) > -1)
			weaponBolts.append( mod )

		if(mod.find( "hopup" ) > -1)
			weaponHopup.append( mod )
	}

	//Remove Blacklisted Items
	array<array<string> > allWeaponMods = [ weaponOptics, weaponBarrels, weaponMagazines, weaponStocks, weaponBolts, weaponHopup ]
	foreach(array<string> modsarray in allWeaponMods)
		foreach(int i, string mod in modsarray)
			foreach(string blacklistedmod in file.blacklistedmods)
				if(blacklistedmod.find( mod ) > -1)
					modsarray.remove(i)

	table<string, array<string> > CatagoryToArray = {
		[catanames[0]] = weaponOptics,
		[catanames[1]] = weaponBarrels,
		[catanames[2]] = weaponMagazines,
		[catanames[3]] = weaponStocks,
		[catanames[4]] = weaponBolts,
		[catanames[5]] = weaponHopup
	}

	var previousPanelForPinning
	foreach(int i, string cata in catanames)
	{
		if(CatagoryToArray[cata].len() == 0)
			continue
		
		var button = Hud_GetChild( file.menu, cata )
		Hud_SetVisible( button, true )

		if(i == 0)
		{
			Hud_SetY( button, -10 )
			Hud_SetX( button, -10 )
		}
		else 
		{
			Hud_SetPinSibling( button, Hud_GetHudName( previousPanelForPinning ) )
			Hud_SetX( button, -(Hud_GetWidth(previousPanelForPinning)) - 15 )
		}

		previousPanelForPinning = button
	}
}