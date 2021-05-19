//

#if CLIENT || UI 
global function ShPassPanel_LevelInit
#endif

#if(CLIENT)
global function UIToClient_StartBattlePassScene
global function UIToClient_StopBattlePassScene
global function UIToClient_ItemPresentation
global function BattlePassScene_Thread
global function InitBattlePassLights
global function BattlePassLightsOn
global function BattlePassLightsOff
global function ClearBattlePassItem
#endif

#if(UI)
global function InitPassPanel
global function InitRewardPanel
global function InitPassAwardsMenu
global function InitLegendBonusDialog
global function InitAboutBattlePass1Dialog

global function GetRewardPanel

global function InitPassXPPurchaseDialog
global function InitPassPurchaseMenu

global function GetNumPages

global function GetBattlePassPurchaseOffer
global function GetBattlePassBundlePurchaseOffer
global function GetBattlePassXPPurchaseOffer

global function TryDisplayBattlePassAwards

global function InitBattlePassRewardButtonRui
#endif

#if(UI)
global function ShowPassAwardsDialog
#endif


//
//
//
//
//

struct RewardPanelData
{
	var panelCenter
	var panelLeft
	var panelRight
}

struct FileStruct_LifetimeLevel
{
	#if(CLIENT)
		bool                       isBattlePassSceneThreadActive = false
		vector                     sceneRefOrigin
		vector                     sceneRefAngles
		entity                     mover
		array<entity>              models
		NestedGladiatorCardHandle& bannerHandle
		var                        topo
		var                        rui
		array<entity>              stationaryLights
		//
		//
		string 						playingQuipAlias
	#endif
	table signalDummy
	int videoChannel = -1

}
FileStruct_LifetimeLevel& fileLevel


struct
{
	#if(UI)
		int currentPage = 0
		var rewardBarPanel
		var rewardBarFooter

		var nextPageButton
		var prevPageButton

		var statusBox
		var purchaseButton

		var levelReqButton
		var premiumReqButton

		var bonusPanel
		var bonusPanelButton

		var detailBox

		RewardPanelData[2] rewardPanelGroups
	#endif

} file

#if(UI)
global struct RewardGroup
{
	int                     level
	array<BattlePassReward> rewards
}

const int REWARDS_PER_PAGE = 14
#endif

//
//
//
//
//
#if CLIENT || UI 
void function ShPassPanel_LevelInit()
{
	#if(CLIENT)
		RegisterSignal( "StopBattlePassSceneThread" )
		RegisterButtonPressedCallback( MOUSE_WHEEL_UP, OnMouseWheelUp )
		RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN, OnMouseWheelDown )
	#endif
}
#endif


#if(UI)
void function InitPassPanel( var panel )
{
	SetPanelTabTitle( panel, "#PASS" )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, OnPanelShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, OnPanelHide )

	file.rewardBarPanel = Hud_GetChild( panel, "RewardBarPanel" )
	array<var> rewardButtons = GetPanelElementsByClassname( file.rewardBarPanel, "RewardButton" )
	foreach ( rewardButton in rewardButtons )
	{
		Hud_AddEventHandler( rewardButton, UIE_GET_FOCUS, BattlePass_OnFocusReward )
	}

	file.rewardBarFooter = Hud_GetChild( panel, "RewardBarFooter" )

	file.nextPageButton = Hud_GetChild( panel, "RewardBarNextButton" )
	file.prevPageButton = Hud_GetChild( panel, "RewardBarPrevButton" )
	var prevPageRui = Hud_GetRui( file.prevPageButton )
	RuiSetBool( prevPageRui, "flipHorizontal", true )

	Hud_AddEventHandler( file.nextPageButton, UIE_CLICK, BattlePass_PageForward )
	Hud_AddEventHandler( file.prevPageButton, UIE_CLICK, BattlePass_PageBackward )
	//
	file.statusBox = Hud_GetChild( panel, "StatusBox" )

	file.purchaseButton = Hud_GetChild( panel, "PurchaseButton" )
	Hud_AddEventHandler( file.purchaseButton, UIE_CLICK, BattlePass_OnPurchase )

	HudElem_SetRuiArg( Hud_GetChild( panel, "AboutButton" ), "buttonText", "#BATTLE_PASS_BUTTON_ABOUT" )
	Hud_AddEventHandler( Hud_GetChild( panel, "AboutButton" ), UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "BattlePassAboutPage1" ) ) )

	file.levelReqButton = Hud_GetChild( panel, "LevelReqButton" )
	file.premiumReqButton = Hud_GetChild( panel, "PremiumReqButton" )

	file.bonusPanel = Hud_GetChild( panel, "BonusBox" )
	file.bonusPanelButton = Hud_GetChild( file.bonusPanel, "FrameButton" )
	Hud_AddEventHandler( file.bonusPanelButton, UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "PassLegendBonusMenu" ) ) )
	Hud_AddEventHandler( file.bonusPanelButton, UIE_GET_FOCUS, (void function( var button ) : ()
		{
			HudElem_SetRuiArg( Hud_GetChild( file.bonusPanel, "PanelFrame" ), "isFocused", true )
		})
	)
	Hud_AddEventHandler( file.bonusPanelButton, UIE_LOSE_FOCUS, (void function( var button ) : ()
		{
			HudElem_SetRuiArg( Hud_GetChild( file.bonusPanel, "PanelFrame" ), "isFocused", false )
		})
	)

	file.detailBox = Hud_GetChild( panel, "DetailsBox" )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


var function GetRewardPanel()
{
	return file.rewardBarPanel
}

void function InitRewardPanel( var rewardBarPanel, array<RewardGroup> rewardGroups )
{
	int panelMaxWidth = Hud_GetBaseWidth( rewardBarPanel )
	printt( panelMaxWidth, Hud_GetBaseWidth( rewardBarPanel ), Hud_GetWidth( rewardBarPanel ) )

	const int MAX_REWARD_BUTTONS = 15
	const int MAX_REWARD_FOOTERS = 15

	int thinDividers
	int thickDividers
	int numButtons = 0
	foreach ( rewardIndex, rewardGroup in rewardGroups )
	{
		if ( rewardGroup.rewards.len() == 0 )
			continue

		thinDividers += (rewardGroup.rewards.len() - 1)
		if ( rewardIndex < (rewardGroups.len() - 1) )
			thickDividers++
		numButtons += rewardGroup.rewards.len()
	}

	array<var> rewardFooters = GetPanelElementsByClassname( rewardBarPanel, "RewardFooter" )
	Assert( rewardFooters.len() == MAX_REWARD_FOOTERS )

	array<var> rewardButtons = GetPanelElementsByClassname( rewardBarPanel, "RewardButton" )
	Assert( rewardButtons.len() == MAX_REWARD_BUTTONS )
	rewardButtons.sort( SortByScriptId )
	int buttonWidth = Hud_GetWidth( rewardButtons[0] )

	foreach ( rewardFooter in rewardFooters )
		Hud_Hide( rewardFooter )

	foreach ( rewardButton in rewardButtons )
		Hud_Hide( rewardButton )

	int totalPadding = panelMaxWidth - (buttonWidth * rewardButtons.len())

	int thinPadding  = ContentScaledXAsInt( 8 )
	int thickPadding = ContentScaledXAsInt( 16 )

	int contentWidth = (buttonWidth * numButtons) + (thinPadding * thinDividers) + (thickPadding * thickDividers)
	//
	bool hasPremiumPass = false
	int battlePassLevel = 0

	Hud_SetWidth( rewardBarPanel, contentWidth )
	Hud_SetWidth( file.rewardBarFooter, contentWidth )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null
	if ( hasActiveBattlePass )
	{
		expect ItemFlavor( activeBattlePass )
		hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
		battlePassLevel = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	}


	int offset      = 0
	int buttonIndex = 0
	int footerIndex = 0
	foreach ( _, rewardGroup in rewardGroups )
	{
		if ( rewardGroup.rewards.len() == 0 )
			continue

		var rewardFooter = rewardFooters[footerIndex]
		Hud_SetX( rewardFooter, offset )
		var footerRui = Hud_GetRui( rewardFooter )
		RuiSetString( footerRui, "levelText", GetBattlePassDisplayLevel( rewardGroup.level, true ) )
		RuiSetInt( footerRui, "level", rewardGroup.level )
		Hud_Show( rewardFooter )

		int footerWidth = 0
		foreach ( rewardIndex, bpReward in rewardGroup.rewards )
		{
			var rewardButton = rewardButtons[buttonIndex]

			Hud_SetX( rewardButton, offset )
			Hud_SetEnabled( rewardButton, hasActiveBattlePass )
			if ( buttonIndex == 0 )
				Hud_SetFocused( rewardButton )

			bool isOwned = (!bpReward.isPremium || hasPremiumPass) && bpReward.level < battlePassLevel
			HudElem_SetRuiArg( rewardButton, "isOwned", isOwned )
			RuiSetBool( footerRui, "isOwned", isOwned )
			HudElem_SetRuiArg( rewardButton, "isPremium", bpReward.isPremium )

			int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
			HudElem_SetRuiArg( rewardButton, "rarity", rarity )
			RuiSetImage( Hud_GetRui( rewardButton ), "buttonImage", GetImageForBattlePassReward( bpReward ) )

			if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
				HudElem_SetRuiArg( rewardButton, "isLootBox", true )

			HudElem_SetRuiArg( rewardButton, "itemCountString", "" )
			if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
				HudElem_SetRuiArg( rewardButton, "itemCountString", string( bpReward.quantity ) )

			HudElem_SetRuiArg( rewardButton, "bpLevel", bpReward.level )
			HudElem_SetRuiArg( rewardButton, "isRewardBar", true )

			offset += buttonWidth
			footerWidth += buttonWidth

			if ( rewardIndex < (rewardGroup.rewards.len() - 1) )
			{
				offset += thinPadding
				footerWidth += thinPadding
			}
			else
			{
				offset += thickPadding
			}

			buttonIndex++
		}
		Hud_SetWidth( rewardFooter, footerWidth )
		footerIndex++
	}

	for ( int index = 0; index < buttonIndex; index++ )
	{
		Hud_Show( rewardButtons[index] )
	}
}

void function BattlePass_PageForward( var button )
{
	EmitUISound( "UI_Menu_BattlePass_LevelTab" )
	BattlePass_SetPage( file.currentPage + 1 )
}


void function BattlePass_PageBackward( var button )
{
	EmitUISound( "UI_Menu_BattlePass_LevelTab" )
	BattlePass_SetPage( file.currentPage - 1 )
}


void function BattlePass_OnPurchase( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		return
	}
	expect ItemFlavor( activeBattlePass )

	int battlePassLevel               = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	bool hasPremiumPass               = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )

	if ( !hasPremiumPass )
		AdvanceMenu( GetMenu( "PassPurchaseMenu" ) )
	else if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) > 0 )
		AdvanceMenu( GetMenu( "PassXPPurchaseDialog" ) )
	else
		return
}

