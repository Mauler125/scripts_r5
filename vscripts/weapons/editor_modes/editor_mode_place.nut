global function EditorModePlace_Init

global function ServerCallback_SwitchProp
#if SERVER
global function ClientCommand_Model
global function ClientCommand_Spawnpoint

global function ClientCommand_UP_Server
global function ClientCommand_DOWN_Server
#elseif CLIENT
global function ClientCommand_UP_Client
global function ClientCommand_DOWN_Client
#endif

// Copied from _jump_pads. This is being hacked for the gravity lifts.
#if SERVER
// init functions:
global function GravityLift_Init
global function GravityLift_Trigger

// set constants:
const asset GRAVITY_LIFT_FX = $"P_ar_loot_drop_point"

const float JUMP_PAD_PUSH_RADIUS = 64
const float JUMP_PAD_PUSH_PROJECTILE_RADIUS = 32.0//98.0
const float JUMP_PAD_PUSH_VELOCITY = 950.0      // maybe can change this in-editor?
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

struct {
    array<PropInfo> propInfoList
    float offsetZ = 0
	array<var> inputHintRuis	

    #if SERVER
    table<entity, float> snapSizes
    table<entity, float> pitches
    table<entity, float> offsets
    #elseif CLIENT
    float snapSize = 64
    float pitch = 0
    #endif
} file
EditorMode function EditorModePlace_Init() 
{
    // INIT FOR WEAPON

    EditorMode mode

    mode.displayName = "Place"
    
    mode.onActivationCallback = EditorModePlace_Activation
    mode.onDeactivationCallback = EditorModePlace_Deactivation
    mode.onAttackCallback = EditorModePlace_Place

    // END INIT FOR WEAPON

    // FILE LEVEL INIT

    file.propInfoList.append(NewPropInfo($"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <0, 0, 0>))
    file.propInfoList.append(NewPropInfo($"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <128, 0, 0>))
    file.propInfoList.append(NewPropInfo($"mdl/Humans/class/medium/combat_dummie_medium.rmdl", <0, 0, 0>))


    
    // save and load functions
    #if SERVER
    AddClientCommandCallback("model", ClientCommand_Model)
    AddClientCommandCallback("compile", ClientCommand_Compile)
    AddClientCommandCallback("load", ClientCommand_Load)
    AddClientCommandCallback("spawnpoint", ClientCommand_Spawnpoint)
    #endif

    // in-editor functions
    #if SERVER
    AddClientCommandCallback("moveUp", ClientCommand_UP_Server )
    AddClientCommandCallback("moveDown", ClientCommand_DOWN_Server )
    AddClientCommandCallback( "ChangeSnapSize", ChangeSnapSize)
    AddClientCommandCallback( "ChangeRotation", ChangeRotation)
    #endif


    // AddClientCommandCallback("rotate", ClientCommand_Rotate)
    // AddClientCommandCallback("undo", ClientCommand_Undo)

    // END FILE INIT

    return mode
}

void function EditorModePlace_Activation(entity player)
{
    AddInputHint( "%attack%", "Place Prop" )
    AddInputHint( "%zoom%", "Switch Prop")
    AddInputHint( "%scriptCommand1%", "Change Snap Size" )
    AddInputHint( "%scriptCommand6%", "Change Rotation" )
    AddInputHint( "%weaponSelectPrimary0%", "Raise" )
    AddInputHint( "%weaponSelectPrimary1%", "Lower" )

    #if CLIENT
    
    RegisterConCommandTriggeredCallback( "+scriptCommand1", SwapToNextSnapSize )
    RegisterConCommandTriggeredCallback( "+scriptCommand6", SwapToNextPitch )
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP_Client )
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN_Client )

    #elseif SERVER
    AddButtonPressedPlayerInputCallback( player, IN_ZOOM, ServerCallback_SwitchProp )
    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- 64
    }
    if( !(player in file.pitches) )
    {
        file.pitches[player] <- 0
    }
    if( !(player in file.offsets) )
    {
        file.offsets[player] <- 0
    }
    #endif

    if(player.p.selectedProp.model == $"")
    {
        player.p.selectedProp = file.propInfoList[0]
    }
    
    StartNewPropPlacement(player)
}

void function EditorModePlace_Deactivation(entity player)
{
    RemoveAllHints()
    #if CLIENT
    // deregister here so no errors. 
    // we're also deregistering so we don't change the z offset while we are doing something else e.g. playtesting.
    // should also use +scriptCommands. Seriously.
    DeregisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP_Client )
    DeregisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN_Client )
    DeregisterConCommandTriggeredCallback( "+scriptCommand1", SwapToNextSnapSize )
    DeregisterConCommandTriggeredCallback( "+scriptCommand6", SwapToNextPitch )
    #elseif SERVER
    RemoveButtonPressedPlayerInputCallback( player, IN_ZOOM, ServerCallback_SwitchProp )
    #endif
    if(IsValid(GetProp(player)))
    {
        GetProp(player).Destroy()
    }
}

