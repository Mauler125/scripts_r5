global function OnWeaponActivate_DEVMODELFINDER
global function OnWeaponDeactivate_DEVMODELFINDER
global function OnWeaponPrimaryAttack_DEVMODELFINDER

//--------------------------------------------------
// R101 DEV MODEL FINDER
//--------------------------------------------------

void function OnWeaponActivate_DEVMODELFINDER( entity weapon )
{
	OnWeaponActivate_weapon_basic_bolt( weapon )

	OnWeaponActivate_RUIColorSchemeOverrides( weapon )
	OnWeaponActivate_ReactiveKillEffects( weapon )
}

void function OnWeaponDeactivate_DEVMODELFINDER( entity weapon )
{
	OnWeaponDeactivate_ReactiveKillEffects( weapon )
}

var function OnWeaponPrimaryAttack_DEVMODELFINDER( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    #if CLIENT || UI
        print("Weapon Dev Model Finder")
        
        entity player = GetLocalClientPlayer();
        vector eyePosition = player.EyePosition()
        vector viewVector = player.GetViewVector()
        TraceResults traceResults = TraceLineHighDetail( eyePosition, eyePosition + viewVector * 10000, player, TRACE_MASK_PLAYERSOLID | TRACE_MASK_TITANSOLID | TRACE_MASK_NPCWORLDSTATIC, TRACE_COLLISION_GROUP_PLAYER )
        if( traceResults.hitEnt )
        {
            AddPlayerHint( 2.0, 0.25, $"", "Model name: " + traceResults.hitEnt.GetModelName())
            printt( "TraceResults: " )
            printt( "=========================" )
            printt( "Model: "+traceResults.hitEnt.GetModelName() )
            printt( "hitEnt: " + traceResults.hitEnt )
            printt( "endPos: " + traceResults.endPos )
            printt( "surfaceNormal: " + traceResults.surfaceNormal )
            printt( "surfaceName: " + traceResults.surfaceName )
            printt( "fraction: " + traceResults.fraction )
            printt( "fractionLeftSolid: " + traceResults.fractionLeftSolid )
            printt( "hitGroup: " + traceResults.hitGroup )
            printt( "startSolid: " + traceResults.startSolid )
            printt( "allSolid: " + traceResults.allSolid )
            printt( "hitSky: " + traceResults.hitSky )
            printt( "contents: " + traceResults.contents )
            printt( "TargetName: "+traceResults.hitEnt.GetTargetName() )
            printt( "ScriptsName: "+traceResults.hitEnt.GetScriptName() )
            printt( "=========================" )
        }
    #endif

	if ( weapon.HasMod( "altfire_highcal" ) )
		thread PlayDelayedShellEject( weapon, RandomFloatRange( 0.03, 0.04 ) )

	weapon.FireWeapon_Default( attackParams.pos, attackParams.dir, 1.0, 1.0, false )

	return weapon.GetWeaponSettingInt( eWeaponVar.ammo_per_shot )
}
