global function OnWeaponTossReleaseAnimEvent_weapon_jump_pad
global function OnWeaponAttemptOffhandSwitch_weapon_jump_pad
global function OnWeaponTossPrep_weapon_jump_pad

const float JUMP_PAD_ANGLE_LIMIT = 0.70

bool function OnWeaponAttemptOffhandSwitch_weapon_jump_pad( entity weapon )
{
	int ammoReq = weapon.GetAmmoPerShot()
	int currAmmo = weapon.GetWeaponPrimaryClipCount()
	if ( currAmmo < ammoReq )
		return false

	entity player = weapon.GetWeaponOwner()
	if ( player.IsPhaseShifted() )
		return false

	return true
}

var function OnWeaponTossReleaseAnimEvent_weapon_jump_pad( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	int ammoReq = weapon.GetAmmoPerShot()
	weapon.EmitWeaponSound_1p3p( GetGrenadeThrowSound_1p( weapon ), GetGrenadeThrowSound_3p( weapon ) )

	entity deployable = ThrowDeployable( weapon, attackParams, 1.0, OnJumpPadPlanted )
	if ( deployable )
	{
		entity player = weapon.GetWeaponOwner()
		PlayerUsedOffhand( player, weapon, true, deployable )

		#if(false)








#endif

		#if(false)

#endif

	}

	return ammoReq
}

void function OnWeaponTossPrep_weapon_jump_pad( entity weapon, WeaponTossPrepParams prepParams )
{
	weapon.EmitWeaponSound_1p3p( GetGrenadeDeploySound_1p( weapon ), GetGrenadeDeploySound_3p( weapon ) )
}

void function OnJumpPadPlanted( entity projectile )
{
	#if(false)





















//










//
//


#endif
}