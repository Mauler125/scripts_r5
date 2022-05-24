"scripts/resource/ui/menus/R5R/panels/home.res"
{
	"DarkenBackground"
	{
		"ControlName"			"Label"
		"xpos"					"550"
		"ypos"					"0"
		"zpos"					"0"
		"wide"					"1350"
		"tall"					"935"
		"labelText"				""
		"bgcolor_override"		"0 0 0 150"
		"visible"				"1"
		"paintbackground"		"1"
	}

	Map0
	{
		ControlName			RuiButton
		InheritProperties	LoadoutButtonLarge
        rui					"ui/map_button_large.rpak"
		xpos			0
		ypos			0
		wide			128
		tall			128
		visible			1
		scaleImage		1
		tabPosition		1
		drawColor		"255 255 255 255"

		zpos			1

		"pin_to_sibling"		"DarkenBackground"
		"pin_corner_to_sibling"	"TOP_LEFT"
		"pin_to_sibling_corner"	"TOP_LEFT"
	}
}

