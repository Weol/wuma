
WUMA = WUMA or {}
WUMA.GUI = {}
WUMA.GUI.Tabs = {}
local WGUI = WUMA.GUI

if not WUMA.HasCreatedFonts then
	surface.CreateFont("WUMATextSmall", {
		font = "Arial",
		size = 10,
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true
	})
end

WUMA.HasCreatedFonts = true

function WUMA.GUI.Initialize(panel)

	WGUI.Tab = panel
	
	WUMA.RequestFromServer(WUMA.NET.RESTRICTION:GetID())
	WUMA.RequestFromServer(WUMA.NET.LIMIT:GetID())
	WUMA.RequestFromServer(WUMA.NET.LOADOUT:GetID())
	
	WUMA.RequestFromServer(WUMA.NET.USERS:GetID())
	WUMA.RequestFromServer(WUMA.NET.GROUPS:GetID())
	WUMA.RequestFromServer(WUMA.NET.MAPS:GetID())
	WUMA.RequestFromServer(WUMA.NET.LOOKUP:GetID(),200)
	

	--Paint function
	WGUI.Tab.Paint = function()
		draw.RoundedBox(3, 0 , 0, WGUI.Tab:GetWide(), WGUI.Tab:GetTall(), {r=234, g=234, b=234, a=255})
	end
	
	--Create propertysheet
	WGUI.Base = WUMA.CreatePropertySheet{parent=WGUI.Tab,x=-5,y=7,w=WGUI.Tab:GetWide()-3,h=WGUI.Tab:GetTall()-7}
	
	--Request panels
	WGUI.Tabs.Settings = vgui.Create("WUMA_Settings", WGUI.Base) --Settings
	WGUI.Tabs.Restrictions = vgui.Create("WUMA_Restrictions", WGUI.Base) --Restriction
	WGUI.Tabs.Limits = vgui.Create("WUMA_Limits", WGUI.Base) --Limit
	WGUI.Tabs.Loadouts = vgui.Create("WUMA_Loadouts", WGUI.Base) --Loadout
	WGUI.Tabs.Users = vgui.Create("WUMA_Users", WGUI.Base) --Player

	--Adding panels to base
	WGUI.Base:AddSheet(WGUI.Tabs.Settings:GetTabName(), WGUI.Tabs.Settings, WGUI.Tabs.Settings:GetTabIcon()) --Settings
	WGUI.Base:AddSheet(WGUI.Tabs.Restrictions:GetTabName(), WGUI.Tabs.Restrictions, WGUI.Tabs.Restrictions:GetTabIcon()) --Restriction
	WGUI.Base:AddSheet(WGUI.Tabs.Limits:GetTabName(), WGUI.Tabs.Limits, WGUI.Tabs.Limits:GetTabIcon()) --Limit
	WGUI.Base:AddSheet(WGUI.Tabs.Loadouts:GetTabName(), WGUI.Tabs.Loadouts, WGUI.Tabs.Loadouts:GetTabIcon()) --Loadout
	WGUI.Base:AddSheet(WGUI.Tabs.Users:GetTabName(), WGUI.Tabs.Users, WGUI.Tabs.Users:GetTabIcon()) --Player
	
end

local function handleRelative(tbl,gui)

	if tbl.relative then
		tbl.relative_align = tbl.relative_align or 1
		
		local x, y = tbl.relative:GetPos()
		
		if (tbl.relative_align == 1) then
			tbl.x = tbl.x + x
			tbl.y = tbl.y + y
		elseif (tbl.relative_align == 2) then
			tbl.x = tbl.x + x + tbl.relative:GetWide()
			tbl.y = tbl.y + y
		elseif (tbl.relative_align == 3) then
			tbl.x = tbl.x + x
			tbl.y = tbl.y + y + tbl.relative:GetTall()
		elseif (tbl.relative_align == 4) then
			tbl.x = tbl.x + x + tbl.relative:GetWide()
			tbl.y = tbl.y + y + tbl.relative:GetTall()
		end
		
	end	
	
	return tbl

end

local function handleAlign(tbl,gui)

	if tbl.align then
	
		if (tbl.align == 2) and tbl.x and tbl.w then
			tbl.x = tbl.x-tbl.w
			tbl.y = tbl.y
		elseif (tbl.align == 3) and tbl.y and tbl.h then
			tbl.x = tbl.x
			tbl.y = tbl.y-tbl.h
		elseif (tbl.align == 4) and tbl.x and tbl.y and tbl.w and tbl.h then
			tbl.x = tbl.x-tbl.w
			tbl.y = tbl.y-tbl.h
		end
		
	end
	
	return tbl
	
