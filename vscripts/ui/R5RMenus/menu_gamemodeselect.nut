global function InitR5RGamemodeSelectDialog

struct {
	var menu
	var closeButton
	var selectionPanel

	array<var>         modeSelectButtonList
	table<var, string> selectButtonPlaylistNameMap
    table<var, asset> selectButtonPlaylistAssetMap
} file

const int MAX_DISPLAYED_MODES = 5

const table<string, asset> GAMEMODE_IMAGE_MAP = {
	play_apex = $"rui/menu/gamemode/play_apex",
	apex_elite = $"rui/menu/gamemode/apex_elite",
	training = $"rui/menu/gamemode/training",
	firing_range = $"rui/menu/gamemode/firing_range",
	generic_01 = $"rui/menu/gamemode/generic_01",
	generic_02 = $"rui/menu/gamemode/generic_02",
	ranked_1 = $"rui/menu/gamemode/ranked_1",
	ranked_2 = $"rui/menu/gamemode/ranked_2",
	solo_iron_crown = $"rui/menu/gamemode/solo_iron_crown",
	duos = $"rui/menu/gamemode/duos",
	worlds_edge = $"rui/menu/gamemode/worlds_edge",
	shotguns_and_snipers = $"rui/menu/gamemode/shotguns_and_snipers",
	shadow_squad = $"rui/menu/gamemode/shadow_squad",
	worlds_edge_after_dark = $"rui/menu/gamemode/shadow_squad",
}

void function InitR5RGamemodeSelectDialog( var newMenuArg ) //
{
	var menu = GetMenu( "R5RGamemodeSelectV2Dialog" )
	file.menu = menu

	SetDialog( menu, true )
	SetClearBlur( menu, false )

	var prevPageButton = Hud_GetChild( menu, "PrevPageButton" )
	HudElem_SetRuiArg( prevPageButton, "flipHorizontal", true )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenModeSelectDialog )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnCloseModeSelectDialog )

	file.closeButton = Hud_GetChild( menu, "CloseButton" )
	Hud_AddEventHandler( file.closeButton, UIE_CLICK, OnCloseButton_Activate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#CLOSE" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT" )
}

void function OnOpenModeSelectDialog()
{
	
}

void function OnCloseModeSelectDialog()
{

}

void function OnCloseButton_Activate( var button )
{
	CloseAllDialogs()
}