void function BattlePass_OnFocusReward( var button )
{
	printt( "BattlePass_OnFocusReward" )
	int scriptId = int( Hud_GetScriptID( button ) )

	array<RewardGroup> rewardGroups = GetRewardGroupsForPage( file.currentPage )

	int buttonIndex = 0
	foreach ( groupIndex, rewardGroup in rewardGroups )
	{
		foreach ( rewardIndex, bpReward in rewardGroup.rewards )
		{
			if ( scriptId == buttonIndex )
			{
				BattlePass_UpdateRewardDetails( bpReward )
				//
				return
			}

			buttonIndex++
		}
	}
}

string function BattlePass_GetShortDescString( BattlePassReward reward )
{
	switch( ItemFlavor_GetType( reward.flav ) )
	{
		case eItemType.weapon_skin:
			ItemFlavor ref = WeaponSkin_GetWeaponFlavor( reward.flav )
			return Localize( "#REWARD_SKIN", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.character_skin:
			ItemFlavor ref = CharacterSkin_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_SKIN", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.gladiator_card_stat_tracker:
			ItemFlavor ref = GladiatorCardStatTracker_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_TRACKER", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.gladiator_card_intro_quip:
			ItemFlavor ref = CharacterIntroQuip_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_QUIP", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.gladiator_card_kill_quip:
			ItemFlavor ref = CharacterKillQuip_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_QUIP", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.gladiator_card_frame:
			ItemFlavor ref = GladiatorCardFrame_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_FRAME", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.gladiator_card_stance:
			ItemFlavor ref = GladiatorCardStance_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_STANCE", Localize( ItemFlavor_GetLongName( ref ) ) )
		case eItemType.gladiator_card_badge:
			return Localize( "#REWARD_BADGE" )
	}

	return ""
}

string function GetBattlePassRewardHeaderText( BattlePassReward reward )
{
	string headerText = BattlePass_GetShortDescString( reward )
	if ( ItemFlavor_HasQuality( reward.flav ) )
	{
		string rarityName = ItemFlavor_GetQualityName( reward.flav )
		if ( headerText == "" )
			headerText = Localize( "#BATTLE_PASS_ITEM_HEADER", Localize( rarityName ) )
		else
			headerText = Localize( "#BATTLE_PASS_ITEM_HEADER_DESC", Localize( rarityName ), headerText )
	}

	return headerText
}


string function GetBattlePassRewardItemName( BattlePassReward reward )
{
	return ItemFlavor_GetLongName( reward.flav )
}


string function GetBattlePassRewardItemDesc( BattlePassReward reward )
{
	string itemDesc 	= ItemFlavor_GetLongDescription( reward.flav )
	if ( ItemFlavor_GetType( reward.flav ) == eItemType.account_currency )
	{
		if ( reward.flav == GetItemFlavorByAsset( $"settings/itemflav/grx_currency/crafting.rpak" ) )
			 itemDesc = GetFormattedValueForCurrency( reward.quantity, GRX_CURRENCY_CRAFTING )
		else
			itemDesc = GetFormattedValueForCurrency( reward.quantity, GRX_CURRENCY_PREMIUM )
	}
	else if ( ItemFlavor_GetType( reward.flav ) == eItemType.xp_boost )
		itemDesc = Localize( itemDesc, XpEventTypeData_GetFrac( XP_TYPE.BONUS_FRIEND_BOOST ) * 100.0 )

	return itemDesc
}

void function BattlePass_UpdateRewardDetails( BattlePassReward reward )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		return
	}
	expect ItemFlavor( activeBattlePass )

	int battlePassLevel = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )

	string itemName 	= GetBattlePassRewardItemName( reward )
	int rarity        	= ItemFlavor_HasQuality( reward.flav ) ? ItemFlavor_GetQuality( reward.flav ) : 0

	string itemDesc 	= GetBattlePassRewardItemDesc( reward )
	string headerText = GetBattlePassRewardHeaderText( reward )

	HudElem_SetRuiArg( file.detailBox, "headerText", headerText )
	HudElem_SetRuiArg( file.detailBox, "titleText", itemName )
	HudElem_SetRuiArg( file.detailBox, "descText", itemDesc )
	HudElem_SetRuiArg( file.detailBox, "rarity", rarity )

	HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityBulletText3", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText3", "" )

	if ( ItemFlavor_GetType( reward.flav ) == eItemType.account_pack )
	{
		if ( rarity == 1 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#LOOT_RARITY_CHANCE_1" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", Localize( "#LOOT_RARITY_CHANCE_2" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText3", Localize( "#LOOT_RARITY_CHANCE_3" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", Localize( "#LOOT_RARITY_PERCENT_1" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", Localize( "#LOOT_RARITY_PERCENT_2" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText3", Localize( "#LOOT_RARITY_PERCENT_3" ) )
		}
		else if ( rarity == 2 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#LOOT_RARITY_CHANCE_2" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", Localize( "#LOOT_RARITY_CHANCE_3" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", Localize( "#LOOT_RARITY_PERCENT_1" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", Localize( "#LOOT_RARITY_PERCENT_3" ) )
		}
		else if ( rarity == 3 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#LOOT_RARITY_CHANCE_3" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", Localize( "#LOOT_RARITY_PERCENT_1" ) )
		}
	}

	HudElem_SetRuiArg( file.levelReqButton, "buttonText", Localize( "#BATTLE_PASS_LEVEL_REQUIRED", reward.level + 2 ) )
	HudElem_SetRuiArg( file.levelReqButton, "meetsRequirement", battlePassLevel >= reward.level + 1 )
	HudElem_SetRuiArg( file.levelReqButton, "isPremium", false )

	if ( reward.isPremium && hasPremiumPass )
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_PREMIUM_REWARD" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", true )
	}
	else if ( reward.isPremium && !hasPremiumPass )
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_PREMIUM_REQUIRED" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", false )
	}
	else
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_FREE_REWARD" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", true )
	}

	HudElem_SetRuiArg( file.premiumReqButton, "isPremium", reward.isPremium )

	RunClientScript( "UIToClient_ItemPresentation", ItemFlavor_GetGUID( reward.flav ), reward.level )
}


array<RewardGroup> function GetRewardGroupsForPage( int pageNumber )
{
	array<RewardGroup> rewardGroups

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return rewardGroups

	expect ItemFlavor( activeBattlePass )

	if ( pageNumber == 0 )
	{
		RewardGroup rewardGroup
		rewardGroup.level = 0

		array<BattlePassReward> rewardList = GetBattlePassBaseRewards( activeBattlePass )

		rewardGroup.rewards = rewardList
		rewardGroups.append( rewardGroup )
	}

	int levelOffset = GetLevelOffsetForPage( activeBattlePass, pageNumber )
	int endLevelOffset = GetNumLevelsForPage( activeBattlePass, pageNumber )
	for ( int levelIndex = levelOffset; levelIndex < endLevelOffset; levelIndex++ )
	{
		RewardGroup rewardGroup
		rewardGroup.level = levelIndex + 1
		rewardGroup.rewards = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
		rewardGroups.append( rewardGroup )
	}

	return rewardGroups
}


int function GetLevelOffsetForPage( ItemFlavor activeBattlePass, int pageIndex )
{
	array<int> pageToLevelIndex = [0]
	int rewardCount             = GetBattlePassBaseRewards( activeBattlePass ).len()
	for ( int levelIndex = 0; levelIndex < GetBattlePassMaxLevelIndex( activeBattlePass ); levelIndex++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
		if ( rewardCount + rewards.len() <= REWARDS_PER_PAGE )
		{
			rewardCount += rewards.len()
		}
		else
		{
			pageToLevelIndex.append( levelIndex )
			rewardCount = rewards.len()
		}
	}

	return pageToLevelIndex[pageIndex]
}


int function GetNumPages( ItemFlavor activeBattlePass )
{
	array<int> pageToLevelIndex = [0]
	int rewardCount             = GetBattlePassBaseRewards( activeBattlePass ).len()
	for ( int levelIndex = 0; levelIndex < GetBattlePassMaxLevelIndex( activeBattlePass ); levelIndex++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
		if ( rewardCount + rewards.len() <= REWARDS_PER_PAGE )
		{
			rewardCount += rewards.len()
		}
		else
		{
			pageToLevelIndex.append( levelIndex )
			rewardCount = rewards.len()
		}
	}

	return pageToLevelIndex.len()
}


int function GetNumLevelsForPage( ItemFlavor activeBattlePass, int pageIndex )
{
	int rewardCount = pageIndex == 0 ? 3 : 0
	int levelIndex  = GetLevelOffsetForPage( activeBattlePass, pageIndex )
	for ( ; levelIndex <= GetBattlePassMaxLevelIndex( activeBattlePass ) && rewardCount < REWARDS_PER_PAGE; levelIndex++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
		rewardCount += rewards.len()

		if ( rewardCount > REWARDS_PER_PAGE )
			return levelIndex
	}

	return levelIndex
}


array<RewardGroup> function GetEmptyRewardGroups()
{
	array<RewardGroup> rewardGroups
	BattlePassReward emptyReward

	for ( int levelIndex = 0; levelIndex < 10; levelIndex++ )
	{
		RewardGroup rewardGroup
		rewardGroup.level = levelIndex
		rewardGroup.rewards.append( emptyReward )
		if ( levelIndex % 2 )
		{
			rewardGroup.rewards.append( emptyReward )
		}
		rewardGroups.append( rewardGroup )
	}

	return rewardGroups
}

void function BattlePass_SetPageToCurrentLevel()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		BattlePass_SetPage( 0 )
		return
	}
	expect ItemFlavor( activeBattlePass )

	int currentLevel = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false ) + 1
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )

	for ( int pageNum = 0 ; pageNum < GetNumPages( activeBattlePass ) ; pageNum++ )
	{
		int startLevel = GetLevelOffsetForPage( activeBattlePass, pageNum )
		int endLevel = GetNumLevelsForPage( activeBattlePass, pageNum )
		if ( currentLevel >= startLevel && currentLevel <= endLevel )
		{
			BattlePass_SetPage( pageNum )
			if ( hasPremiumPass )
				BattlePass_UpdateRewardDetailsToNextReward( activeBattlePass, currentLevel )
			else
				BattlePass_UpdateRewardDetails( GetBattlePassBaseRewards( activeBattlePass )[0] )
			return
		}
	}

	BattlePass_SetPage( GetNumPages( activeBattlePass ) )
	BattlePass_UpdateRewardDetailsToNextReward( activeBattlePass, currentLevel )

	//
}

void function BattlePass_UpdateRewardDetailsToNextReward( ItemFlavor activeBattlePass, int currentLevel )
{
	int levelIndex = currentLevel - 1
	array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIndex, GetUIPlayer() )
	foreach( BattlePassReward reward in rewards )
	{
		BattlePass_UpdateRewardDetails( reward )
		return
	}
}