end

local function handlePercent(tbl,gui)

	if not tbl.percent then return end
	if not tbl.parent then return end
	
	if tbl.w then
		tbl.w = tbl.parent:GetWide()/100 * tbl.w
	end
	
	if tbl.h then
		tbl.h = tbl.parent:GetTall()/100 * tbl.h
	end
	
	return tbl

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
	text - Button text
	icon - Button icon
	onclick - DoClick function
--]]
function WUMA.CreateButton(tbl) 
	
	local gui = vgui.Create("DButton", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end
	
	handleAlign(tbl,gui)
	handleRelative(tbl,gui)
	handlePercent(tbl,gui)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui:SetText(tbl.text or "")
	gui:SetContentAlignment(5)
	
	if tbl.icon then gui:SetImage(tbl.icon) end
	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end

	if tbl.onclick then
		gui.DoClick = tbl.onclick
	end

	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui
	
end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	visible - Wether or not to set visibility. Default: true
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
	text - Header text
	multiselect - Enable multiselect? true/false
	header_height - Header height
	onrowselected = OnRowSelected function
	populate = table to populate
--]]
function WUMA.CreateList(tbl) 

	local gui = vgui.Create("DListView", tbl.parent)

	gui.wuma = tbl
	
	if tbl.populate then WUMA.PopulateList(gui,tbl.populate) end

	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
		
	if tbl.size_to_content_y then 
		gui:SetTall( #gui:GetLines() * 17 + gui:GetHeaderHeight() + 5)
	end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui:SetMultiSelect(tbl.multiselect)
	gui:SetHeaderHeight(tbl.header_height or 20)
		
	if not (gui.sortable == nil) then gui:SetSortable(gui.sortable) end
		
	if istable(tbl.text) then
		for _,text in pairs(tbl.text) do
			gui:AddColumn(text)
		end
	else
		gui:AddColumn(tbl.text)
	end
	
	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end

	if tbl.onrowselected then gui.OnRowSelected = tbl.onrowselected end
	
	--[[if tbl.sort then
		local oldAddLine = gui.AddLine
		gui.AddLine = function(...)
			local line = oldAddLine(...)
			local metatable = getmetatable(line)
			
			metatable.__lt = function(obj1, obj2) 
				return tbl.sort.lt(obj1, obj2)
			end
			
			metatable.__eq = function(obj1, obj2) 
				return tbl.sort.eq(obj1, obj2)
			end
			
			metatable.__le = function(obj1, obj2) 
				return tbl.sort.le(obj1, obj2)
			end
		end
	end--]]
	
	return gui
	
end
 
function WUMA.PopulateList(gui,tbl,column,clear)

	if isbool(column) or clear then 
		gui:Clear() 
		column = 1
	end

	column = column or 1

	for k, v in pairs(tbl) do
		if istable(v) then
			gui:AddLine(k,column)
			gui.population = v
		else
			gui:AddLine(v,column)
		end
	end
	
	if gui.wuma.select then
		if isstring(gui.wuma.select) then
			if (#gui:GetLines() > 0) then
				for line, item in pairs(gui:GetLines()) do
					if (item:GetColumnText(1) == gui.wuma.select) then
						gui:SelectItem(gui:GetLines()[line])
					end
				end
			end
		else
			if (#gui:GetLines() > 0) then
				gui:SelectFirstItem()
			end
		end
	end

end
 
 --[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreatePropertySheet(tbl) 

	local gui = vgui.Create("DPropertySheet", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)

	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui
	
end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
	text - Label text
	text_color - Text color
--]]
function WUMA.CreateLabel(tbl) 

	local gui = vgui.Create("DLabel", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui:SetText(tbl.text)
	
	if tbl.text_color then gui:SetTextColor(tbl.text_color) end

	if tbl.relative then
		tbl.relative.relatives = tbl.relative.relatives or {}
		if tbl.relative then table.insert(gui.relative.relatives, gui) end
	end
	
	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	min = Min value
	max = Max value.
	decimals = decimals
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreateSlider(tbl) 

	local gui = vgui.Create("DNumSlider", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	if tbl.min then gui:SetMin( tbl.min ) end
	if tbl.max then gui:SetMax( tbl.max ) end
	if tbl.decimals then gui:SetDecimals( tbl.decimals ) end
		
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui

end


--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreateCombobox(tbl) 

	local gui = vgui.Create("DComboBox", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	if tbl.onselect then gui.OnSelect = tbl.ononselect end
	
	gui:SetValue( tbl.default or "" )
	
	if tbl.options then
		for option,data in pairs(tbl.options) do
			if istable(data) then
				gui:AddChoice(option,data,data.select)
			else
				gui:AddChoice(data)
			end
		end
	end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreatePropertyViewer(tbl) 
	
	local gui = WUMA.CreatePanel(tbl) 
	gui.Paint = function()
		surface.SetDrawColor( 255, 255, 255, 255)
		surface.DrawRect(0,0,gui:GetWide(),gui:GetTall())
		
		surface.SetDrawColor( 0, 0, 0, 255)
		surface.DrawOutlinedRect(0,0,gui:GetWide(),gui:GetTall())
	
		local y = 3
		for k, v in pairs(gui.properties or {}) do
			draw.DrawText( v[1]..":", "DermaDefault", 5, y, Color(0,0,0), TEXT_ALIGN_LEFT )
			y=y+12
			
			if v[2] then 
				draw.DrawText( v[2], "DermaDefault", 10, 2+y, Color(0,0,0), TEXT_ALIGN_LEFT )
				y=y+15
			end
			
			surface.DrawLine(0,y+5,gui:GetWide(),y+5)
			y = y+7
			
		end 
		
		gui:SetTall(y-2);
	end
	
	gui.SetProperties = function(self,properties)
		gui.properties = properties
	end

	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreateMapChooser(tbl) 
	
	local options = tbl.options
	tbl.options = nil

	local gui = WUMA.CreateCombobox(tbl)
	
	gui.AddOptions = function(self,options)
		for _, map in pairs(options) do
			map = string.gsub(map,".bsp","")
			if (map == game.GetMap()) then
				self:AddChoice(map,nil,true)
			else
				self:AddChoice(map)
			end
		end
	end
	gui:AddOptions(options)
	
	gui.GetArgument = function()
		if not gui or not gui:GetSelected() then return nil end
	
		local text, data = gui:GetSelected()

		return text
	end
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	decimals = decimals
	background = background color. Color value
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreateTimeChooser(tbl) 

	local gui = vgui.Create("DPanel", tbl.parent)
	local slider = vgui.Create("DSlider", gui)
	local combobox = vgui.Create("DComboBox", gui)
	local wang = vgui.Create( "DNumberWang", gui )
	
	gui.Paint = function()
		if tbl.background then
			draw.RoundedBox(4,0,0,gui:GetWide(),gui:GetTall(),tbl.background)
		end
	end
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) else gui:SetWide(120) end
	if tbl.h then gui:SetTall(tbl.h) else gui:SetTall(combobox:GetTall()+slider:GetTall()) end
		
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	wang:SetWide(40)
	wang:SetPos(gui:GetWide()-wang:GetWide(),0)
	
	wang.OnValueChanged = function(panel,val)
		val = math.Clamp(tonumber(val),0,combobox:GetOptionData(combobox:GetSelectedID()).max)
		slider:SetSlideX(1/combobox:GetOptionData(combobox:GetSelectedID()).max*val)
	end
	
	slider:SetWide(gui:GetWide())
	slider:SetPos(0,gui:GetTall()-slider:GetTall())
	slider:SetLockY( 0.5 )
	slider:SetTrapInside( true )
	slider:SetHeight( 16 )
	Derma_Hook( slider, "Paint", "Paint", "NumSlider" )
	
	slider.TranslateValues = function(panel,x,y) 
		wang:SetValue(math.Round(combobox:GetOptionData(combobox:GetSelectedID()).max*x))
		return x, y
	end
	
	combobox:SetPos( 0, 0 )
	combobox:SetSize( 60, 20 )
	combobox:SetValue( "kek" )
	
	local options = {
		Minutes = {max=1440,default=30,time=60,select=true},
		Hours = {max=168,default=12,time=60*60},
		Days = {max=365,default=3,time=3600*24},
		Weeks = {max=52,default=2,time=3600*60*24*7},
		Months = {max=60,default=3,time=math.Round(52/12*(3600*60*24*7))},
		Years = {max=5,default=1,time=3600*60*24*365}
	}
	
	combobox.OnSelect = function(panel, index, value, data)
		wang:SetMinMax(1, data.max)
		wang:SetValue(data.default)
		slider:SetSlideX(1/data.max*data.default)
	end
	
	for option,data in pairs(options) do
		combobox:AddChoice(option,data,data.select)
	end
	
	gui.GetArgument = function()
		if not combobox or not combobox:GetSelected() then return nil end
	
		local text, data = combobox:GetSelected()

		return math.Round(data.time*wang:GetValue())
	end
	
	gui.wuma = tbl
	gui.slider = slider
	gui.combobox = combobox
	gui.wang = wang
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	decimals = decimals
	background = background color. Color value
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreatePeriodChooser(tbl) 

	local gui = vgui.Create("DPanel", tbl.parent)
	local from_hour = WUMA.CreateTextbox{parent=gui,default="hh",text_align=5,numeric=true,min_numeric=0,max_numeric=23,x=0,y=9,w=36,h=20}
	local from_minute = WUMA.CreateTextbox{parent=gui,default="mm",text_align=5,numeric=true,min_numeric=0,max_numeric=59,x=38,y=9,w=36,h=20}
	
	local until_hour = WUMA.CreateTextbox{parent=gui,default="hh",text_align=5,numeric=true,min_numeric=0,max_numeric=23,x=0,y=38,w=36,h=20}
	local until_minute = WUMA.CreateTextbox{parent=gui,default="mm",text_align=5,numeric=true,min_numeric=0,max_numeric=59,x=38,y=38,w=36,h=20}
	
	gui.Paint = function()
		if tbl.background then
			draw.RoundedBox(4,0,0,gui:GetWide(),gui:GetTall(),tbl.background)
		end
				
		draw.DrawText("from", "WUMATextSmall", 29, 0, Color(0, 0, 0, 150))
		draw.DrawText("until", "WUMATextSmall", 29, 29, Color(0, 0, 0, 150))
	end
	
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) else gui:SetWide(120) end
	if tbl.h then gui:SetTall(tbl.h) else gui:SetTall(from_hour:GetTall()*2+9*2) end
		
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui.GetArgument = function()
		if (from_hour:GetValue() == "") or (from_minute:GetValue() == "") or (until_hour:GetValue() == "") or (until_minute:GetValue() == "") then return nil end
		
		if (tonumber(from_hour:GetValue()) == nil) or (tonumber(from_minute:GetValue()) == nil) or (tonumber(until_hour:GetValue()) == nil) or (tonumber(until_minute:GetValue()) == nil) then return nil end
		
		return {from = tonumber(from_hour:GetValue())*3600+tonumber(from_minute:GetValue())*60,to = tonumber(until_hour:GetValue())*3600+tonumber(until_minute:GetValue())*60}
	end
	
	gui.wuma = tbl
	gui.from_hour = from_hour
	gui.from_minute = from_minute
	gui.until_hour = until_hour
	gui.until_minute = until_minute
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	decimals = decimals
	background = background color. Color value
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreateDateChooser(tbl) 

	local gui = vgui.Create("DPanel", tbl.parent)
	local day = WUMA.CreateTextbox{parent=gui,default="Day",text_align=5,numeric=true,min_numeric=0,max_numeric=31,x=0,y=9,w=36,h=20}
	local month = WUMA.CreateTextbox{parent=gui,default="Month",text_align=5,numeric=true,min_numeric=0,max_numeric=12,x=38,y=9,w=36,h=20}
	local year = WUMA.CreateTextbox{parent=gui,default="Year",text_align=5,numeric=true,min_numeric=0,max_numeric=3000,x=76,y=9,w=36,h=20}

	gui.Paint = function()
		if tbl.background then
			draw.RoundedBox(4,0,0,gui:GetWide(),gui:GetTall(),tbl.background)
		end
				
		draw.DrawText("day", "WUMATextSmall", 12, 0, Color(0, 0, 0, 150))
		draw.DrawText("month", "WUMATextSmall", 44, 0, Color(0, 0, 0, 150))
		draw.DrawText("year", "WUMATextSmall", 87, 0, Color(0, 0, 0, 150))
	end
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) else gui:SetWide(112) end
	if tbl.h then gui:SetTall(tbl.h) else gui:SetTall(29) end
		
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui.GetArgument = function()
		if (day:GetValue() == "") or (month:GetValue() == "") or (year:GetValue() == "") then return nil end
		
		if (tonumber(day:GetValue()) == nil) or (tonumber(month:GetValue()) == nil) or (tonumber(year:GetValue()) == nil) then return nil end
		
		return {day=tonumber(day:GetValue()),month=tonumber(month:GetValue()),year=tonumber(year:GetValue())}
	end
	
	gui.wuma = tbl
	gui.day = day
	gui.month = month
	gui.year = year
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	text - Checkbox text
	checked - 1/0
	checkedFunc - Function, return 1/0
--]]
function WUMA.CreateCheckbox(tbl) 

	local gui = vgui.Create("DCheckBoxLabel", tbl.parent)

	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)

	gui:SetPos(tbl.x, tbl.y)
	gui:SetSize(tbl.w or 15, tbl.h or 15)
	
	gui:SetText(tbl.text)
	gui:SetTextColor(tbl.text_color or Color(0,0,0))
	
	gui:SizeToContents()

	if tbl.checked then gui:SetValue(tbl.checked) end
	if tbl.checkedFunc then gui:SetValue(tbl.checkedFunc()) end
	
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end

	gui.wuma = tbl
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
--]]
function WUMA.CreatePanel(tbl) 

	local gui = vgui.Create("DPanel", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)

	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align = Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	size_to_content = Wether or not to size gui to content. True / false
	size_to_content_x = Wether or not to size gui x-axis to content. True / false
	size_to_content_y = Wether or not to size gui y-axis to content. True / false
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	fill - Should fill?
	title - Frame title
