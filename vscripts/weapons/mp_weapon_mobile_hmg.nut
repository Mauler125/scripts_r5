global function MpWeaponMobileHMG_Init
global function OnWeaponActivate_weapon_mobile_hmg
global function OnWeaponStartZoomIn_weapon_mobile_hmg
global function OnWeaponStartZoomOut_weapon_mobile_hmg
global function OnWeaponReload_weapon_mobile_hmg

#if CLIENT
global function OnClientAnimEvent_weapon_mobile_hmg
#endif

global const string MOBILE_HMG_WEAPON_NAME = "mp_weapon_mobile_hmg"


const string TURRET_BUTTON_PRESS_SOUND_1P = "weapon_sheilaturret_triggerpull"
const string TURRET_BUTTON_PRESS_SOUND_3P = "weapon_sheilaturret_triggerpull_3p"
const string TURRET_BARREL_SPIN_LOOP_1P = "weapon_sheilaturret_motorloop_1p"
const string TURRET_BARREL_SPIN_LOOP_3P = "Weapon_sheilaturret_mobile_motorLoop_3P"
const string TURRET_WINDUP_1P = "weapon_sheilaturret_windup_1p"
const string TURRET_WINDUP_3P = "weapon_sheilaturret_windup_3p"

const string TURRET_WINDDOWN_1P = "weapon_sheilaturret_mobile_winddown_1p"
const string TURRET_WINDDOWN_3P = "weapon_sheilaturret_winddown_3P"
const string TURRET_RELOAD_3P = "weapon_sheilaturret_reload_generic_comp_3p"
const string TURRET_RELOAD_RAMPART_3P = "weapon_sheilaturret_reload_rampart_comp_3p"
const string TURRET_RELOAD = "weapon_sheilaturret_reload_rampart_null"
const string TURRET_FIRED_LAST_SHOT_1P = "weapon_sheilaturret_lastshot_1p"
const string TURRET_FIRED_LAST_SHOT_3P = "weapon_sheilaturret_lastshot_3p"
const string TURRET_DISMOUNT_1P = "weapon_sheilaturret_mobile_dismount_1p"
const string TURRET_SIGHT_FLIP_UP_1P = "weapon_sheilaturret_sightflipup"
const string TURRET_SIGHT_FLIP_DOWN_1P = "weapon_sheilaturret_sightflipdown"

const string TURRET_DRAWFIRST_1P = "weapon_sheilaturret_drawfirst_1p"
const string TURRET_DRAW_1P = "weapon_sheilaturret_draw_1p"

const string TURRET_BARREL_SPIN_AMPED_LOOP_1P = "weapon_sheilaturret_motorloop_1p"
const string TURRET_BARREL_SPIN_AMPED_LOOP_3P = "Weapon_sheilaturret_mobile_motorLoop_3P"

const string TURRET_WINDUP_AMPED_1P = "wweapon_particle_accelerator_windup_1p"
const string TURRET_WINDUP_AMPED_3P = "weapon_particle_accelerator_windup_3p"
const string TURRET_WINDDOWN_AMPED_1P = "weapon_havoc_winddown_1p"
const string TURRET_WINDDOWN_AMPED_3P = "weapon_havoc_winddown_3p"

const TURRET_LASER_1P = $"P_wpn_lasercannon_aim_long"

const TURRET_LASER_AMPED_1P	= $"P_wpn_lasercannon_aim_short_blue"
const TURRET_AMPED_FX_UI_1P = $"P_wpn_arcball_flare_amp"
const TURRET_AMPED_FX_1P = $"P_charge_tool_glow"

struct
{
	#if CLIENT
		bool IsClientLaserEnabled = false
	#endif
} file

const float SMART_PISTOL_TRACKER_TIME = 10.0

void function MpWeaponMobileHMG_Init()
{
	PrecacheParticleSystem( TURRET_LASER_1P )
	PrecacheParticleSystem( TURRET_LASER_AMPED_1P )

	PrecacheParticleSystem( TURRET_AMPED_FX_UI_1P )
	PrecacheParticleSystem( TURRET_AMPED_FX_1P )
}

bool function IsAmped( entity weapon )
{
	return weapon.HasMod("altfire")
}