void function BattlePass_SetPage( int pageNumber )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		file.currentPage = 0
		return
	}

	expect ItemFlavor( activeBattlePass )

	pageNumber = ClampInt( pageNumber, 0, GetNumPages( activeBattlePass ) - 1 )
	file.currentPage = pageNumber

	array<RewardGroup> rewardGroups = GetRewardGroupsForPage( pageNumber )

	var rewardBarPanel = file.rewardBarPanel

	InitRewardPanel( rewardBarPanel, rewardGroups )
	Hud_SetVisible( file.prevPageButton, pageNumber > 0 )
	Hud_SetVisible( file.nextPageButton, pageNumber < 9 )

	int startLevel = GetLevelOffsetForPage( activeBattlePass, pageNumber ) + 1
	int endLevel = GetNumLevelsForPage( activeBattlePass, pageNumber )

	if ( pageNumber == 0 )
		startLevel--

	HudElem_SetRuiArg( file.rewardBarFooter, "currentPage", pageNumber )
	HudElem_SetRuiArg( file.rewardBarFooter, "levelRangeText", Localize( "#BATTLE_PASS_LEVEL_RANGE", startLevel + 1, endLevel + 1 ) )
	HudElem_SetRuiArg( file.rewardBarFooter, "numPages", GetNumPages( activeBattlePass ) )
}
#endif


#if(UI)
void function OnPanelShow( var panel )
{
	UI_SetPresentationType( ePresentationType.BATTLE_PASS )
	//

	RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN, BattlePass_PageForward )
	RegisterButtonPressedCallback( MOUSE_WHEEL_UP, BattlePass_PageBackward )
	RegisterButtonPressedCallback( BUTTON_TRIGGER_LEFT, BattlePass_PageBackward )
	RegisterButtonPressedCallback( BUTTON_TRIGGER_RIGHT, BattlePass_PageForward )

	BattlePass_SetPageToCurrentLevel()
	BattlePass_UpdateStatus()
	BattlePass_UpdateBonusPanel()
	BattlePass_UpdatePurchaseButton()

	AddCallbackAndCallNow_OnGRXOffersRefreshed( OnGRXStateChanged )
	AddCallbackAndCallNow_OnGRXInventoryStateChanged( OnGRXStateChanged )
}


void function OnPanelHide( var panel )
{
	RunClientScript( "UIToClient_StopBattlePassScene" )

	DeregisterButtonPressedCallback( MOUSE_WHEEL_DOWN, BattlePass_PageForward )
	DeregisterButtonPressedCallback( MOUSE_WHEEL_UP, BattlePass_PageBackward )
	DeregisterButtonPressedCallback( BUTTON_TRIGGER_LEFT, BattlePass_PageBackward )
	DeregisterButtonPressedCallback( BUTTON_TRIGGER_RIGHT, BattlePass_PageForward )

	RemoveCallback_OnGRXOffersRefreshed( OnGRXStateChanged )
	RemoveCallback_OnGRXInventoryStateChanged( OnGRXStateChanged )
}


void function OnGRXStateChanged()
{
	bool ready = GRX_IsInventoryReady() && GRX_AreOffersReady()

	if ( !ready )
		return

	thread TryDisplayBattlePassAwards()
}


void function BattlePass_UpdatePurchaseButton()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#COMING_SOON" )
		return
	}

	expect ItemFlavor( activeBattlePass )

	Hud_SetLocked( file.purchaseButton, false )
	Hud_ClearToolTipData( file.purchaseButton )

	if ( GRX_IsItemOwnedByPlayer( activeBattlePass ) )
	{
		HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#BATTLE_PASS_BUTTON_PURCHASE_XP" )

		if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) == 0 )
		{
			HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#BATTLE_PASS_BUTTON_PURCHASE_XP" )
			Hud_SetLocked( file.purchaseButton, true )
			ToolTipData toolTipData
			toolTipData.titleText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL"
			toolTipData.descText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL_DESC"
			Hud_SetToolTipData( file.purchaseButton, toolTipData )
		}
	}
	else
	{
		HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#BATTLE_PASS_BUTTON_PURCHASE" )
	}
}

/*






























*/

struct BPCharacterXPData
{
	ItemFlavor & character
	int          earnedXP
}

void function BattlePass_UpdateBonusPanel()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		Hud_SetVisible( file.bonusPanel, false )
		return
	}
	expect ItemFlavor( activeBattlePass )

	array<BPCharacterXPData> characterXpDataArray
	int charactersWithRemainingXp = 0

	int maxCharacterXP = GetBattlePassCharacterBonusXPMax( activeBattlePass )

	foreach( ItemFlavor character in GetAllCharacters() )
	{
		if ( !IsItemFlavorUnlockedForLoadoutSlot( ToEHI( GetUIPlayer() ), Loadout_CharacterClass(), character ) )
			continue

		BPCharacterXPData characterXpData
		characterXpData.character = character
		characterXpData.earnedXP = GetPlayerBattlePassCharacterXP( GetUIPlayer(), activeBattlePass, character )
		if ( characterXpData.earnedXP < maxCharacterXP )
			charactersWithRemainingXp++

		characterXpDataArray.append( characterXpData )
	}

	characterXpDataArray.sort( SortByRemainingXP )

	Hud_SetVisible( file.bonusPanel, characterXpDataArray[0].earnedXP < maxCharacterXP )

	const int BONUS_BUTTONS = 6
	array<float> buttonAlphas = [1.0, .45, .15, .05, .01, 0.05]
	for ( int index = 0; index < BONUS_BUTTONS; index++ )
	{
		var button = Hud_GetChild( file.bonusPanel, "BonusButton" + (index + 1) )
		if ( index >= characterXpDataArray.len() )
		{
			Hud_SetVisible( button, false )
			continue
		}

		Hud_SetVisible( button, characterXpDataArray[index].earnedXP < maxCharacterXP )

		if ( index == (BONUS_BUTTONS - 1) && characterXpDataArray[index].earnedXP < maxCharacterXP )
		{
			HudElem_SetRuiArg( button, "buttonImage", $"rui/hud/common/chevron_left_big", eRuiArgType.IMAGE )
			HudElem_SetRuiArg( button, "xp", charactersWithRemainingXp - (BONUS_BUTTONS - 1) )
			HudElem_SetRuiArg( button, "isMoreButton", true )
		}
		else
		{
			HudElem_SetRuiArg( button, "buttonImage", CharacterClass_GetGalleryPortrait( characterXpDataArray[index].character ), eRuiArgType.IMAGE )
			HudElem_SetRuiArg( button, "buttonBackground", CharacterClass_GetGalleryPortraitBackground( characterXpDataArray[index].character ), eRuiArgType.IMAGE )
			HudElem_SetRuiArg( button, "xp", characterXpDataArray[index].earnedXP )
			HudElem_SetRuiArg( button, "isMoreButton", false )
			HudElem_SetRuiArg( button, "alpha", buttonAlphas[index])
		}
	}
}


int function SortByRemainingXP( BPCharacterXPData a, BPCharacterXPData b )
{
	if ( a.earnedXP > b.earnedXP )
		return 1
	else if ( b.earnedXP > a.earnedXP )
		return -1

	return 0
}

void function BattlePass_UpdateStatus()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null

	if ( !hasActiveBattlePass )
		return

	expect ItemFlavor(activeBattlePass)

	int currentBattlePassXP = GetPlayerBattlePassXPProgress( ToEHI( GetUIPlayer() ), activeBattlePass, false )

	int ending_passLevel       = GetBattlePassLevelForXP( activeBattlePass, currentBattlePassXP )
	int ending_passXP          = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel - 1 )

	int ending_nextPassLevelXP
	if ( ending_passLevel > GetBattlePassMaxLevelIndex( activeBattlePass ) )
		ending_nextPassLevelXP = ending_passXP
	else
		ending_nextPassLevelXP = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel )

	int xpToCompleteLevel = ending_nextPassLevelXP - ending_passXP
	int xpForLevel        = currentBattlePassXP - ending_passXP

	Assert( currentBattlePassXP >= ending_passXP )
	Assert( currentBattlePassXP <= ending_nextPassLevelXP )
	float ending_passLevelFrac = GraphCapped( currentBattlePassXP, ending_passXP, ending_nextPassLevelXP, 0.0, 1.0 )

	//
	//
	//
	//
	//

	ItemFlavor ornull currentSeason = GetLatestSeason( GetUnixTimestamp() )
	int seasonEndUnixTime = CalEvent_GetFinishUnixTime( expect ItemFlavor( currentSeason ) )
	DisplayTime dt = SecondsToDHMS( seasonEndUnixTime - GetUnixTimestamp() )

	HudElem_SetRuiArg( file.statusBox, "seasonNameText", ItemFlavor_GetLongName( activeBattlePass ) )
	HudElem_SetRuiArg( file.statusBox, "timeRemainingText", Localize( "#BATTLE_PASS_DAYS_REMAINING", string( dt.days ), string( dt.hours ) ) )
	HudElem_SetRuiArg( file.statusBox, "seasonNumberText", Localize( "#BATTLE_PASS_SEASON_NUMBER", "1" ) )

	ItemFlavor dummy
	ItemFlavor bpLevelBadge = GetItemFlavorByAsset( $"settings/itemflav/gcard_badge/account/season01_bplevel.rpak" )

	RuiDestroyNestedIfAlive( Hud_GetRui( file.statusBox ), "currentBadgeHandle" )
	CreateNestedGladiatorCardBadge( Hud_GetRui( file.statusBox ), "currentBadgeHandle", ToEHI( GetUIPlayer() ), bpLevelBadge, 0, dummy, ending_passLevel + 1 )

	RuiDestroyNestedIfAlive( Hud_GetRui( file.statusBox ), "nextBadgeHandle" )
	if ( xpToCompleteLevel > 0 )
		CreateNestedGladiatorCardBadge( Hud_GetRui( file.statusBox ), "nextBadgeHandle", ToEHI( GetUIPlayer() ), bpLevelBadge, 0, dummy, ending_passLevel + 2 )

	HudElem_SetRuiArg( file.statusBox, "currentXp", xpForLevel )
	HudElem_SetRuiArg( file.statusBox, "requiredXp", xpToCompleteLevel )
}
#endif


#if(UI)
struct
{
	var menu
	var rewardPanel
	var header
	var background

	var purchaseButton
	var incButton
	var decButton

	table<var, BattlePassReward> buttonToItem

	int purchaseQuantity = 1

	bool closeOnGetTopLevel = false

} s_passPurchaseXPDialog
#endif


