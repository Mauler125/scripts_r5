global function InitR5RLegendsPanel
global function R5RCharactersPanel_Show

struct
{
	var menu
	var panel
	var characterSelectInfoRui
	array<var> buttons
	var actionLabel
	table<var, ItemFlavor> buttonToCharacter
	ItemFlavor ornull	   presentedCharacter
} file

global bool g_InLegendsMenu = false

void function InitR5RLegendsPanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )
	file.characterSelectInfoRui = Hud_GetRui( Hud_GetChild( file.panel, "CharacterSelectInfo" ) )
	file.buttons = GetPanelElementsByClassname( panel, "CharacterButtonClass" )

	foreach ( button in file.buttons )
	{
		Hud_AddEventHandler( button, UIE_CLICK, CharacterButton_OnActivate )
		Hud_AddEventHandler( button, UIE_CLICKRIGHT, CharacterButton_OnRightClick )
		Hud_AddEventHandler( button, UIE_MIDDLECLICK, CharacterButton_OnMiddleClick )

		ToolTipData toolTipData
		toolTipData.tooltipStyle = eTooltipStyle.BUTTON_PROMPT
		toolTipData.actionHint1 = "#X_BUTTON_TOGGLE_LOADOUT"
		Hud_SetToolTipData( button, toolTipData )
	}

	file.actionLabel = Hud_GetChild( panel, "ActionLabel" )
	Hud_SetText( file.actionLabel, "#X_BUTTON_TOGGLE_LOADOUT" )
}

void function CharacterButton_OnMiddleClick( var button )
{
	SetFeaturedCharacterFromButton( button )
}

void function SetFeaturedCharacterFromButton( var button )
{
	if ( button in file.buttonToCharacter )
		SetFeaturedCharacter( file.buttonToCharacter[button] )
}

void function CharacterButton_OnActivate( var button )
{
	ItemFlavor character = file.buttonToCharacter[button]
	CustomizeCharacterMenu_SetCharacter( character )
	RequestSetItemFlavorLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), character ) // TEMP, Some menu state is broken without this. Need Declan to look at why RefreshLoadoutSlotInternal doesn't run when editing a loadout that isn't the featured one before removing this.

	SetFeaturedCharacter( character )

	SetTopLevelCustomizeContext( character )
	EmitUISound( "UI_Menu_Legend_Select" )
	AdvanceMenu( GetMenu( "CustomizeCharacterMenu" ) )
	g_InLegendsMenu = true
}

void function CharacterButton_OnRightClick( var button )
{
	OpenCharacterSkillsDialog( file.buttonToCharacter[button] )
}

void function SetFeaturedCharacter( ItemFlavor character )
{
	foreach ( button in file.buttons )
		if ( button in file.buttonToCharacter )
			Hud_SetSelected( button, file.buttonToCharacter[button] == character )
	
	RequestSetItemFlavorLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), character )

	EmitUISound( "UI_Menu_Legend_SetFeatured" )
}

void function InitCharacterButtons()
{
	file.buttonToCharacter.clear()

	array<ItemFlavor> allCharacters
	foreach ( ItemFlavor itemFlav in GetAllCharacters() )
		allCharacters.append( itemFlav )

	foreach ( button in file.buttons )
		Hud_SetVisible( button, false )

	table<int,ItemFlavor> mappingTable = GetCharacterButtonMapping( allCharacters, file.buttons.len() )
	foreach ( int buttonIndex, ItemFlavor itemFlav in mappingTable )
	{
		CharacterButton_Init( file.buttons[ buttonIndex ], itemFlav )
		Hud_SetVisible( file.buttons[ buttonIndex ], true )
	}

	array<int> rowSizes = GetCharacterButtonRowSizes( allCharacters.len() )
	array< array<var> > buttonRows

	int buttonIndex = 0
	foreach ( rowSize in rowSizes )
	{
		array<var> buttons
		int last = buttonIndex + rowSize

		while ( buttonIndex < last )
		{
			buttons.append( file.buttons[buttonIndex] )
			buttonIndex++
		}

		buttonRows.append( buttons )
	}
	LayoutCharacterButtons( buttonRows )
}


void function CharacterButton_Init( var button, ItemFlavor character )
{
	file.buttonToCharacter[button] <- character

	bool isSelected = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_CharacterClass() ) == character

	Hud_SetVisible( button, true )
	Hud_SetLocked( button, !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), character ) )
	Hud_SetSelected( button, isSelected )

	RuiSetString( Hud_GetRui( button ), "buttonText", Localize( ItemFlavor_GetLongName( character ) ).toupper() )
	RuiSetImage( Hud_GetRui( button ), "buttonImage", CharacterClass_GetGalleryPortrait( character ) )
	RuiSetImage( Hud_GetRui( button ), "bgImage", CharacterClass_GetGalleryPortraitBackground( character ) )
	RuiSetImage( Hud_GetRui( button ), "roleImage", CharacterClass_GetCharacterRoleImage( character ) )
}

void function R5RCharactersPanel_Show()
{
	UI_SetPresentationType( ePresentationType.CHARACTER_SELECT )

	ItemFlavor character = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_CharacterClass() )
	SetTopLevelCustomizeContext( character )
	PresentCharacter( character )

	InitCharacterButtons()
}

void function PresentCharacter( ItemFlavor character )
{
	if ( file.presentedCharacter == character )
		return

	RuiSetString( file.characterSelectInfoRui, "nameText", Localize( ItemFlavor_GetLongName( character ) ).toupper() )
	RuiSetString( file.characterSelectInfoRui, "subtitleText", Localize( CharacterClass_GetCharacterSelectSubtitle( character ) ) )
	RuiSetGameTime( file.characterSelectInfoRui, "initTime", Time() )

	file.presentedCharacter = character
}