global function EditorModeDelete_Init


struct {
    array<PropInfo> propInfoList
    float offsetZ = 0
	array<var> inputHintRuis	

    // not using player.p.xxx because I already did this using these variables and I am not rewriting everything.
    #if SERVER
    table<entity, float> snapSizes
    table<entity, float> pitches
    table<entity, float> offsets
    #elseif CLIENT
    float snapSize = 64
    float pitch = 0
    #endif
} file



EditorMode function EditorModeDelete_Init() 
{
    // INIT FOR WEAPON

    EditorMode mode

    mode.displayName = "Delete"
    mode.crosshairActive = true
    
    mode.onActivationCallback = EditorModeDelete_Activation
    mode.onDeactivationCallback = EditorModeDelete_Deactivation
    mode.onAttackCallback = EditorModeDelete_Delete

    return mode
}

void function EditorModeDelete_Activation(entity player)
{
    AddInputHint( "%attack%", "Delete Prop" )
}

void function EditorModeDelete_Deactivation(entity player)
{
    RemoveAllHints()
}

void function EditorModeDelete_Delete(entity player)
{
    DeleteProp(player)
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


void function DeleteProp(entity player)
{
    #if SERVER
    TraceResults result = TraceLine(player.EyePosition() + 5 * player.GetViewForward(), player.GetOrigin() + 1500 * player.GetViewForward(), [player], TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER)
    if (IsValid(result.hitEnt))
    {
        if (GetPlacedProps().contains(result.hitEnt))
        {
            GetPlacedProps().removebyvalue(result.hitEnt)
            result.hitEnt.Destroy()
        }
    }
    #endif
}

