global function MpWeaponEditor_Init
global function OnWeaponAttemptOffhandSwitch_weapon_editor
global function OnWeaponActivate_weapon_editor
global function OnWeaponDeactivate_weapon_editor
global function OnWeaponOwnerChanged_weapon_editor
global function OnWeaponPrimaryAttack_weapon_editor
global function ServerCallback_SwitchProp

#if CLIENT
global function ClientCommand_UP
global function ClientCommand_DOWN
#endif

struct PropSaveInfo
{
    PropInfo& prop
    vector origin
    vector angles
}

PropInfo function NewPropInfo(asset model, vector originDisplacement)
{
    PropInfo prop
    prop.model = model
    prop.originDisplacement = originDisplacement
    return prop
}

struct
{
	array<var> inputHintRuis
    array<PropInfo> propInfoList
    float offsetZ = 0

} file


void function MpWeaponEditor_Init()
{
    // save and load functions
    // AddClientCommandCallback("model", ClientCommand_Model)
    // AddClientCommandCallback("compile", ClientCommand_Compile)
    // AddClientCommandCallback("load", ClientCommand_Load)
    // AddClientCommandCallback("spawnpoint", ClientCommand_Spawnpoint)

    // in-editor functions
    #if CLIENT
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP )
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN )
    #endif
    // AddClientCommandCallback("rotate", ClientCommand_Rotate)
    // AddClientCommandCallback("undo", ClientCommand_Undo)

    file.propInfoList.append(NewPropInfo($"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <0, 0, 0>))
    file.propInfoList.append(NewPropInfo($"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <128, 0, 0>))
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


void function OnWeaponActivate_weapon_editor( entity weapon )
{
    entity owner = weapon.GetOwner()

    #if CLIENT
    if(owner != GetLocalClientPlayer()) return;
    #endif

    AddInputHint( "%attack%", "Place Prop" )
    AddInputHint( "%zoom%", "Switch Prop")

    #if SERVER
    AddButtonPressedPlayerInputCallback( owner, IN_ZOOM, ServerCallback_SwitchProp )
    #endif
    if(owner.p.selectedProp.model == $"")
    {
        owner.p.selectedProp = file.propInfoList[0]
    }
        
    
    StartNewPropPlacement(owner)
}

void function OnWeaponDeactivate_weapon_editor( entity weapon )
{
    RemoveAllHints()
    #if CLIENT
    if(weapon.GetOwner() != GetLocalClientPlayer()) return;
    #endif
    #if SERVER
    RemoveButtonPressedPlayerInputCallback( weapon.GetOwner(), IN_ZOOM, ServerCallback_SwitchProp )
    #endif
    if(IsValid(GetProp(weapon.GetOwner())))
    {
        GetProp(weapon.GetOwner()).Destroy()
    }
    
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
    SetProp(player, CreatePropDynamic(file.playerPreferedBuilds[player], <0, 0, file.offsetZ>, <0, 0, 0>, SOLID_VPHYSICS ))
    GetProp(player).NotSolid()
    GetProp(player).Hide()
    
    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
	SetProp(player, CreateClientSidePropDynamic( <0, 0, file.offsetZ>, <0, 0, 0>, file.playerPreferedBuilds[player] ))
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
        origin.z = floor((origin.z / gridSize) * gridSize) + offsetZ
        
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



// CODE FROM THE OTHER VERSION OF THE MODEL TOOL
// Most of this was written by Pebbers (@Vysteria on Github)

#if CLIENT
bool function ClientCommand_UP(entity player)
{
    file.offsetZ += 64
    printl("moving up " + file.offsetZ)
    return true
}

bool function ClientCommand_DOWN(entity player)
{
    file.offsetZ -= 64
    printl("moving down " + file.offsetZ)
    return true
}
#endif


bool function ClientCommand_Model(entity player, array<string> args) {
// 	if (args.len() < 1) {
// 		return false
// 	}

// 	try {
// 		string modelName = args[0]
// 	    file.buildProp = CastStringToAsset(modelName)
// 		file.currentModelName = modelName
//   } catch (error) {
// 		printl(error)
// 	}
	return true
}


bool function ClientCommand_Compile(entity player, array<string> args) {
    //printl("SERIALIZED: " + serialize())
    return true
}

bool function ClientCommand_Load(entity player, array<string> args) {
    // if (args.len() == 0) {
    //     printl("USAGE: load \"<serialized code>\"")
    //     return false
    // }

    // string serializedCode = args[0]
    // file.entityModifications = deserialize(serializedCode, true)
    return true
}

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

/*
string function serialize() {
    // Model Serializer
    
    string serialized = ""
    
    int index = 0
    bool isNext = file.spawnPoints.len() != 0
    foreach (modelSerialized in file.modifications) {
        serialized += "m:" + modelSerialized
        if (isNext || index != (file.modifications.len() - 1)) {
            serialized += "|"
        }
        index++
    }
    index = 0
    foreach(position in file.spawnPoints) {
        vector origin = position.origin 
        vector angles = position.angles

        string oSer = origin.x + "," + origin.y + "," + origin.z
        string aSer = angles.x + "," + angles.y + "," + angles.z
        serialized += "s:" + oSer + ";" + aSer

        if (index != (file.spawnPoints.len() - 1)) {
            serialized += "|"
        }
        index++
    }

    printl("Serialization: " + serialized)
    
    return serialized
}

array<entity> function deserialize(string serialized, bool dummies) {
    array<string> sections = split(serialized, "|")
    array<entity> entities = []

    int index = 0
    foreach(section in sections) {
        index++

        bool isModelSection = section.find("m:") != -1
        bool isPositionSection = section.find("s:") != -1
        
        if (isModelSection) {
            string payload = StringReplace(section, "m:", "")

            array<string> payloadSections = split(payload, ";")

            if (payloadSections.len() < 3) {
                printl("Problem with loading model: Less than 3 payloadSections ")
                foreach(psec in payloadSections) {
                    printl(psec)
                }
                continue
            }

            string modelName = payloadSections[0]
            vector origin = deserializeVector(payloadSections[1], "origin")
            vector angles = deserializeVector(payloadSections[2], "angles")
            
            entities.append(CreateFRProp(CastStringToAsset(modelName), origin, angles))
            printl("Loading model: " + modelName + " at " + origin + " with angle " + angles)
        } else if (isPositionSection) { 
            string payload = StringReplace(section, "s:", "")

            array<string> payloadSections = split(payload, ";")

            if (payloadSections.len() < 2) {
                printl("Problem with loading model: Less than 2 payloadSections ")
                foreach(psec in payloadSections) {
                    printl(psec)
                }
                continue
            }

            vector origin = deserializeVector(payloadSections[0], "origin")
            vector angles = deserializeVector(payloadSections[1], "angles")
            
            if (dummies) {
                entities.append(SpawnDummyAtPosition(origin, angles))
            }
            printl("Loading player position at " + origin + " with angle " + angles)
        } else {
            printl("Problem with section number " + index.tostring())
        }
    } 
    return entities
}
*/


vector function deserializeVector(string serialized, string type) {
    array<string> axis = split(serialized, ",")

    try {
        float x = axis[0].tofloat()
        float y = axis[1].tofloat()
        float z = axis[2].tofloat()
        return <x, y, z>
    } catch(error) {
        printl("Failed to serialize vector " + type + " " + serialized)
        printl(error)
        return <0, 0, 0>
    }
}

/*
void function SpawnDummyAtPlayer(entity player) {
    entity dummy = CreateDummy(99, player.GetOrigin(), player.GetAngles())
    DispatchSpawn( dummy )
	
    dummy.SetSkin(RandomInt(6))
    
    array<string> weapons = ["mp_weapon_vinson", "mp_weapon_mastiff", "mp_weapon_energy_shotgun", "mp_weapon_lstar"]
    string randomWeapon = weapons[RandomInt(weapons.len())]
    dummy.GiveWeapon(randomWeapon, WEAPON_INVENTORY_SLOT_ANY)
    file.entityModifications.append(dummy)
}

void function SpawnDummyAtPosition(vector origin, vector angles) {
    entity dummy = CreateDummy(99, origin, angles)
    DispatchSpawn( dummy )
	
    dummy.SetSkin(RandomInt(6))
    
    array<string> weapons = ["mp_weapon_vinson", "mp_weapon_mastiff", "mp_weapon_energy_shotgun", "mp_weapon_lstar"]
    string randomWeapon = weapons[RandomInt(weapons.len())]
    dummy.GiveWeapon(randomWeapon, WEAPON_INVENTORY_SLOT_ANY)
}
*/

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