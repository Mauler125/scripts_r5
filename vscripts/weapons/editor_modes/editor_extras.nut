// Copied from _jump_pads. This is being hacked for the gravity lifts.
#if SERVER
// init functions:
global function GravityLift_Init
global function GravityLift_Trigger

// set constants:
const asset GRAVITY_LIFT_FX = $"P_ar_loot_drop_point"

const float JUMP_PAD_PUSH_RADIUS = 45.0
const float JUMP_PAD_PUSH_PROJECTILE_RADIUS = 64
const float JUMP_PAD_PUSH_VELOCITY = 950.0
const float JUMP_PAD_VIEW_PUNCH_SOFT = 25.0
const float JUMP_PAD_VIEW_PUNCH_HARD = 4.0
const float JUMP_PAD_VIEW_PUNCH_RAND = 4.0
const TEAM_JUMPJET_DBL = $"P_team_jump_jet_ON_trails"
const ENEMY_JUMPJET_DBL = $"P_enemy_jump_jet_ON_trails"
const asset JUMP_PAD_MODEL = $"mdl/props/octane_jump_pad/octane_jump_pad.rmdl"

const float JUMP_PAD_ANGLE_LIMIT = 0.70
const float JUMP_PAD_ICON_HEIGHT_OFFSET = 48.0
const float JUMP_PAD_ACTIVATION_TIME = 0.5
const asset JUMP_PAD_LAUNCH_FX = $"P_grndpnd_launch"
#endif

///////////////
// Gravity lift code, adapted from jump pads and geyser
//////////////
#if SERVER
void function GravityLift_Init()
{
    // need lift particles here
    PrecacheParticleSystem( GRAVITY_LIFT_FX )
    
    array<entity> gravLiftTargets = GetEntArrayByScriptName( "geyser_jump" ) // ???
	foreach ( target in gravLiftTargets )
	{
		thread GravityLift_Trigger( target )
		//target.Destroy()
	}
}

void function GravityLift_Trigger( entity jumpPad )
{
    // Todo: give the player more control in the air
    vector origin = OriginToGround( jumpPad.GetOrigin() )
	vector angles = jumpPad.GetAngles()

    entity gravLiftBeam = StartParticleEffectInWorld_ReturnEntity(GetParticleSystemIndex( GRAVITY_LIFT_FX ), origin, angles )

	entity trigger = CreateEntity( "trigger_cylinder_heavy" )
	SetTargetName( trigger, "gravlift_trigger" )

	trigger.SetOwner( jumpPad )
	trigger.SetRadius( JUMP_PAD_PUSH_RADIUS )
	trigger.SetAboveHeight( 32 )
	trigger.SetBelowHeight( 16 ) //need this because the player or jump pad can sink into the ground a tiny bit and we check player feet not half height
	trigger.SetOrigin( origin )
	trigger.SetAngles( angles )
	trigger.SetTriggerType( TT_JUMP_PAD )
	trigger.SetLaunchScaleValues( JUMP_PAD_PUSH_VELOCITY, 1.25 )
	trigger.SetViewPunchValues( JUMP_PAD_VIEW_PUNCH_SOFT, JUMP_PAD_VIEW_PUNCH_HARD, JUMP_PAD_VIEW_PUNCH_RAND )
	trigger.SetLaunchDir( <0.0, 0.0, 1.0> )
	trigger.UsePointCollision()
	trigger.kv.triggerFilterNonCharacter = "0"
	DispatchSpawn( trigger )
	trigger.SetEnterCallback( GravityLift_OnJumpPadAreaEnter )
    
    trigger.SetParent( jumpPad )
}



void function GravityLift_OnJumpPadAreaEnter( entity trigger, entity ent )
{
	GravityLift_JumpPadPushEnt( trigger, ent, trigger.GetOrigin(), trigger.GetAngles() )
}

void function GravityLift_JumpPadPushEnt( entity trigger, entity ent, vector origin, vector angles )
{

    if ( ent.IsPlayer() )
    {
        entity jumpPad = trigger.GetOwner()
        if ( IsValid( jumpPad ) )
        {
            int fxId = GetParticleSystemIndex( JUMP_PAD_LAUNCH_FX )
            StartParticleEffectOnEntity( jumpPad, fxId, FX_PATTACH_ABSORIGIN_FOLLOW, 0 )
        }
    }
    else
    {
        EmitSoundOnEntity( ent, "JumpPad_LaunchPlayer_3p" )
        EmitSoundOnEntity( ent, "JumpPad_AirborneMvmt_3p" )
    }
	
}
#endif
