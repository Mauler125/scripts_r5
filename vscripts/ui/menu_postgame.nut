global function InitPostGameMenu
global function IsPostGameMenuValid
global function OpenPostGameMenu
global function ClosePostGameMenu

const PROGRESS_BAR_FILL_TIME = 2.0
const REWARD_AWARD_TIME = 2
const POSTGAME_DATA_EXPIRATION_TIME = 5 * SECONDS_PER_MINUTE
const int MAX_XP_LINES = 7

const string POSTGAME_LINE_ITEM = "ui_menu_matchsummary_xpbreakdown"

struct RewardStruct
{
	float delay
	asset image1
	asset image2
	bool  characterReward
}

struct
{
	var menu

	var continueButton

	var combinedCard
	var decorationRui
	var menuHeaderRui

	bool wasPartyMember = false //HACK Awkward, needed to keep track of whether we should cancel out of putting player in matchmaking after delay when closing post game menu. Remove when we get code notification about party being broken up
	bool disableNavigateBack = false

	bool skippableWaitSkipped = false
} file

void function InitPostGameMenu()
{
	RegisterSignal( "PGDisplay" )

	file.menu = GetMenu( "PostGameMenu" )
	var menu = file.menu

	file.combinedCard = Hud_GetChild( menu, "CombinedCard" )
	file.menuHeaderRui = Hud_GetRui( Hud_GetChild( menu, "MenuHeader" ) )
	file.decorationRui = Hud_GetRui( Hud_GetChild( menu, "Decoration" ) )
	file.continueButton = Hud_GetChild( menu, "ContinueButton" )

	Hud_AddEventHandler( file.continueButton, UIE_CLICK, OnContinue_Activate )

	RuiSetString( file.menuHeaderRui, "menuName", "#MATCH_SUMMARY" )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenPostGameMenu )
	AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnShowPostGameMenu )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnClosePostGameMenu )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnNavigateBack )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#B_BUTTON_CLOSE", null, CanNavigateBack )
	AddMenuFooterOption( menu, LEFT, BUTTON_BACK, true, "", "", ClosePostGameMenu, CanNavigateBack )


	AddUICallback_OnLevelInit( OnLevelInit )
}


void function InitSquadDataDisplay( var squadDataRui )
{
	int maxTrackedSquadMembers = PersistenceGetArrayCount( "lastGameSquadStats" )

	for ( int k = 0 ; k < maxTrackedSquadMembers ; k++ )
	{
		RuiSetString( squadDataRui, "playerName" + k, string(GetPersistentVar( "lastGameSquadStats[" + k + "].playerName" )) )

		int playerSecondsAlive = GetPersistentVarAsInt( "lastGameSquadStats[" + k + "].survivalTime" )
		string m               = string( playerSecondsAlive / 60 )
		string s               = string ( playerSecondsAlive % 60 )
		if ( s.len() == 1 )
			s = "0" + s
		string playerTimeString = m + ":" + s
		RuiSetString( squadDataRui, "playerTime" + k, playerTimeString )

		RuiSetInt( squadDataRui, "playerKills" + k, GetPersistentVarAsInt( "lastGameSquadStats[" + k + "].kills" ) )
		RuiSetInt( squadDataRui, "playerDamage" + k, GetPersistentVarAsInt( "lastGameSquadStats[" + k + "].damageDealt" ) )
		RuiSetInt( squadDataRui, "playerRevives" + k, GetPersistentVarAsInt( "lastGameSquadStats[" + k + "].revivesGiven" ) )

		string characterGUIDString = string( GetPersistentVar( "lastGameSquadStats[" + k + "].character" ) )
		int characterGUID          = ConvertItemFlavorGUIDStringToGUID( characterGUIDString )
		if ( IsValidItemFlavorGUID( characterGUID ) )
		{
			ItemFlavor squadCharacterClass = GetItemFlavorByGUID( characterGUID )
			RuiSetImage( squadDataRui, "playerImage" + k, CharacterClass_GetCharacterSelectPortrait( squadCharacterClass ) )
		}
	}
}
/*
SURVIVAL_DURATION,
TOP_THREE,
WIN_MATCH,
KILL,
KILL_CHAMPION,
DAMAGE_DEALT,
BONUS_FIRST_GAME,
BONUS_SQUAD,
ACCOUNT_BOOST,
BONUS_FIRST_KILL,
BONUS_CHAMPION,
BONUS_REVIVE_ALLY,
BONUS_RESPAWN_ALLY,
*/

array< array< int > > xpDisplayGroups = [
	[
		XP_TYPE.WIN_MATCH,
		XP_TYPE.TOP_THREE,
		XP_TYPE.SURVIVAL_DURATION,
		XP_TYPE.KILL,
		XP_TYPE.DOWN,
		XP_TYPE.DAMAGE_DEALT,
		XP_TYPE.REVIVE_ALLY,
		XP_TYPE.RESPAWN_ALLY,
	],

	[
		XP_TYPE.BONUS_FIRST_GAME,
		XP_TYPE.BONUS_FIRST_KILL,
		XP_TYPE.KILL_CHAMPION_MEMBER,
		XP_TYPE.KILL_LEADER,
		XP_TYPE.BONUS_CHAMPION,
		XP_TYPE.BONUS_FRIEND,
	],

	[
		XP_TYPE.TOTAL_MATCH,
		XP_TYPE.BONUS_FRIEND_BOOST,
		XP_TYPE.BONUS_FIRST_KILL_AS,
		XP_TYPE.BONUS_RESTED_AS,
	],
]