--]]
function WUMA.CreateFrame(tbl) 

	local gui = vgui.Create("DFrame", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
	
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui:SetTitle(tbl.title or "")
	
	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui

end

--[[ARGUMENTS:
	parent - Parent gui
	x, y, w, h - Bounds
	align - Which corner of the gui that x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	percent - wether or not to treat w & h like percent instead of px. true/false
	relative - The gui element that x and y should be relative to
	relative_align - Which part of the relative gui it should be aligned to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	align - Which corner x & y should apply to. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right
	minimum_width, minimum_height - Minimum size
	animation - Wether to enable automatic animation or not. True/false. Default: true
	numeric - Wether or not textbox should be numeric. True/false. Default: false
	max_numeric = max numeric value, only enabled if numeric == true
	min_numeric = max numeric value, only enabled if numeric == true
	fill - Should fill?
	text_color - Text color
	text_changed - OnChange function
	default - Default text
--]]
function WUMA.CreateTextbox(tbl) 

	local gui = vgui.Create("DTextEntry", tbl.parent)
	
	if tbl.size_to_content then gui:SizeToContents() end
	if tbl.size_to_content_x then gui:SizeToContentsX() end
	if tbl.size_to_content_y then gui:SizeToContentsY() end

	if tbl.fill then gui:Dock(FILL) end
	if (tbl.visible != nil) then gui:SetVisible(tbl.visible) end
		
	handleAlign(tbl)
	handleRelative(tbl)
	handlePercent(tbl)
	
	if tbl.w then gui:SetWide(tbl.w) end
	if tbl.h then gui:SetTall(tbl.h) end
	
	gui:SetPos(tbl.x, tbl.y)
	gui:SetMinimumSize(tbl.minimum_width or 0, tbl.minimum_height or 0)
	
	gui:SetTextColor(tbl.text_color or Color(0,0,0))
	
	if tbl.text_align then
		gui:SetContentAlignment( tbl.text_align )
	end
	
	if tbl.numeric and (tbl.max_numeric or tbl.min_numeric) then
		gui:SetNumeric(tbl.numeric)
		gui.OnChange = function(...)
			gui:SetAllowNonAsciiCharacters(false)
			if (tbl.max_numeric and gui:GetValue() and gui:GetValue() ~= "") then
				if (tonumber(gui:GetValue()) > tonumber(tbl.max_numeric)) then gui:SetText(tostring(tbl.max_numeric)) end
			end
			
			if (tbl.min_numeric and gui:GetValue()  and gui:GetValue() ~= "") then
				if (tonumber(gui:GetValue()) < tonumber(tbl.min_numeric)) then gui:SetText(tostring(tbl.min_numeric)) end
			end
			
			if tbl.text_changed then
				gui.OnChange = tbl.text_changed
			end
		end
	else
		if tbl.text_changed then
			gui.OnChange = tbl.text_changed
		end
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
			if (text == gui.default) then
				gui:SetText("")
				gui:SetTextColor(default_color)
			else
				gui:SetTextColor(default_color)
				gui:SelectAll()
			end
			hook.Run("OnTextEntryGetFocus", gui)
		end
		
		gui:SetText(gui.default)
		gui:SetTextColor(color)
		
	end
	
	gui.wuma = tbl
	gui.wuma.handleRelative = handleRelative
	gui.wuma.handleAlign = handleAlign
	gui.wuma.handlePercent = handlePercent
	
	return gui

end