#if(UI)
void function InitPassXPPurchaseDialog()
{
	var menu = GetMenu( "PassXPPurchaseDialog" )
	s_passPurchaseXPDialog.menu = menu
	s_passPurchaseXPDialog.rewardPanel = Hud_GetChild( menu, "RewardList" )
	s_passPurchaseXPDialog.header = Hud_GetChild( menu, "Header" )
	s_passPurchaseXPDialog.background = Hud_GetChild( menu, "Background" )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PassXPPurchaseDialog_OnOpen )

	AddMenuEventHandler( menu, eUIEvent.MENU_GET_TOP_LEVEL, PassXPPurchaseDialog_OnGetTopLevel )

	//

	//

	s_passPurchaseXPDialog.purchaseButton = Hud_GetChild( menu, "PurchaseButton" )
	Hud_AddEventHandler( s_passPurchaseXPDialog.purchaseButton, UIE_CLICK, PassXPPurchaseButton_OnActivate )

	s_passPurchaseXPDialog.incButton = Hud_GetChild( menu, "IncButton" )
	Hud_AddEventHandler( s_passPurchaseXPDialog.incButton, UIE_CLICK, PassXPIncButton_OnActivate )

	s_passPurchaseXPDialog.decButton = Hud_GetChild( menu, "DecButton" )
	Hud_AddEventHandler( s_passPurchaseXPDialog.decButton, UIE_CLICK, PassXPDecButton_OnActivate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function PassXPPurchaseDialog_OnOpen()
{
	s_passPurchaseXPDialog.purchaseQuantity = 1

	PassXPPurchaseDialog_UpdateRewards()
}


void function PassXPPurchaseDialog_OnGetTopLevel()
{
	if ( s_passPurchaseXPDialog.closeOnGetTopLevel )
	{
		s_passPurchaseXPDialog.closeOnGetTopLevel = false
		CloseActiveMenu()
	}
}


void function PassXPPurchaseDialog_UpdateRewards()
{
	GRXScriptOffer xpPurchaseOffer = expect GRXScriptOffer( GetBattlePassXPPurchaseOffer() )
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	int startingPurchaseLevelIndex = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	int maxPurchasableLevels = GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass )

	if ( s_passPurchaseXPDialog.purchaseQuantity == maxPurchasableLevels )
	{
		ToolTipData toolTipData
		toolTipData.titleText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL"
		toolTipData.descText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL_DESC"
		Hud_SetToolTipData( s_passPurchaseXPDialog.incButton, toolTipData )
	}
	else
	{
		Hud_ClearToolTipData( s_passPurchaseXPDialog.incButton )
	}

	if ( s_passPurchaseXPDialog.purchaseQuantity == 1 )
	{
		HudElem_SetRuiArg( s_passPurchaseXPDialog.purchaseButton, "quantityText", Localize( "#BATTLE_PASS_PLUS_N_LEVEL", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "titleText", Localize( "#BATTLE_PASS_PURCHASE_LEVEL", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "descText", Localize( "#BATTLE_PASS_PURCHASE_LEVEL_DESC", s_passPurchaseXPDialog.purchaseQuantity, (startingPurchaseLevelIndex + 1) + s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.background, "headerText", "#BATTLE_PASS_YOU_WILL_RECEIVE" )
	}
	else
	{
		HudElem_SetRuiArg( s_passPurchaseXPDialog.purchaseButton, "quantityText", Localize( "#BATTLE_PASS_PLUS_N_LEVELS", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "titleText", Localize( "#BATTLE_PASS_PURCHASE_LEVELS", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "descText", Localize( "#BATTLE_PASS_PURCHASE_LEVELS_DESC", s_passPurchaseXPDialog.purchaseQuantity, (startingPurchaseLevelIndex + 1) + s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.background, "headerText", "#BATTLE_PASS_YOU_WILL_RECEIVE" )
	}

	HudElem_SetRuiArg( s_passPurchaseXPDialog.purchaseButton, "buttonText", GRX_GetFormattedPrice( xpPurchaseOffer.prices[0], s_passPurchaseXPDialog.purchaseQuantity ) )

	array<BattlePassReward> rewards
	array<BattlePassReward> allRewards
	for ( int index = 0; index < s_passPurchaseXPDialog.purchaseQuantity; index++ )
	{
		allRewards.extend( GetBattlePassLevelRewards( activeBattlePass, startingPurchaseLevelIndex + index ) )
	}

	foreach ( reward in allRewards )
	{
		rewards.append( reward )
	}

	var scrollPanel = Hud_GetChild( s_passPurchaseXPDialog.rewardPanel, "ScrollPanel" )

	foreach ( button, _ in s_passPurchaseXPDialog.buttonToItem )
	{
		//
	}
	s_passPurchaseXPDialog.buttonToItem.clear()

	int numRewards = rewards.len()

	Hud_InitGridButtonsDetailed( s_passPurchaseXPDialog.rewardPanel, numRewards, 2, minint( numRewards, 5 ) )
	for ( int index = 0; index < numRewards; index++ )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + index )

		BattlePassReward bpReward = rewards[index]
		s_passPurchaseXPDialog.buttonToItem[button] <- bpReward

		HudElem_SetRuiArg( button, "isOwned", true )
		HudElem_SetRuiArg( button, "isPremium", bpReward.isPremium )

		int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
		HudElem_SetRuiArg( button, "rarity", rarity )
		RuiSetImage( Hud_GetRui( button ), "buttonImage", GetImageForBattlePassReward( bpReward ) )

		if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
			HudElem_SetRuiArg( button, "isLootBox", true )

		HudElem_SetRuiArg( button, "itemCountString", "" )
		if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
			HudElem_SetRuiArg( button, "itemCountString", string( bpReward.quantity ) )

		ToolTipData toolTip
		toolTip.titleText = GetBattlePassRewardHeaderText( bpReward )
		toolTip.descText = GetBattlePassRewardItemName( bpReward )
		Hud_SetToolTipData( button, toolTip )
	}
}


void function InitBattlePassRewardButtonRui( var rui, BattlePassReward bpReward )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null
	bool hasPremiumPass                = false
	int battlePassLevel                = 0
	if ( hasActiveBattlePass )
	{
		expect ItemFlavor( activeBattlePass )
		hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
		battlePassLevel = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	}

	bool isOwned = (!bpReward.isPremium || hasPremiumPass) && bpReward.level < battlePassLevel
	RuiSetBool( rui, "isOwned", isOwned )
	RuiSetBool( rui, "isPremium", bpReward.isPremium )

	int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
	RuiSetInt( rui, "rarity", rarity )
	RuiSetImage( rui, "buttonImage", GetImageForBattlePassReward( bpReward ) )

	if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
		RuiSetBool( rui, "isLootBox", true )

	RuiSetString( rui, "itemCountString", "" )
	if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
		RuiSetString( rui, "itemCountString", string( bpReward.quantity ) )
}



void function PassXPPurchaseButton_OnActivate( var button )
{
	if ( Hud_IsLocked( button ) )
		return

	if ( GetBattlePassXPPurchaseOffer() == null )
		return

	int quantity = s_passPurchaseXPDialog.purchaseQuantity

	ItemFlavorPurchasabilityInfo ifpi = GRX_GetItemPurchasabilityInfo( BATTLEPASS_SEASON1_PURCAHSED_XP_FLAV )
	Assert( ifpi.isPurchasableAtAll )

	if ( IsDialog( GetActiveMenu() ) )
		CloseActiveMenu()

	PurchaseDialog( BATTLEPASS_SEASON1_PURCAHSED_XP_FLAV, quantity, false, null, OnBattlePassXPPurchaseResult )
}


void function OnBattlePassXPPurchaseResult( bool wasSuccessful )
{
	if ( wasSuccessful )
		s_passPurchaseXPDialog.closeOnGetTopLevel = true
}


void function PassXPIncButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	int maxPurchasableLevels = GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass )
	s_passPurchaseXPDialog.purchaseQuantity = minint(s_passPurchaseXPDialog.purchaseQuantity + 1, maxPurchasableLevels)

	PassXPPurchaseDialog_UpdateRewards()
}


void function PassXPDecButton_OnActivate( var button )
{
	s_passPurchaseXPDialog.purchaseQuantity = maxint( s_passPurchaseXPDialog.purchaseQuantity - 1, 1 )

	PassXPPurchaseDialog_UpdateRewards()
}
#endif

#if(UI)
struct
{
	var menu

	var header

	array<var> characterButtons
	table<var, ItemFlavor> buttonToCharacter

} s_legendBonusDialog


void function InitLegendBonusDialog()
{
	var menu = GetMenu( "PassLegendBonusMenu" )
	s_legendBonusDialog.menu = menu
	s_legendBonusDialog.header = Hud_GetChild( menu, "Header" )

	SetDialog( menu, true )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, LegendBonusDialog_OnOpen )

	s_legendBonusDialog.characterButtons = GetPanelElementsByClassname( menu, "CharacterButtonClass" )

	foreach ( button in s_legendBonusDialog.characterButtons )
	{
		Hud_AddEventHandler( button, UIE_GET_FOCUS, LegendBonusButton_GetFocus )
		Hud_AddEventHandler( button, UIE_LOSE_FOCUS, LegendBonusButton_LoseFocus )
	}

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function LegendBonusDialog_OnOpen()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	if ( GetBattlePassCharacterWeeklyXPMax( activeBattlePass ) > 0 )
	{
		string weeklyValue = ShortenNumber( string( GetBattlePassCharacterWeeklyXPMax( activeBattlePass ) ) )
		HudElem_SetRuiArg( s_legendBonusDialog.header, "descText", Localize( "#BATTLE_PASS_BONUS_REMAINING_WEEKLY_DESC", weeklyValue ) )
	}
	else
	{
		string xpValue = ShortenNumber( string( GetBattlePassCharacterBonusXPMax( activeBattlePass ) ) )
		HudElem_SetRuiArg( s_legendBonusDialog.header, "descText", Localize( "#BATTLE_PASS_BONUS_REMAINING_DESC", xpValue ) )
	}

	InitLegendBonusCharacterButtons()
}


void function LegendBonusButton_GetFocus( var button )
{
	ItemFlavor character = s_legendBonusDialog.buttonToCharacter[button]

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	int characterXP = GetPlayerBattlePassCharacterXP( GetUIPlayer(), activeBattlePass, character )

	RuiSetString( Hud_GetRui( button ), "buttonText", Localize( ItemFlavor_GetLongName( character ) ).toupper() )

}


void function LegendBonusButton_LoseFocus( var button )
{
	UpdateCharacterButtonXPData( button )
}


void function UpdateCharacterButtonXPData( var button )
{
	ItemFlavor character = s_legendBonusDialog.buttonToCharacter[button]

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	int characterXP = GetPlayerBattlePassCharacterXP( GetUIPlayer(), activeBattlePass, character )
	if ( characterXP >= GetBattlePassCharacterBonusXPMax( activeBattlePass ) )
	{
		RuiSetString( Hud_GetRui( button ), "buttonText", Localize( "#BATTLE_PASS_DONE" ) )
	}
	else
	{
		string characterXPString = string( characterXP )
		string maxXPString = string( GetBattlePassCharacterBonusXPMax( activeBattlePass ) )
		RuiSetString( Hud_GetRui( button ), "buttonText", Localize( "#N_SLASH_N", ShortenNumber( characterXPString ), ShortenNumber( maxXPString ) ) )
		RuiSetString( Hud_GetRui( button ), "buttonText", ShortenNumber( characterXPString ) + "`1 /" + ShortenNumber( maxXPString ) )
		//
	}
}