int function InitXPEarnedDisplay( var xpEarnedRui, array<int> xpTypes, string headerText, string subHeaderText, bool isBattlePass, vector sectionColor )
{
	entity player = GetUIPlayer()

	RuiSetGameTime( xpEarnedRui, "startTime", Time() )
	RuiSetString( xpEarnedRui, "headerText", headerText )
	RuiSetString( xpEarnedRui, "subHeaderText", subHeaderText )

	RuiSetColorAlpha( xpEarnedRui, "sectionColor", sectionColor, 1.0 )

	int lineIndex = 0
	foreach ( index, xpType in xpTypes )
	{
		int eventValue = isBattlePass ? GetBattlePassXPEventValue( player, xpType ) : GetXPEventValue( player, xpType )
		if ( XpEventTypeData_DisplayEmpty( xpType ) || eventValue > 0 )
		{
			lineIndex++
			if ( lineIndex <= MAX_XP_LINES )
			{
				RuiSetString( xpEarnedRui, "line" + lineIndex + "KeyString", GetXPEventNameDisplay( player, xpType ) )

				string valueDisplay = isBattlePass ? GetBattlePassXPEventValueDisplay( player, xpType ) : GetXPEventValueDisplay( player, xpType )
				RuiSetString( xpEarnedRui, "line" + lineIndex + "ValueString", valueDisplay )
				vector lineColor = (xpType == XP_TYPE.TOTAL_MATCH) ? <1.0, 1.0, 1.0> : sectionColor
				RuiSetColorAlpha( xpEarnedRui, "line" + lineIndex + "Color", lineColor, 1.0 )
			}
		}
	}

	int numDisplayedLines = lineIndex

	RuiSetInt( xpEarnedRui, "numLines", lineIndex )

	for ( lineIndex++ ; lineIndex <= MAX_XP_LINES; lineIndex++ )
	{
		RuiSetString( xpEarnedRui, "line" + lineIndex + "KeyString", "" )
		RuiSetString( xpEarnedRui, "line" + lineIndex + "ValueString", "" )
	}

	return numDisplayedLines
}


void function OnContinue_Activate( var button )
{
	file.skippableWaitSkipped = true

	if ( !file.disableNavigateBack )
		CloseActiveMenu()
}


void function ResetSkippableWait()
{
	file.skippableWaitSkipped = false
}


bool function IsSkippableWaitSkipped()
{
	return file.skippableWaitSkipped || !file.disableNavigateBack
}


bool function SkippableWait( float waitTime, string uiSound = "" )
{
	if ( IsSkippableWaitSkipped() )
		return false

	if ( uiSound != "" )
		EmitUISound( uiSound )

	float startTime = Time()
	while ( Time() - startTime < waitTime )
	{
		if ( IsSkippableWaitSkipped() )
			return false

		WaitFrame()
	}

	return true
}


