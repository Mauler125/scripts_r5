global function OnWeaponPrimaryAttack_weapon_decoyspawner
global function OnProjectileCollision_weapon_decoyspawner

#if SERVER
global function OnWeaponNpcPrimaryAttack_weapon_decoyspawner
#endif // #if SERVER


const DECOY_AR_MARKER = $"P_ar_ping_squad_CP"
const float DECOY_TRACE_DIST = 5000.0

const DECOY_FLAG_FX = $"P_flag_fx_foe"
const HOLO_EMITTER_CHARGE_FX_1P = $"P_mirage_holo_emitter_glow_FP"
const HOLO_EMITTER_CHARGE_FX_3P = $"P_mirage_emitter_flash"
const asset DECOY_TRIGGERED_ICON = $"rui/hud/tactical_icons/tactical_mirage_in_world"

struct
{
	table<entity, int> playerToDecoysActiveTable //Mainly used to track stat for holopilot unlock
} file



global entity _weapon


var function OnWeaponPrimaryAttack_weapon_decoyspawner( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    _weapon = weapon
    printt(_weapon.GetWeaponOwner())
    //EmitSoundOnEntity( weapon, "Mirage_PsycheOut_Activate_3P" )
	bool playerFired = true
	return FireGenericBoltWithDrop( weapon, attackParams, playerFired)
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_weapon_decoyspawner( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    _weapon = weapon
    //EmitSoundOnEntity( weapon, "Mirage_PsycheOut_Activate_3P" )
	bool playerFired = false
	return FireGenericBoltWithDrop( weapon, attackParams, playerFired )
}
#endif // #if SERVER


void function OnProjectileCollision_weapon_decoyspawner( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
{
    printt("Projectile hit -------------------------------" + hitEnt)
    #if SERVER
	if (hitEnt.IsWorld())
	    CreateHoloPilotDecoys_decoyspawner( _weapon.GetWeaponOwner(), pos)
    #endif
}

#if SERVER
void function CreateHoloPilotDecoys_decoyspawner( entity player,  vector offsetOrigin)
{
	Assert( player )

	asset modelName = $""
	ItemFlavor character = LoadoutSlot_GetItemFlavor( ToEHI( player ), Loadout_CharacterClass() )
	ItemFlavor skin = LoadoutSlot_GetItemFlavor( ToEHI( player ), Loadout_CharacterSkin( character ))



	entity decoy

    //Create the look angle
	vector normalizedAngle = player.GetAngles()
	normalizedAngle.y = AngleNormalize( normalizedAngle.y ) //Only care about changing the yaw

    //Calculates forward vector from look angle
	vector forwardVector = AnglesToForward( normalizedAngle )

    //Creates then move the decoys to the correct origin
 	decoy = CreateDecoy( offsetOrigin + <0,0,25>, $"", modelName, player, skin, 6 )
	decoy.SetAngles( normalizedAngle )
	decoy.SetOrigin( offsetOrigin + <0,0,25> ) //Using player origin instead of decoy origin as defensive fix, see bug 223066
	PutEntityInSafeSpot( decoy, player, null, offsetOrigin + <0,0,25>, decoy.GetOrigin() )

	thread MonitorDecoyActiveForPlayer( decoy, player )

}

entity function CreateDecoy( vector endPosition, asset settingsName, asset modelName, entity player, ItemFlavor skin, float duration )
{
	entity decoy = player.CreateTargetedPlayerDecoy( endPosition, settingsName, modelName, 0, 0 )
	CharacterSkin_Apply( decoy, skin )
	decoy.SetMaxHealth( 50 )
	decoy.SetHealth( 50 )
	decoy.EnableAttackableByAI( 50, 0, AI_AP_FLAG_NONE )
	SetObjectCanBeMeleed( decoy, true )
	decoy.SetTimeout( duration )
	decoy.SetPlayerOneHits( true )

	StatsHook_HoloPiliot_OnDecoyCreated( player )
	AddEntityCallback_OnPostDamaged( decoy, void function( entity decoy, var damageInfo ) : ( player ) {
		if ( IsValid( player ) )
			HoloPiliot_OnDecoyDamaged( decoy, player, damageInfo )
	})
	return decoy
}

void function HoloPiliot_OnDecoyDamaged( entity decoy, entity owner, var damageInfo )
{
	entity attacker = DamageInfo_GetAttacker( damageInfo )
	if ( !IsValid( attacker ) || !attacker.IsPlayer() || !IsEnemyTeam( owner.GetTeam(), attacker.GetTeam() ) )
		return

	if ( decoy.e.attachedEnts.contains( attacker ) )
		return

	StatsHook_HoloPiliot_OnDecoyDamaged( decoy, owner, attacker, damageInfo )

	decoy.e.attachedEnts.append( attacker )

	PingForDecoyTriggered( owner, attacker )
}

entity function PingForDecoyTriggered( entity playerOwner, entity targetEnt )
{
	if ( playerOwner.IsPlayer() )
		EmitSoundOnEntityOnlyToPlayer( playerOwner, playerOwner, "ui_mapping_item_1p" )

	entity wp = CreateWaypoint_BasicPos( targetEnt.GetOrigin() + <0,0,96>, "", DECOY_TRIGGERED_ICON )
	wp.SetOwner( playerOwner )
	wp.SetOnlyTransmitToSingleTeam( playerOwner.GetTeam() )
	targetEnt.Signal( "MirageSpotted" )
	thread DelayedDestroyWP( wp, targetEnt )
	return wp
}

void function DelayedDestroyWP( entity wp, entity targetEnt )
{
	wp.EndSignal( "OnDestroy" )
	targetEnt.EndSignal( "MirageSpotted" )

	OnThreadEnd(
	function() : ( wp )
		{
			if ( IsValid( wp ) )
				wp.Destroy()
		}
	)

	wait 2.5
}

void function MonitorDecoyActiveForPlayer( entity decoy, entity player )
{
	if ( player in file.playerToDecoysActiveTable )
		++file.playerToDecoysActiveTable[ player ]
	else
		file.playerToDecoysActiveTable[ player ] <- 1

	decoy.EndSignal( "OnDestroy" ) //Note that we do this OnDestroy instead of the inbuilt OnHoloPilotDestroyed() etc functions so there is a bit of leeway after the holopilot starts to die/is fully invisible before being destroyed
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "CleanupPlayerPermanents" )

	OnThreadEnd(
	function() : ( player )
		{
			if ( IsValid( player ) )
			{
				Assert( player in file.playerToDecoysActiveTable )
				--file.playerToDecoysActiveTable[ player ]
			}
		}
	)

	//WaitForever()
}

#endif