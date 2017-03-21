
local PANEL = {}

PANEL.HelpText = [[
	You can set your own 
	loadout in this window.
	Any weapons you can spawn 
	with are shown here,
	any missing weapons are 
	either weapons that the
	server does not have or 
	weapons that the server 
	hasrestricted from you 
	or your usergroup.
]]

function PANEL:Init()
	
	self.lblTitle:SetTextColor(Color(0,0,0))
	
	self.WeaponsPerLine = 5
	
	self.weapons = {}
	self.categories = {}
	
	self.sidebar = vgui.Create("DPanel",self)
	self.sidebar.Paint = function() end
	
	self.sliders = vgui.Create("DPanel",self.sidebar)

	self.slider_primary = vgui.Create("WSlider",self.sliders)
	self.slider_primary:SetMinMax(1,1000)
	self.slider_primary:SetText("Primary ammo")
	self.slider_primary:SetDecimals(0)

	self.slider_secondary = vgui.Create("WSlider",self.sliders)
	self.slider_secondary:SetMinMax(1,1000)
	self.slider_secondary:SetText("Secondary ammo")
	self.slider_secondary:SetDecimals(0)
	
	self.buttons = vgui.Create("DPanel",self.sidebar)
		
	self.button_remove = vgui.Create("DButton",self.buttons)
	self.button_remove:SetText("Remove weapons")
	self.button_remove.DoClick = function(button) self:OnRemoveClick() end 
	
	self.button_add = vgui.Create("DButton",self.buttons)
	self.button_add:SetText("Add weapons")
	self.button_add.DoClick = function(button) self:OnAddClick() end 
	
	self.help = vgui.Create("DPanel",self.sidebar)
	
	self.helplabel = vgui.Create("DLabel",self.help)
	self.helplabel:SetMultiline(true) 
	self.helplabel:SetTextColor(Color(0,0,0))
	self.helplabel:SetText(self.HelpText)
	self.helplabel:SetContentAlignment(5)
	
	self.properties = vgui.Create("DPanel",self.sidebar)
	
	self.loadout_title = vgui.Create("DPanel",self)
	self.loadout_title.Paint = function(panel, w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color(234, 234, 234, 255))
		draw.RoundedBox(0, 0, 33, w, 3, Color(159, 163, 167, 255))
		draw.DrawText("Loadout","DermaLarge",5,2,Color(0, 0, 0, 255))
	end
	
	self.loadout = vgui.Create("DScrollPanel",self)
	self.loadout.Paint = function(panel, w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color(234, 234, 234, 255))
	end
	
	self.selection_title = vgui.Create("DPanel",self)
	self.selection_title.Paint = function(panel, w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color(234, 234, 234, 255))
		draw.RoundedBox(0, 0, 33, w, 3, Color(159, 163, 167, 255))
		draw.DrawText("Weapons","DermaLarge",5,2,Color(0, 0, 0, 255))
	end
		
	self.selection = vgui.Create("DScrollPanel",self)
	self.selection.Paint = function(panel, w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color( 234, 234, 234, 255 ) )
	end

end

