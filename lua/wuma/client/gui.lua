
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
	WGUI.Tabs.Restriction = vgui.Create("WUMA_Restriction", WGUI.Base) --Restriction
	WGUI.Tabs.Limit = vgui.Create("WUMA_Restriction", WGUI.Base) --Limit
	WGUI.Tabs.Loadout = vgui.Create("WUMA_Restriction", WGUI.Base) --Loadout
	WGUI.Tabs.Player = vgui.Create("WUMA_Restriction", WGUI.Base) --Player

	--Adding panels to base
	WGUI.Base:AddSheet(WGUI.Tabs.Restriction:GetTabName(), WGUI.Tabs.Restriction, WGUI.Tabs.Restriction:GetTabIcon()) --Restriction
	WGUI.Base:AddSheet(WGUI.Tabs.Limit:GetTabName(), WGUI.Tabs.Limit, WGUI.Tabs.Limit:GetTabIcon()) --Limit
	WGUI.Base:AddSheet(WGUI.Tabs.Loadout:GetTabName(), WGUI.Tabs.Loadout, WGUI.Tabs.Loadout:GetTabIcon()) --Loadout
	WGUI.Base:AddSheet(WGUI.Tabs.Player:GetTabName(), WGUI.Tabs.Player, WGUI.Tabs.Player:GetTabIcon()) --Player
	
end

function WUMA.CreateButton(tbl) 
	
	local gui = vgui.Create("DButton", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetText(tbl.text or "")
	
	if tbl.fill then gui:Dock(FILL) end
	
	if gui.onclick then
		gui.DoClick = gui.onclick
	end
	
	return gui
	
end

function WUMA.CreateList(tbl) 

	local gui = vgui.Create("DListView", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetText(tbl.text)
	gui:SetMultiSelect(tbl.multiselect)
	gui:SetHeaderHeight(tbl.header_height or 20)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui
	
end
 
function WUMA.CreatePropertySheet(tbl) 

	local gui = vgui.Create("DPropertySheet", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)

	if tbl.fill then gui:Dock(FILL) end
	
	return gui
	
end

function WUMA.CreateLabel(tbl) 

	local gui = vgui.Create("DLabel", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	gui:SetText(tbl.text)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

function WUMA.CreateSlider(tbl) 

	local gui = vgui.Create("DSlider", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

function WUMA.CreatePanel(tbl) 

	local gui = vgui.Create("DPanel", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

function WUMA.CreateFrame(tbl) 

	local gui = vgui.Create("DFrame", tbl.parent)
	gui:SetSize(tbl.w or 60, tbl.h or 20)
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	if tbl.fill then gui:Dock(FILL) end
	
	return gui

end

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