void function InitLegendBonusCharacterButtons()
{
	s_legendBonusDialog.buttonToCharacter.clear()

	array<ItemFlavor> shippingCharacters
	array<ItemFlavor> devCharacters
	array<ItemFlavor> allCharacters
	foreach ( ItemFlavor itemFlav in GetAllCharacters() )
	{
		bool isAvailable = IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), itemFlav )
		if ( !isAvailable )
		{
			if ( !ItemFlavor_ShouldBeVisible( itemFlav, GetUIPlayer() ) )
				continue
		}

		allCharacters.append( itemFlav )
	}

	foreach ( button in s_legendBonusDialog.characterButtons )
		Hud_SetVisible( button, false )

	table<int,ItemFlavor> mappingTable = GetCharacterButtonMapping( allCharacters, s_legendBonusDialog.characterButtons.len() )
	foreach( int buttonIndex, ItemFlavor itemFlav in mappingTable )
	{
		CharacterButton_Init( s_legendBonusDialog.characterButtons[ buttonIndex ], itemFlav )
		Hud_SetVisible( s_legendBonusDialog.characterButtons[ buttonIndex ], true )
	}
}


void function CharacterButton_Init( var button, ItemFlavor character )
{
	s_legendBonusDialog.buttonToCharacter[button] <- character

	//
	//
	bool isLocked   = IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), character )

	Hud_SetVisible( button, true )
	Hud_SetLocked( button, !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_CharacterClass(), character ) )

	RuiSetString( Hud_GetRui( button ), "buttonText", Localize( ItemFlavor_GetLongName( character ) ).toupper() )
	RuiSetImage( Hud_GetRui( button ), "buttonImage", CharacterClass_GetGalleryPortrait( character ) )
	RuiSetImage( Hud_GetRui( button ), "bgImage", CharacterClass_GetGalleryPortraitBackground( character ) )
	RuiSetImage( Hud_GetRui( button ), "roleImage", CharacterClass_GetCharacterRoleImage( character ) )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	int characterXP = GetPlayerBattlePassCharacterXP( GetUIPlayer(), activeBattlePass, character )
	HudElem_SetRuiArg( button, "fillFrac", characterXP / float( GetBattlePassCharacterBonusXPMax( activeBattlePass ) ) )

	UpdateCharacterButtonXPData( button )
}

#endif //

#if(UI)

void function InitAboutBattlePass1Dialog()
{
	var menu = GetMenu( "BattlePassAboutPage1" )
	SetDialog( menu, true )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, AboutBattlePass1Dialog_OnOpen )

	//

	//
	//
	//
	//
	//

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function AboutBattlePass1Dialog_OnOpen()
{
	var menu = GetMenu( "BattlePassAboutPage1" )
	var rui = Hud_GetRui( Hud_GetChild( menu, "InfoPanel" ) )

	RuiSetBool( rui, "grxOfferRestricted", GRX_IsOfferRestricted() )
}

#endif


#if(UI)
void function ShowRewardTable( var button )
{
	//
}
#endif


#if(CLIENT)
void function UIToClient_StartBattlePassScene( var panel )
{
	//
	//
}
#endif


#if(CLIENT)
void function UIToClient_StopBattlePassScene()
{
	//
	Signal( fileLevel.signalDummy, "StopBattlePassSceneThread" )
	ClearBattlePassItem()
}
#endif


#if(CLIENT)
//
//
//
//
//
//
struct CarouselColumnState
{
	int    level = -1
	var    topo
	var    rui
	var    columnClickZonePanel
	entity reward1Model
	var    reward1DetailsPanel
	entity reward2Model
	var    reward2DetailsPanel
	entity light
	float  growSize = 0.0
}


void function BattlePassScene_Thread( var panel )
{
	Signal( fileLevel.signalDummy, "StopBattlePassSceneThread" ) //
	EndSignal( fileLevel.signalDummy, "StopBattlePassSceneThread" )

	fileLevel.isBattlePassSceneThreadActive = true

	entity cam = clGlobal.menuCamera
	//
	//
	//

	float camSceneDist = 100.0
	vector camOrg      = cam.GetOrigin()
	vector camAng      = cam.GetAngles()
	vector camForward  = AnglesToForward( camAng )
	vector camRight    = AnglesToRight( camAng )
	vector camUp       = AnglesToUp( camAng )

	float bgSize       = 10000.0
	vector bgCenterPos = camOrg + 300.0 * camForward - bgSize * 0.5 * camRight + bgSize * 0.5 * camUp
	var bgTopo         = RuiTopology_CreatePlane( bgCenterPos, bgSize * camRight, bgSize * -camUp, false )
	DebugDrawAxis( camOrg + camSceneDist * camForward )
	var bgRui = RuiCreate( $"ui/lobby_battlepass_temp_bg.rpak", bgTopo, RUI_DRAW_WORLD, 10000 )
	RuiSetFloat3( bgRui, "pos", bgCenterPos )
	RuiKeepSortKeyUpdated( bgRui, true, "pos" )

	OnThreadEnd( function() : ( bgTopo, bgRui ) {

		fileLevel.isBattlePassSceneThreadActive = false

		RuiDestroy( bgRui )
		RuiTopology_Destroy( bgTopo )
	} )

	WaitForever()
}
#endif


#if(CLIENT)
void function OnMouseWheelUp( entity unused )
{
	//
}
#endif


#if(CLIENT)
void function OnMouseWheelDown( entity unused )
{
	//
}
#endif

#if(UI)
struct
{
	var menu
	var rewardPanel
	var passPurchaseButton
	var bundlePurchaseButton
	var seasonLogoBox

	bool closeOnGetTopLevel = false
} s_passPurchaseMenu

void function InitPassPurchaseMenu()
{
	var menu = GetMenu( "PassPurchaseMenu" )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PassPurchaseMenu_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_GET_TOP_LEVEL, PassPurchaseMenu_OnGetTopLevel )

	s_passPurchaseMenu.menu = menu
	s_passPurchaseMenu.passPurchaseButton = Hud_GetChild( menu, "PassPurchaseButton" )
	s_passPurchaseMenu.bundlePurchaseButton = Hud_GetChild( menu, "BundlePurchaseButton" )
	s_passPurchaseMenu.seasonLogoBox = Hud_GetChild( menu, "SeasonLogo" )

	Hud_AddEventHandler( s_passPurchaseMenu.passPurchaseButton, UIE_CLICK, PassPurchaseButton_OnActivate )
	Hud_AddEventHandler( s_passPurchaseMenu.bundlePurchaseButton, UIE_CLICK, BundlePurchaseButton_OnActivate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function PassPurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	if ( !CanPlayerPurchaseBattlePass( GetUIPlayer(), activeBattlePass ) )
		return

	ItemFlavor battlePass = GRX_BATTLEPASS_PURCHASE_PACK_BASIC
	PurchaseDialog( battlePass, 1, false, null, OnBattlePassPurchaseResults )
	PurchaseDialog_SetPurchaseOverrideSound( "UI_Menu_BattlePass_Purchase" )
}


void function BundlePurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	if ( !CanPlayerPurchaseBattlePass( GetUIPlayer(), activeBattlePass ) )
		return

	if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) < 25 )
		return

	ItemFlavor battlePassBundle = GRX_BATTLEPASS_PURCHASE_PACK_BUNDLE
	PurchaseDialog( battlePassBundle, 1, false, null, OnBattlePassPurchaseResults )
	PurchaseDialog_SetPurchaseOverrideSound( "UI_Menu_BattlePass_Purchase" )
}


void function PassPurchaseMenu_OnOpen()
{
	RunClientScript( "ClearBattlePassItem" )
	UI_SetPresentationType( ePresentationType.BATTLE_PASS )

	if ( GRX_IsOfferRestricted( GetUIPlayer() ) )
	{
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText1", "#BATTLE_PASS_FEATURE_1" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText2", "#BATTLE_PASS_FEATURE_2" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText3", "#BATTLE_PASS_FEATURE_3" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText4", "#BATTLE_PASS_FEATURE_RESTRICTED" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText5", "#BATTLE_PASS_FEATURE_7" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText6", "#BATTLE_PASS_FEATURE_8" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText7", "#BATTLE_PASS_FEATURE_9" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText8", "#BATTLE_PASS_FEATURE_10" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText9", "#BATTLE_PASS_FEATURE_11" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText10", "#BATTLE_PASS_FEATURE_12" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText11", "#BATTLE_PASS_FEATURE_13" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText12", "#BATTLE_PASS_FEATURE_14" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText13", "" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText14", "" )
	}
	else
	{
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText1", "#BATTLE_PASS_FEATURE_1" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText2", "#BATTLE_PASS_FEATURE_2" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText3", "#BATTLE_PASS_FEATURE_3" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText4", "#BATTLE_PASS_FEATURE_4" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText5", "#BATTLE_PASS_FEATURE_5" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText6", "#BATTLE_PASS_FEATURE_6" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText7", "#BATTLE_PASS_FEATURE_7" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText8", "#BATTLE_PASS_FEATURE_8" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText9", "#BATTLE_PASS_FEATURE_9" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText10", "#BATTLE_PASS_FEATURE_10" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText11", "#BATTLE_PASS_FEATURE_11" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText12", "#BATTLE_PASS_FEATURE_12" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText13", "#BATTLE_PASS_FEATURE_13" )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText14", "#BATTLE_PASS_FEATURE_14" )
	}

	UpdatePassPurchaseButtons()
}


void function PassPurchaseMenu_OnGetTopLevel()
{
	if ( s_passPurchaseMenu.closeOnGetTopLevel )
	{
		s_passPurchaseMenu.closeOnGetTopLevel = false
		CloseActiveMenu()
	}
}