function PANEL:PerformLayout()

	local titlePush = 0

	if ( IsValid( self.imgIcon ) ) then

		self.imgIcon:SetPos( 5, 5 )
		self.imgIcon:SetSize( 16, 16 )
		titlePush = 16

	end

	self.btnClose:SetPos( self:GetWide() - 31 - 4, 0 )
	self.btnClose:SetSize( 31, 31 )

	self.btnMaxim:SetPos( self:GetWide() - 31 * 2 - 4, 0 )
	self.btnMaxim:SetSize( 31, 31 )

	self.btnMinim:SetPos( self:GetWide() - 31 * 3 - 4, 0 )
	self.btnMinim:SetSize( 31, 31 )

	self.lblTitle:SetPos( 8 + titlePush, 2 )
	self.lblTitle:SetSize( self:GetWide() - 25 - titlePush, 20 )

	////////////////////////////////////////////////////////
	/////		 		   Custom stuff		 		   /////
	////////////////////////////////////////////////////////
	
	self.sidebar:SetWide(150)
	self.sidebar:DockMargin(0,0,0,0)
	self.sidebar:Dock(LEFT)
	
	self.slider_primary:SetSize(self.sidebar:GetWide(),40)
	self.slider_primary:DockMargin(5,5,5,0)
	self.slider_primary:Dock(TOP)
	
	self.slider_secondary:SetSize(self.sidebar:GetWide(),40)
	self.slider_secondary:DockMargin(5,5,5,0)
	self.slider_secondary:Dock(TOP)
	
	self.sliders:SizeToContents()
	self.sliders:SetTall(95)
	self.sliders:Dock(TOP)
	
	self.button_add:SetWide(self.sidebar:GetWide())
	self.button_add:DockMargin(5,0,5,5)
	self.button_add:Dock(BOTTOM)
	
	self.button_remove:SetWide(self.sidebar:GetWide())
	self.button_remove:DockMargin(5,0,5,5)
	self.button_remove:Dock(BOTTOM)
	
	self.buttons:SizeToContents()
	self.buttons:SetTall(59)
	self.buttons:Dock(BOTTOM)

	self.helplabel:DockMargin(5,5,5,5)
	self.helplabel:Dock(FILL)
	
	self.help:SetSize(w,150)
	self.help:DockMargin(0,0,0,5)
	self.help:Dock(BOTTOM)
	
	self.properties:DockMargin(0,5,0,5)
	self.properties:Dock(FILL)
	
	self.loadout_title:SetTall(36)
	self.loadout_title:DockMargin(5,0,0,0)
	self.loadout_title:Dock(TOP)
	
	self.loadout:SetTall(self:GetTall()/3)
	self.loadout:DockMargin(5,0,0,0)
	self.loadout:Dock(TOP)

	for _, category in pairs(self.categories) do
		category:SetWide(self:GetWide())
		category:DockMargin(0,2,0,0)
		category:Dock(TOP)
		
		for i, icon in pairs(category:GetContents():GetChildren()) do
			i = i - 2
			icon:SetSize(self:GetIconSize(),self:GetIconSize())
			icon:SetPos(self:GetIconPos(i))
		end
	end
	
	for i, icon in pairs(self.loadout.pnlCanvas:GetChildren()) do
		icon:SetSize(self:GetIconSize(),self:GetIconSize())
		icon:SetPos(self:GetIconPos(i))
	end
		
	self.selection_title:SetTall(36)
	self.selection_title:DockMargin(5,5,0,0)
	self.selection_title:Dock(TOP)

	self.selection:DockMargin(5,0,0,0)
	self.selection:Dock(TOP)
	self.selection:SetTall(self.sidebar:GetTall()-self.loadout:GetTall()-5)

	--[[
	for i, icon in pairs(self.selection:GetCanvas():GetChildren()) do
		icon:SetSize(self:GetIconSize(),self:GetIconSize())
		icon:SetPos(self:GetIconPos(i))
	end
	--]]	
	
end

function PANEL:Paint(w, h)
	draw.RoundedBox( 8, 0, 0, w, h, Color( 159, 163, 167, 255 ) )
end

function PANEL:GetIconSize()
	return ((self.loadout:GetCanvas():GetWide()-self.loadout:GetVBar():GetWide())-(self.WeaponsPerLine-1)*5)/self.WeaponsPerLine
end

function PANEL:GetIconPos(i)
	return ((((i-1)/self.WeaponsPerLine)-math.floor((i-1)/self.WeaponsPerLine))*self.WeaponsPerLine)*(self:GetIconSize()+5),math.floor((i-1)/self.WeaponsPerLine)*(self:GetIconSize()+5)
end

function PANEL:AddWeapon(weapon)
	if not weapon.Spawnable then return end

	local index = table.insert(self.weapons,weapon)

	local category = weapon.Category or "Other"
	if not self:GetCategory(category) then
		self:AddCategory(category)
	end

	local icon = vgui.Create("SpawnIcon",self:GetCategory(category):GetContents())
	icon:SetModel(weapon.WorldModel)

	local self_panel = self