var function DisplayPostGameSummary( bool isFirstTime )
{
	EndSignal( uiGlobal.signalDummy, "PGDisplay" )

	while ( !IsFullyConnected() )
	{
		WaitFrame()
	}

	entity player = GetUIPlayer()
	if ( !player )
	{
		return
	}

	EmitUISound( "UI_Menu_MatchSummary_Appear" )

	ItemFlavor ornull activeBattlePass
	if ( IsBattlePassEnabled() )
		activeBattlePass = GetPlayerActiveBattlePass( WaitForLocalClientEHI() )

	Hud_SetVisible( file.continueButton, isFirstTime )
	Hud_SetVisible( file.combinedCard, isFirstTime || activeBattlePass == null )

	file.disableNavigateBack = isFirstTime
	ResetSkippableWait()
	OnThreadEnd(
		function() : ()
		{
			file.disableNavigateBack = false
			UpdateFooterOptions()
		}
	)

	// Update the pilot model to be the character the player used in the last match
	int characterPDefEnumIndex = player.GetPersistentVarAsInt( "characterForXP" ) // todo(dw): fix this
	Assert( characterPDefEnumIndex >= 0 && characterPDefEnumIndex < PersistenceGetEnumCount( "eCharacterFlavor" ) )
	string characterGUIDString = PersistenceGetEnumItemNameForIndex( "eCharacterFlavor", characterPDefEnumIndex )

	int characterGUID = ConvertItemFlavorGUIDStringToGUID( characterGUIDString )

	if ( !IsValidItemFlavorGUID( characterGUID ) )
	{
		Warning( "Cannot display post-game summary banner because character \"" + characterGUIDString + "\" is not registered right now." ) // todo: human readable
	}
	else
	{
		ItemFlavor character = GetItemFlavorByGUID( characterGUID )
		RunMenuClientFunction( "UpdateMenuCharacterModel", ItemFlavor_GetNetworkIndex_DEPRECATED( character ) )

		SetupMenuGladCard( file.combinedCard, "card", true )
		SendMenuGladCardPreviewCommand( eGladCardPreviewCommandType.CHARACTER, 0, character )
	}

	// Get how much XP we earned for each type last round
	int previousAccountXP = GetPersistentVarAsInt( "previousXP" )
	int currentAccountXP  = GetPersistentVarAsInt( "xp" )
	int totalXP           = currentAccountXP - previousAccountXP

	var matchRankRui = Hud_GetRui( Hud_GetChild( file.menu, "MatchRank" ) )
	var squadDataRui = Hud_GetRui( Hud_GetChild( file.menu, "SquadSummary" ) )

	//################
	// MATCH PLACEMENT
	//################

	RuiSetInt( matchRankRui, "squadRank", GetPersistentVarAsInt( "lastGameRank" ) )
	RuiSetInt( matchRankRui, "totalPlayers", GetPersistentVarAsInt( "lastGameSquads" ) )
	int elapsedTime = GetUnixTimestamp() - GetPersistentVarAsInt( "lastGameTime" )

	RuiSetString( matchRankRui, "lastPlayedText", Localize( "#EOG_LAST_PLAYED", GetFormattedIntByType( elapsedTime, eNumericDisplayType.TIME_MINUTES_LONG ) ) )

	//################
	// SQUAD DATA
	//################
	InitSquadDataDisplay( squadDataRui )

	//################
	// XP EARNED
	//################

	const vector COLOR_MATCH = <255, 255, 255> / 255.0
	const vector COLOR_BONUS = <142, 250, 255> / 255.0
	//
	vector COLOR_BP_PREMIUM = SrgbToLinear( <255, 90, 40> / 255.0 )

	const float LINE_DISPLAY_TIME = 0.25

	float baseDelay = isFirstTime ? 1.0 : 0.0

	Hud_SetVisible( Hud_GetChild( file.menu, "XPEarned1" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "XPEarned2" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "XPEarned3" ), false )
	Hud_SetVisible( Hud_GetChild( file.menu, "XPProgressBarBattlePass" ), false )

	while ( !Hud_IsVisible( file.menu ) )
		WaitFrame()

	{
		var xpEarned1Rui = Hud_GetRui( Hud_GetChild( file.menu, "XPEarned1" ) )
		var xpEarned2Rui = Hud_GetRui( Hud_GetChild( file.menu, "XPEarned2" ) )

		Hud_SetVisible( Hud_GetChild( file.menu, "XPEarned1" ), true )
		Hud_SetVisible( Hud_GetChild( file.menu, "XPEarned2" ), true )

		RuiSetFloat( xpEarned1Rui, "startDelay", baseDelay )
		int numLines = InitXPEarnedDisplay( xpEarned1Rui, xpDisplayGroups[0], "#EOG_MATCH_XP", "", false, COLOR_MATCH )
		RuiSetFloat( xpEarned1Rui, "lineDisplayTime", LINE_DISPLAY_TIME )

		RuiSetFloat( xpEarned2Rui, "startDelay", baseDelay + (numLines * LINE_DISPLAY_TIME) )
		numLines += InitXPEarnedDisplay( xpEarned2Rui, xpDisplayGroups[1], "", "", false, COLOR_BONUS )
		RuiSetFloat( xpEarned2Rui, "lineDisplayTime", LINE_DISPLAY_TIME )

		//
		//
		//

		//
		int start_accountLevel = GetAccountLevelForXP( previousAccountXP )
		Assert( start_accountLevel >= 0 )
		int start_accountXP          = GetTotalXPToCompleteAccountLevel( start_accountLevel - 1 )
		int start_nextAccountLevelXP = GetTotalXPToCompleteAccountLevel( start_accountLevel )
		Assert( previousAccountXP >= start_accountXP )
		Assert( previousAccountXP < start_nextAccountLevelXP )

		float start_accountLevelFrac = GraphCapped( previousAccountXP, start_accountXP, start_nextAccountLevelXP, 0.0, 1.0 )

		//
		int ending_accountLevel       = GetAccountLevelForXP( currentAccountXP )
		int ending_accountXP          = GetTotalXPToCompleteAccountLevel( ending_accountLevel - 1 )
		int ending_nextAccountLevelXP = GetTotalXPToCompleteAccountLevel( ending_accountLevel )
		Assert( currentAccountXP >= ending_accountXP )
		Assert( currentAccountXP < ending_nextAccountLevelXP )
		float ending_accountLevelFrac = GraphCapped( currentAccountXP, ending_accountXP, ending_nextAccountLevelXP, 0.0, 1.0 )

		//
		var accountProgressRUI = Hud_GetRui( Hud_GetChild( file.menu, "XPProgressBarAccount" ) )
		RuiSetString( accountProgressRUI, "displayName", GetPlayerName() )
		RuiSetColorAlpha( accountProgressRUI, "oldProgressColor", <196 / 255.0, 151 / 255.0, 41 / 255.0>, 1 )
		RuiSetColorAlpha( accountProgressRUI, "newProgressColor", <255 / 255.0, 182 / 255.0, 0 / 255.0>, 1 )
		RuiSetString( accountProgressRUI, "totalEarnedXPText", ShortenNumber( string( totalXP ) ) )
		RuiSetBool( accountProgressRUI, "largeFormat", true )
		RuiSetInt( accountProgressRUI, "startLevel", start_accountLevel )
		RuiSetFloat( accountProgressRUI, "startLevelFrac", start_accountLevelFrac )
		RuiSetInt( accountProgressRUI, "endLevel", start_accountLevel )
		RuiSetFloat( accountProgressRUI, "endLevelFrac", 1.0 )
		RuiSetGameTime( accountProgressRUI, "startTime", RUI_BADGAMETIME )
		RuiSetFloat( accountProgressRUI, "startDelay", 0.0 )
		RuiSetString( accountProgressRUI, "headerText", "#EOG_XP_HEADER_MATCH" )
		RuiSetFloat( accountProgressRUI, "progressBarFillTime", PROGRESS_BAR_FILL_TIME )
		RuiSetInt( accountProgressRUI, format( "displayLevel1XP", start_accountLevel + 1 ), GetTotalXPToCompleteAccountLevel( start_accountLevel ) - GetTotalXPToCompleteAccountLevel( start_accountLevel - 1 ) )

		RuiSetString( accountProgressRUI, "currentDisplayLevel", GetAccountDisplayLevel( start_accountLevel ) )
		RuiSetString( accountProgressRUI, "nextDisplayLevel", GetAccountDisplayLevel( start_accountLevel + 1 ) )

		RuiSetImage( accountProgressRUI, "currentDisplayBadge", GetAccountDisplayBadge( start_accountLevel ) )
		RuiSetImage( accountProgressRUI, "nextDisplayBadge", GetAccountDisplayBadge( start_accountLevel + 1 ) )

		array<RewardData> accountRewardArray = GetRewardsForAccountLevel( start_accountLevel )
		RuiSetImage( accountProgressRUI, "rewardImage1", accountRewardArray.len() >= 1 ? GetImageForReward( accountRewardArray[0] ) : $"" )
		RuiSetImage( accountProgressRUI, "rewardImage2", accountRewardArray.len() >= 2 ? GetImageForReward( accountRewardArray[1] ) : $"" )
		RuiSetString( accountProgressRUI, "reward1Value", accountRewardArray.len() >= 1 ? GetStringForReward( accountRewardArray[0] ) : "" )
		RuiSetString( accountProgressRUI, "reward2Value", accountRewardArray.len() >= 2 ? GetStringForReward( accountRewardArray[1] ) : "" )

		ResetSkippableWait()
		SkippableWait( baseDelay )

		for ( int lineIndex = 0; lineIndex < numLines; lineIndex++ )
		{
			if ( IsSkippableWaitSkipped() )
				continue

			SkippableWait( LINE_DISPLAY_TIME, POSTGAME_LINE_ITEM )
		}

		RuiSetFloat( xpEarned1Rui, "startDelay", -50.0 )
		RuiSetGameTime( xpEarned1Rui, "startTime", Time() - 50.0 )
		RuiSetFloat( xpEarned2Rui, "startDelay", -50.0 )
		RuiSetGameTime( xpEarned2Rui, "startTime", Time() - 50.0 )

		int accountLevelsToPopulate = minint( (ending_accountLevel - start_accountLevel) + 1, 5 )
		for ( int index = 0; index < accountLevelsToPopulate; index++ )
		{
			int currentLevel = start_accountLevel + index
			int xpForLevel   = GetTotalXPToCompleteAccountLevel( currentLevel ) - GetTotalXPToCompleteAccountLevel( currentLevel - 1 )
			RuiSetInt( accountProgressRUI, format( "displayLevel1XP", index + 1 ), xpForLevel )

			int startLevel    = currentLevel
			int endLevel      = currentLevel
			float startXPFrac = index == 0 ? start_accountLevelFrac : 0.0
			float endXPFrac   = currentLevel == ending_accountLevel ? ending_accountLevelFrac : 1.0
			float startDelay  = index == 0 ? 0.0 : 0.5

			RuiSetInt( accountProgressRUI, "startLevel", startLevel )
			RuiSetFloat( accountProgressRUI, "startLevelFrac", startXPFrac )
			RuiSetInt( accountProgressRUI, "endLevel", endLevel )
			RuiSetFloat( accountProgressRUI, "endLevelFrac", endXPFrac )
			RuiSetGameTime( accountProgressRUI, "startTime", RUI_BADGAMETIME )
			RuiSetFloat( accountProgressRUI, "progressBarFillTime", PROGRESS_BAR_FILL_TIME )
			RuiSetFloat( accountProgressRUI, "startDelay", startDelay )
			RuiSetString( accountProgressRUI, "headerText", "#EOG_XP_HEADER_MATCH" )

			RuiSetString( accountProgressRUI, "currentDisplayLevel", GetAccountDisplayLevel( startLevel ) )
			RuiSetString( accountProgressRUI, "nextDisplayLevel", GetAccountDisplayLevel( startLevel + 1 ) )

			RuiSetImage( accountProgressRUI, "currentDisplayBadge", GetAccountDisplayBadge( startLevel ) )
			RuiSetImage( accountProgressRUI, "nextDisplayBadge", GetAccountDisplayBadge( startLevel + 1 ) )

			array<RewardData> rewardsArray = GetRewardsForAccountLevel( startLevel )
			RuiSetImage( accountProgressRUI, "rewardImage1", rewardsArray.len() >= 1 ? GetImageForReward( rewardsArray[0] ) : $"" )
			RuiSetImage( accountProgressRUI, "rewardImage2", rewardsArray.len() >= 2 ? GetImageForReward( rewardsArray[1] ) : $"" )
			RuiSetString( accountProgressRUI, "reward1Value", rewardsArray.len() >= 1 ? GetStringForReward( rewardsArray[0] ) : "" )
			RuiSetString( accountProgressRUI, "reward2Value", rewardsArray.len() >= 2 ? GetStringForReward( rewardsArray[1] ) : "" )

			float waitTime = startDelay + (PROGRESS_BAR_FILL_TIME * (endXPFrac - startXPFrac))

			RuiSetGameTime( accountProgressRUI, "startTime", Time() )
			//
			SkippableWait( waitTime, "UI_Menu_MatchSummary_XPBar" )
			StopUISoundByName( "UI_Menu_MatchSummary_XPBar" )
			RuiSetGameTime( accountProgressRUI, "startTime", -50.0 )
			RuiSetFloat( accountProgressRUI, "progressBarFillTime", 0.0 )
			RuiSetFloat( accountProgressRUI, "startDelay", 0.0 )

			if ( currentLevel < ending_accountLevel && isFirstTime )
			{
				var rewardDisplayRui = Hud_GetRui( Hud_GetChild( file.menu, "RewardDisplay" ) )
				RuiSetAsset( rewardDisplayRui, "rewardImage1", rewardsArray.len() >= 1 ? GetImageForReward( rewardsArray[0] ) : $"" )
				RuiSetAsset( rewardDisplayRui, "rewardImage2", rewardsArray.len() >= 2 ? GetImageForReward( rewardsArray[1] ) : $"" )
				RuiSetString( rewardDisplayRui, "reward1Value", rewardsArray.len() >= 1 ? GetStringForReward( rewardsArray[0] ) : "" )
				RuiSetString( rewardDisplayRui, "reward2Value", rewardsArray.len() >= 2 ? GetStringForReward( rewardsArray[1] ) : "" )

				RuiSetString( rewardDisplayRui, "headerText", "#EOG_LEVEL_UP_HEADER" )
				RuiSetString( rewardDisplayRui, "rewardHeaderText", rewardsArray.len() > 1 ? "#EOG_REWARDS_LABEL" : "#EOG_REWARD_LABEL" )
				RuiSetString( rewardDisplayRui, "accountLevelText", GetAccountDisplayLevel( startLevel + 1 ) )

				RuiSetImage( rewardDisplayRui, "accountBadgeIcon", GetAccountDisplayBadge( startLevel + 1 ) )

				EmitUISound( "ui_menu_matchsummary_levelup" )

				RuiSetFloat( rewardDisplayRui, "rewardsDuration", REWARD_AWARD_TIME )

				RuiSetGameTime( rewardDisplayRui, "rewardsStartTime", Time() )
				RuiSetFloat( rewardDisplayRui, "rewardsDuration", REWARD_AWARD_TIME )

				wait REWARD_AWARD_TIME - 0.5
			}
		}

		SkippableWait( baseDelay )
	}

	if ( IsBattlePassEnabled() )
		activeBattlePass = GetPlayerActiveBattlePass( WaitForLocalClientEHI() )
	if ( activeBattlePass == null )
		return

	expect ItemFlavor(activeBattlePass)

	Hud_SetVisible( file.combinedCard, false )

	{
		int previousBattlePassXP = GetPlayerBattlePassXPProgress( ToEHI( player ), activeBattlePass, true )
		int currentBattlePassXP  = GetPlayerBattlePassXPProgress( ToEHI( player ), activeBattlePass, false )
		int totalBattlePassXP    = currentBattlePassXP - previousBattlePassXP

		var xpEarned3Rui = Hud_GetRui( Hud_GetChild( file.menu, "XPEarned3" ) )
		Hud_SetVisible( Hud_GetChild( file.menu, "XPEarned3" ), true )
		Hud_SetVisible( Hud_GetChild( file.menu, "XPProgressBarBattlePass" ), true )

		bool isFreePlayer = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
		RuiSetFloat( xpEarned3Rui, "startDelay", baseDelay )
		int numLines = InitXPEarnedDisplay( Hud_GetRui( Hud_GetChild( file.menu, "XPEarned3" ) ), xpDisplayGroups[2], "#EOG_MATCH_BP", "#BATTLE_PASS_SEASON_1", true, COLOR_BP_PREMIUM )
		RuiSetFloat( xpEarned3Rui, "lineDisplayTime", LINE_DISPLAY_TIME )

	//######################################
	// PROGRESS BARS
	//######################################

		//
		int start_passLevel = GetBattlePassLevelForXP( activeBattlePass, previousBattlePassXP )
		Assert( start_passLevel >= 0 )
		int start_passXP          = GetTotalXPToCompletePassLevel( activeBattlePass, start_passLevel - 1 )

		int start_nextPassLevelXP
		if ( start_passLevel > GetBattlePassMaxLevelIndex( activeBattlePass ) )
			start_nextPassLevelXP = start_passXP
		else
			start_nextPassLevelXP = GetTotalXPToCompletePassLevel( activeBattlePass, start_passLevel )

		Assert( previousBattlePassXP >= start_passXP )
		Assert( previousBattlePassXP <= start_nextPassLevelXP )

		float start_passLevelFrac = GraphCapped( previousBattlePassXP, start_passXP, start_nextPassLevelXP, 0.0, 1.0 )

		//
		int ending_passLevel       = GetBattlePassLevelForXP( activeBattlePass, currentBattlePassXP )
		int ending_passXP          = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel - 1 )
		bool isMaxPassLevel 	   = ending_passLevel > GetBattlePassMaxLevelIndex( activeBattlePass )

		int ending_nextPassLevelXP
		if ( isMaxPassLevel )
			ending_nextPassLevelXP = ending_passXP
		else
			ending_nextPassLevelXP = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel )

		Assert( currentBattlePassXP >= ending_passXP )
		Assert( currentBattlePassXP <= ending_nextPassLevelXP )
		float ending_passLevelFrac = GraphCapped( currentBattlePassXP, ending_passXP, ending_nextPassLevelXP, 0.0, 1.0 )

		//
		var passProgressRUI = Hud_GetRui( Hud_GetChild( file.menu, "XPProgressBarBattlePass" ) )
		RuiSetBool( passProgressRUI, "battlePass", true )

		RuiSetString( passProgressRUI, "displayName", GetPlayerName() )
		RuiSetColorAlpha( passProgressRUI, "oldProgressColor", <196 / 255.0, 151 / 255.0, 41 / 255.0>, 1 )
		RuiSetColorAlpha( passProgressRUI, "newProgressColor", <255 / 255.0, 182 / 255.0, 0 / 255.0>, 1 )
		RuiSetString( passProgressRUI, "totalEarnedXPText", ShortenNumber( string( totalBattlePassXP ) ) )
		RuiSetBool( passProgressRUI, "largeFormat", true )
		RuiSetInt( passProgressRUI, "startLevel", start_passLevel )
		RuiSetFloat( passProgressRUI, "startLevelFrac", start_passLevelFrac )
		RuiSetInt( passProgressRUI, "endLevel", start_passLevel )
		RuiSetFloat( passProgressRUI, "endLevelFrac", 1.0 )
		RuiSetGameTime( passProgressRUI, "startTime", RUI_BADGAMETIME )
		RuiSetFloat( passProgressRUI, "startDelay", 0.0 )
		RuiSetString( passProgressRUI, "headerText", "#EOG_XP_HEADER_MATCH" )
		RuiSetFloat( passProgressRUI, "progressBarFillTime", PROGRESS_BAR_FILL_TIME )
		if ( isMaxPassLevel )
			RuiSetInt( passProgressRUI, "displayLevel1XP", 0 )
		else
			RuiSetInt( passProgressRUI, "displayLevel1XP", GetTotalXPToCompletePassLevel( activeBattlePass, start_passLevel ) - GetTotalXPToCompletePassLevel( activeBattlePass, start_passLevel - 1 ) )

		ItemFlavor dummy
		ItemFlavor bpLevelBadge = GetItemFlavorByAsset( $"settings/itemflav/gcard_badge/account/season01_bplevel.rpak" )

		RuiSetString( passProgressRUI, "currentDisplayLevel", "" )
		RuiSetString( passProgressRUI, "nextDisplayLevel", "" )
		RuiSetImage( passProgressRUI, "currentDisplayBadge", $"" )
		RuiSetImage( passProgressRUI, "nextDisplayBadge", $"" )

		RuiDestroyNestedIfAlive( passProgressRUI, "currentBadgeHandle" )
		CreateNestedGladiatorCardBadge( passProgressRUI, "currentBadgeHandle", ToEHI( player ), bpLevelBadge, 0, dummy, start_passLevel + 1 )

		RuiDestroyNestedIfAlive( passProgressRUI, "nextBadgeHandle" )
		if ( !isMaxPassLevel )
			CreateNestedGladiatorCardBadge( passProgressRUI, "nextBadgeHandle", ToEHI( player ), bpLevelBadge, 0, dummy, start_passLevel + 2 )

		array<BattlePassReward> passRewardArray = GetBattlePassLevelRewards( activeBattlePass, start_passLevel )
		RuiSetImage( passProgressRUI, "rewardImage1", passRewardArray.len() >= 1 ? GetImageForBattlePassReward( passRewardArray[0] ) : $"" )
		RuiSetImage( passProgressRUI, "rewardImage2", passRewardArray.len() >= 2 ? GetImageForBattlePassReward( passRewardArray[1] ) : $"" )
		RuiSetString( passProgressRUI, "reward1Value", passRewardArray.len() >= 1 ? ItemFlavor_GetType( passRewardArray[0].flav ) == eItemType.account_currency ? string( passRewardArray[0].quantity ) : " " : "" )
		RuiSetString( passProgressRUI, "reward2Value", passRewardArray.len() >= 2 ? ItemFlavor_GetType( passRewardArray[1].flav ) == eItemType.account_currency ? string( passRewardArray[1].quantity ) : " " : "" )
		RuiSetBool( passProgressRUI, "reward1Premium", passRewardArray.len() >= 1 ? passRewardArray[0].isPremium : false )
		RuiSetBool( passProgressRUI, "reward2Premium", passRewardArray.len() >= 2 ? passRewardArray[1].isPremium : false )


		RuiDestroyNestedIfAlive( passProgressRUI, "reward1Handle" )
		if ( passRewardArray.len() >= 1 )
		{
			var reward1NestedRui = RuiCreateNested( passProgressRUI, "reward1Handle", $"ui/battle_pass_reward_button.rpak" )
			RuiSetBool( reward1NestedRui, "isRewardBar", true )
			InitBattlePassRewardButtonRui( reward1NestedRui, passRewardArray[0] )
		}

		RuiDestroyNestedIfAlive( passProgressRUI, "reward2Handle" )
		if ( passRewardArray.len() >= 2 )
		{
			var reward2NestedRui = RuiCreateNested( passProgressRUI, "reward2Handle", $"ui/battle_pass_reward_button.rpak" )
			RuiSetBool( reward2NestedRui, "isRewardBar", true )
			InitBattlePassRewardButtonRui( reward2NestedRui, passRewardArray[1] )
		}

		ResetSkippableWait()
		SkippableWait( baseDelay )

		for ( int lineIndex = 0; lineIndex < numLines; lineIndex++ )
		{
			if ( IsSkippableWaitSkipped() )
				continue

			SkippableWait( LINE_DISPLAY_TIME, POSTGAME_LINE_ITEM )
		}

		RuiSetFloat( xpEarned3Rui, "startDelay", -50.0 )
		RuiSetGameTime( xpEarned3Rui, "startTime", Time() - 50.0 )

		int passLevelsToPopulate = minint( (ending_passLevel - start_passLevel) + 1, 5 )
		for ( int index = 0; index < passLevelsToPopulate; index++ )
		{
			int currentLevel = start_passLevel + index
			int xpForLevel   = isMaxPassLevel ? 0 : GetTotalXPToCompletePassLevel( activeBattlePass, currentLevel ) - GetTotalXPToCompletePassLevel( activeBattlePass, currentLevel - 1 )
			RuiSetInt( passProgressRUI, format( "displayLevel1XP", index + 1 ), xpForLevel )

			int startLevel    = currentLevel
			int endLevel      = currentLevel
			float startXPFrac = index == 0 ? start_passLevelFrac : 0.0
			float endXPFrac   = isMaxPassLevel ? 0.0 : currentLevel == ending_passLevel ? ending_passLevelFrac : 1.0
			float startDelay  = 0.0//

			RuiSetInt( passProgressRUI, "startLevel", startLevel )
			RuiSetFloat( passProgressRUI, "startLevelFrac", startXPFrac )
			RuiSetInt( passProgressRUI, "endLevel", endLevel )
			RuiSetFloat( passProgressRUI, "endLevelFrac", endXPFrac )
			RuiSetGameTime( passProgressRUI, "startTime", RUI_BADGAMETIME )
			RuiSetFloat( passProgressRUI, "progressBarFillTime", PROGRESS_BAR_FILL_TIME )
			RuiSetFloat( passProgressRUI, "startDelay", startDelay )
			RuiSetString( passProgressRUI, "headerText", "#EOG_XP_HEADER_PASS" )

			RuiSetString( passProgressRUI, "currentDisplayLevel", "" )
			RuiSetString( passProgressRUI, "nextDisplayLevel", "" )
			RuiSetImage( passProgressRUI, "currentDisplayBadge", $"" )
			RuiSetImage( passProgressRUI, "nextDisplayBadge", $"" )

			RuiDestroyNestedIfAlive( passProgressRUI, "currentBadgeHandle" )
			CreateNestedGladiatorCardBadge( passProgressRUI, "currentBadgeHandle", ToEHI( player ), bpLevelBadge, 0, dummy, startLevel + 1 )

			RuiDestroyNestedIfAlive( passProgressRUI, "nextBadgeHandle" )
			if ( !isMaxPassLevel )
				CreateNestedGladiatorCardBadge( passProgressRUI, "nextBadgeHandle", ToEHI( player ), bpLevelBadge, 0, dummy, startLevel + 2 )

			if ( isMaxPassLevel )
				passRewardArray = []
			else
				passRewardArray = GetBattlePassLevelRewards( activeBattlePass, startLevel )

			RuiSetImage( passProgressRUI, "rewardImage1", passRewardArray.len() >= 1 ? GetImageForBattlePassReward( passRewardArray[0] ) : $"" )
			RuiSetImage( passProgressRUI, "rewardImage2", passRewardArray.len() >= 2 ? GetImageForBattlePassReward( passRewardArray[1] ) : $"" )
			RuiSetString( passProgressRUI, "reward1Value", passRewardArray.len() >= 1 ? ItemFlavor_GetType( passRewardArray[0].flav ) == eItemType.account_currency ? string( passRewardArray[0].quantity ) : " " : "" )
			RuiSetString( passProgressRUI, "reward2Value", passRewardArray.len() >= 2 ? ItemFlavor_GetType( passRewardArray[1].flav ) == eItemType.account_currency ? string( passRewardArray[1].quantity ) : " " : "" )
			RuiSetBool( passProgressRUI, "reward1Premium", passRewardArray.len() >= 1 ? passRewardArray[0].isPremium : false )
			RuiSetBool( passProgressRUI, "reward2Premium", passRewardArray.len() >= 2 ? passRewardArray[1].isPremium : false )

			RuiDestroyNestedIfAlive( passProgressRUI, "reward1Handle" )
			if ( passRewardArray.len() >= 1 )
			{
				var reward1NestedRui = RuiCreateNested( passProgressRUI, "reward1Handle", $"ui/battle_pass_reward_button.rpak" )
				InitBattlePassRewardButtonRui( reward1NestedRui, passRewardArray[0] )
			}

			RuiDestroyNestedIfAlive( passProgressRUI, "reward2Handle" )
			if ( passRewardArray.len() >= 2 )
			{
				var reward2NestedRui = RuiCreateNested( passProgressRUI, "reward2Handle", $"ui/battle_pass_reward_button.rpak" )
				InitBattlePassRewardButtonRui( reward2NestedRui, passRewardArray[1] )
			}


			float waitTime = startDelay + (PROGRESS_BAR_FILL_TIME * (endXPFrac - startXPFrac))

			RuiSetGameTime( passProgressRUI, "startTime", Time() )
			//
			SkippableWait( waitTime, "UI_Menu_MatchSummary_XPBar" )
			StopUISoundByName( "UI_Menu_MatchSummary_XPBar" )
			RuiSetGameTime( passProgressRUI, "startTime", -50.0 )
			RuiSetFloat( passProgressRUI, "progressBarFillTime", 0.0 )
			RuiSetFloat( passProgressRUI, "startDelay", 0.0 )

			if ( currentLevel < ending_passLevel && isFirstTime )
			{

			}
		}

		thread TryDisplayBattlePassAwards()

		SkippableWait( baseDelay )
	}
	return
	//######################################
}