void function UpdatePassPurchaseButtons()
{
	Assert( GRX_IsInventoryReady( ) )

	var passButton = Hud_GetRui( s_passPurchaseMenu.passPurchaseButton )
	GRXScriptOffer passOffer = expect GRXScriptOffer( GetBattlePassPurchaseOffer() )
	string passPrice = GRX_GetFormattedPrice( passOffer.prices[0] )
	RuiSetString( passButton, "price", passPrice )
	RuiSetAsset( passButton, "backgroundImage", ItemFlavor_GetIcon( GRX_BATTLEPASS_PURCHASE_PACK_BASIC ) )
	RuiSetString( passButton, "offerTitle", ItemFlavor_GetShortName( GRX_BATTLEPASS_PURCHASE_PACK_BASIC ) )
	RuiSetString( passButton, "offerDesc", ItemFlavor_GetLongDescription( GRX_BATTLEPASS_PURCHASE_PACK_BASIC ) )

	var bundleButton = Hud_GetRui( s_passPurchaseMenu.bundlePurchaseButton )
	GRXScriptOffer bundleOffer = expect GRXScriptOffer( GetBattlePassBundlePurchaseOffer() )
	string bundlePrice = GRX_GetFormattedPrice( bundleOffer.prices[0] )
	RuiSetString( bundleButton, "price", bundlePrice )
	RuiSetAsset( bundleButton, "backgroundImage", ItemFlavor_GetIcon( GRX_BATTLEPASS_PURCHASE_PACK_BUNDLE ) )
	RuiSetString( bundleButton, "offerTitle", ItemFlavor_GetShortName( GRX_BATTLEPASS_PURCHASE_PACK_BUNDLE ) )
	RuiSetString( bundleButton, "offerDesc", ItemFlavor_GetLongDescription( GRX_BATTLEPASS_PURCHASE_PACK_BUNDLE ) )
	RuiSetString( bundleButton, "priceBeforeDiscount", GetFormattedValueForCurrency( 4700, GRX_CURRENCY_PREMIUM ) )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	bool canPurchaseBundle = GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) >= 25

	Hud_SetLocked( s_passPurchaseMenu.bundlePurchaseButton, !canPurchaseBundle )
	if ( !canPurchaseBundle )
	{
		ToolTipData toolTipData
		toolTipData.titleText = "#BATTLE_PASS_BUNDLE_PROTECT"
		toolTipData.descText = "#BATTLE_PASS_BUNDLE_PROTECT_DESC"
		Hud_SetToolTipData( s_passPurchaseMenu.bundlePurchaseButton, toolTipData )
	}
	else
	{
		Hud_ClearToolTipData( s_passPurchaseMenu.bundlePurchaseButton )
	}
}

void function OnBattlePassPurchaseResults( bool wasSuccessful )
{
	if ( wasSuccessful )
	{
		s_passPurchaseMenu.closeOnGetTopLevel = true
	}
}
#endif //

#if(UI)
bool function TryDisplayBattlePassAwards()
{
	WaitEndFrame()

	bool ready = GRX_IsInventoryReady() && GRX_AreOffersReady()
	if ( !ready )
		return false

	EHI playerEHI = ToEHI( GetUIPlayer() )
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return false

	expect ItemFlavor( activeBattlePass )

	int currentXP = GetPlayerBattlePassXPProgress( playerEHI, activeBattlePass )
	int lastSeenXP = GetPlayerBattlePassLastSeenXP( playerEHI, activeBattlePass )
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
	bool hadPremiumPass = GetPlayerBattlePassLastSeenPremium( playerEHI, activeBattlePass )

	if ( currentXP == lastSeenXP && hasPremiumPass == hadPremiumPass )
		return false

	if ( IsDialog( GetActiveMenu() ) )
		return false

	int lastLevel = GetBattlePassLevelForXP( activeBattlePass, lastSeenXP )
	int currentLevel = GetBattlePassLevelForXP( activeBattlePass, currentXP )

	array<BattlePassReward> allAwards
	array<BattlePassReward> freeAwards
	for ( int levelIndex = lastLevel; levelIndex < currentLevel; levelIndex++ )
	{
		array<BattlePassReward> awardsForLevel = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
		foreach ( award in awardsForLevel )
		{
			if ( award.isPremium )
				continue

			freeAwards.append( award )
		}
	}

	allAwards.extend( freeAwards )

	if ( hasPremiumPass )
	{
		array<BattlePassReward> premiumAwards
		if ( hasPremiumPass != hadPremiumPass )
		{
			premiumAwards = GetBattlePassBaseRewards( activeBattlePass )
			lastLevel = 0
		}

		for ( int levelIndex = lastLevel; levelIndex < currentLevel; levelIndex++ )
		{
			array<BattlePassReward> awardsForLevel = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
			foreach ( award in awardsForLevel )
			{
				if ( !award.isPremium )
					continue

				premiumAwards.append( award )
			}
		}

		allAwards.extend( premiumAwards )
	}

	if ( allAwards.len() == 0 )
		return false

	allAwards.sort( SortByAwardLevel )

	ShowPassAwardsDialog( allAwards )

	return true
}


int function SortByAwardLevel( BattlePassReward a, BattlePassReward b )
{
	if ( a.level > b.level )
		return 1
	else if ( a.level < b.level )
		return -1

	if ( a.isPremium && !b.isPremium )
		return 1
	else if ( b.isPremium && !a.isPremium )
		return -1

	return 0
}


struct
{
	var menu
	var awardPanel
	var awardHeader
	var continueButton

	array<BattlePassReward> displayAwards = []

	table<var, BattlePassReward> buttonToItem

} s_passAwardsMenu


void function InitPassAwardsMenu()
{
	var menu = GetMenu( "PassAwardsMenu" )

	s_passAwardsMenu.awardHeader = Hud_GetChild( menu, "Header" )
	s_passAwardsMenu.awardPanel = Hud_GetChild( menu, "AwardsList" )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PassAwardsDialog_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, PassAwardsDialog_OnClose )

	s_passAwardsMenu.continueButton = Hud_GetChild( menu, "ContinueButton" )
	Hud_AddEventHandler( s_passAwardsMenu.continueButton, UIE_CLICK, ContinueButton_OnActivate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function ShowPassAwardsDialog( array<BattlePassReward> awards )
{
	PassAwardsDialog_SetAwards( awards )
	AdvanceMenu( GetMenu( "PassAwardsMenu" ) )
}


void function PassAwardsDialog_SetAwards( array<BattlePassReward> awards )
{
	s_passAwardsMenu.displayAwards = clone awards
}

void function PassAwardsDialog_OnOpen()
{
	UI_SetPresentationType( ePresentationType.BATTLE_PASS )

	Assert( s_passAwardsMenu.displayAwards.len() != 0 )

	ClientCommand( "UpdateBattlePassLastEarnedXP" )
	ClientCommand( "UpdateBattlePassLastPurchasedXP" )
	ClientCommand( "UpdateBattlePassLastSeenPremium" )

	RegisterButtonPressedCallback( BUTTON_A, ContinueButton_OnActivate )
	RegisterButtonPressedCallback( KEY_SPACE, ContinueButton_OnActivate )

	PassDialog_UpdateAwards()

	EmitUISound( "UI_Menu_BattlePass_LevelUp" )
}

void function ContinueButton_OnActivate( var button )
{
	CloseActiveMenu()
}


void function PassAwardsDialog_OnClose()
{
	s_passAwardsMenu.displayAwards = []

	DeregisterButtonPressedCallback( BUTTON_A, ContinueButton_OnActivate )
	DeregisterButtonPressedCallback( KEY_SPACE, ContinueButton_OnActivate )
}

void function PassDialog_UpdateAwards()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	int startingAwardLevel      = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )

	HudElem_SetRuiArg( s_passAwardsMenu.awardHeader, "headerText", Localize( "#BATTLE_PASS_REACHED_LEVEL", GetBattlePassDisplayLevel( startingAwardLevel ) ) )
	HudElem_SetRuiArg( s_passAwardsMenu.awardHeader, "titleText", Localize( "#BATTLE_PASS_REACHED_LEVEL", GetBattlePassDisplayLevel( startingAwardLevel ) ) )

	//
	//
	//
	//
	//
	//
	var scrollPanel = Hud_GetChild( s_passAwardsMenu.awardPanel, "ScrollPanel" )

	foreach ( button, _ in s_passAwardsMenu.buttonToItem )
	{
		Hud_RemoveEventHandler( button, UIE_GET_FOCUS, PassAward_OnFocusAward )
	}
	s_passAwardsMenu.buttonToItem.clear()

	int numAwards = s_passAwardsMenu.displayAwards.len()

	Hud_InitGridButtonsDetailed( s_passAwardsMenu.awardPanel, numAwards, 1, minint( numAwards, 8 ) )
	Hud_SetHeight( s_passAwardsMenu.awardPanel, Hud_GetHeight( s_passAwardsMenu.awardPanel ) * 1.3 )
	for ( int index = 0; index < numAwards; index++ )
	{
		var awardButton = Hud_GetChild( scrollPanel, "GridButton" + index )

		BattlePassReward bpReward = s_passAwardsMenu.displayAwards[index]
		s_passAwardsMenu.buttonToItem[awardButton] <- bpReward

		HudElem_SetRuiArg( awardButton, "isOwned", true )
		HudElem_SetRuiArg( awardButton, "isPremium", bpReward.isPremium )

		int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
		HudElem_SetRuiArg( awardButton, "rarity", rarity )
		RuiSetImage( Hud_GetRui( awardButton ), "buttonImage", GetImageForBattlePassReward( bpReward ) )

		if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
			HudElem_SetRuiArg( awardButton, "isLootBox", true )

		HudElem_SetRuiArg( awardButton, "itemCountString", "" )
		if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
			HudElem_SetRuiArg( awardButton, "itemCountString", string( bpReward.quantity ) )

		Hud_AddEventHandler( awardButton, UIE_GET_FOCUS, PassAward_OnFocusAward )

		if ( index == 0 )
			PassAward_OnFocusAward( awardButton )
	}
}

void function PassAward_OnFocusAward( var button )
{
	RunClientScript( "UIToClient_ItemPresentation", ItemFlavor_GetGUID( s_passAwardsMenu.buttonToItem[button].flav ), s_passAwardsMenu.buttonToItem[button].level )
}


#endif


#if(UI)
GRXScriptOffer ornull function GetBattlePassPurchaseOffer()
{
	array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( GRX_BATTLEPASS_PURCHASE_PACK_BASIC, "battlepass" )
	return offers.len() > 0 ? offers[0] : null
}

GRXScriptOffer ornull function GetBattlePassBundlePurchaseOffer()
{
	array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( GRX_BATTLEPASS_PURCHASE_PACK_BUNDLE, "battlepass" )
	return offers.len() > 0 ? offers[0] : null
}

GRXScriptOffer ornull function GetBattlePassXPPurchaseOffer()
{
	array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( BATTLEPASS_SEASON1_PURCAHSED_XP_FLAV, "battlepass" )
	return offers.len() > 0 ? offers[0] : null
}
#endif


#if(CLIENT)
void function UIToClient_ItemPresentation( SettingsAssetGUID itemFlavorGUID, int level )
{
	entity sceneRef = GetEntByScriptName( "battlepass_ref" )
	fileLevel.sceneRefOrigin = sceneRef.GetOrigin()
	fileLevel.sceneRefAngles = sceneRef.GetAngles()

	ShowBattlepassItem( GetItemFlavorByGUID( itemFlavorGUID ), level )

	//
	//

	//
}


