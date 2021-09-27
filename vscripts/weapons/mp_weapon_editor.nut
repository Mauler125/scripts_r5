global function MpWeaponEditor_Init
global function OnWeaponAttemptOffhandSwitch_weapon_editor
global function OnWeaponActivate_weapon_editor
global function OnWeaponDeactivate_weapon_editor
global function OnWeaponOwnerChanged_weapon_editor
global function OnWeaponPrimaryAttack_weapon_editor

#if SERVER
global function ClientCommand_Compile

global function ClientCommand_UP_Server
global function ClientCommand_DOWN_Server
#elseif CLIENT
global function ClientCommand_UP_Client
global function ClientCommand_DOWN_Client
#endif

struct PropSaveInfo
{
    PropInfo& prop
    vector origin
    vector angles
}


struct
{

    // store the props here for saving and loading
    array<entity> allProps
    array<EditorMode> editorModes

} file


void function MpWeaponEditor_Init()
{
    // save and load functions
    #if SERVER
    // AddClientCommandCallback("model", ClientCommand_Model)
    AddClientCommandCallback("compile", ClientCommand_Compile)
    // AddClientCommandCallback("load", ClientCommand_Load)
    // AddClientCommandCallback("spawnpoint", ClientCommand_Spawnpoint)
    #endif

    // in-editor functions
    #if CLIENT
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP_Client )
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN_Client )
    #elseif SERVER
    AddClientCommandCallback("moveUp", ClientCommand_UP_Server )
    AddClientCommandCallback("moveDown", ClientCommand_DOWN_Server )
    #endif


    // AddClientCommandCallback("rotate", ClientCommand_Rotate)
    // AddClientCommandCallback("undo", ClientCommand_Undo)


    file.editorModes.append(EditorModePlace_Init())
}


void function OnWeaponActivate_weapon_editor( entity weapon )
{
    #if CLIENT
    if (weapon.GetOwner() != GetLocalClientPlayer()) return
    entity player = GetLocalClientPlayer()
    #elseif SERVER
    entity player = weapon.GetOwner()
    #endif

    player.p.selectedEditorMode = file.editorModes[0]
    player.p.selectedEditorMode.onActivationCallback(player)
}

void function OnWeaponDeactivate_weapon_editor( entity weapon )
{
    #if CLIENT
    if (weapon.GetOwner() != GetLocalClientPlayer()) return
    entity player = GetLocalClientPlayer()
    #elseif SERVER
    entity player = weapon.GetOwner()
    #endif

    player.p.selectedEditorMode = file.editorModes[0]
    player.p.selectedEditorMode.onDeactivationCallback(player)
}

var function OnWeaponPrimaryAttack_weapon_editor( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    #if CLIENT
    if (weapon.GetOwner() != GetLocalClientPlayer()) return
    entity player = GetLocalClientPlayer()
    #elseif SERVER
    entity player = weapon.GetOwner()
    #endif

    player.p.selectedEditorMode = file.editorModes[0]
    player.p.selectedEditorMode.onAttackCallback(player)
}

void function OnWeaponOwnerChanged_weapon_editor( entity weapon, WeaponOwnerChangedParams changeParams )
{
	
}

bool function OnWeaponAttemptOffhandSwitch_weapon_editor( entity weapon )
{
    int ammoReq  = weapon.GetAmmoPerShot()
    int currAmmo = weapon.GetWeaponPrimaryClipCount()

    return true //currAmmo >= ammoReq
}





// CODE FROM THE OTHER VERSION OF THE MODEL TOOL
// Most of this was written by Pebbers (@Vysteria on Github)

#if SERVER
bool function ClientCommand_UP_Server(entity player, array<string> args)
{
    file.offsetZ += 64
    printl("moving up " + file.offsetZ)
    return true
}

bool function ClientCommand_DOWN_Server(entity player, array<string> args)
{
    file.offsetZ -= 64
    printl("moving down " + file.offsetZ)
    return true
}

#elseif CLIENT
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

#if SERVER
bool function ClientCommand_Compile(entity player, array<string> args) {
    printl("SERIALIZED: " + serialize())
    return true
}
#endif

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


string function serialize() {
    // Model Serializer
    
    string serialized = ""
    
    int index = 0
    bool isNext = false // file.spawnPoints.len() != 0
    foreach (model in file.allProps) {
        string origin = serializeVector(model.GetOrigin())
        string angles = serializeVector(model.GetAngles())
        string name = model.GetModelName()

        serialized += "m:" + name + ";" + origin + ";" + angles
        if (isNext || index != (file.allProps.len() - 1)) {
            serialized += "|"
        }
        index++
    }
    index = 0
    // foreach(position in file.spawnPoints) {
    //     vector origin = position.origin 
    //     vector angles = position.angles

    //     string oSer = origin.x + "," + origin.y + "," + origin.z
    //     string aSer = angles.x + "," + angles.y + "," + angles.z
    //     serialized += "s:" + oSer + ";" + aSer

    //     if (index != (file.spawnPoints.len() - 1)) {
    //         serialized += "|"
    //     }
    //     index++
    // }

    printl("Serialization: " + serialized)
    
    return serialized
}

/*
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

string function serializeVector(vector vec) {
    return vec.x + "," + vec.y + "," + vec.z
}

/*
void function SpawnDummyAtPlayer(entity player) {
    SpawnDummyAtPosition(player.GetOrigin(), player.GetAngles())
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