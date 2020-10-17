
local PANEL = {}

AccessorFunc(PANEL, "settings", "Settings")

function PANEL:Init()

	self.Inheritance = {}

	self:SetSettings({})

	--Restriction types list
	self.list_types = vgui.Create("DListView", self)
	self.list_types:SetMultiSelect(false)
	self.list_types:AddColumn("Types")
	self.list_types:SetSortable(false)
	self.list_types.OnRowSelected = function(_, lineid, line) self:OnTypeChange(lineid, line) end

	--Usergroups list
	self.list_usergroups = vgui.Create("DListView", self)
	self.list_usergroups:SetMultiSelect(true)
	self.list_usergroups:AddColumn("Usergroups")
	self.list_usergroups.OnRowSelected = function(_, lineid, line) self:OnUsergroupsChanged(lineid, line) end

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = function() self:OnSearch(self.textbox_search:GetValue()) end

	--Delete button
	self.button_delete = vgui.Create("DButton", self)
	self.button_delete:SetText("Delete")
	self.button_delete:SetDisabled(true)
	self.button_delete.DoClick = function() self:OnDeleteClick() end

	--Restrict button
	self.button_add = vgui.Create("WCollapsableButton", self)
	self.button_add:SetText("Restrict")
	self.button_add:SetInnerPadding(0, 5)
	self.button_add.DoClick = function() self:OnRestrictClick() end

	--Derestrict button
	self.button_derestrict = vgui.Create("DButton", self)
	self.button_derestrict:SetText("De-restrict")
	self.button_derestrict.DoClick = function() self:OnDerestrictClick() end

	self.button_add:AddButton(self.button_derestrict)

	--Suggestion list
	self.list_suggestions = vgui.Create("DListView", self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)

	--Items list
	self.list_items = vgui.Create("WListView", self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items.OnItemSelected = function(_, item) return self:OnItemSelected(item) end
	self.list_items.OnViewChanged = function() return self:OnViewChanged() end
	self.list_items:SetClassifyFunction(function(...) return self:ClassifyRestriction(...) end)
	self.list_items:SetSortGroupingFunction(function(...) return self:SortGrouping(...) end)

	--Whitelist checkbox
	self.checkbox_whitelist = vgui.Create("WCheckBoxLabel", self)
	self.checkbox_whitelist:SetText("This list is a whitelist")
	self.checkbox_whitelist:SetTextColor(Color(0, 0, 0))
	self.checkbox_whitelist:SetValue(-1)
	self.checkbox_whitelist.OnChange = function(_, val) self:OnWhitelistCheckboxChanged(val) end

	--All checkbox
	self.checkbox_restrictall = vgui.Create("WCheckBoxLabel", self)
	self.checkbox_restrictall:SetTextColor(Color(0, 0, 0))
	self.checkbox_restrictall:SetValue(-1)
	self.checkbox_restrictall.OnChange = function(_, val) self:OnRestrictAllCheckboxChanged(val) end

	--List footer
	self.items_footer = vgui.Create("DPanel")
	self.items_footer:SetVisible(false)

	self.footer_label = vgui.Create("DLabel", self.items_footer)
	self.footer_label:SetText("Not showing inherited restrictions when several usergroups are selected")
	self.footer_label:SizeToContents()
	self.footer_label:SetTextColor(Color(0, 0, 0))
	self.footer_label.DoClick = function() self:OnLoadMoreUsers() end

	self.items_footer.footer_label = self.footer_label

	function self.items_footer:SizeToContentsY()
		self:SetTall(10 + self.footer_label:GetTall())
	end

	local list = self.list_items
	function self.items_footer:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(0, 0, w, h)

		if (self.y > 0) then
			surface.SetDrawColor(82, 82, 82, 255)
			surface.DrawLine(0, 0, w, 0)
		end

		local _, y = self:LocalToScreen(0, h)
		local _, y2 = list:LocalToScreen(0, list:GetTall())
		if (y + 1 ~= y2) then
			surface.SetDrawColor(82, 82, 82, 255)
			surface.DrawLine(0, h - 1, w, h - 1)
		end
	end

	function self.items_footer:PerformLayout(w, h)
		self.footer_label:SetPos(w / 2 - self.footer_label:GetWide() / 2, h / 2 - self.footer_label:GetTall() / 2)
	end

	self.list_items:AddPanel(self.items_footer)

	for _, type in pairs(WUMA.RestrictionTypes) do
		self.list_types:AddLine(type:GetPrint())
	end
	self.list_types:SelectFirstItem()
end

function PANEL:PerformLayout()
	self.list_types:SetPos(5, 5)
	self.list_types:SizeToContents()
	self.list_types:SetWide(100)

	self.list_usergroups:SetPos(5, self.list_types.y+self.list_types:GetTall() + 5)
	self.list_usergroups:SetSize(self.list_types:GetWide(), self:GetTall() - self.list_usergroups.y - 5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos((self:GetWide() - 5) - self.textbox_search:GetWide(), 5)

	self.button_delete:SetSize(self.textbox_search:GetWide(), 25)
	self.button_delete:SetPos(self.textbox_search.x,  (self:GetTall() - 5) - self.button_delete:GetTall())

	self.button_add:SetWide(self.textbox_search:GetWide())
	self.button_add:SetPos(self.button_delete.x, (self.button_delete.y - 5) - self.button_add:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y + self.textbox_search:GetTall() + 5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y - self.list_suggestions.y - 5)

	self.list_items:SetPos(self.list_types.x + self.list_types:GetWide() + 5, 5)
	self.list_items:SetSize(self.textbox_search.x-self.list_items.x - 5, self:GetTall() - self.checkbox_whitelist:GetTall() - 20)

	self.checkbox_whitelist:SetPos(self.list_items.x + 5, self.list_items.y+self.list_items:GetTall() + 5)

	self.checkbox_restrictall:SetPos(self.checkbox_whitelist.x + self.checkbox_whitelist:GetWide() + 10, self.checkbox_whitelist.y)
end

function PANEL:SortGrouping(restriction)
	if (table.Count(self:GetSelectedUsergroups()) == 1) then
		local selected = self:GetSelectedUsergroups()[1]
		for i, group in ipairs(self.Inheritance[selected] or {}) do
			if (group == restriction:GetParent()) then
				return i + 1, "Inherited from " .. group, true
			end
		end
	end
	return 1
end

function PANEL:ClassifyRestriction(restriction)
	local group = restriction:GetType() .. "_" .. restriction:GetParent()

	local icon
	if restriction:GetIsAnti() then
		icon = {"icon16/lightning_delete.png", "This restriction is an anti-restriction"}
	end

	return group, {restriction:GetParent(), restriction:GetItem()}, nil, nil, icon
end

function PANEL:ReloadSuggestions(type)
	local items = WUMA.RestrictionTypes[type]:GetItems()

	if table.IsEmpty(items) then
		self.list_suggestions:SetDisabled(true)
		self.list_suggestions:Clear()
	else
		self.list_suggestions:SetDisabled(false)

		self.list_suggestions:Clear()

		if (self.textbox_search:GetValue() ~= "") then
			self.list_suggestions:AddLine(self.textbox_search:GetValue())
		end

		for k, v in pairs(items) do
			if (v ~= self.textbox_search:GetValue()) then
				self.list_suggestions:AddLine(v)
			end
		end

		self.list_suggestions:SelectFirstItem()
	end
end

function PANEL:GetSelectedType()
	for k, restriction_type in pairs(WUMA.RestrictionTypes) do
		if (restriction_type:GetPrint() == self.list_types:GetSelected()[1]:GetValue(1)) then
			return k
		end
	end
end

function PANEL:GetSelectedSuggestions()
	local tbl = {}
	for _, v in pairs(self.list_suggestions:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end

	return tbl
end

function PANEL:GetSelectedUsergroups()
	local tbl = {}
	for _, v in pairs(self.list_usergroups:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end

	return tbl
end

function PANEL:NotifyRestrictionsChanged(restrictions, parent, updated, deleted)
	if (restrictions ~= self.list_items:GetDataSources()[parent]) then
		self.list_items:AddDataSource(parent, restrictions)
	else
		self.list_items:UpdateDataSource(parent, updated, deleted)
	end
end

function PANEL:NotifyUsergroupsChanged(usergroups)
	self.list_usergroups:Clear()
	for _, usergroup in pairs(usergroups) do
		self.list_usergroups:AddLine(usergroup)
	end
	self.list_usergroups:SelectFirstItem()
end

function PANEL:NotifySettingsChanged(parent, new_settings)
	local settings = self:GetSettings()
	if table.IsEmpty(new_settings) then
		settings[parent] = nil
	else
		settings[parent] = new_settings
	end
	self:ReloadSettings()
end

function PANEL:OnSearch(text)
	self:ReloadSuggestions(self:GetSelectedType())

	if (text ~= "") then
		for k, line in pairs(self.list_suggestions:GetLines()) do
			local item = line:GetValue(1)
			if not string.match(string.lower(item), string.lower(text)) then
				self.list_suggestions:RemoveLine(k)
			end
		end

		self.list_suggestions:SelectFirstItem()
	end
end

function PANEL:OnItemChange()

end

function PANEL:ReloadSettings()
	local usergroups = self:GetSelectedUsergroups()

	self.DisregardSettingsChange = true
	if (#usergroups == 1) then
		local type = self:GetSelectedType()

		local settings = self:GetSettings()

		self.checkbox_restrictall:SetValue(-1)
		self.checkbox_whitelist:SetValue(-1)

		local prev_restrict_type
		local prev_whitelist

		local first = true

		local lock_restrict_type = false
		local lock_whitelist = false
		for _, usergroup in pairs(usergroups) do
			local restrict_type = settings[usergroup] and settings[usergroup]["restrict_type_" .. type]
			local is_whiteliest = settings[usergroup] and settings[usergroup]["iswhitelist_type_" .. type]

			if not first and not lock_restrict_type and restrict_type ~= prev_restrict_type then
				self.checkbox_restrictall:SetValue(0)
				lock_restrict_type = true
			elseif not lock_restrict_type and restrict_type then
				self.checkbox_restrictall:SetValue(1)
			end

			if not first and not lock_whitelist and is_whiteliest ~= prev_whitelist then
				self.checkbox_whitelist:SetValue(0)
				lock_whitelist = true
			elseif not lock_whitelist and is_whiteliest then
				self.checkbox_whitelist:SetValue(1)
			end

			prev_whitelist = is_whiteliest
			prev_restrict_type = restrict_type
			first = false
		end
	else
		self.checkbox_restrictall:SetValue(0)
		self.checkbox_whitelist:SetValue(0)
	end

	self.DisregardSettingsChange = false
end

function PANEL:OnTypeChange(lineid, _)
	if (self.list_types.previous_line == lineid) or not self:GetSelectedType() then return end

	self:ReloadSuggestions(self:GetSelectedType())

	self.textbox_search:SetDefault(WUMA.RestrictionTypes[self:GetSelectedType()]:GetSearch())
	self.textbox_search:SetText("")
	self.textbox_search:OnLoseFocus()

	self.list_suggestions.VBar:SetScroll(0)
	self.list_suggestions:SelectFirstItem()

	self.checkbox_restrictall:SetText("Restrict all " .. string.lower(WUMA.RestrictionTypes[self:GetSelectedType()]:GetPrint2()))

	self:ShowUsergroups(self:GetSelectedUsergroups())

	self.list_types.previous_line = lineid
end

function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_delete:SetDisabled(false)
	else
		self.button_delete:SetDisabled(true)
	end
end

function PANEL:OnItemSelected(_)
	self.button_delete:SetDisabled(false)
end

function PANEL:NotifyInheritanceChanged(inheritance)
	inheritance = inheritance["restrictions"] or {}

	self.Inheritance = {}
	for usergroup, inheritsFrom in pairs(inheritance) do
		self.Inheritance[usergroup] = self.Inheritance[usergroup] or {}

		local current = inheritsFrom
		while current do
			table.insert(self.Inheritance[usergroup], current)

			current = inheritance[current]
		end
	end

	self:ShowUsergroups(self:GetSelectedUsergroups())
end

function PANEL:OnUsergroupsChanged()
	for _, group in pairs(self:GetSelectedUsergroups()) do
		self:OnUsergroupSelected(group)
	end

	if (#self:GetSelectedUsergroups() > 1) then
		self.checkbox_restrictall:SetDisabled(true)
		self.checkbox_whitelist:SetDisabled(true)

		local message = "Disabled when multiple usergroups are selected"
		self.checkbox_restrictall:SetHoverMessage(message)
		self.checkbox_whitelist:SetHoverMessage(message)
	else
		self.checkbox_restrictall:SetDisabled(false)
		self.checkbox_whitelist:SetDisabled(false)

		self.checkbox_restrictall:SetHoverMessage(nil)
		self.checkbox_whitelist:SetHoverMessage(nil)
	end

	self:ReloadSettings()
	self:ShowUsergroups(self:GetSelectedUsergroups())
end

function PANEL:ShowUsergroups(usergroups)
	local to_show = {}

	local selected_type = self:GetSelectedType()
	if (table.Count(usergroups) == 1) then
		for _, selected in pairs(usergroups) do
			table.insert(to_show, selected_type .. "_" .. selected)
			for _, group in ipairs(self.Inheritance[selected] or {}) do
				table.insert(to_show, selected_type .. "_" .. group)
			end
		end

		self.items_footer:SetVisible(false)
	else
		for i, selected in ipairs(usergroups) do
			table.insert(to_show, selected_type .. "_" .. selected)
		end

		self.items_footer:SetVisible(true)
	end

	self.list_items:GroupAll()
	self.list_items:Show(to_show)
end

--luacheck: push no unused args
function PANEL:OnUsergroupSelected(usergroup)
	--For override
end
--luacheck: pop

function PANEL:OnWhitelistCheckboxChanged(checked)
	if (checked == 0) or self.DisregardSettingsChange then
		return
	else
		checked = (checked == 1)
	end

	local usergroups = self:GetSelectedUsergroups()
	local type = self:GetSelectedType()

	self:OnWhitelistChanged(usergroups, type, checked)
end

--luacheck: push no unused args
function PANEL:OnWhitelistChanged(usergroups, type, is_whitelist)
	--For override
end
--luacheck: pop

function PANEL:OnRestrictAllCheckboxChanged(checked)
	if (checked == 0) or self.DisregardSettingsChange then
		return
	else
		checked = (checked == 1)
	end

	local usergroups = self:GetSelectedUsergroups()
	local type = self:GetSelectedType()

	self:OnRestrictAllChanged(usergroups, type, checked)
end

--luacheck: push no unused args
function PANEL:OnRestrictAllChanged(usergroups, type, restrict_all)
	--For override
end
--luacheck: pop

function PANEL:OnRestrictClick()
	local selected_type = self:GetSelectedType()
	if not selected_type then return end

	local usergroups = self:GetSelectedUsergroups()

	local suggestions = self:GetSelectedSuggestions()

	self:OnAddRestrictions(usergroups, selected_type, suggestions, false)
end

function PANEL:OnDerestrictClick()
	local selected_type = self:GetSelectedType()
	if not selected_type then return end

	local usergroups = self:GetSelectedUsergroups()

	local suggestions = self:GetSelectedSuggestions()

	self:OnAddRestrictions(usergroups, selected_type, suggestions, true)
end

--luacheck: push no unused args
function PANEL:OnAddRestrictions(usergroups, selected_type, suggestions, is_anti)
	--For override
end
--luacheck: pop

function PANEL:OnDeleteClick()
	local selected_type = self:GetSelectedType()
	if not selected_type then return end

	local selected_items = self.list_items:GetSelectedItems()
	if table.IsEmpty(selected_items) then return end

	local parents, items = {}, {}
	for _, item in pairs(selected_items) do
		parents[item:GetParent()] = true

		items[item:GetParent()] = items[item:GetParent()] or {}

		table.insert(items[item:GetParent()], item:GetItem())
	end

	for parent, _ in pairs(parents) do
		self:OnDeleteRestrictions(parent, selected_type, items[parent])
	end
end

--luacheck: push no unused args
function PANEL:OnDeleteRestrictions(usergroups, types, items)
	--For override
end
--luacheck: pop

vgui.Register("WUMA_Restrictions", PANEL, 'DPanel');
