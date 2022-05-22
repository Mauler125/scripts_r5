scripts/resource/ui/menus/R5R/panels/createserver.res
{
	"DarkenBackground"
	{
		ControlName				Label
		xpos					0
		ypos					0
		wide					%100
		tall					%100
		labelText				""
		bgcolor_override		"0 0 0 0"
		visible					1
		paintbackground			1
	}

	"R5Reloaded"
	{
		ControlName				Label
		xpos                    -150
		ypos					-20
		zpos					3
		auto_wide_tocontents	1
		tall					40
		visible					1
		fontHeight				50
		labelText				"Create Server"
		font					DefaultBold_41
		allcaps					1
		fgcolor_override		"255 255 255 255"

		pin_to_sibling			DarkenBackground
		pin_corner_to_sibling	TOP_LEFT
		pin_to_sibling_corner	TOP_LEFT
	}

    "CreateServerBackground"
	{
        "ControlName"			"ImagePanel"
		"wide"					"f0"
		"tall"					"f0"
		"visible"				"1"
        "scaleImage"			"1"
		"zpos"					"0"
        "fillColor"				"30 30 30 200"
        "drawColor"				"30 30 30 200"

		"pin_to_sibling"		"DarkenBackground"
		"pin_corner_to_sibling"	"TOP"
		"pin_to_sibling_corner"	"TOP"
	}
}

