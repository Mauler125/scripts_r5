#if SERVER
global function CodeCallback_MapInit
#endif //SERVER

#if SERVER
void function CodeCallback_MapInit()
{
	SharedInit()
	Desertlands_MapInit_Common()
}
#endif //SERVER

#if CLIENT
void function ClientCodeCallback_MapInit()
{
	SharedInit()
}
#endif //CLIENT

void function SharedInit()
{
	ShPrecacheShadowSquadAssets()
	ShPrecacheEvacShipAssets()
	ShLootCreeps_Init()
}

#if SERVER
void function OnDeathFieldStopShrink_ShadowSquad( DeathFieldStageData deathFieldData )
{
	LootCreepGarbageCollect()
}
#endif //SERVER