void function ShowBattlepassItem( ItemFlavor item, int level )
{
	ClearBattlePassItem()

	int itemType = ItemFlavor_GetType( item )

	switch ( itemType )
	{
		case eItemType.account_currency:
			ShowBattlePassItem_Currency( item )
			break

		case eItemType.account_pack:
			ShowBattlePassItem_ApexPack( item )
			break

		case eItemType.character_skin:
			ShowBattlePassItem_CharacterSkin( item )
			break

		case eItemType.character_execution:
			ShowBattlePassItem_Execution( item )
			break

		case eItemType.weapon_skin:
			asset video = WeaponSkin_GetVideo( item )
			if ( video != $"" )
				ShowBattlePassItem_WeaponSkinVideo( item, video )
			else
				ShowBattlePassItem_WeaponSkin( item )
			break

		case eItemType.gladiator_card_stance:
		case eItemType.gladiator_card_frame:
			ShowBattlePassItem_Banner( item )
			break

		case eItemType.gladiator_card_intro_quip:
		case eItemType.gladiator_card_kill_quip:
			ShowBattlePassItem_Quip( item )
			break

		case eItemType.gladiator_card_stat_tracker:
			ShowBattlePassItem_StatTracker( item )
			break

		case eItemType.xp_boost:
			ShowBattlePassItem_XPBoost( item )
			break

		case eItemType.gladiator_card_badge:
			ShowBattlePassItem_Badge( item, level )
			break

		default:
			Warning( "Loot Ceremony reward item type not supported: " + DEV_GetEnumStringSafe( "eItemType", itemType ) )
			ShowBattlePassItem_Unknown( item )
			break
	}
}
#endif //

#if(CLIENT)
const float BATTLEPASS_MODEL_ROTATE_SPEED = 15.0

void function ClearBattlePassItem()
{
	foreach ( model in fileLevel.models )
	{
		if ( IsValid( model ) )
			model.Destroy()
	}

	if ( IsValid( fileLevel.mover ) )
		fileLevel.mover.Destroy()

	CleanupNestedGladiatorCard( fileLevel.bannerHandle )

	if ( fileLevel.rui != null )
		RuiDestroyIfAlive( fileLevel.rui )

	if ( fileLevel.topo != null )
	{
		RuiTopology_Destroy( fileLevel.topo )
		fileLevel.topo = null
	}

	if ( fileLevel.videoChannel != -1 )
	{
		ReleaseVideoChannel( fileLevel.videoChannel )
		fileLevel.videoChannel = -1
	}

	if ( fileLevel.playingQuipAlias != "" )
		StopSoundOnEntity( GetLocalClientPlayer(), fileLevel.playingQuipAlias )
}

void function ShowBattlePassItem_ApexPack( ItemFlavor item )
{
	vector origin = fileLevel.sceneRefOrigin + <0, 0, 10.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	int rarity      = ItemFlavor_GetQuality( item )
	asset tickAsset = $"mdl/robots/drone_frag/drone_frag_loot.rmdl"
	int tickSkin    = 0
	switch ( rarity )
	{
		case eQuality.EPIC:
			tickSkin = 2
			break

		case eQuality.LEGENDARY:
			tickSkin = 3
			break

		case eQuality.HEIRLOOM:
		case eQuality.COMMON:
		case eQuality.RARE:
		default:
			tickAsset = $"mdl/robots/drone_frag/drone_frag_loot.rmdl"
			tickSkin = 0
	}

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, <0, 135, 0> ), tickAsset )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( 0.75 )
	model.SetParent( mover )
	model.SetSkin( tickSkin )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_CharacterSkin( ItemFlavor item )
{
	vector origin = fileLevel.sceneRefOrigin + <0, 0, 4.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, angles, $"mdl/dev/empty_model.rmdl" )
	CharacterSkin_Apply( model, item )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( 0.8 )
	model.SetParent( mover )

	thread PlayAnim( model, "ACT_MP_MENU_LOOT_CEREMONY_IDLE", mover )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_Execution( ItemFlavor item )
{
	const float BATTLEPASS_EXECUTION_Z_OFFSET = 12.0
	const vector BATTLEPASS_EXECUTION_LOCAL_ANGLES = <0, 15, 0>
	const float BATTLEPASS_EXECUTION_SCALE = 0.8

	//
	ItemFlavor attackerCharacter = CharacterExecution_GetCharacterFlavor( item )
	ItemFlavor characterSkin     = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_CharacterSkin( attackerCharacter ) )

	asset attackerAnimSeq = CharacterExecution_GetAttackerPreviewAnimSeq( item )
	asset victimAnimSeq   = CharacterExecution_GetVictimPreviewAnimSeq( item )

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_EXECUTION_Z_OFFSET>
	vector angles = AnglesCompose( fileLevel.sceneRefAngles, BATTLEPASS_EXECUTION_LOCAL_ANGLES )

	entity mover         = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	entity attackerModel = CreateClientSidePropDynamic( origin, angles, $"mdl/dev/empty_model.rmdl" )
	entity victimModel   = CreateClientSidePropDynamic( origin, angles, $"mdl/dev/empty_model.rmdl" )

	CharacterSkin_Apply( attackerModel, characterSkin )
	victimModel.SetModel( $"mdl/humans/class/medium/pilot_medium_generic.rmdl" )

	//
	bool attackerHasSequence = attackerModel.Anim_HasSequence( attackerAnimSeq )
	bool victimHasSequence   = victimModel.Anim_HasSequence( victimAnimSeq )

	if ( !attackerHasSequence || !victimHasSequence )
	{
		asset attackerPlayerSettings = CharacterClass_GetSetFile( attackerCharacter )
		string attackerRigWeight     = GetGlobalSettingsString( attackerPlayerSettings, "bodyModelRigWeight" )
		string attackerAnim          = "mp_pt_execution_" + attackerRigWeight + "_attacker_loot"

		attackerModel.Anim_Play( attackerAnim )
		victimModel.Anim_Play( "mp_pt_execution_default_victim_loot" )
		Warning( "Couldn't find menu idles for execution reward: " + DEV_DescItemFlavor( item ) + ". Using fallback anims." )
		if ( !attackerHasSequence )
			Warning( "ATTACKER could not find sequence: " + attackerAnimSeq )
		if ( !victimHasSequence )
			Warning( "VICTIM could not find sequence: " + victimAnimSeq )
	}
	else
	{
		attackerModel.Anim_Play( attackerAnimSeq )
		victimModel.Anim_Play( victimAnimSeq )
	}

	mover.MakeSafeForUIScriptHack()

	attackerModel.MakeSafeForUIScriptHack()
	attackerModel.SetParent( mover )

	victimModel.MakeSafeForUIScriptHack()
	victimModel.SetParent( mover )

	//
	attackerModel.SetModelScale( BATTLEPASS_EXECUTION_SCALE )
	victimModel.SetModelScale( BATTLEPASS_EXECUTION_SCALE )

	int rarity = ItemFlavor_GetQuality( item )
	ModelRarityFlash( attackerModel, rarity )
	ModelRarityFlash( victimModel, rarity )

	fileLevel.mover = mover
	fileLevel.models.append( attackerModel )
	fileLevel.models.append( victimModel )
}


void function ShowBattlePassItem_WeaponSkin( ItemFlavor item )
{
	const vector BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES = <5, -45, 0>

	vector origin = fileLevel.sceneRefOrigin + <0, 0, 29.0>
	vector angles = fileLevel.sceneRefAngles

	//
	ItemFlavor weaponItem = WeaponSkin_GetWeaponFlavor( item )

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES ), $"mdl/dev/empty_model.rmdl" )
	WeaponSkin_Apply( model, item )
	ShowDefaultBodygroupsOnFakeWeapon( model, WeaponItemFlavor_GetClassname( weaponItem ) )
	model.MakeSafeForUIScriptHack()
	model.SetVisibleForLocalPlayer( 0 )
	model.Anim_SetPaused( true )
	model.SetModelScale( WeaponItemFlavor_GetBattlePassScale( weaponItem ) )
	model.SetParent( mover )

	//
	model.SetLocalOrigin( GetAttachmentOriginOffset( model, "MENU_ROTATE", BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES ) )
	model.SetLocalAngles( BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_Banner( ItemFlavor item )
{
	int itemType = ItemFlavor_GetType( item )
	Assert( itemType == eItemType.gladiator_card_frame || itemType == eItemType.gladiator_card_stance )

	const float BATTLEPASS_BANNER_WIDTH = 528.0
	const float BATTLEPASS_BANNER_HEIGHT = 912.0
	const float BATTLEPASS_BANNER_SCALE = 0.08
	const float BATTLEPASS_BANNER_Z_OFFSET = -4.0

	entity player = GetLocalClientPlayer()
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_BANNER_Z_OFFSET>
	vector angles = AnglesCompose( fileLevel.sceneRefAngles, <0, 180, 0> )

	float width  = BATTLEPASS_BANNER_WIDTH * BATTLEPASS_BANNER_SCALE
	float height = BATTLEPASS_BANNER_HEIGHT * BATTLEPASS_BANNER_SCALE

	var topo = CreateRUITopology_Worldspace( origin + <0, 0, height * 0.5>, angles, width, height )
	var rui  = RuiCreate( $"ui/loot_ceremony_glad_card.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )

	int gcardPresentation
	if ( itemType == eItemType.gladiator_card_frame )
		gcardPresentation = eGladCardPresentation.FRONT_FRAME_ONLY
	else
		gcardPresentation = eGladCardPresentation.FRONT_STANCE_ONLY

	NestedGladiatorCardHandle nestedGCHandleFront = CreateNestedGladiatorCard( rui, "card", eGladCardDisplaySituation.MENU_LOOT_CEREMONY_ANIMATED, gcardPresentation )
	ChangeNestedGladiatorCardOwner( nestedGCHandleFront, ToEHI( player ) )

	if ( itemType == eItemType.gladiator_card_frame )
	{
		ItemFlavor character = GladiatorCardFrame_GetCharacterFlavor( item )
		SetNestedGladiatorCardOverrideCharacter( nestedGCHandleFront, character )
		SetNestedGladiatorCardOverrideFrame( nestedGCHandleFront, item )
	}
	else
	{
		ItemFlavor character = GladiatorCardStance_GetCharacterFlavor( item )
		SetNestedGladiatorCardOverrideCharacter( nestedGCHandleFront, character )
		SetNestedGladiatorCardOverrideStance( nestedGCHandleFront, item )

		ItemFlavor characterDefaultFrame = GetDefaultItemFlavorForLoadoutSlot( EHI_null, Loadout_GladiatorCardFrame( character ) )
		SetNestedGladiatorCardOverrideFrame( nestedGCHandleFront, characterDefaultFrame ) //
	}

	RuiSetBool( rui, "battlepass", true )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )

	fileLevel.topo = topo
	fileLevel.rui = rui
	fileLevel.bannerHandle = nestedGCHandleFront
}


void function ShowBattlePassItem_Quip( ItemFlavor item )
{
	int itemType = ItemFlavor_GetType( item )
	Assert( itemType == eItemType.gladiator_card_intro_quip || itemType == eItemType.gladiator_card_kill_quip )

	const float BATTLEPASS_QUIP_WIDTH = 390.0
	const float BATTLEPASS_QUIP_HEIGHT = 208.0
	const float BATTLEPASS_QUIP_SCALE = 0.091
	const float BATTLEPASS_QUIP_Z_OFFSET = 20.5
	const asset BATTLEPASS_QUIP_BG_MODEL = $"mdl/menu/loot_ceremony_quip_bg.rmdl"

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_QUIP_Z_OFFSET>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	//
	float width  = BATTLEPASS_QUIP_WIDTH * BATTLEPASS_QUIP_SCALE
	float height = BATTLEPASS_QUIP_HEIGHT * BATTLEPASS_QUIP_SCALE

	entity model = CreateClientSidePropDynamic( origin, angles, BATTLEPASS_QUIP_BG_MODEL )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( BATTLEPASS_QUIP_SCALE )

	var topo = CreateRUITopology_Worldspace( origin + <0, 0, (height * 0.5)>, placardAngles, width, height )
	var rui
	ItemFlavor quipCharacter
	string labelText
	string quipAlias = ""

	if ( itemType == eItemType.gladiator_card_intro_quip )
	{
		//
		rui = RuiCreate( $"ui/loot_reward_intro_quip.rpak", topo, RUI_DRAW_WORLD, 0 )
		quipCharacter = CharacterIntroQuip_GetCharacterFlavor( item )
		labelText = "#LOOT_QUIP_INTRO"
		quipAlias = CharacterIntroQuip_GetVoiceSoundEvent( item )
	}
	else
	{
		//
		rui = RuiCreate( $"ui/loot_reward_kill_quip.rpak", topo, RUI_DRAW_WORLD, 0 )
		quipCharacter = CharacterKillQuip_GetCharacterFlavor( item )
		labelText = "#LOOT_QUIP_KILL"
		quipAlias = CharacterKillQuip_GetVictimVoiceSoundEvent( item )
	}

	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )
	RuiSetImage( rui, "portraitImage", CharacterClass_GetGalleryPortrait( quipCharacter ) )
	RuiSetString( rui, "quipTypeText", labelText )
	RuiTrackFloat( rui, "level", null, RUI_TRACK_SOUND_METER, 0 )

	fileLevel.models.append( model )
	fileLevel.topo = topo
	fileLevel.rui = rui

	//
	if ( quipAlias != "" )
	{
		fileLevel.playingQuipAlias = quipAlias
		EmitSoundOnEntity( GetLocalClientPlayer(), quipAlias )
	}
}


