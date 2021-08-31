
local PANEL = {}

AccessorFunc(PANEL, "inheritance", "Inheritance")
AccessorFunc(PANEL, "usergroups", "Usergroups")
AccessorFunc(PANEL, "inherits_from", "InheritsFrom")
AccessorFunc(PANEL, "inherits_to", "InheritsTo")

function PANEL:Init()

	--Limit chooser
	self.slider_limit = vgui.Create("WSlider", self)
	self.slider_limit:SetMinMax(1, 300)
	self.slider_limit:SetText("Limit")
	self.slider_limit:SetMaxOverride(-1, "∞")

	--Adv. Limit textbox
	self.textbox_advlimit = vgui.Create("WTextbox", self)
	self.textbox_advlimit:SetDefault("Adv. Limit")
	self.textbox_advlimit.OnChange = function() self:OnAdvLimitChanged(self.textbox_advlimit:GetValue()) end

	--Usergroups list
	self.list_usergroups = vgui.Create("DListView", self)
	self.list_usergroups:SetMultiSelect(true)
	self.list_usergroups:SetSortable(false)
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

	--Add button
	self.button_add = vgui.Create("WCollapsableButton", self)
	self.button_add:SetText("Add limit")
	self.button_add:SetInnerPadding(0, 5)
	self.button_add.DoClick = function() self:OnAddClick() end

	--Add exclusive button
	self.button_add_exlusive = vgui.Create("DButton", self)
	self.button_add_exlusive:SetText("Add exclusive limit")
	self.button_add_exlusive.DoClick = function() self:OnAddExclusiveClick() end

	self.button_add:AddButton(self.button_add_exlusive)

	--Suggestion list
	self.list_suggestions = vgui.Create("DListView", self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)

	--Items list
	self.list_items = vgui.Create("WListView", self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Limit")
	self.list_items.OnItemSelected = function(_, item) return self:OnItemSelected(item) end
	self.list_items.OnViewChanged = function() return self:OnViewChanged() end
	self.list_items:SetClassifyFunction(function(...) return self:ClassifyLimit(...) end)

	self:ReloadSuggestions()

end

function PANEL:PerformLayout(w, h)
	self.slider_limit:SetPos(5, 5)
	self.slider_limit:SetDecimals(0)
	self.slider_limit:SetSize(100, 40)

	self.textbox_advlimit:SetPos(5, self.slider_limit.y + self.slider_limit:GetTall() + 5)
	self.textbox_advlimit:SetSize(self.slider_limit:GetWide(), 20)

	self.list_usergroups:SetPos(5, self.textbox_advlimit.y + self.textbox_advlimit:GetTall() + 5)
	self.list_usergroups:SetSize(self.slider_limit:GetWide(), h - self.list_usergroups.y-5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos(w - self.textbox_search:GetWide() - 5, 5)

	self.button_delete:SetSize(self.textbox_search:GetWide(), 25)
	self.button_delete:SetPos(self.textbox_search.x, h - self.button_delete:GetTall() - 5)

	self.button_add:SetWide(self.textbox_search:GetWide())
	self.button_add:SetPos(self.button_delete.x, (self.button_delete.y - 5) - self.button_add:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y+self.textbox_search:GetTall()+5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y-self.list_suggestions.y-5)

	self.list_items:SetPos(self.slider_limit.x + self.slider_limit:GetWide() + 5, 5)
	self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10)
end

--[[
	Should return 4 values:
		group_id - the id of the group the limit belongs to, can be a table to be a composite key, is converted to table with single value otherwise
		display - a table that specifies which values should be displayed for each column
		sort - a table that specifies which value the limit should be sorted by for each column, can be null to have natural sorting
		highlight - specifies which color the limit should be highlighted with (use Color(r, g, b, a)), can be null for no highlighting
]]
function PANEL:ClassifyLimit(limit)
	local l = limit:GetLimit()
	if ((tonumber(l) or 0) < 0) then l = "∞" end

	return limit:GetParent(), {limit:GetParent(), limit:GetItem(), l}, nil, nil
end

function PANEL:SortGrouping(limit)
	local selected_usergroups = self:GetSelectedUsergroups()
	local usergroup = limit:GetParent()
	local usergroup_display = self:GetUsergroupDisplay(usergroup) or usergroup --So that we can set usergroup_display on user-limits tab

	if (#selected_usergroups > 1) then
		return table.KeyFromValue(self:GetSelectedUsergroups(), usergroup), "Limits for " .. usergroup
	else
		for i, group in ipairs(self:GetInheritsFrom()[self:GetSelectedUsergroups()[1]] or {}) do
			if (group == limit:GetParent()) then
				return i + 1, "Inherited limits from " .. usergroup_display, true
			end
		end

		return 1, "Limits for " .. usergroup_display
	end
end

function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_delete:SetDisabled(false)
	else
		self.button_delete:SetDisabled(true)
	end

	local selected_usergroups = self:GetSelectedUsergroups()

	for _, line in pairs(self.list_items:GetLines()) do
		if line:GetValue():GetIsExclusive() then
			local icon = {"icon16/ruby.png", "This limit is an exclusive limit"}
			line:SetIcon(icon)
		elseif line:GetIcon() then
			line:SetIcon(nil)
		end
	end

	if (#selected_usergroups == 1) then
		local overriden_items = {}

		local inheritsFrom = self:GetInheritsFrom()[selected_usergroups[1]]
		if inheritsFrom then
			local data_registry = self.list_items:GetDataRegistry()
			for i = #inheritsFrom, 1, -1 do
				for j = i - 1, 0, -1 do
					for _, line in pairs(data_registry[inheritsFrom[i]] or {}) do
						local limit = line:GetValue()

						local usergroup = (j >= 0) and inheritsFrom[j] or selected_usergroups[1]

						local item_key = usergroup .. "_" .. limit:GetItem()
						if not overriden_items[line] and data_registry[usergroup] and data_registry[usergroup][item_key] then
							overriden_items[line] = usergroup
						end
					end
				end
			end
		end

		for line, overiddenBy in pairs(overriden_items) do
			local icon = {"icon16/cancel.png", "This limit has been overridden by " .. (self:GetUsergroupDisplay(overiddenBy) or overiddenBy)}
			line:SetIcon(icon)
		end
	end
end

function PANEL:GetUsergroupDisplay(usergroup)
	--For use in user-restrictions
	return usergroup
end

function PANEL:ReloadSuggestions()
	self.list_suggestions:Clear()

	if (self.textbox_search:GetValue() ~= "") then
		self.list_suggestions:AddLine(self.textbox_search:GetValue())
	end

	for _, item in pairs(WUMA.GetAllLimits()) do
		if (item ~= self.textbox_search:GetValue()) then
			self.list_suggestions:AddLine(item)
		end
	end

	self.list_suggestions.VBar:SetScroll(0)
	self.list_suggestions:SelectFirstItem()
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

function PANEL:GetLimit()
	local limit = self.slider_limit:GetValue()
	if (self.slider_limit:GetDisabled()) then
		limit = self.textbox_advlimit:GetValue()
	end

	return limit
end

function PANEL:OnAdvLimitChanged(text)
	if (text ~= "") then
		self.slider_limit:SetDisabled(true)
	else
		self.slider_limit:SetDisabled(false)
	end

	if (text ~= "" and self.textbox_search:GetValue() ~= "" and text == self.textbox_search:GetValue() and text ~= self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) ~= nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
	end
end

function PANEL:OnSearch(text)
	self:ReloadSuggestions()

	for k, line in pairs(self.list_suggestions:GetLines()) do
		local item = line:GetValue(1)

		if not string.match(string.lower(item), string.lower(text)) then
			self.list_suggestions:RemoveLine(k)
		end
	end

	self.list_suggestions:SelectFirstItem()

	if (self.textbox_advlimit:GetValue() ~= "" and self.textbox_search:GetValue() ~= "" and self.textbox_advlimit:GetValue() == self.textbox_search:GetValue() and self.textbox_advlimit:GetValue() ~= self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) ~= nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
	end
end

function PANEL:OnItemSelected(_)
	self.button_delete:SetDisabled(false)
end

function PANEL:NotifyLimitsChanged(limits, parent, updated, deleted)
	if (limits ~= self.list_items:GetDataSources()[parent]) then
		self.list_items:AddDataSource(parent, limits)
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

	if self:GetUsergroups() then
		self:NotifyUsergroupsChanged(self:GetUsergroups())
	end

	self:ShowSelectedUsergroups()
end

--luacheck: push no unused args
function PANEL:OnItemChange(lineid, line)

end
--luacheck: pop

function PANEL:OnUsergroupsChanged()
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
	
	--[[
		Sequential array of arrays:
			1 - the group_id to show
			2 - title of the header for the group (or null to not show a header)
			3 - boolean that decides whether or not items in this group should be selectable or not (true: unselectable, nil or false: selectable)
	]]
	local groups = {}

	self.list_items:ClearPanels()

	if (#usergroups == 1) then
		local selected = usergroups[1]

		local header_function = function(limits)
			if (table.Count(limits) == 0) then
				return "No limits for " .. self:GetUsergroupDisplay(selected)
			else
				return "Limits for " .. self:GetUsergroupDisplay(selected)
			end
		end
		table.insert(groups, {selected, header_function})

		if self:GetInheritsFrom() and self:GetInheritsFrom()[selected] then
			for _, usergroup in ipairs(self:GetInheritsFrom()[selected]) do
				local header_function = function(limits)
					if (table.Count(limits) == 0) then
						return "No limits inherited from " .. self:GetUsergroupDisplay(usergroup)
					else
						return "Limits inherited from " .. self:GetUsergroupDisplay(usergroup)
					end
				end
				table.insert(groups, {usergroup, header_function, true})
			end
		end
	else
		for i, selected in ipairs(usergroups) do
			local header_function = function(limits)
				if (table.Count(limits) == 0) then
					return "No limits for " .. self:GetUsergroupDisplay(selected)
				else
					return "Limits for " .. self:GetUsergroupDisplay(selected)
				end
			end
			table.insert(groups, {selected, header_function})
		end

		self.list_items:AddPanel("Not showing inherited limits", BOTTOM)
	end

	self.list_items:Show(groups)
end

--luacheck: push no unused args
function PANEL:OnUsergroupSelected(usergroup)
	--For override
end
--luacheck: pop

function PANEL:OnAddClick()
	local usergroups = self:GetSelectedUsergroups()
	local suggestions = self:GetSelectedSuggestions()

	local limit = self:GetLimit()

	self:OnAddLimits(usergroups, suggestions, limit, false)
end

function PANEL:OnAddExclusiveClick()
	local usergroups = self:GetSelectedUsergroups()
	local suggestions = self:GetSelectedSuggestions()

	local limit = self:GetLimit()

	self:OnAddLimits(usergroups, suggestions, limit, true)
end

--luacheck: push no unused args
function PANEL:OnAddLimits(usergroups, suggestions, limit, is_exclusive)
	--For override
end
--luacheck: pop

function PANEL:OnDeleteClick()
	local selected_items = self.list_items:GetSelectedItems()
	if table.IsEmpty(selected_items) then return end

	local parents, items = {}, {}
	for _, item in pairs(selected_items) do
		parents[item:GetParent()] = true

		items[item:GetParent()] = items[item:GetParent()] or {}

		table.insert(items[item:GetParent()], item:GetItem())
	end

	for parent, _ in pairs(parents) do
		self:OnDeleteLimits(parent, items[parent])
	end
end

--luacheck: push no unused args
function PANEL:OnDeleteLimits(usergroups, items)
	--For override
end
--luacheck: pop

vgui.Register("WUMA_Limits", PANEL, 'DPanel');