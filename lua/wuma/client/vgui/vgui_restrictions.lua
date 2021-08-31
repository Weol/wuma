
local PANEL = {}

AccessorFunc(PANEL, "inheritance", "Inheritance")
AccessorFunc(PANEL, "usergroups", "Usergroups")
AccessorFunc(PANEL, "settings", "Settings")
AccessorFunc(PANEL, "inherits_from", "InheritsFrom")
AccessorFunc(PANEL, "inherits_to", "InheritsTo")

function PANEL:Init()

	self.settings = {}

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

--[[
	Should return 4 values:
		group_id - the id of the group the restriction belongs to, can be a table to be a composite key, is converted to table with single value otherwise
		display - a table that specifies which values should be displayed for each column
		sort - a table that specifies which value the restriction should be sorted by for each column, can be null to have natural sorting
		highlight - specifies which color the restriction should be highlighted with (use Color(r, g, b, a)), can be null for no highlighting
]]
function PANEL:ClassifyRestriction(restriction)
	local group = restriction:GetParent() .. "_" .. restriction:GetType()

	return group, {restriction:GetParent(), restriction:GetItem()}, nil, nil
end

function PANEL:BuildSettings()
	local raw_settings = self.RawSettings
	local inheritsFrom = self:GetInheritsFrom()
	local settings = table.Copy(raw_settings)

	if not raw_settings then return end

	if inheritsFrom then
		for usergroup, _ in pairs(inheritsFrom) do
			if inheritsFrom[usergroup] then
				for name, type in pairs(WUMA.RestrictionTypes) do
					for i = #inheritsFrom[usergroup], 1, -1 do
						local current = inheritsFrom[usergroup][i]

						local restrict_type = raw_settings[current] and raw_settings[current]["restrict_type_" ..name]
						local is_whiteliest = raw_settings[current] and raw_settings[current]["iswhitelist_type_" ..name]

						if restrict_type or (settings[usergroup] and settings[usergroup]["inherited_restrict_type_" ..name]) then
							settings[usergroup] = settings[usergroup] or {}
							settings[usergroup]["inherited_restrict_type_" ..name] = current
						end

						if is_whiteliest or (settings[usergroup] and settings[usergroup]["inherited_iswhitelist_type_" ..name]) then
							settings[usergroup] = settings[usergroup] or {}
							settings[usergroup]["inherited_iswhitelist_type_" ..name] = current
						end
					end
				end
			end
		end
	end

	self:SetSettings(settings)
end

--Returns whether or not a usergroups type is a whitelist or not (includes if it is inherited)
function PANEL:IsTypeWhitelist(type, usergroup)
	return self:GetSetting(usergroup, "iswhitelist_type_" .. type) or self:IsTypeWhitelistInherited(type, usergroup)
end

--Returns from whom the usergroup inherits type whitelist from, or null if it does not inherit a whitelist (can be false when PANEL:IsTypeWhitelist() is true)
function PANEL:IsTypeWhitelistInherited(type, usergroup)
	return self:GetSetting(usergroup, "inherited_iswhitelist_type_" .. type)
end

--Returns whether or not a usergroups type is restricted or not (includes if it is inherited)
function PANEL:IsTypeRestricted(type, usergroup)
	return self:GetSetting(usergroup, "restrict_type_" .. type) or self:GetSetting(usergroup, "inherited_restrict_type_" .. type)
end

--Returns from whom the usergroup inherits type restriction from, or null if it does not inherit a type restriction (can be false when PANEL:IsTypeRestricted() is true)
function PANEL:IsTypeRestrictedInherited(type, usergroup)
	return self:GetSetting(usergroup, "inherited_restrict_type_" .. type)
end

function PANEL:GetSetting(usergroup, key)
	local settings = self:GetSettings()
	return settings and settings[usergroup] and settings[usergroup][key]
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

		local inheritsFrom = self:GetInheritsFrom() and self:GetInheritsFrom()[selected_usergroups[1]]
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
			local icon = {"icon16/cancel.png", "This restriction has been overridden by " .. (self:GetUsergroupDisplay(overiddenBy))}
			line:SetIcon(icon)
		end
	end
end

--For use in user-restrictions
function PANEL:GetUsergroupDisplay(usergroup)
	return usergroup
end

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
	local inheritance = self:GetInheritance()
	if inheritance then
		usergroups = WUMA.TopologicalSort(inheritance, usergroups)
	end

	self:SetUsergroups(usergroups)

	self.list_usergroups:Clear()
	for i, usergroup in ipairs(usergroups) do
		local line = self.list_usergroups:AddLine(self:GetUsergroupDisplay(usergroup))
		line.usergroup = usergroup
		line:SetSortValue(1, i)
	end

	self.list_usergroups:SelectFirstItem()
