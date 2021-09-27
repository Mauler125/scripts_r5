global function EditorModePlace_Init

global function ServerCallback_SwitchProp

struct {
    array<PropInfo> propInfoList
    float offsetZ = 0
	array<var> inputHintRuis
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

    // END FILE INIT

    return mode
}

void function EditorModePlace_Activation(entity player)
{

    AddInputHint( "%attack%", "Place Prop" )
    AddInputHint( "%zoom%", "Switch Prop")

    #if SERVER
    AddButtonPressedPlayerInputCallback( player, IN_ZOOM, ServerCallback_SwitchProp )
    
    #endif
    if(player.p.selectedProp.model == $"")
    {
        player.p.selectedProp = file.propInfoList[0]
    }
        
    
    StartNewPropPlacement(player)
}

void function EditorModePlace_Deactivation(entity player)
{
    #if CLIENT
    if(player != GetLocalClientPlayer()) return;
    #endif

    RemoveAllHints()
    #if SERVER
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
    #if SERVER
    SetProp(player, CreatePropDynamic( player.p.selectedProp.model, <0, 0, file.offsetZ>, <0, 0, 0>, SOLID_VPHYSICS ))
    GetProp(player).NotSolid()
    GetProp(player).Hide()
    
    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
	SetProp(player, CreateClientSidePropDynamic( <0, 0, file.offsetZ>, <0, 0, 0>, player.p.selectedProp.model ))
    DeployableModelWarningHighlight( GetProp(player) )
    
	GetProp(player).kv.renderamt = 255
	GetProp(player).kv.rendermode = 3
	GetProp(player).kv.rendercolor = "255 255 255 150"
    #endif

    #if SERVER
    thread PlaceProxyThink(player)
    #elseif CLIENT
    thread PlaceProxyThink(GetLocalClientPlayer())
    #endif
}

void function PlaceProp(entity player)
{
    //file.allProps.append(GetProp(player))
    #if SERVER
    GetProp(player).Show()
    GetProp(player).Solid()
    printl("------------------------ Server offset: " + file.offsetZ)
    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
    GetProp(player).Destroy()
    SetProp(player, null)
    printl("------------------------ Client offset: " + file.offsetZ)
    #endif
}

void function PlaceProxyThink(entity player)
{
    float gridSize = 256

    while( IsValid( GetProp(player) ) )
    {
        if(!IsValid( player )) return
        if(!IsAlive( player )) return

        GetProp(player).SetModel( player.p.selectedProp.model )

	    TraceResults result = TraceLine(player.EyePosition() + 5 * player.GetViewForward(), player.GetOrigin() + 200 * player.GetViewForward(), [player], TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER)

        vector origin = result.endPos
        origin.x = floor(origin.x / gridSize) * gridSize
        origin.y = floor(origin.y / gridSize) * gridSize
        origin.z = floor((origin.z / gridSize) * gridSize) + file.offsetZ
        
        vector offset = player.GetViewForward()
        
        // convert offset to -1 if value it's less than -0.5, 0 if it's between -0.5 and 0.5, and 1 if it's greater than 0.5

        vector ang = VectorToAngles(player.GetViewForward())
        ang.x = 0
        ang.y = floor(clamp(ang.y + 45, -360, 360) / 90) * 90
        ang.z = floor(clamp(ang.z + 45, -360, 360) / 90) * 90

        offset = RotateVector(player.p.selectedProp.originDisplacement, ang)
        // offset.x = offset.x * player.p.selectedProp.originDisplacement.x
        // offset.y = offset.y * player.p.selectedProp.originDisplacement.y
        // offset.z = offset.z * player.p.selectedProp.originDisplacement.z

        origin = origin + offset
        

        vector angles = VectorToAngles( -1 * player.GetViewVector() )
        angles.x = GetProp(player).GetAngles().x
        angles.y = floor(clamp(angles.y - 45, -360, 360) / 90) * 90

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