float function CalculateAccountLevelingUpDuration( int start_accountLevel, int ending_accountLevel, float start_accountLevelFrac, float ending_accountLevelFrac )
{
	float totalDelay

	int displayLevel = start_accountLevel
	while( displayLevel < ending_accountLevel + 1 )
	{
		float startFrac  = (displayLevel == start_accountLevel) ? start_accountLevelFrac : 0.0
		float endFrac    = (displayLevel == ending_accountLevel) ? ending_accountLevelFrac : 1.0
		float timeToFill = (endFrac - startFrac) * PROGRESS_BAR_FILL_TIME

		totalDelay += timeToFill
		displayLevel++
	}

	return totalDelay
}


void function OnLevelInit()
{
	PostGame_ClearDisplay()
}


void function PostGame_ClearDisplay()
{
}


void function OnOpenPostGameMenu()
{
	if ( !IsFullyConnected() )
	{
		CloseActiveMenu()
		return
	}

	RegisterButtonPressedCallback( BUTTON_A, OnContinue_Activate )
	RegisterButtonPressedCallback( KEY_SPACE, OnContinue_Activate )

	UI_SetPresentationType( ePresentationType.WEAPON_CATEGORY )

	RuiSetGameTime( file.decorationRui, "initTime", Time() )

	file.wasPartyMember = AmIPartyMember()

	bool isFirstTime = GetPersistentVarAsInt( "showGameSummary" ) != 0

	thread DisplayPostGameSummary( isFirstTime )
	ClientCommand( "ViewedGameSummary" )
}