void function EditorModePlace_Place(entity player)
{
    PlaceProp(player)
    StartNewPropPlacement(player)
}



void function RemoveAllHints()
{
    #if CLIENT
    foreach( rui in file.inputHintRuis )
    {
        RuiDestroy( rui )
    }
    file.inputHintRuis.clear()
    #endif
}

void function AddInputHint( string buttonText, string hintText)
{

    #if CLIENT
    var hintRui = CreateFullscreenRui( $"ui/tutorial_hint_line.rpak" )

	RuiSetString( hintRui, "buttonText", buttonText )
	// RuiSetString( hintRui, "gamepadButtonText", gamePadButtonText )
	RuiSetString( hintRui, "hintText", hintText )
	// RuiSetString( hintRui, "altHintText", altHintText )
	RuiSetInt( hintRui, "hintOffset", file.inputHintRuis.len() )
	// RuiSetBool( hintRui, "hideWithMenus", false )

    file.inputHintRuis.append( hintRui )

    #endif
}

void function ServerCallback_SwitchProp( entity player )
{
    #if CLIENT
    if(player != GetLocalClientPlayer()) return;
    player = GetLocalClientPlayer()
    #endif

    if(!IsValid( player )) return
    if(!IsAlive( player )) return

    player.p.selectedProp = file.propInfoList[(file.propInfoList.find(player.p.selectedProp) + 1) % file.propInfoList.len()] // increment to next prop info in list
    printl(player.p.selectedProp.model)
    #if SERVER
    Remote_CallFunction_Replay( player, "ServerCallback_SwitchProp", player )
    #endif
}


void function StartNewPropPlacement(entity player)
{
    // incoming
    #if SERVER
    SetProp(player, CreatePropDynamic( player.p.selectedProp.model, <0, 0, file.offsets[player]>, <0, 0, 0>, SOLID_VPHYSICS ))
    GetProp(player).NotSolid()
    GetProp(player).Hide()
    
    #elseif CLIENT
	SetProp(player, CreateClientSidePropDynamic( <0, 0, file.offsetZ>, <0, 0, 0>, player.p.selectedProp.model ))
    DeployableModelWarningHighlight( GetProp(player) )
    
	GetProp(player).kv.renderamt = 255
	GetProp(player).kv.rendermode = 3
	GetProp(player).kv.rendercolor = "255 255 255 150"

    #endif

    thread PlaceProxyThink(player)


    
}

