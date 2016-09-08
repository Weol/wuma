
local wuma = xlib.makepanel{ parent=xgui.null, x=-5, y=6, w=600, h=368 }
xgui.addModule("WUMA", wuma, "icon16/keyboard.png")

local function initialize()
	if WUMA and WUMA.Loaded then 
		WUMA.GUI.Initialize(wuma)
		return 
	end
	timer.Simple(1,initialize)
end
initialize() 