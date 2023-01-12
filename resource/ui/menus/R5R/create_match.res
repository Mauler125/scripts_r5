resource/ui/menus/dialog_gamemode_select_v2.menu
{
	menu
	{
		ControlName				Frame
		xpos					0
		ypos					0
		zpos					3
		wide					f0
		tall					f0
		autoResize				0
		pinCorner				0
		visible					1
		enabled					1
		tabPosition				1
		PaintBackgroundType		0
		infocus_bgcolor_override	"0 0 0 0"
		outoffocus_bgcolor_override	"0 0 0 0"
		modal					1

		ScreenBlur
		{
			ControlName				Label
            labelText               ""
		}

        ScreenFrame
        {
            ControlName				RuiPanel
            xpos					0
            ypos					0
            wide					%100
            tall					%100
            visible					1
            enabled 				1
            scaleImage				1
            rui                     "ui/screen_blur.rpak"
            drawColor				"255 255 255 255"
        }

        "MainButtonsFrame"
		{
            "ControlName"				"ImagePanel"
			"wide"						"f0"
			"tall"						"83"
			"visible"					"1"
            "scaleImage"				"1"
			"zpos"						"0"
            "fillColor"					"30 30 30 200"
            "drawColor"					"30 30 30 200"

			"pin_to_sibling"			"ScreenFrame"
			"pin_corner_to_sibling"		"TOP"
			"pin_to_sibling_corner"		"TOP"
		}

		"GamemodesBtn"
        {
			"ControlName"				"RuiButton"
			"InheritProperties"			"TabButtonSettings"
			"classname" 				"TopButtons"
			"zpos"						"3"
            "xpos"                      "-100"

			ruiArgs
			{
				isSelected 0
				buttonText "Quick Play"
			}

			"pin_to_sibling"			"MainButtonsFrame"
			"pin_corner_to_sibling"		"CENTER"
			"pin_to_sibling_corner"		"CENTER"
		}

        "PrivateMatchBtn"
        {
			"ControlName"				"RuiButton"
			"InheritProperties"			"TabButtonSettings"
			"classname" 				"TopButtons"
			"zpos"						"3"
            "xpos"                      "-80"

			ruiArgs
			{
				isSelected 1
				buttonText "Private Match"
			}

			"pin_to_sibling"			"GamemodesBtn"
			"pin_corner_to_sibling"		"LEFT"
			"pin_to_sibling_corner"		"RIGHT"
		}

        Cover
        {
            ControlName				ImagePanel
            xpos					0
            ypos					0
            wide                    %200
            tall					%200
            visible					1
            enabled 				1
            scaleImage				1
            image					"vgui/HUD/white"
            drawColor				"0 0 0 200"

            pin_to_sibling			ScreenFrame
            pin_corner_to_sibling	CENTER
            pin_to_sibling_corner	CENTER
        }

        FooterButtons
		{
			ControlName				CNestedPanel
			InheritProperties       FooterButtons
		}
	}
}
