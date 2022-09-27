global function ShInit_ArenaComposite
global function CodeCallback_MapInit

void function CodeCallback_MapInit()
{
	PrecacheModel( $"mdl/rocks/rock_white_chalk_modular_wallrun_03.rmdl" )
	//thread CustomMapLoad()
}

void function ShInit_ArenaComposite()
{
	SetVictorySequencePlatformModel( $"mdl/dev/empty_model.rmdl", < 0, 0, -10 >, < 0, 0, 0 > )
	#if CLIENT
	  SetVictorySequenceLocation(<1374, -4060, 418>, <0, 201.828598, 0> )
	#endif
}

