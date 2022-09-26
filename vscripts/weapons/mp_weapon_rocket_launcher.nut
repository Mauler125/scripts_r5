untyped

global function MpWeaponRocketLauncher_Init

global function OnWeaponActivate_weapon_rocket_launcher
global function OnWeaponDeactivate_weapon_rocket_launcher
global function OnWeaponPrimaryAttack_weapon_rocket_launcher
global function OnWeaponOwnerChanged_weapon_rocket_launcher
global function OnWeaponReload_weapon_rocket_launcher

//14 //RUMBLE_FLAT_BOTH
const LOCKON_RUMBLE_INDEX 	= 1 //RUMBLE_PISTOL
const LOCKON_RUMBLE_AMOUNT	= 45
const S2S_MISSILE_SPEED = 2500
const S2S_MISSILE_HOMING = 5000

function MpWeaponRocketLauncher_Init()
{
	RegisterSignal( "StopLockonRumble" )
	RegisterSignal( "StopGuidedLaser" )
}

function MissileThink( weapon, missile )
{
	expect entity( missile )

	#if SERVER
		missile.EndSignal( "OnDestroy" )

		bool playedWarning = false

		while ( IsValid( missile ) )
		{
			entity target = missile.GetMissileTarget()

			if ( IsValid( target ) && target.IsPlayer() )
			{
				float distance = Distance( missile.GetOrigin(), target.GetOrigin() )

				if ( distance < 1536 && !playedWarning )
				{
					EmitSoundOnEntityOnlyToPlayer( target, target, "titan_cockpit_missile_close_warning" )
					playedWarning = true
				}
			}

			WaitFrame()
		}
	#endif
}

void function OnWeaponActivate_weapon_rocket_launcher( entity weapon )
{
	if ( !( "initialized" in weapon.s ) )
	{
		weapon.s.missileThinkThread <- MissileThink
		weapon.s.initialized <- true
	}

	bool hasGuidedMissiles = weapon.HasMod( "guided_missile" )

	if ( !hasGuidedMissiles )
	{
		SmartAmmo_SetAllowUnlockedFiring( weapon )
		SmartAmmo_SetMissileSpeed( weapon, 1200 )
		SmartAmmo_SetMissileHomingSpeed( weapon, 125 )
		SmartAmmo_SetMissileSpeedLimit( weapon, 1400 )
		
		SmartAmmo_SetMissileShouldDropKick( weapon, false )  // TODO set to true to see drop kick behavior issues
		SmartAmmo_SetUnlockAfterBurst( weapon, true )
	}

	entity weaponOwner = weapon.GetWeaponOwner()

	if ( hasGuidedMissiles )
	{
		if ( !("guidedLaserPoint" in weaponOwner.s) )
			weaponOwner.s.guidedLaserPoint <- null

		thread CalculateGuidancePoint( weapon, weaponOwner )
	}
}

void function OnWeaponDeactivate_weapon_rocket_launcher( entity weapon )
{
	if ( weapon.HasMod( "guided_missile" ) )
		weapon.Signal( "StopGuidedLaser" )
}