#if SERVER
bool function IsServerLaserEnabled( entity owner )
{
	return GetEntArrayByScriptName( "laser_" + owner.GetPlayerName() ).len() > 0
}

void function SetServerLaser( entity fx , entity owner)
{
    fx.SetScriptName("laser_" + owner.GetPlayerName())
	fx.kv.VisibilityFlags = ENTITY_VISIBLE_TO_ENEMY
}

array<entity> function GetServerLasers(entity owner)
{
	if(IsServerLaserEnabled(owner))
        return GetEntArrayByScriptName( "laser_" + owner.GetPlayerName() )

	return []
}
#endif

void function OnWeaponActivate_weapon_mobile_hmg( entity weapon )
{
	OnWeaponActivate_weapon_basic_bolt( weapon )
}


void function OnWeaponStartZoomIn_weapon_mobile_hmg( entity weapon )
{
	StopSoundOnEntity( weapon, TURRET_WINDDOWN_AMPED_1P )
	StopSoundOnEntity( weapon, TURRET_WINDDOWN_AMPED_3P )
	StopSoundOnEntity( weapon, TURRET_WINDDOWN_1P )
	StopSoundOnEntity( weapon, TURRET_WINDDOWN_3P )

	entity weaponOwner = weapon.GetWeaponOwner()

	if ( !IsValid( weaponOwner ) && weapon.IsWeaponInAds() )
		return

	#if SERVER
	SetTurretVMLaserEnabled( weapon, true )
	#endif

	if( IsAmped( weapon ) )
	    weapon.EmitWeaponSound_1p3p( TURRET_WINDUP_AMPED_1P, TURRET_WINDUP_AMPED_3P )
    else weapon.EmitWeaponSound_1p3p( TURRET_WINDUP_1P, TURRET_WINDUP_3P )

    #if CLIENT
	if ( weaponOwner == GetLocalViewPlayer() )
		weapon.EmitWeaponSound_1p3p( TURRET_BARREL_SPIN_LOOP_1P, TURRET_BARREL_SPIN_LOOP_3P )

	#endif
}

void function OnWeaponStartZoomOut_weapon_mobile_hmg( entity weapon )
{
	entity weaponOwner = weapon.GetWeaponOwner()

	weapon.StopWeaponSound( TURRET_BARREL_SPIN_LOOP_1P )
	weapon.StopWeaponSound( TURRET_BARREL_SPIN_LOOP_3P )
	weapon.StopWeaponSound( TURRET_BUTTON_PRESS_SOUND_1P )
	weapon.StopWeaponSound( TURRET_BUTTON_PRESS_SOUND_3P )

	StopSoundOnEntity( weapon, TURRET_WINDUP_AMPED_1P )
	StopSoundOnEntity( weapon, TURRET_WINDUP_AMPED_3P )
	StopSoundOnEntity( weapon, TURRET_WINDUP_1P )
	StopSoundOnEntity( weapon, TURRET_WINDUP_3P )

	if ( !IsValid( weaponOwner ) && weapon.IsWeaponInAds())
		return

	SetTurretVMLaserEnabled( weapon, false )

	if( IsAmped( weapon ) )
	    weapon.EmitWeaponSound_1p3p( TURRET_WINDDOWN_AMPED_1P, TURRET_WINDDOWN_AMPED_3P )
    else weapon.EmitWeaponSound_1p3p( TURRET_WINDDOWN_1P, TURRET_WINDDOWN_3P )
}

void function OnWeaponReload_weapon_mobile_hmg( entity weapon, int milestoneIndex )
{
	//#if SERVER
	//entity owner = weapon.GetOwner()
//
	//thread function () : (owner, weapon)
	//{
	//	printl("Weapon is Reloading 3")
	//	StatusEffect_AddEndless( owner, eStatusEffect.frozencontrols, 999 )
	//	while( !weapon.IsReadyToFire() )
	//		WaitFrame()
//
	//	printl("Weapon is Reloading 4")
	//	StatusEffect_StopAllOfType( owner, eStatusEffect.frozencontrols)
//
	//}()
//
	//#endif
}

