
local PANEL = {}

function PANEL:Init()

	self.Inheritance = {}
	self.InheritsFrom = {}
	self.InheritsTo = {}
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
	self.list_usergroups.OnRowSelected = function(_, lineid, line) self:OnUsergroupsSelected(lineid, line) end

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

	return group, {restriction:GetParent(), restriction:GetItem()}, nil, nil
end

function PANEL:SortGrouping(restriction)
	local selected_usergroups = self:GetSelectedUsergroups()
	local settings = self.Settings
	local usergroup = restriction:GetParent()
	local selected_type = self:GetSelectedType()
	local usergroup_display = self:GetUsergroupDisplay(usergroup) or usergroup --So that we can set usergroup_display on user-restrictions tab

	if (#selected_usergroups > 1) then
		local is_whiteliest = settings[usergroup] and settings[usergroup]["iswhitelist_type_" .. selected_type]

		if is_whiteliest then
			return #(self.InheritsFrom[usergroup] or {}) + 1, "Whitelist for " .. usergroup_display
		else
			return table.KeyFromValue(self:GetSelectedUsergroups(), usergroup), "Restrictions for " .. usergroup
		end
	else
		for i, group in ipairs(self.InheritsFrom[self:GetSelectedUsergroups()[1]] or {}) do
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


function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_delete:SetDisabled(false)
	else
		self.button_delete:SetDisabled(true)
	end

	local selected_usergroups = self:GetSelectedUsergroups()
	local selected_type = self:GetSelectedType()

	for _, line in pairs(self.list_items:GetLines()) do
		if line:GetValue():GetIsAnti() then
			local icon = {"icon16/lightning_delete.png", "This restriction is an anti-restriction"}
			line:SetIcon(icon)
		elseif line:GetIcon() then
			line:SetIcon(nil)
		end
	end

	if (#selected_usergroups == 1) then
		local overriden_items = {}

		local inheritsFrom = self.InheritsFrom[selected_usergroups[1]]
		if inheritsFrom then
			local data_registry = self.list_items:GetDataRegistry()
			for i = #inheritsFrom, 1, -1 do
				for j = i - 1, 0, -1 do
					for _, line in pairs(data_registry[selected_type .. "_" .. inheritsFrom[i]] or {}) do
						local restiction = line:GetValue()

						local usergroup = (j >= 0) and inheritsFrom[j] or selected_usergroups[1]

						local group_key = selected_type .. "_" .. usergroup
						local item_key = usergroup.. "_" .. selected_type  .. "_" .. restiction:GetItem()
						if not overriden_items[line] and data_registry[group_key] and data_registry[group_key][item_key] then
							overriden_items[line] = usergroup
						end
					end
				end
			end
		end

		for line, overiddenBy in pairs(overriden_items) do
			local icon = {"icon16/cancel.png", "This restriction has been overridden by " .. (self:GetUsergroupDisplay(overiddenBy) or overiddenBy)}
			line:SetIcon(icon)
		end
	end
end

--luacheck: push no unused args
function PANEL:GetUsergroupDisplay(usergroup)
	--For use in user-restrictions
end
--luacheck: pop

function PANEL:ReloadSuggestions(type)
	local items = WUMA.RestrictionTypes[type]:GetItems()

	self.list_suggestions:SetDisabled(false)
	self.button_add:SetDisabled(false)

	self.list_suggestions:Clear()
	if (self.textbox_search:GetValue() ~= "") then
		self.list_suggestions:AddLine(self.textbox_search:GetValue())
	elseif table.IsEmpty(items) then
		self.list_suggestions:SetDisabled(true)
		self.button_add:SetDisabled(true)
	end

	if not table.IsEmpty(items) then
		for k, v in pairs(items) do
			if (v ~= self.textbox_search:GetValue()) then
				self.list_suggestions:AddLine(v)
			end
		end
	end

	self.list_suggestions:SelectFirstItem()
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

	if self.Inheritance then
		self.sorted_usergroups = WUMA.TopologicalSort(self.Inheritance, usergroups)
	else
		self.sorted_usergroups = table.ClearKeys(usergroups)
	end

	self.list_usergroups:Clear()
	for i, usergroup in ipairs(self.sorted_usergroups) do
		local line = self.list_usergroups:AddLine(usergroup)
		line:SetSortValue(1, i)
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
	local inheritance = inheritance["restrictions"] or {}

	self.Inheritance = inheritance
	self.InheritsFrom = {}
	self.InheritsTo = {}
	for usergroup, inheritsFrom in pairs(inheritance) do
		self.InheritsFrom[usergroup] = self.InheritsFrom[usergroup] or {}

		local current = inheritsFrom
		while current do
			table.insert(self.InheritsFrom[usergroup], current)

			self.InheritsTo[current] = self.InheritsTo[current] or {}
			table.insert(self.InheritsTo[current], 1, usergroup)

			current = inheritance[current]
		end
	end

	if self.usergroups then
		self:NotifyUsergroupsChanged(self.usergroups)
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

	if self.usergroups then
		self:ShowUsergroups(self:GetSelectedUsergroups())
	end

	self.list_types.previous_line = lineid
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
	local inheritsFrom = self.InheritsFrom
	local settings = table.Copy(raw_settings)

	for usergroup, _ in pairs(inheritsFrom) do
		for name, type in pairs(WUMA.RestrictionTypes) do
			for i = #inheritsFrom[usergroup], 1, -1 do
				local current = inheritsFrom[usergroup][i]

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

function PANEL:OnUsergroupsSelected()
	local usergroups = self:GetSelectedUsergroups()
	for _, group in pairs(usergroups) do
		self:OnUsergroupSelected(group)
	end

	self:ShowUsergroups(usergroups)
end


--luacheck: push no unused args
function PANEL:ShowUsergroups(usergroups)
	--For override
end
--luacheck: pop

--luacheck: push no unused args
function PANEL:OnUsergroupSelected(usergroup)
	--For override
end
--luacheck: pop

vgui.Register("WBaseView", PANEL, 'DPanel');
