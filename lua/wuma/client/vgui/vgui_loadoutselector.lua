
local PANEL = {}

PANEL.HelpText = [[You can set your own loadout in this window. Any weapons you can spawn with are shown here, any missing weapons are either weapons that the server does not have or weapons that the server has restricted from you or your usergroup.]]

function PANEL:Init()

	self.weapons = {}
	self.restricted_weapons = {}

	--HelpText Label
	self.helptext_label = vgui.Create("DLabel", self)
	self.helptext_label:SetText(self.HelpText)
	self.helptext_label:SetTextColor(Color(0, 0, 0))
	self.helptext_label:SetAutoStretchVertical(true)

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = function() self:OnSearchWeapons() end

	--Primary button
	self.button_primary = vgui.Create("DButton", self)
	self.button_primary:SetText("Set Primary")
	self.button_primary.DoClick = function() self:OnButtonPrimaryClick() end

	--Delete button
	self.button_delete = vgui.Create("DButton", self)
	self.button_delete:SetText("Delete")
	self.button_delete.DoClick = function() self:OnButtonDeleteClick() end

	--Add button
	self.button_add = vgui.Create("DButton", self)
	self.button_add:SetText("Add")
	self.button_add.DoClick = function() self:OnButtonAddClick() end

	--Suggestion list
	self.list_suggestions = vgui.Create("DListView", self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)

	--Items list
	self.list_items = vgui.Create("WListView", self)
	self.list_items:AddColumn("Weapon")
	self.list_items.OnRowSelected = function(_, lineid, line) self:OnItemChange(lineid, line) end

	self.list_suggestions:SetClassifyFunction(function(...) return self:ClassifyItem(...) end)
end

function PANEL:PerformLayout()

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos((self:GetWide()-5)-self.textbox_search:GetWide(), 5)

	self.button_primary:SetSize(self.textbox_search:GetWide(), 25)
	self.button_primary:SetPos(self.textbox_search.x, self:GetTall()-self.button_primary:GetTall()-5)

	self.button_add:SetSize(self.textbox_search:GetWide()/2-3, 25)
	self.button_add:SetPos(self.button_primary.x, (self.button_primary.y-5)-self.button_primary:GetTall())

	self.button_delete:SetSize(self.textbox_search:GetWide()/2-3, 25)
	self.button_delete:SetPos(self.button_add.x+self.button_add:GetWide()+6, (self.button_primary.y-5)-self.button_primary:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y+self.textbox_search:GetTall()+5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y-self.list_suggestions.y-5)

	self.list_items:SetPos(5, 5)
	self.list_items:SetSize(self:GetWide()-20-self.textbox_search:GetWide(), self:GetTall()-100)

	self.helptext_label:SetWide(self.list_items:GetWide())
	self.helptext_label:SetPos(5, self.list_items:GetTall() + 5)

	self.helptext_label:SetText("")
	local words = string.Explode(" ", self.HelpText)
	local current_line = ""
	for _, word in pairs(words) do
		self.helptext_label:SetText(self.helptext_label:GetText() .. " " .. word)
		current_line = current_line .. " " .. word

		surface.SetFont(self.helptext_label:GetFont())
		local w, h = surface.GetTextSize(current_line .. " " .. word)

		if (w > self.list_items:GetWide()-10) then
			self.helptext_label:SetText(self.helptext_label:GetText() .. "\n")
			current_line = ""
		end
	end

	self.list_items:SetTall(self:GetTall() - self.helptext_label:GetTall() - 15)
	self.helptext_label:SetPos(5, self.list_items:GetTall() + 10)

end

function PANEL:ClassifyItem(item)
	return item:GetParent(), {item:GetClass()}
end

function PANEL:SetWeapons(weapons)
	self.weapons = weapons

	self.list_suggestions:Clear()

	for _, weapon in pairs(weapons) do
		if not self.restricted_weapons[weapon] then
			self.list_suggestions:AddLine(weapon)
		end
	end

	self.list_suggestions.VBar:SetScroll(0)
end

function PANEL:GetWeapons()
	return self.weapons
end

function PANEL:SetRestrictedWeapons(restricted_weapons)
	self.restricted_weapons = {}
	for key, restriction in pairs(restricted_weapons) do
		self.restricted_weapons[restriction:GetItem()] = true
	end

	self:SetWeapons(self:GetWeapons())
end

function PANEL:GetClassetRestrictedWeapons()
	return self.restricted_weapons
end

function PANEL:GetSelectedWeapons()
	local tbl = {}
	for _, v in pairs(self.list_suggestions:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end
	return tbl
end

function PANEL:OnSearchWeapons()
	local text = self.textbox_search:GetValue()

	self.list_suggestions:Clear()
	if (text == "") then
		for _, weapon in pairs(self:GetWeapons()) do
			self.list_suggestions:AddLine(weapon)
		end
	else
		for _, weapon in pairs(self:GetWeapons()) do
			if string.match(weapon, text) then
				self.list_suggestions:AddLine(weapon)
			end
		end
	end

	self.list_suggestions.VBar:SetScroll(0)
end

function PANEL:OnItemChange(lineid, line)

end

function PANEL:OnButtonPrimaryClick()
	local items = self.list_items:GetSelectedItems()

	if table.IsEmpty(items) then return end

	local class = items[1]:GetClass()

	WUMA.Commands.SetPersonalPrimaryWeapon:Invoke(class)
end

function PANEL:OnButtonAddClick()
	local suggestions = self:GetSelectedWeapons()

	if table.IsEmpty(suggestions) then return end

	WUMA.Commands.AddPersonalLoadout:Invoke(suggestions)
end

function PANEL:OnButtonDeleteClick()
	local items = self.list_items:GetSelectedItems()

	if table.IsEmpty(items) then return end

	local classes = {}
	for _, item in pairs(items) do
		classes[item:GetClass()] = item:GetClass()
	end

	WUMA.Commands.RemovePersonalLoadout:Invoke(classes)
end

vgui.Register("WUMA_PersonalLoadout", PANEL, 'DPanel');