void function OnShowPostGameMenu()
{
	UI_SetPresentationType( ePresentationType.WEAPON_CATEGORY )
}


void function OnClosePostGameMenu()
{
	Signal( uiGlobal.signalDummy, "PGDisplay" )

	PostGame_ClearDisplay()
	DeregisterButtonPressedCallback( BUTTON_A, OnContinue_Activate )
	DeregisterButtonPressedCallback( KEY_SPACE, OnContinue_Activate )
}


bool function CanNavigateBack()
{
	return file.disableNavigateBack != true
}


void function OnNavigateBack()
{
	if ( !CanNavigateBack() )
		return

	ClosePostGameMenu( null )
}


bool function PartyStatusUnchangedDuringPostGameMenu()
{
	return file.wasPartyMember == AmIPartyMember()
}


bool function IsPostGameMenuValid( bool checkTime = false )
{
	if ( checkTime && GetUnixTimestamp() - GetPersistentVarAsInt( "lastGameTime" ) > POSTGAME_DATA_EXPIRATION_TIME )
		return false

	if ( !IsPersistenceAvailable() )
		return false

	if ( GetPersistentVarAsInt( "lastGamePlayers" ) == 0 && GetPersistentVarAsInt( "lastGameSquads" ) == 0 )
		return false

	return true
}


void function OpenPostGameMenu( var button )
{
	Assert( IsPostGameMenuValid() )

	AdvanceMenu( file.menu )
}


void function ClosePostGameMenu( var button )
{
	if ( GetActiveMenu() == file.menu )
		thread CloseActiveMenu()
}