void function OnWeaponZoomFOVToggle_weapon_mobile_hmg( entity weapon, float targetFOV )
{
	SetTurretVMLaserEnabled( weapon, false )

	#if CLIENT
	if ( weapon.GetOwner() != GetLocalViewPlayer() )
		return

	if ( targetFOV == weapon.GetWeaponSettingFloat( eWeaponVar.zoom_fov ) )
	{
		EmitSoundOnEntity( weapon, TURRET_SIGHT_FLIP_DOWN_1P )
		StopSoundOnEntity( weapon, TURRET_SIGHT_FLIP_UP_1P )
	}
	else
	{
		EmitSoundOnEntity( weapon, TURRET_SIGHT_FLIP_UP_1P )
		StopSoundOnEntity( weapon, TURRET_SIGHT_FLIP_DOWN_1P )
	}
	#endif
}

void function SetTurretVMLaserEnabled( entity weapon, bool enabled )
{
	entity weaponOwner = weapon.GetWeaponOwner()

	if ( enabled )
	{
		SetTurretVMLaserEnabled( weapon, false )

		#if SERVER
        if( IsServerLaserEnabled( weaponOwner ) )
		    return

		int fxid = GetParticleSystemIndex( TURRET_LASER_1P )
		if( IsAmped( weapon ) )
			fxid = GetParticleSystemIndex( TURRET_LASER_AMPED_1P )

		entity fx = StartParticleEffectOnEntity_ReturnEntity( weapon, fxid , FX_PATTACH_POINT_FOLLOW, weapon.LookupAttachment( "LASER" ) )
		fx.SetOwner( weaponOwner )
		SetServerLaser( fx , weaponOwner )

		#elseif CLIENT
		if ( file.IsClientLaserEnabled )
		    return

		if( IsAmped( weapon ) )
		{
			weapon.PlayWeaponEffect( TURRET_LASER_AMPED_1P, $"", "LASER")
			weapon.PlayWeaponEffect( TURRET_AMPED_FX_1P, $"", "muzzle_flash")

			weapon.PlayWeaponEffect( TURRET_AMPED_FX_1P, $"", "MENU_ROTATE")
			weapon.PlayWeaponEffect( TURRET_AMPED_FX_UI_1P, $"", "ADS_CENTER_SIGHT_RAMPART_TURRET" )

		} else weapon.PlayWeaponEffect( TURRET_LASER_1P, $"", "LASER")

		file.IsClientLaserEnabled = true
		#endif
	}
	else
	{

        #if SERVER
        if( IsServerLaserEnabled( weaponOwner ) )
		{
           array<entity> laserz = GetServerLasers( weaponOwner );

		   foreach(laser in laserz)
		        laser.Destroy()
		}

		#elseif CLIENT
		if ( !file.IsClientLaserEnabled )
		    return
			file.IsClientLaserEnabled = false
		#endif

		weapon.StopWeaponEffect( TURRET_AMPED_FX_UI_1P, $"" )
		weapon.StopWeaponEffect( TURRET_AMPED_FX_1P, $"" )
		weapon.StopWeaponEffect( TURRET_LASER_AMPED_1P, $"" )
		weapon.StopWeaponEffect( TURRET_LASER_1P, $"" )
	}
}

void function OnAnimEvent_weapon_mobile_hmg( entity weapon, string eventName )
{
	if(weapon.GetOwner().GetZoomFrac() >= 1)
	   return

	switch ( eventName )
	{
		case "rampart_turret_mobile_button_press":
			weapon.EmitWeaponSound_1p3p( TURRET_BUTTON_PRESS_SOUND_1P, TURRET_BUTTON_PRESS_SOUND_3P )
			break
		case "rampart_turret_mobile_spin_up":
			weapon.EmitWeaponSound_1p3p( TURRET_BARREL_SPIN_LOOP_1P, TURRET_BARREL_SPIN_LOOP_3P )
			break
		case "rampart_turret_mobile_laser_on":
			SetTurretVMLaserEnabled( weapon, true )
			break
		default:
			return
	}
}

#if CLIENT
void function OnClientAnimEvent_weapon_mobile_hmg( entity weapon, string eventName )
{
	GlobalClientEventHandler( weapon, eventName )

	OnAnimEvent_weapon_mobile_hmg( weapon, eventName )
}
#endif