end

function PANEL:GetCategory(category)
	return self.categories[category]
end

function PANEL:GetCategories()
	return self.categories
end

function PANEL:AddCategory(name)
	local category = vgui.Create("DCollapsibleCategory", self.selection)	
	category:SetPos(25, 50)											 
	category:SetSize(250, 100)										 
	category:SetExpanded(0)											 
	category:SetLabel(name)		
	category.index = #self.categories	

	local listpanel = vgui.Create("DPanelList", category)
	listpanel:SetSpacing(5)							
	listpanel:EnableHorizontal(false)				
	listpanel:EnableVerticalScrollbar(true)
	category:SetContents(listpanel)	
	
	category.GetContents = function(panel) return panel.Contents end

	self.categories[name] = category
	
	return category
end

function PANEL:AddWeapons(weapons)
	for _, weapon in pairs(weapons) do 
		self:AddWeapon(weapon)
	end
end

function PANEL:OnRemoveClick()
	for _, icon in pairs(self.loadout:GetCanvas():GetChildren()) do
		if (icon:GetName() != "DPanel" and icon:IsSelected()) then
			icon:SetParent(self:GetCategory(icon:GetCategory()):GetContents())
			icon:SetSelected(false)
		end
	end
	self:InvalidateLayout()
end

function PANEL:OnAddClick()
	for _, category in pairs(self:GetCategories()) do
		for _, icon in pairs(category:GetContents():GetChildren()) do
			if icon:IsSelected() then
				icon:SetParent(self.loadout)
				icon:SetSelected(false)
			end
		end
	end
	self:InvalidateLayout()
end

vgui.Register("WUMA_UserLoadout", PANEL, 'DFrame');

local ICON = {}

function ICON:Init()
	
end

function ICON:PerformLayout(w, h) 
	
end

function ICON:Paint(w, h)

	if not self:IsSelected() then
		draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0))
	else
		draw.RoundedBox(4, 0, 0, w, h, Color(0,200,0))
	end

	surface.SetDrawColor(Color(255,255,255))
	surface.SetMaterial(self:GetImage())
	surface.DrawTexturedRectUV(2, 2, w-4, h-4, 0, 0, 1, 1)
	
	surface.SetDrawColor(Color(0,0,0,220))

	if not self.highlight and not self:IsSelected() then
		local height = 18
		surface.DrawRect(2,h-height,w-4,height)
		surface.SetFont("DermaDefault")
		local text_w, text_h = surface.GetTextSize(self:GetName())
		if (self:GetName() == "SMG") then WUMADebug(text_w) end
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( w/2-text_w/2, (h-height)+(height/2)-(text_h/2))
		surface.DrawText(self:GetName())	
	end
	
end

function ICON:SetCategory(category)
	self.category = category
end

function ICON:GetCategory()
	return self.category or ""
end

function ICON:SetClass(class)
	self.class = class
end

function ICON:GetClass()
	return self.class or ""
end

function ICON:SetName(name)
	self.name = name
end

function ICON:GetName()
	return self.name
end

function ICON:SetImage(img)
	self.image = Material(img,"smooth noclamp")
	if (self.image:IsError()) then 
	
	end
end

function ICON:GetImage()
	return self.image
end

function ICON:SetWeapon(weapon)
	self.weapon = weapon
end

function ICON:GetWeapon()
	return self.weapon
end

function ICON:SetSelected(bool)
	self.selected = bool
	self:Paint(self:GetSize())
end

function ICON:IsSelected()
	return self.selected
end

function ICON:OnCursorExited()
	self.highlight = false
	self:Paint(self:GetSize())
end

function ICON:OnCursorEntered()
	self.highlight = true
	self:Paint(self:GetSize())
end

function ICON:OnMousePressed()
	self:SetSelected(not self:IsSelected())
end

vgui.Register("WUMA_WeaponIcon", ICON, "SpawnIcon")