void function ShowBattlePassItem_StatTracker( ItemFlavor item )
{
	const float BATTLEPASS_STAT_TRACKER_WIDTH = 594.0
	const float BATTLEPASS_STAT_TRACKER_HEIGHT = 230.0
	const float BATTLEPASS_STAT_TRACKER_SCALE = 0.06
	const asset BATTLEPASS_STAT_TRACKER_BG_MODEL = $"mdl/menu/loot_ceremony_stat_tracker_bg.rmdl"

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, 23>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	//
	float width  = BATTLEPASS_STAT_TRACKER_WIDTH * BATTLEPASS_STAT_TRACKER_SCALE
	float height = BATTLEPASS_STAT_TRACKER_HEIGHT * BATTLEPASS_STAT_TRACKER_SCALE

	var topo = CreateRUITopology_Worldspace( origin + <0, 0, (height * 0.5)>, placardAngles, width, height )
	var rui  = RuiCreate( $"ui/loot_ceremony_stat_tracker.rpak", topo, RUI_DRAW_WORLD, 0 )

	entity model = CreateClientSidePropDynamic( origin, angles, BATTLEPASS_STAT_TRACKER_BG_MODEL )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( BATTLEPASS_STAT_TRACKER_SCALE )

	ItemFlavor character = GladiatorCardStatTracker_GetCharacterFlavor( item )

	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )
	UpdateRuiWithStatTrackerData( rui, "tracker", LocalClientEHI(), character, -1, item, null, true )
	RuiSetColorAlpha( rui, "trackerColor0", GladiatorCardStatTracker_GetColor0( item ), 1.0 )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )

	fileLevel.models.append( model )
	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_Badge( ItemFlavor item, int level )
{
	const float BATTLEPASS_BADGE_WIDTH = 670.0
	const float BATTLEPASS_BADGE_HEIGHT = 670.0
	const float BATTLEPASS_BADGE_SCALE = 0.06
	const asset BATTLEPASS_BADGE_BG_MODEL = $"mdl/menu/loot_ceremony_stat_tracker_bg.rmdl"

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, 30>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	float width  = BATTLEPASS_BADGE_WIDTH * BATTLEPASS_BADGE_SCALE
	float height = BATTLEPASS_BADGE_HEIGHT * BATTLEPASS_BADGE_SCALE

	var topo = CreateRUITopology_Worldspace( origin, placardAngles, width, height )
	var rui  = RuiCreate( $"ui/world_space_badge.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )
	ItemFlavor dummy
	CreateNestedGladiatorCardBadge( rui, "badge", LocalClientEHI(), item, 0, dummy, level + 2 )
	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_Currency( ItemFlavor item )
{
	Assert( ItemFlavor_GetType( item ) == eItemType.account_currency )
	Assert( item == GRX_CURRENCIES[GRX_CURRENCY_PREMIUM] || item == GRX_CURRENCIES[GRX_CURRENCY_CRAFTING] )

	asset modelAsset = $""

	switch ( item )
	{
		case GRX_CURRENCIES[GRX_CURRENCY_PREMIUM]:
			modelAsset = BATTLEPASS_MODEL_APEX_COINS
			break

		case GRX_CURRENCIES[GRX_CURRENCY_CRAFTING]:
			modelAsset = BATTLEPASS_MODEL_CRAFTING_METALS
			break

		default:
			Assert( false, "Unsupported currency item!" )
			break
	}

	vector origin = fileLevel.sceneRefOrigin + <0, 0, 29>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, <0, 32, 0> ), modelAsset )
	model.MakeSafeForUIScriptHack()
	if ( modelAsset == BATTLEPASS_MODEL_CRAFTING_METALS )
		model.SetModelScale( 1.5 )
	model.SetParent( mover )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	int rarity = 0
	if ( ItemFlavor_HasQuality( item ) )
		rarity = ItemFlavor_GetQuality( item )

	ModelRarityFlash( model, rarity )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_XPBoost( ItemFlavor item )
{
	vector origin = fileLevel.sceneRefOrigin + <0, 0, 28.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, <0, 32, 0> ), BATTLEPASS_MODEL_BOOST )
	model.MakeSafeForUIScriptHack()
	model.SetParent( mover )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_WeaponSkinVideo( ItemFlavor item, asset video )
{
	const float BATTLEPASS_UNKNOWN_WIDTH = 800.0
	const float BATTLEPASS_UNKNOWN_HEIGHT = 450.0
	const float BATTLEPASS_UNKNOWN_Z_OFFSET = 28

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_UNKNOWN_Z_OFFSET>
	vector angles = VectorToAngles( AnglesToForward( fileLevel.sceneRefAngles ) * -1 )

	float width  = BATTLEPASS_UNKNOWN_WIDTH / 14.0
	float height = BATTLEPASS_UNKNOWN_HEIGHT / 14.0

	var topo = CreateRUITopology_Worldspace( origin, angles, width, height )
	var rui  = RuiCreate( $"ui/finisher_video.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )

	fileLevel.videoChannel = ReserveVideoChannel( BattlePassVideoOnFinished )
	RuiSetInt( rui, "channel", fileLevel.videoChannel )
	StartVideoOnChannel( fileLevel.videoChannel, video, true, 0.0 )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_Unknown( ItemFlavor item )
{
	const float BATTLEPASS_UNKNOWN_WIDTH = 450.0
	const float BATTLEPASS_UNKNOWN_HEIGHT = 200.0
	const float BATTLEPASS_UNKNOWN_Z_OFFSET = 25

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_UNKNOWN_Z_OFFSET>
	vector angles = VectorToAngles( AnglesToForward( fileLevel.sceneRefAngles ) * -1 )

	float width  = BATTLEPASS_UNKNOWN_WIDTH / 16.0
	float height = BATTLEPASS_UNKNOWN_HEIGHT / 16.0

	var topo = CreateRUITopology_Worldspace( origin, angles, width, height )
	var rui  = RuiCreate( $"ui/loot_reward_temp.rpak", topo, RUI_DRAW_WORLD, 0 )

	RuiSetString( rui, "bodyText", Localize( ItemFlavor_GetLongName( item ) ) )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function BattlePassVideoOnFinished( int channel )
{
}


/*















*/


void function InitBattlePassLights()
{
	fileLevel.stationaryLights = GetEntArrayByScriptName( "battlepass_stationary_light" )

	//
	/*




*/
}


void function BattlePassLightsOn()
{
	foreach	( light in fileLevel.stationaryLights )
		light.SetTweakLightUpdateShadowsEveryFrame( true )

	//

	/*








































*/
}

void function BattlePassLightsOff()
{
	foreach	( light in fileLevel.stationaryLights )
		light.SetTweakLightUpdateShadowsEveryFrame( false )

	//

	/*







*/
}


void function ModelRarityFlash( entity model, int rarity )
{
	vector color = GetFXRarityColorForUnlockable( rarity ) / 255

	float fillIntensityScalar = 10.0
	float outlineIntensityScalar = 300.0
	float fadeInTime = 0.01
	float fadeOutTime = 0.3
	float lifeTime = 0.1

	thread ModelAndChildrenRarityFlash( model, color, fillIntensityScalar, outlineIntensityScalar, fadeInTime, fadeOutTime, lifeTime )
}


void function ModelAndChildrenRarityFlash( entity model, vector color, float fillIntensityScalar, float outlineIntensityScalar, float fadeInTime, float fadeOutTime, float lifeTime )
{
	WaitFrame()

	if ( !IsValid( model ) )
		return

	foreach ( ent in GetEntityAndItsChildren( model ) )
		BattlePassModelHighlightBloom( ent, color, fillIntensityScalar, outlineIntensityScalar, fadeInTime, fadeOutTime, lifeTime )
}

void function BattlePassModelHighlightBloom( entity model, vector color, float fillIntensityScalar, float outlineIntensityScalar, float fadeInTime, float fadeOutTime, float lifeTime )
{
	const float HIGHLIGHT_RADIUS = 2

	model.Highlight_ResetFlags()
	model.Highlight_SetVisibilityType( HIGHLIGHT_VIS_ALWAYS )
	model.Highlight_SetCurrentContext( HIGHLIGHT_CONTEXT_NEUTRAL )
	int highlightId = model.Highlight_GetState( HIGHLIGHT_CONTEXT_NEUTRAL )
	model.Highlight_SetFunctions( HIGHLIGHT_CONTEXT_NEUTRAL, HIGHLIGHT_FILL_MENU_MODEL_REVEAL, true, HIGHLIGHT_OUTLINE_MENU_MODEL_REVEAL, HIGHLIGHT_RADIUS, highlightId, false )
	model.Highlight_SetParam( HIGHLIGHT_CONTEXT_NEUTRAL, 0, color )
	model.Highlight_SetParam( HIGHLIGHT_CONTEXT_NEUTRAL, 1, <fillIntensityScalar, outlineIntensityScalar, 0> )

	model.Highlight_SetFadeInTime( fadeInTime )
	model.Highlight_SetFadeOutTime( fadeOutTime )
	model.Highlight_StartOn()

	model.Highlight_SetLifeTime( lifeTime )
}
#endif //