var function OnWeaponPrimaryAttack_weapon_rocket_launcher( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()

	float zoomFrac = weaponOwner.GetZoomFrac()
	if ( zoomFrac < 1 )
		return 0

	vector angles = VectorToAngles( weaponOwner.GetViewVector() )
	vector right = AnglesToRight( angles )
	vector up = AnglesToUp( angles )
	#if SERVER
		if ( weaponOwner.GetTitanSoulBeingRodeoed() != null )
			attackParams.pos = attackParams.pos + up * 20
	#endif

	if ( !weapon.HasMod( "guided_missile" ) )
	{
		int fired = SmartAmmo_FireWeapon( weapon, attackParams, damageTypes.projectileImpact, damageTypes.explosive )

		if ( fired )
		{
			weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
		}

		return fired
	}
	else
	{
		if( !weapon.IsWeaponAdsButtonPressed() )
			return 0

		bool shouldPredict = weapon.ShouldPredictProjectiles()
		#if CLIENT
			if ( !shouldPredict )
				return 1
		#endif

		float speed = 1200.0
		if ( weapon.HasMod("titanhammer") )
			speed = 800.0

		weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
		
		//bool shouldPredict = true
		WeaponFireMissileParams fireMissileParams
		fireMissileParams.pos = attackParams.pos
		fireMissileParams.dir = attackParams.dir
		fireMissileParams.speed = 1200
		fireMissileParams.scriptTouchDamageType = damageTypes.projectileImpact
		fireMissileParams.scriptExplosionDamageType = damageTypes.explosive
		fireMissileParams.doRandomVelocAndThinkVars = false
		fireMissileParams.clientPredicted = false
		entity missile = weapon.FireWeaponMissile( fireMissileParams )
	
		if ( missile )
		{
			if( "guidedMissileTarget" in weapon.s && IsValid( weapon.s.guidedMissileTarget ) )
			{
				missile.SetMissileTarget( weapon.s.guidedMissileTarget, Vector( 0, 0, 0 ) )
				missile.SetHomingSpeeds( 300, 0 )
			}

			InitializeGuidedMissile( weaponOwner, missile )
		}
	}
}

void function OnWeaponReload_weapon_rocket_launcher( entity weapon, int milestoneIndex )
{
	thread MissingMaterialOnReloadHACK()
}

void function MissingMaterialOnReloadHACK()
{
	wait 0.5
	SetConVarBool( "r_drawparticles", false )
	wait 3 //reload time
	SetConVarBool( "r_drawparticles", true )
}

//GUIDED MISSILE FUNCTIONS
function CalculateGuidancePoint( entity weapon, entity weaponOwner )
{
	weaponOwner.EndSignal( "OnDestroy" )
	weapon.EndSignal( "OnDestroy" )
	weapon.EndSignal( "StopGuidedLaser" )

	entity info_target
	#if SERVER
		info_target = CreateEntity( "info_target" )
		info_target.SetOrigin( weapon.GetOrigin() )
		info_target.SetInvulnerable()
		DispatchSpawn( info_target )
		weapon.s.guidedMissileTarget <- info_target
	#endif

	OnThreadEnd(
		function() : ( weapon, info_target )
		{
			if ( IsValid( info_target ) )
			{
				info_target.Kill_Deprecated_UseDestroyInstead()
				delete weapon.s.guidedMissileTarget
			}
		}
	)

	while ( true )
	{
		if ( !IsValid_ThisFrame( weaponOwner ) || !IsValid_ThisFrame( weapon ) )
			return

		weaponOwner.s.guidedLaserPoint = null
		if ( weapon.IsWeaponInAds())
		{
			TraceResults result = GetViewTrace( weaponOwner )
			weaponOwner.s.guidedLaserPoint = result.endPos
			#if SERVER
				info_target.SetOrigin( result.endPos )
			#endif
		}

		WaitFrame()
	}
}

function InitializeGuidedMissile( entity weaponOwner, entity missile )
{
		missile.s.guidedMissile <- true
		if ( "missileInFlight" in weaponOwner.s )
			weaponOwner.s.missileInFlight = true
		else
			weaponOwner.s.missileInFlight <- true

		missile.kv.lifetime = 10

		#if SERVER
			missile.SetOwner( weaponOwner )
			thread playerHasMissileInFlight( weaponOwner, missile )
		#endif
}

#if SERVER
function playerHasMissileInFlight( entity weaponOwner, entity missile )
{
	weaponOwner.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function() : ( weaponOwner )
		{
			if ( IsValid( weaponOwner ) )
			{
				weaponOwner.s.missileInFlight = false
				//Using a remote call because if this thread is on the client it gets triggered prematurely due to prediction.
				Remote_CallFunction_NonReplay( weaponOwner, "ServerCallback_GuidedMissileDestroyed" )
			}
		}
	)

	WaitSignal( missile, "OnDestroy" )
}
#endif // SERVER


void function OnWeaponOwnerChanged_weapon_rocket_launcher( entity weapon, WeaponOwnerChangedParams changeParams )
{
	#if SERVER
		weapon.w.missileFiredCallback = null
	#endif
}