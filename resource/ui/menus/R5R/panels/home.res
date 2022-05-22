scripts/resource/ui/menus/R5R/panels/home.res
{
	"DarkenBackground"
	{
		"ControlName"			"Label"
		"xpos"					"0"
		"ypos"					"0"
		"zpos"					"0"
		"wide"					"%100"
		"tall"					"%100"
		"labelText"				""
		"bgcolor_override"		"0 0 0 0"
		"visible"				"1"
		"paintbackground"		"1"
	}

    "HomeBackground"
	{
        "ControlName"			"ImagePanel"
		"wide"					"f0"
		"tall"					"f0"
		"visible"				"1"
        "scaleImage"			"1"
		"zpos"					"0"
        "fillColor"				"30 30 30 0"
        "drawColor"				"30 30 30 0"

		"pin_to_sibling"		"DarkenBackground"
		"pin_corner_to_sibling"	"TOP"
		"pin_to_sibling_corner"	"TOP"
	}

	"HomeBackground"
	{
        "ControlName"			"ImagePanel"
		"wide"					"500"
		"tall"					"870"
		"visible"				"1"
        "scaleImage"			"1"
		"xpos"					"-45"
		"ypos"					"-20"
		"zpos"					"0"
        "fillColor"				"30 30 30 200"
        "drawColor"				"30 30 30 200"

		"pin_to_sibling"		"DarkenBackground"
		"pin_corner_to_sibling"	"TOP_LEFT"
		"pin_to_sibling_corner"	"TOP_LEFT"
	}

	R5RPicBox
	{
		ControlName				RuiPanel
		wide					500
		tall					275
		rui                     "ui/basic_image.rpak"
		visible					1
		scaleImage				1

		pin_to_sibling			HomeBackground
		pin_corner_to_sibling	TOP
		pin_to_sibling_corner	TOP
	}

	"Welcome"
	{
        ControlName				Label
		xpos                    -25
		ypos					20
		auto_wide_tocontents	1
		tall					40
		visible					1
		fontHeight				30
		labelText				"Welcome to R5Reloaded!"
		font					DefaultBold_41
		allcaps					0
		fgcolor_override		"255 100 100 255"

		pin_to_sibling			R5RPicBox
		pin_corner_to_sibling	TOP_LEFT
		pin_to_sibling_corner	BOTTOM_LEFT
	}

	"Test"
	{
        ControlName				Label
		xpos                    0
		ypos					20
		wide					450
		tall					400
		visible					1
		wrap					1
		fontHeight				25
		textAlignment			"north-west"
		labelText				"Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
		font					DefaultBold_41
		allcaps					0
		fgcolor_override		"200 200 200 255"

		pin_to_sibling			Welcome
		pin_corner_to_sibling	TOP_LEFT
		pin_to_sibling_corner	BOTTOM_LEFT
	}
}