end

function PANEL:NotifySettingsChanged(parent, new_settings)
	local settings = self.RawSettings or {}
	if table.IsEmpty(new_settings) then
		settings[parent] = nil
	else
		settings[parent] = new_settings
	end

	self.RawSettings = settings 
	self:BuildSettings()

	self:ShowSelectedUsergroups()
end

function PANEL:NotifyInheritanceChanged(inheritance)
	local inheritance = inheritance["restrictions"] or {}

	local inheritsFrom = {}
	local inheritsTo = {}

	for usergroup, from in pairs(inheritance) do
		inheritsFrom[usergroup] = inheritsFrom[usergroup] or {}

		local current = from
		while current do
			table.insert(inheritsFrom[usergroup], current)

			inheritsTo[current] = inheritsTo[current] or {}
			table.insert(inheritsTo[current], 1, usergroup)

			current = inheritance[current]
		end
	end

	self:SetInheritsFrom(inheritsFrom)
	self:SetInheritsTo(inheritsTo)
	self:SetInheritance(inheritance)

	self:BuildSettings()

	if self:GetUsergroups() then
		self:NotifyUsergroupsChanged(self:GetUsergroups())
	end

	self:ShowSelectedUsergroups()
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

function PANEL:OnTypeChange(lineid)
	if (self.list_types.previous_line == lineid) or not self:GetSelectedType() then return end

	self:ReloadSuggestions(self:GetSelectedType())

	self.textbox_search:SetDefault(WUMA.RestrictionTypes[self:GetSelectedType()]:GetSearch())
	self.textbox_search:SetText("")
	self.textbox_search:OnLoseFocus()

	self.list_suggestions.VBar:SetScroll(0)

	local plural_type = WUMA.RestrictionTypes[self:GetSelectedType()]:GetPrint2()
	self.checkbox_restrictall:SetText("Restrict all " .. string.lower(plural_type))

	self:ShowSelectedUsergroups()

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

function PANEL:OnUsergroupsSelected()
	for _, group in pairs(self:GetSelectedUsergroups()) do
		self:OnUsergroupSelected(group)
	end

	self:ShowSelectedUsergroups()
end