void function PlaceProp(entity player)
{
    #if SERVER
    GetProp(player).SetScriptName("editor_placed_prop")
    GetProp(player).Show()
    GetProp(player).Solid()

    // prints prop info to the console to save it
    vector myOrigin = GetProp(player).GetOrigin()
    vector myAngles = GetProp(player).GetAngles()

    string positionSerialized = myOrigin.x.tostring() + "," + myOrigin.y.tostring() + "," + myOrigin.z.tostring()
	string anglesSerialized = myAngles.x.tostring() + "," + myAngles.y.tostring() + "," + myAngles.z.tostring()
    printl("[editor]" + player.p.selectedProp.model + ";" + positionSerialized + ";" + anglesSerialized)

    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
    GetProp(player).Destroy()
    SetProp(player, null)
    #endif
}

void function PlaceProxyThink(entity player)
{
    float gridSize = 256

    while( IsValid( GetProp(player) ) )
    {
        #if CLIENT
        gridSize = file.snapSize
        #elseif SERVER
        gridSize = file.snapSizes[player]
        #endif
        if(!IsValid( player )) return
        if(!IsAlive( player )) return

        GetProp(player).SetModel( player.p.selectedProp.model )

	    TraceResults result = TraceLine(player.EyePosition() + 5 * player.GetViewForward(), player.GetOrigin() + 200 * player.GetViewForward(), [player], TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER)

        vector origin = result.endPos

        origin.x = RoundToNearestInt(origin.x / gridSize) * gridSize
        origin.y = RoundToNearestInt(origin.y / gridSize) * gridSize
        origin.z = (RoundToNearestInt(origin.z / gridSize) * gridSize)
        #if CLIENT
        origin.z += file.offsetZ
        #elseif SERVER
        origin.z += file.offsets[player]
        #endif
        
        vector offset = player.GetViewForward()
        
        // convert offset to -1 if value it's less than -0.5, 0 if it's between -0.5 and 0.5, and 1 if it's greater than 0.5

        vector ang = VectorToAngles(player.GetViewForward())

        float functionref(float val, float x, float y) smartClamp = float function(float val, float x, float y)
        {
            // clamp val circularly between x and y, which can be negative
            if(val < x)
            {
                return val + (y - x)
            }
            else if(val > y)
            {
                return val - (y - x)
            }
            return val
        }

        ang.x = 0
        ang.y = floor(smartClamp(ang.y + 45, -360, 360) / 90) * 90
        ang.z = floor(smartClamp(ang.z + 45, -360, 360) / 90) * 90

        offset = RotateVector(player.p.selectedProp.originDisplacement, ang)

        origin = origin + offset
        

        vector angles = VectorToAngles( -1 * player.GetViewVector() )
        angles.x = GetProp(player).GetAngles().x
        angles.y = floor(smartClamp(angles.y - 45, -360, 360) / 90) * 90
        #if CLIENT
        angles.z += file.pitch
        #elseif SERVER
        angles.z += file.pitches[player]
        #endif

        GetProp(player).SetOrigin( origin )
        GetProp(player).SetAngles( angles )

        wait 0.1
    }
}

entity function GetProp(entity player)
{
    #if SERVER || CLIENT
    return player.p.currentPropEntity
    #endif
    return null
}

void function SetProp(entity player, entity prop)
{
    #if SERVER || CLIENT
    player.p.currentPropEntity = prop
    #endif
    return null
}

PropInfo function NewPropInfo(asset model, vector originDisplacement)
{
    PropInfo prop
    prop.model = model
    prop.originDisplacement = originDisplacement
    return prop
}

#if SERVER
bool function ClientCommand_UP_Server(entity player, array<string> args)
{
    file.offsets[player] += 64
    printl("moving up " + file.offsets[player])
    return true
}

bool function ClientCommand_DOWN_Server(entity player, array<string> args)
{
    file.offsets[player] -= 64
    printl("moving down " + file.offsets[player])
    return true
}
bool function ChangeSnapSize( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- args[0].tofloat()
    }
    file.snapSizes[player] = args[0].tofloat()

    return true
}

