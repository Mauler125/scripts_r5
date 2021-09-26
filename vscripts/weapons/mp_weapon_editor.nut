global function MpWeaponEditor_Init
global function OnWeaponAttemptOffhandSwitch_weapon_editor
global function OnWeaponActivate_weapon_editor
global function OnWeaponDeactivate_weapon_editor
global function OnWeaponOwnerChanged_weapon_editor
global function OnWeaponPrimaryAttack_weapon_editor
global function ServerCallback_SwitchProp

struct
{
	array<var> inputHintRuis
    #if SERVER
    table<entity, entity> playerProps
    #elseif CLIENT
    entity buildProp
    #endif
    table<entity, asset> playerPreferedBuilds
} file


void function MpWeaponEditor_Init()
{

}

entity function GetProp(entity player)
{
    #if SERVER
    return file.playerProps[player]
    #elseif CLIENT
    return file.buildProp
    #endif
    return null
}

void function SetProp(entity player, entity prop)
{
    #if SERVER
    file.playerProps[player] = prop
    #elseif CLIENT
    file.buildProp = prop
    #endif
}


void function OnWeaponActivate_weapon_editor( entity weapon )
{
    entity owner = weapon.GetOwner()

    AddInputHint( "%attack%", "Place Prop" )
    AddInputHint( "%zoom%", "Switch Prop")

    #if SERVER
    AddButtonPressedPlayerInputCallback( owner, IN_DUCK, ServerCallback_SwitchProp )
    if( !(owner in file.playerProps) )
    {
        file.playerProps[owner] <- null
    }
    #endif
    file.playerPreferedBuilds[owner] <- $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl"
    
    StartNewPropPlacement(owner)
}

void function OnWeaponDeactivate_weapon_editor( entity weapon )
{
    RemoveAllHints()
    #if SERVER
    RemoveButtonPressedPlayerInputCallback( weapon.GetOwner(), IN_DUCK, ServerCallback_SwitchProp )
    #endif
    GetProp(weapon.GetOwner()).Destroy()
}

void function ServerCallback_SwitchProp( entity player )
{
    #if CLIENT
    player = GetLocalClientPlayer()
    #endif

    if(!IsValid( player )) return
    if(!IsAlive( player )) return

    if(file.playerPreferedBuilds[player] == $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl")
    {
        file.playerPreferedBuilds[player] = $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl"
    }
    else
    {
        file.playerPreferedBuilds[player] = $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl"
    }

    GetProp(player).SetModel(file.playerPreferedBuilds[player])
    #if SERVER
    Remote_CallFunction_Replay( player, "ServerCallback_SwitchProp", player )
    #endif
}

void function StartNewPropPlacement(entity player)
{
    #if SERVER
    SetProp(player, CreatePropDynamic(file.playerPreferedBuilds[player], <0, 0, 0>, <0, 0, 0>, SOLID_VPHYSICS ))
    GetProp(player).NotSolid()
    GetProp(player).Hide()
    
    #elseif CLIENT
	SetProp(player, CreateClientSidePropDynamic( <0, 0, 0>, <0, 0, 0>, file.playerPreferedBuilds[player] ))
    DeployableModelHighlight( GetProp(player) )
    #endif

    #if SERVER
    thread PlaceProxyThink(player)
    #elseif CLIENT
    thread PlaceProxyThink(GetLocalClientPlayer())
    #endif
}

void function PlaceProp(entity player)
{
    #if SERVER
    GetProp(player).Show()
    GetProp(player).Solid()
    #elseif CLIENT
    GetProp(player).Destroy()
    SetProp(player, null)
    #endif
}

void function PlaceProxyThink(entity player)
{
    float gridSize = 64

    while( IsValid( GetProp(player) ) )
    {
        if(!IsValid( player )) return
        if(!IsAlive( player )) return

	    TraceResults result = TraceLine(player.EyePosition() + 5 * player.GetViewForward(), player.GetOrigin() + 200 * player.GetViewForward(), [player], TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER)

        vector origin = result.endPos
        origin.x = floor(origin.x / gridSize) * gridSize
        origin.y = floor(origin.y / gridSize) * gridSize
        origin.z = floor(origin.z / gridSize) * gridSize

        vector angles = VectorToAngles( -1 * player.GetViewVector() )
        angles.x = GetProp(player).GetAngles().x
        angles.y = floor(angles.y / 90) * 90

        GetProp(player).SetOrigin( origin )
        GetProp(player).SetAngles( angles )

        WaitFrame()
    }
}



bool function OnWeaponAttemptOffhandSwitch_weapon_editor( entity weapon )
{
    int ammoReq  = weapon.GetAmmoPerShot()
    int currAmmo = weapon.GetWeaponPrimaryClipCount()

    return true //currAmmo >= ammoReq
}

var function OnWeaponPrimaryAttack_weapon_editor( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    PlaceProp(weapon.GetOwner())
    StartNewPropPlacement(weapon.GetOwner())
}

void function OnWeaponOwnerChanged_weapon_editor( entity weapon, WeaponOwnerChangedParams changeParams )
{
	
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