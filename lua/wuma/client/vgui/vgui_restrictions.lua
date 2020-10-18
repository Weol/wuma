
local PANEL = {}

function PANEL:Init()

	self.Inheritance = {}
	self.Settings = {}
	self.RawSettings = {}

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
	self.list_items.OnItemDeselected = function(_, item) return self:OnItemDeselected(item) end
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

	for _, type in pairs(WUMA.RestrictionTypes) do
		local line = self.list_types:AddLine(type:GetPrint())
		line.RestrictionType = type
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

function PANEL:ClassifyRestriction(restriction)
	local group = restriction:GetType() .. "_" .. restriction:GetParent()

	local icon
	if restriction:GetIsAnti() then
		icon = {"icon16/lightning_delete.png", "This restriction is an anti-restriction"}
	end

	return group, {restriction:GetParent(), restriction:GetItem()}, nil, nil, icon
end

function PANEL:SortGrouping(restriction)
	local selected_usergroups = self:GetSelectedUsergroups()
	local settings = self.Settings
	local usergroup = restriction:GetParent()
	local selected_type = self:GetSelectedType()
	local usergroup_display = self:GetUsergroupDisplay(usergroup) or usergroup --So that we can set usergroup_display on user-restrictions tab

	if (#selected_usergroups > 1) then
		local is_whiteliest = settings[usergroup] and settings[usergroup]["iswhitelist_type_" .. selected_type]
		local inherited_is_whiteliest = settings[usergroup] and settings[usergroup]["inherited_iswhitelist_type_" .. selected_type]

		if is_whiteliest then
			if inherited_is_whiteliest then
				return #(self.Inheritance[usergroup] or {}) + 1, "Whitelist for "  .. usergroup_display .. " (Inherited from " .. inherited_is_whiteliest .. ")"
			else
				return #(self.Inheritance[usergroup] or {}) + 1, "Whitelist for " .. usergroup_display
			end
		else
			return table.KeyFromValue(self:GetSelectedUsergroups(), usergroup), "Restrictions for " .. usergroup
		end
	else
		for i, group in ipairs(self.Inheritance[self:GetSelectedUsergroups()[1]] or {}) do
			if (group == restriction:GetParent()) then
				local is_whiteliest = settings[group] and settings[group]["iswhitelist_type_" .. selected_type]

				if is_whiteliest then
					return i + 1, "Inherited whitelist from " .. usergroup_display, true
				else
					return i + 1, "Inherited restrictions from " .. usergroup_display, true
				end
			end
		end
	end
	local is_whiteliest = settings[usergroup] and settings[usergroup]["iswhitelist_type_" .. selected_type]

	if is_whiteliest then
		return 1, "Whitelist for " .. usergroup_display
	else
		return 1, "Restrictions for " .. usergroup_display
	end
end

--luacheck: push no unused args
function PANEL:GetUsergroupDisplay(usergroup)
	--For use in user-restrictions
end
--luacheck: pop

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
	return self.list_types:GetSelected()[1].RestrictionType:GetName()
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
	self.usergroups = usergroups
	self.list_usergroups:Clear()
	for _, usergroup in pairs(usergroups) do
		self.list_usergroups:AddLine(usergroup)
	end
	self.list_usergroups:SelectFirstItem()
end

function PANEL:NotifySettingsChanged(parent, new_settings)
	if table.IsEmpty(new_settings) then
		self.RawSettings[parent] = nil
	else
		self.RawSettings[parent] = new_settings
	end
	self:BuildSettings()
	self:ShowUsergroups(self:GetSelectedUsergroups())
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

	self:BuildSettings()
	self:ShowUsergroups(self:GetSelectedUsergroups())
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

function PANEL:OnTypeChange(lineid, _)
	if (self.list_types.previous_line == lineid) or not self:GetSelectedType() then return end

	self:ReloadSuggestions(self:GetSelectedType())

	self.textbox_search:SetDefault(WUMA.RestrictionTypes[self:GetSelectedType()]:GetSearch())
	self.textbox_search:SetText("")
	self.textbox_search:OnLoseFocus()

	self.list_suggestions.VBar:SetScroll(0)
	self.list_suggestions:SelectFirstItem()

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

function PANEL:OnItemSelected()
	self.button_delete:SetDisabled(false)
end

function PANEL:OnItemDeselected()
	if (#self.list_items:GetSelectedItems() == 0) then
		self.button_delete:SetDisabled(true)
	end
end

function PANEL:BuildSettings()
	local raw_settings = self.RawSettings
	local inheritance = self.Inheritance
	local settings = table.Copy(raw_settings)

	for usergroup, _ in pairs(inheritance) do
		for name, type in pairs(WUMA.RestrictionTypes) do
			for i = #inheritance[usergroup], 1, -1 do
				local current = inheritance[usergroup][i]

				local restrict_type = raw_settings[current] and raw_settings[current]["restrict_type_" ..name]
				local is_whiteliest = raw_settings[current] and raw_settings[current]["iswhitelist_type_" ..name]

				if restrict_type or (settings[usergroup] and settings[usergroup]["inherited_restrict_type_" ..name]) then
					settings[usergroup] = settings[usergroup] or {}
					settings[usergroup]["restrict_type_" ..name] = true
					settings[usergroup]["inherited_restrict_type_" ..name] = current
				end

				if is_whiteliest or (settings[usergroup] and settings[usergroup]["inherited_iswhitelist_type_" ..name]) then
					settings[usergroup] = settings[usergroup] or {}
					settings[usergroup]["iswhitelist_type_" ..name] = true
					settings[usergroup]["inherited_iswhitelist_type_" ..name] = current
				end
			end
		end
	end

	self.Settings = settings
end

function PANEL:OnUsergroupsChanged()
	local usergroups = self:GetSelectedUsergroups()
	for _, group in pairs(usergroups) do
		self:OnUsergroupSelected(group)
	end

	self:ShowUsergroups(usergroups)
end

function PANEL:ShowUsergroups(usergroups)
	self.list_items:ClearPanels()

	local to_show = {}

	local selected_type = self:GetSelectedType()
	local plural_type = string.lower(WUMA.RestrictionTypes[self:GetSelectedType()]:GetPrint2())

	local settings = self.Settings

	if (#usergroups == 1) then
		for _, selected in pairs(usergroups) do
			to_show[selected] = selected
			for _, group in ipairs(self.Inheritance[selected] or {}) do
				to_show[group] = group
			end
		end
	else
		for i, selected in ipairs(usergroups) do
			to_show[selected] = selected
		end
	end

	if (#usergroups > 1) then
		self.checkbox_restrictall:SetValue(0)
		self.checkbox_whitelist:SetValue(0)

		self.checkbox_restrictall:SetText("Restrict all " .. plural_type)

		self.checkbox_restrictall:SetDisabled(true)
		self.checkbox_whitelist:SetDisabled(true)

		local message = "Disabled when multiple usergroups are selected"
		self.checkbox_restrictall:SetHoverMessage(message)
		self.checkbox_whitelist:SetHoverMessage(message)

		for _, usergroup in ipairs(usergroups) do
			local restrict_type = settings[usergroup] and settings[usergroup]["restrict_type_" .. selected_type]
			local inherited_restrict_type = settings[usergroup] and settings[usergroup]["inherited_restrict_type_" .. selected_type]

			if (inherited_restrict_type) then
				self.list_items:AddPanel(string.format("All %s are restricted from %s (Inherited from %s)", plural_type, usergroup, inherited_restrict_type), BOTTOM)
				to_show[usergroup] = nil
			elseif (restrict_type) then
				self.list_items:AddPanel("All " .. plural_type .. " are restricted from " .. usergroup, BOTTOM)
				to_show[usergroup] = nil
			end
		end

		self.list_items:AddPanel("Not showing inherited restrictions", BOTTOM)
	else
		self.DisregardSettingsChange = true

		local usergroup = usergroups[1]

		local restrict_type = settings[usergroup] and settings[usergroup]["restrict_type_" .. selected_type]
		local is_whiteliest = settings[usergroup] and settings[usergroup]["iswhitelist_type_" .. selected_type]

		local inherited_restrict_type = settings[usergroup] and settings[usergroup]["inherited_restrict_type_" .. selected_type]
		local inherited_is_whiteliest = settings[usergroup] and settings[usergroup]["inherited_iswhitelist_type_" .. selected_type]

		--SetDisabled to false before setting their values, otherwise the set values will be ignored
		self.checkbox_restrictall:SetDisabled(false)
		self.checkbox_whitelist:SetDisabled(false)

		self.checkbox_restrictall:SetValue(restrict_type and 1 or -1)
		self.checkbox_whitelist:SetValue(is_whiteliest and 1 or -1)

		self.checkbox_restrictall:SetHoverMessage(nil)
		self.checkbox_whitelist:SetHoverMessage(nil)

		if inherited_restrict_type then
			self.checkbox_whitelist:SetValue(-1)

			self.checkbox_restrictall:SetDisabled(true)
			self.checkbox_restrictall:SetHoverMessage("Cannot change inherited restrictions")

			self.checkbox_whitelist:SetDisabled(true)
			self.checkbox_whitelist:SetHoverMessage("Cannot make whitelist when all " .. plural_type .. " are restricted")

			self.button_derestrict:SetDisabled(true)
			self.button_add:SetDisabled(true)
		elseif restrict_type then
			self.checkbox_whitelist:SetValue(-1)

			self.checkbox_whitelist:SetDisabled(true)
			self.checkbox_whitelist:SetHoverMessage("Cannot make whitelist when all " .. plural_type .. " are restricted")

			self.button_derestrict:SetDisabled(true)
			self.button_add:SetDisabled(true)
		else
			self.button_derestrict:SetDisabled(false)
			self.button_add:SetDisabled(false)
		end

		if usergroup then
			if inherited_is_whiteliest then
				self.checkbox_whitelist:SetDisabled(true)
				self.checkbox_whitelist:SetHoverMessage("Cannot change inherited whitelist")

				to_show = {}
				to_show[usergroup] = usergroup

				local current = inherited_is_whiteliest
				while current do
					to_show[current] = current

					current = settings[current] and settings[current]["inherited_iswhitelist_type_" .. selected_type]
				end
			elseif is_whiteliest then
				to_show = {}
				to_show[usergroup] = usergroup
			end
		end

		if (inherited_restrict_type) then
			self.list_items:AddPanel(string.format("All %s are restricted from %s (Inherited from %s)", plural_type, usergroup, inherited_restrict_type), BOTTOM)
			to_show = {}
		elseif (restrict_type) then
			self.list_items:AddPanel("All " .. plural_type .. " are restricted from " .. usergroup, BOTTOM)
			to_show = {}
		end

		self.DisregardSettingsChange = false

		self.checkbox_restrictall:SetText("Restrict all " .. plural_type)
	end

	self.list_items:GroupAll()

	local tbl = {}
	for _, v in pairs(to_show) do
		table.insert(tbl, selected_type .. "_" .. v)
	end
	self.list_items:Show(tbl)

	self.list_items.VBar:SetScroll(0)
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

	local usergroups = {}
	for _, usergroup in ipairs(self:GetSelectedUsergroups()) do
		local restrict_type = self.Settings[usergroup] and self.Settings[usergroup]["restrict_type_" .. selected_type]
		if not restrict_type then
			table.insert(usergroups, usergroup)
		end
	end

	if (#usergroups == 0) then return end

	local suggestions = self:GetSelectedSuggestions()

	self:OnAddRestrictions(usergroups, selected_type, suggestions, false)
end

function PANEL:OnDerestrictClick()
	local selected_type = self:GetSelectedType()
	if not selected_type then return end

	local usergroups = {}
	for _, usergroup in ipairs(self:GetSelectedUsergroups()) do
		local restrict_type = self.Settings[usergroup] and self.Settings[usergroup]["restrict_type_" .. selected_type]
		if not restrict_type then
			table.insert(usergroups, usergroup)
		end
	end

	if (#usergroups == 0) then return end

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