bool function ChangeRotation( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    printl(args[0].tofloat())
    if( !(player in file.pitches) )
    {
        file.pitches[player] <- args[0].tofloat()
    }
    file.pitches[player] = args[0].tofloat()

    return true
}
#elseif CLIENT
void function SwapToNextSnapSize(entity player)
{
    if (player != GetLocalClientPlayer()) return;
    switch (file.snapSize)
    {
        case 64:
            file.snapSize = 128
            player.ClientCommand( "ChangeSnapSize 128" )
            break;
        case 128:
            file.snapSize = 256
            player.ClientCommand( "ChangeSnapSize 256" )
            break;
        case 256:
            file.snapSize = 4
            player.ClientCommand( "ChangeSnapSize 4" )
            break;
        default:
            file.snapSize = 64
            player.ClientCommand( "ChangeSnapSize 64" )
            break;
    }
}
void function SwapToNextPitch(entity player)
{
    if (player != GetLocalClientPlayer()) return;
    switch (file.pitch)
    {
        case 0:
            file.pitch = 30
            player.ClientCommand( "ChangeRotation 30" )
            break;
        case 30:
            file.pitch = 35
            player.ClientCommand( "ChangeRotation 35" )
            break;
        case 35:
            file.pitch = 45
            player.ClientCommand( "ChangeRotation 45" )
            break;
        case 45:
        default:
            file.pitch = 0
            player.ClientCommand( "ChangeRotation 0" )
            break;
    }
}
bool function ClientCommand_UP_Client(entity player)
{
    GetLocalClientPlayer().ClientCommand("moveUp")
    file.offsetZ += 64
    return true
}

bool function ClientCommand_DOWN_Client(entity player)
{
    GetLocalClientPlayer().ClientCommand("moveDown")
    file.offsetZ -= 64
    return true
}
#endif

bool function ClientCommand_Model(entity player, array<string> args) {
    /* 	
    if (args.len() < 1) {
		return false
 	}

 	try {
 		string modelName = args[0]
 	    file.buildProp = CastStringToAsset(modelName)
 		file.currentModelName = modelName
    } catch (error) {
 		printl(error)
 	}
    */
	return true
}

bool function ClientCommand_Rotate(entity player, array<string> args) {
    return true
}

bool function ClientCommand_Undo(entity player, array<string> args) {
    return true
}

// deleted createFRProp

asset function CastStringToAsset( string val ) {
	return GetKeyValueAsAsset( {kn = val}, "kn")
}

// Snaps a number to the nearest size
int function snapTo( float f, int size ) {
    return ((f / size).tointeger()) * size
}

// Snaps a vector to the grid of size
vector function snapVec( vector vec, int size  ) {
    int x = snapTo(vec.x, size)
    int y = snapTo(vec.y, size)
    int z = snapTo(vec.z, size)

    return <x,y,z>
}



TraceResults function PlayerLookingAtRes(entity player) {
    vector angles = player.EyeAngles()
	vector forward = AnglesToForward( angles )
	vector origin = player.EyePosition()

	vector start = origin
	vector end = origin + forward * 50000
	TraceResults result = TraceLine( start, end )

	return result
}

vector function PlayerLookingAtVec(entity player) {
    vector angles = player.EyeAngles()
	vector forward = AnglesToForward( angles )
	vector origin = player.EyePosition()

	vector start = origin
	vector end = origin + forward * 50000
	TraceResults result = TraceLine( start, end )

	return result.endPos
}

#if SERVER
bool function ClientCommand_Spawnpoint(entity player, array<string> args) {
    // if (file.currentEditor != null) {
    //     vector origin = player.GetOrigin()
    //     vector angles = player.GetAngles()

    //     LocPair pair = NewLocPair(origin, angles)
    //     file.spawnPoints.append(pair)
    //     printl("Successfully added position " + origin + " " + angles)
    //     SpawnDummyAtPlayer(player)
    // } else {
    //     printl("You must be in editor mode")
    //     return false
    // }
    return true
}
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
// maybe also Geyser_JumpJetsWhileAirborne