function PANEL:ShowSelectedUsergroups()
	local usergroups = self:GetSelectedUsergroups()
	if (#usergroups == 0) then
		return self.list_items:Show({})
	end

	self.DisregardSettingsChange = true

	self.list_items:ClearPanels()

	--[[
		Sequential array of arrays:
			1 - the group_id to show
			2 - title of the header for the group (or null to not show a header)
			3 - boolean that decides whether or not items in this group should be selectable or not (true: unselectable, nil or false: selectable)
	]]
	local groups = {}

	local selected_type = self:GetSelectedType()
	local plural_type = string.lower(WUMA.RestrictionTypes[self:GetSelectedType()]:GetPrint2())

	if (#usergroups == 1) then

		local selected = usergroups[1]

		--SetDisabled to false before setting their values, otherwise the set values will be ignored
		self.checkbox_restrictall:SetDisabled(false)
		self.checkbox_whitelist:SetDisabled(false)

		self.checkbox_restrictall:SetValue(self:IsTypeRestricted(selected_type, selected) and 1 or -1)
		self.checkbox_whitelist:SetValue(self:IsTypeWhitelist(selected_type, selected) and 1 or -1)

		self.checkbox_restrictall:SetHoverMessage(nil)
		self.checkbox_whitelist:SetHoverMessage(nil)

		if self:IsTypeWhitelistInherited(selected_type, selected) then
			self.checkbox_whitelist:SetDisabled(true)
			self.checkbox_whitelist:SetHoverMessage("Cannot change inherited whitelist")
		end

		if self:IsTypeRestrictedInherited(selected_type, selected) then
			self.checkbox_whitelist:SetValue(-1)

			self.checkbox_restrictall:SetDisabled(true)
			self.checkbox_restrictall:SetHoverMessage("Cannot change inherited type restriction")

			self.checkbox_whitelist:SetDisabled(true)
			self.checkbox_whitelist:SetHoverMessage("Cannot make whitelist when all " .. plural_type .. " are restricted")

			self.button_derestrict:SetDisabled(true)
			self.button_add:SetDisabled(true)

			local inheritedFrom = self:IsTypeRestrictedInherited(selected_type, selected)
			self.list_items:AddPanel("All " .. plural_type .. " are restricted from " .. self:GetUsergroupDisplay(selected) .. " (Inherited from " .. inheritedFrom .. ")", TOP)
		elseif self:IsTypeRestricted(selected_type, selected) then
			self.checkbox_whitelist:SetValue(-1)

			self.checkbox_whitelist:SetDisabled(true)
			self.checkbox_whitelist:SetHoverMessage("Cannot make whitelist when all " .. plural_type .. " are restricted")

			self.button_derestrict:SetDisabled(true)
			self.button_add:SetDisabled(true)

			self.list_items:AddPanel("All " .. plural_type .. " are restricted from " .. self:GetUsergroupDisplay(selected), TOP)
		else
			self.button_derestrict:SetDisabled(false)
			self.button_add:SetDisabled(false)

			local header_function = function(restrictions)
				if self:IsTypeRestricted(selected_type, selected) then
					return "All " .. plural_type .. " are restricted from " .. self:GetUsergroupDisplay(selected)
				elseif self:IsTypeWhitelist(selected_type, selected) then
					if (table.Count(restrictions) == 0) then
						return "No " .. string.lower(plural_type) .. " are whitlisted for " .. self:GetUsergroupDisplay(selected)
					else
						return "Whitelist for " .. self:GetUsergroupDisplay(selected)
					end
				else
					if (table.Count(restrictions) == 0) then
						return "No restrictions for " .. self:GetUsergroupDisplay(selected)
					else
						return "Restrictions from " .. self:GetUsergroupDisplay(selected)
					end
				end
			end

			table.insert(groups, {selected .. "_" .. selected_type, header_function})

			if self:GetInheritsFrom() and self:GetInheritsFrom()[selected] then
				for _, usergroup in ipairs(self:GetInheritsFrom()[selected]) do
					if self:IsTypeWhitelist(selected_type, selected) and not self:IsTypeWhitelist(selected_type, usergroup) then
						break
					end

					local header_function = function(restrictions)
						if self:IsTypeWhitelist(selected_type, usergroup) then
							if (table.Count(restrictions) == 0) then
								return "No whitelisted " .. string.lower(plural_type) .. " inherited from " .. self:GetUsergroupDisplay(usergroup)
							else
								return "Whitelist inherited from " .. self:GetUsergroupDisplay(usergroup)
							end
						elseif self:IsTypeRestricted(selected_type, usergroup) then
							return "All " .. plural_type .. " are restricted from " .. self:GetUsergroupDisplay(usergroup)
						else
							if (table.Count(restrictions) == 0) then
								return "No restrictions inherited from " .. self:GetUsergroupDisplay(usergroup)
							else
								return "Restrictions inherited from " .. self:GetUsergroupDisplay(usergroup)
							end
						end
					end

					table.insert(groups, {usergroup .. "_" .. selected_type, header_function, true})
				end
			end
		end
	else
		self.checkbox_restrictall:SetValue(0)
		self.checkbox_whitelist:SetValue(0)

		self.checkbox_restrictall:SetText("Restrict all " .. plural_type)

		self.checkbox_restrictall:SetDisabled(true)
		self.checkbox_whitelist:SetDisabled(true)

		local message = "Disabled when multiple usergroups are selected"
		self.checkbox_restrictall:SetHoverMessage(message)
		self.checkbox_whitelist:SetHoverMessage(message)

		for i, selected in ipairs(usergroups) do
			local header_function = function(restrictions)
				if self:IsTypeWhitelist(selected_type, selected) then
					if (table.Count(restrictions) == 0) then
						return "No " .. string.lower(plural_type) .. " are whitlisted for " .. self:GetUsergroupDisplay(selected)
					else
						return "Whitelist for " .. self:GetUsergroupDisplay(selected)
					end
				elseif self:IsTypeRestricted(selected_type, selected) then
					return "All " .. plural_type .. " are restricted from " .. self:GetUsergroupDisplay(selected)
				else
					if (table.Count(restrictions) == 0) then
						return "No restrictions for " .. self:GetUsergroupDisplay(selected)
					else
						return "Restrictions from " .. self:GetUsergroupDisplay(selected)
					end
				end
			end

			table.insert(groups, {selected .. "_" .. selected_type, header_function})
		end
		self.list_items:AddPanel("Not showing inherited restrictions", BOTTOM)
	end

	self.DisregardSettingsChange = false

	self.list_items:Show(groups)
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
		local restrict_type = self:GetSetting(usergroup, "restrict_type_" .. selected_type)
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
		local restrict_type = self:GetSetting(usergroup, "restrict_type_" .. selected_type)
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
