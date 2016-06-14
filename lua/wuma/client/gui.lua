
if SERVER then return end

WUMA = WUMA or {}
WUMA.GUI = {}
WUMA.GUI.Tabs = {}
WUMA.GUI.Tab = false
local WGUI = WUMA.GUI

function WUMA.GUI.Initialize(panel)
	WGUI.Tab = panel

	--Paint function
	WGUI.Tab.Paint = function()
		draw.RoundedBox(3, 0 , 0, WGUI.Tab:GetWide(), WGUI.Tab:GetTall(), {r=234, g=234, b=234, a=255})
	end
	
	--Create propertysheet
	WGUI.Base = WUMA.CreatePropertySheet{x=-5,y=7,w=WGUI.Tab:GetWide(),h=WGUI.Tab:GetTall()-7,parent=WGUI.Tab}
	
	--Request panels
	WGUI.Tabs.Restrictions = vgui.Create("WUMA_Restrictions", WGUI.Base) --Restriction
	WGUI.Tabs.Limitss = vgui.Create("WUMA_Limits", WGUI.Base) --Limit
	WGUI.Tabs.Loadoutss = vgui.Create("WUMA_Loadouts", WGUI.Base) --Loadout
	WGUI.Tabs.Users = vgui.Create("WUMA_Users", WGUI.Base) --Player

	--Adding panels to base
	WGUI.Base:AddSheet(WGUI.Tabs.Restrictions:GetTabName(), WGUI.Tabs.Restrictions, WGUI.Tabs.Restrictions:GetTabIcon()) --Restriction
	WGUI.Base:AddSheet(WGUI.Tabs.Limits:GetTabName(), WGUI.Tabs.Limits, WGUI.Tabs.Limits:GetTabIcon()) --Limit
	WGUI.Base:AddSheet(WGUI.Tabs.Loadouts:GetTabName(), WGUI.Tabs.Loadouts, WGUI.Tabs.Loadouts:GetTabIcon()) --Loadout
	WGUI.Base:AddSheet(WGUI.Tabs.Users:GetTabName(), WGUI.Tabs.Users, WGUI.Tabs.Users:GetTabIcon()) --Player
	
end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
	text - Button text
	icon - Button icon
	onclick - DoClick function
--]]
function WUMA.CreateButton(tbl) 
	
	local gui = vgui.Create("DButton", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetText(tbl.text or "")
	
	if tbl.icon then gui:SetImage(tbl.icon) end
	if tbl.fill then gui:Dock(FILL) end
	
	if gui.onclick then
		gui.DoClick = gui.onclick
	end
	
	return gui
	
end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
	text - Header text
	multiselect - Enable multiselect?
	header_height - Header height
	onrowselected = OnRowSelected function
--]]
function WUMA.CreateList(tbl) 

	local gui = vgui.Create("DListView", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetText(tbl.text)
	gui:SetMultiSelect(tbl.multiselect)
	gui:SetHeaderHeight(tbl.header_height or 20)
	
	if tbl.fill then gui:Dock(FILL) end
	
	if tbl.onrowselected then gui.OnRowSelected = tbl.onrowselected end
	
	return gui
	
end
 
 --[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
--]]
function WUMA.CreatePropertySheet(tbl) 

	local gui = vgui.Create("DPropertySheet", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)

	if tbl.fill then gui:Dock(FILL) end
	
	return gui
	
end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
	text - Label text
	text_color - Text color
--]]
function WUMA.CreateLabel(tbl) 

	local gui = vgui.Create("DLabel", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetText(tbl.text)
	
	if tbl.text_color then gui:SetTextColor(tbl.text_color) end
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
--]]
function WUMA.CreateSlider(tbl) 

	local gui = vgui.Create("DSlider", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	text - Checkbox text
	checked - 1/0
	checkedFunc - Function, return 1/0
--]]
function WUMA.CreateCheckbox(tbl) 

	local gui = vgui.Create("DSlider", tbl.parent)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetText(tbl.text or "")

	if tbl.checked then gui:SetValue(tbl.checked) end
	if tbl.checkedFunc then gui:SetValue(tbl.checkedFunc()) end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
--]]
function WUMA.CreatePanel(tbl) 

	local gui = vgui.Create("DPanel", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
	title - Frame title
--]]
function WUMA.CreateFrame(tbl) 

	local gui = vgui.Create("DFrame", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetTitle(tbl.title or "")
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	minimum_width, minimum_height - Minimum size
	fill - Should fill?
	text_color - Text color
	text_changed - OnTextChanged function
	default - Default text
--]]
function WUMA.CreateTextbox(tbl) 

	local gui = vgui.Create("DTextEntry", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetTextColor(tbl.text_color or Color(0,0,0))
	
	if tbl.fill then gui:Dock(FILL) end
	
	if tbl.text_changed then
		gui.OnTextChanged = tbl.text_changed
	end
	
	if tbl.default then
		
		gui.default = tbl.default
		color = Color(150,150,150)
		default_color = tbl.text_color or Color(0,0,0)
		
		gui.OnLoseFocus = function()
			local text = gui:GetValue()
			if (not text) or (text == "") then
				gui:SetText(gui.default)
				gui:SetTextColor(color)
			end
			
			gui:UpdateConvarValue()
			hook.Call("OnTextEntryLoseFocus", nil, gui)
		end

		gui.OnGetFocus = function()
			local text = gui:GetValue()
			if (text == default) then
				gui:SetText("")
				gui:SetTextColor(default_color)
			else
				gui:SetTextColor(default_color)
				gui:SelectAll()
			end
			hook.Run("OnTextEntryGetFocus", gui)
		end
		
	end
	
	return gui

end