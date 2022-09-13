global function InitWeaponSkinsPanel
global function WeaponSkinsPanel_SetWeapon

#if(false)



#endif

struct PanelData
{
	var panel
	var weaponNameRui
	var ownedRui
	var listPanel
	var charmsButton

	ItemFlavor ornull weaponOrNull
	array<ItemFlavor> weaponSkinList
#if(false)

#endif
}


struct
{
	table<var, PanelData> panelDataMap

	var currentPanel = null
	ItemFlavor& currentWeapon
	ItemFlavor& currentWeaponSkin
#if(false)

#endif
} file


void function InitWeaponSkinsPanel( var panel )
{
	Assert( !(panel in file.panelDataMap) )
	PanelData pd
	file.panelDataMap[ panel ] <- pd

	pd.weaponNameRui = Hud_GetRui( Hud_GetChild( panel, "WeaponName" ) )

	pd.ownedRui = Hud_GetRui( Hud_GetChild( panel, "Owned" ) )
	RuiSetString( pd.ownedRui, "title", Localize( "#SKINS_OWNED" ).toupper() )

	pd.listPanel = Hud_GetChild( panel, "WeaponSkinList" )
	AddUICallback_InputModeChanged( OnInputModeChanged )

	#if(false)





#endif

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, WeaponSkinsPanel_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, WeaponSkinsPanel_OnHide )
	AddPanelEventHandler_FocusChanged( panel, WeaponSkinsPanel_OnFocusChanged )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	#if(false)


#endif
	AddPanelFooterOption( panel, LEFT, BUTTON_A, false, "#A_BUTTON_SELECT", "", null, CustomizeMenus_IsFocusedItem )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EQUIP", "#X_BUTTON_EQUIP", null, CustomizeMenus_IsFocusedItemEquippable )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_UNLOCK", "#X_BUTTON_UNLOCK", null, CustomizeMenus_IsFocusedItemLocked )
	//
	//
}

#if(false)


































































#endif //

void function OnInputModeChanged( bool controllerModeActive )
{
	#if(false)


#endif
}


void function WeaponSkinsPanel_SetWeapon( var panel, ItemFlavor ornull weaponFlavOrNull )
{
	PanelData pd = file.panelDataMap[panel]
	pd.weaponOrNull = weaponFlavOrNull
}


void function WeaponSkinsPanel_OnShow( var panel )
{
#if(false)

#else
	bool charmsActive = false
#endif

	if ( !charmsActive )
		RunClientScript( "UIToClient_ResetWeaponRotation" )

	RunClientScript( "EnableModelTurn" )

	file.currentPanel = panel

	//
	//
	//

	thread TrackIsOverScrollBar( file.panelDataMap[panel].listPanel )

	WeaponSkinsPanel_Update( panel )
}


void function WeaponSkinsPanel_OnHide( var panel )
{
	//
	Signal( uiGlobal.signalDummy, "TrackIsOverScrollBar" )

	RunClientScript( "EnableModelTurn" )
	WeaponSkinsPanel_Update( panel )
}


void function WeaponSkinsPanel_Update( var panel )
{
	PanelData pd    = file.panelDataMap[panel]
	var scrollPanel = Hud_GetChild( pd.listPanel, "ScrollPanel" )

	//
#if(false)






#endif //

	foreach ( int flavIdx, ItemFlavor unused in pd.weaponSkinList)
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + flavIdx )
		CustomizeButton_UnmarkForUpdating( button )
	}
	pd.weaponSkinList.clear()

	CustomizeMenus_SetActionButton( null )

	//
#if(false)

#else
	string ownedText = "#SKINS_OWNED"
#endif

	RuiSetString( pd.ownedRui, "title", Localize( ownedText ).toupper() )

	//
	if ( IsPanelActive( panel ) && pd.weaponOrNull != null )
	{
		file.currentWeapon = expect ItemFlavor(pd.weaponOrNull)
		LoadoutEntry entry
		array<ItemFlavor> itemList
		void functionref( ItemFlavor ) previewFunc
		bool ignoreDefaultItemForCount

		#if(false)




//





#endif
		{
			entry = Loadout_WeaponSkin( file.currentWeapon )
			pd.weaponSkinList = GetLoadoutItemsSortedForMenu( entry, WeaponSkin_GetSortOrdinal )
			FilterWeaponSkinList( pd.weaponSkinList )
			itemList = pd.weaponSkinList
			previewFunc = PreviewWeaponSkin
			ignoreDefaultItemForCount = false
		}

		RuiSetString( pd.weaponNameRui, "text", Localize( ItemFlavor_GetLongName( file.currentWeapon ) ).toupper() )
		RuiSetString( pd.ownedRui, "collected", CustomizeMenus_GetCollectedString( entry, itemList, ignoreDefaultItemForCount ) )

		Hud_InitGridButtons( pd.listPanel, itemList.len() )

		foreach ( int flavIdx, ItemFlavor flav in itemList )
		{
			var button = Hud_GetChild( scrollPanel, "GridButton" + flavIdx )
			CustomizeButton_UpdateAndMarkForUpdating( button, [entry], flav, previewFunc, null )
		}

		CustomizeMenus_SetActionButton( Hud_GetChild( panel, "ActionButton" ) )
	}
}


void function WeaponSkinsPanel_OnFocusChanged( var panel, var oldFocus, var newFocus )
{
	if ( !IsValid( panel ) ) //
		return
	if ( GetParentMenu( panel ) != GetActiveMenu() )
		return

	UpdateFooterOptions()
}

#if(false)










#endif //

void function PreviewWeaponSkin( ItemFlavor weaponSkinFlavor )
{
	#if(false)


#else
		int weaponCharmId = -1 //
	#endif

	int weaponSkinId = ItemFlavor_GetNetworkIndex_DEPRECATED( weaponSkinFlavor )
	file.currentWeaponSkin = weaponSkinFlavor

	RunClientScript( "UIToClient_PreviewWeaponSkin", weaponSkinId, weaponCharmId, true )
}


void function FilterWeaponSkinList( array<ItemFlavor> weaponSkinList )
{
	for ( int i = weaponSkinList.len() - 1; i >= 0; i-- )
	{
		if ( !ShouldDisplayWeaponSkin( weaponSkinList[i] ) )
			weaponSkinList.remove( i )
	}
}


bool function ShouldDisplayWeaponSkin( ItemFlavor weaponSkin )
{
	if ( GladiatorCardWeaponSkin_ShouldHideIfLocked( weaponSkin ) )
	{
		if ( !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), weaponSkin ) )
			return false
	}

	return true
}
