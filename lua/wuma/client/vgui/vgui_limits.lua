local PANEL = {}

PANEL.TabName = "Limits"
PANEL.TabIcon = "icon16/table.png"

function PANEL:Init()

	self.Command = {}
	self.Command.Add = "setlimit"
	self.Command.Delete = "unsetlimit"
	self.Command.Edit = "setlimit"
	self.Command.DataID = Limit:GetID()

	--Limit chooser
	self.slider_limit = vgui.Create("WSlider", self)
	self.slider_limit:SetMinMax(1, 300)
	self.slider_limit:SetText("Limit")
	self.slider_limit:SetMaxOverride(-1, "∞")

	--Adv. Limit textbox
	self.textbox_advlimit = vgui.Create("WTextbox", self)
	self.textbox_advlimit:SetDefault("Adv. Limit")
	self.textbox_advlimit.OnChange = self.OnAdvLimitChanged

	--Usergroups list
	self.list_usergroups = vgui.Create("DListView", self)
	self.list_usergroups:SetMultiSelect(true)
	self.list_usergroups:AddColumn("Usergroups")
	self.list_usergroups.OnRowSelected = self.OnUsergroupChange

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = self.OnSearch

	--Settings button
	self.button_settings = vgui.Create("DButton", self)
	self.button_settings:SetIcon("icon16/cog.png")
	self.button_settings.DoClick = self.OnSettingsClick

	--Edit button
	self.button_edit = vgui.Create("DButton", self)
	self.button_edit:SetText("Edit")
	self.button_edit.DoClick = self.OnEditClick

	--Delete button
	self.button_delete = vgui.Create("DButton", self)
	self.button_delete:SetText("Delete")
	self.button_delete.DoClick = self.OnDeleteClick

	--Add button
	self.button_add = vgui.Create("DButton", self)
	self.button_add:SetText("Add")
	self.button_add.DoClick = self.OnAddClick

	--Suggestion list
	self.list_suggestions = vgui.Create("DListView", self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)
	self.list_suggestions.OnRowRightClick = function(panel)
		panel:ClearSelection()
	end

	--Items list
	self.list_items = vgui.Create("WDataView", self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Limit")
	self.list_items:AddColumn("Scope")
	self.list_items.OnRowSelected = self.OnItemChange

	--Progress bar
	self.progress = vgui.Create("WProgressBar", self)
	self.progress:SetVisible(false)
	WUMA.GUI.AddHook(WUMA.PROGRESSUPDATE, "WUMALimitsProgressUpdate", function(id, msg)
		if (id ~= self.Command.DataID) then return end
		if msg and not self.progress:IsVisible() then
			self.progress:SetVisible(true)
			self:PerformLayout()
		elseif not msg then
			self.progress:SetVisible(false)
			self:PerformLayout()
		end

		self.progress:SetText(msg or "")
	end)
	self.list_items.OnDataUpdate = function()
		hook.Call(WUMA.PROGRESSUPDATE, nil, self.Command.DataID, nil)

		self:GetDataView():Show(self:GetSelectedUsergroups())
	end

	local highlight = function(line, data, datav)
		if (tonumber(datav[3]) == nil) then
			local id = Limit.GenerateID(Limit, datav.usergroup, datav.string)
			local id_p = Limit.GenerateID(Limit, nil, datav.string)
			if not self:GetDataView():GetDataTable()[id] and not self:GetDataView():GetDataTable()[id_p] then return Color(255, 0, 0, 120); else return nil end
		end
	end
	self:GetDataView():SetHighlightFunction(highlight)

	--Scope list
	self.list_scopes = vgui.Create("DListView", self)
	self.list_scopes:SetMultiSelect(true)
	self.list_scopes:AddColumn("Scope")
	self.list_scopes:SetMultiSelect(false)
	self.list_scopes.OnRowSelected = self.OnScopeChange

	--date_chooser list
	self.date_chooser = vgui.Create("WDatePicker", self)
	self.date_chooser:SetVisible(false)

	--time_chooser list
	self.time_chooser = vgui.Create("WDurationSlider", self)
	self.time_chooser:SetVisible(false)

	--map_chooser
	self.map_chooser = vgui.Create("WMapPicker", self)
	self.map_chooser:SetVisible(false)

	--Allow checkbox
	self.checkbox_exclusive = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_exclusive:SetText("Exclusive limit")
	self.checkbox_exclusive:SetTextColor(Color(0, 0, 0))
	self.checkbox_exclusive:SetValue(false)
	self.checkbox_exclusive:SetVisible(false)

	local display = function(data)
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end

		local limit_sort = tonumber(data.limit) or -1

		local limit = data.limit
		if ((tonumber(limit) or 0) < 0) then limit = "∞" end

		return { data.usergroup, data.print or data.string, limit, scope }, { table.KeyFromValue(WUMA.ServerGroups, data.usergroup), nil, limit_sort, 0 }
	end
	self:GetDataView():SetDisplayFunction(display)

	local sort = function(data)
		return data:GetUserGroup()
	end
	self:GetDataView():SetSortFunction(sort)

	local right_click = function(item)
		local tbl = {}
		tbl[1] = { "Item", item:GetString() }
		tbl[2] = { "Usergroup", item:GetUserGroup() }
		tbl[3] = { "Limit", item:Get() }
		tbl[5] = { "Scope", item:GetScope() or "Permanent" }
		if item:IsExclusive() then tbl[5] = { "Exlusive" } else tbl[5] = { "Inclusive" } end

		return tbl
	end
	self:GetDataView():SetRightClickFunction(right_click)

	self:PopulateList("list_usergroups", WUMA.ServerGroups, true, true)
	self:PopulateList("list_scopes", table.Add({ "Permanent" }, Scope:GetTypes("print")), true)
	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE, "WUMARestrictionsGUIUsergroupUpdateHook2", function()
		self:PopulateList("list_usergroups", WUMA.ServerGroups, true, true)
	end)

	WUMA.GUI.AddHook(WUMA.MAPSUPDATE, "WUMALimitsGUIScopeMapsUpdateHook", function()
		self.map_chooser:AddOptions(WUMA.Maps)
	end)

	WUMA.GUI.AddHook(WUMA.CVARLIMITSUPDATE, "WUMALimitsGUILimitsUpdateHook", function()
		self.cachedSuggestions = nil
		self:ReloadSuggestions()
	end)

	self:ReloadSuggestions()

end

function PANEL:PerformLayout()

	self.slider_limit:SetPos(5, 5)
	self.slider_limit:SetDecimals(0)
	self.slider_limit:SetSize(100, 40)

	self.textbox_advlimit:SetPos(5, self.slider_limit.y + self.slider_limit:GetTall() + 5)
	self.textbox_advlimit:SetSize(self.slider_limit:GetWide(), 20)

	self.list_usergroups:SetPos(5, self.textbox_advlimit.y + self.textbox_advlimit:GetTall() + 5)
	self.list_usergroups:SetSize(self.slider_limit:GetWide(), self:GetTall() - self.list_usergroups.y - 5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos((self:GetWide() - 5) - self.textbox_search:GetWide(), 5)

	self.button_settings:SetSize(25, 25)
	self.button_settings:SetPos((self:GetWide() - 5) - self.button_settings:GetWide(), (self:GetTall() - 5) - self.button_settings:GetTall())

	self.button_edit:SetSize(self.textbox_search:GetWide() - (self.button_settings:GetWide() + 5), 25)
	self.button_edit:SetPos((self.button_settings.x - 10) - self.button_edit:GetWide() + 5, self.button_settings.y)

	self.button_delete:SetSize(self.textbox_search:GetWide(), 25)
	self.button_delete:SetPos(self.button_edit.x, (self.button_edit.y - 5) - self.button_delete:GetTall())

	self.button_add:SetSize(self.textbox_search:GetWide(), 25)
	self.button_add:SetPos(self.button_delete.x, (self.button_delete.y - 5) - self.button_delete:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y + self.textbox_search:GetTall() + 5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y - self.list_suggestions.y - 5)

	self.progress:SetPos(self.slider_limit.x + 5 + self.slider_limit:GetWide(), 5)
	self.progress:SetWide(self.textbox_search.x - self.list_items.x - 5)
	if (self.progress:IsVisible()) then
		self.progress:SetTall(16)
	else
		self.progress:SetTall(0)
		self.progress.y = 0
	end

	self.list_items:SetPos(self.slider_limit.x + 5 + self.slider_limit:GetWide(), self.progress.y + self.progress:GetTall() + 5)

	if self:GetAdditonalOptionsVisibility() then
		self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10 - (#(self.list_scopes:GetLines() or {}) * 17 + self.list_scopes:GetHeaderHeight() + 1) - 25)
	else
		self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10)
	end

	self.checkbox_exclusive:SetPos(self.list_scopes.x, self.list_items.y + self.list_items:GetTall() + 5)

	self.list_scopes:SetPos(self.list_items.x, self.checkbox_exclusive.y + self.checkbox_exclusive:GetTall() + 5)
	self.list_scopes:SizeToContents()
	self.list_scopes:SetWide(120)

	self.date_chooser:SetPos(self.list_scopes.x + 5 + self.list_scopes:GetWide(), self.list_scopes.y)

	self.time_chooser:SetPos(self.list_scopes.x + 5 + self.list_scopes:GetWide(), self.list_scopes.y)
	self.time_chooser:SetSize(120, 40)

	self.map_chooser:SetPos(self.list_scopes.x + 5 + self.list_scopes:GetWide(), self.list_scopes.y)

end

function PANEL:GetDataView()
	return self.list_items
end

function PANEL:PopulateList(key, tbl, clear, select)
	local listview = self[key]

	if clear then
		listview:Clear()
	end

	for k, v in pairs(tbl) do
		listview:AddLine(v)
	end

	if select then
		listview:SelectFirstItem()
	end
end

function PANEL:ReloadSuggestions()
	if not self.list_suggestions then return end

	local tbl = WUMA.GetAllItems()
	for k, v in pairs(WUMA.CVarLimits) do
		tbl[v] = v
	end

	local exists = {}

	for key, item in pairs(tbl) do
		if not exists[item] then
			--Adding exceptions for wire entities, they never use entity class to check limits, so its useless to have them in menu
			if string.match(item, "gmod_wire") then
				tbl[key] = nil
			elseif (string.sub(item, 1, 5) == "gmod_") then
				local str = string.sub(item, 6)

				if table.HasValue(tbl, str .. "s") then
					tbl[key] = nil
				end
			elseif table.HasValue(tbl, item .. "s") then
				tbl[key] = nil
			end

			exists[item] = 1
		end
	end

	local exists = {}
	for key, item in pairs(tbl) do
		local str = item
		if not isstring(item) then
			str = item:GetString()
		end

		if exists[str] then
			tbl[key] = nil
		else
			exists[str] = 1
		end
	end

	self:PopulateList("list_suggestions", tbl, true)

	self.list_suggestions.VBar:SetScroll(0)
end

function PANEL:GetSelectedSuggestions()
	if not self.list_suggestions:GetSelected() or (table.Count(self.list_suggestions:GetSelected()) < 1) then
		if (self.textbox_search:GetValue() ~= "" and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) then
			return { self.textbox_search:GetValue() }
		end
	else
		local tbl = {}
		for _, v in pairs(self.list_suggestions:GetSelected()) do
			table.insert(tbl, v:GetColumnText(1))
		end
		return tbl
	end
	return { false }
end

function PANEL:GetSelectedUsergroups()
	if not self.list_usergroups:GetSelected() then return false end

	local tbl = {}
	for _, v in pairs(self.list_usergroups:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end

	return tbl
end

function PANEL:GetSelectedScope()
	if not self or not self.list_scopes or not self.list_scopes:GetSelected() or (table.Count(self.list_scopes:GetSelected()) < 1) then return nil end

	local selected = self.list_scopes:GetSelected()[1]:GetValue(1)
	local scope = nil

	if (selected == "Permanent") then return nil end

	for k, v in pairs(Scope:GetTypes()) do
		if (v.print == selected) then
			local data = false
			if v.parts then
				if not self[v.parts[1]]:GetArgument() then return nil end

				data = self[v.parts[1]]:GetArgument()

				if v.processdata then data = v.processdata(data) end
			end

			scope = { type = k, data = data }
			break
		end
	end

	return util.TableToJSON(scope)
end

function PANEL:GetIsExclusive()
	if self.checkbox_exclusive:GetChecked() then
		return 1
	else
		return 0
	end
end

function PANEL:GetLimit()
	if not self.slider_limit or not self.textbox_advlimit then return nil end

	local limit = self.slider_limit:GetValue()
	if (self.slider_limit:GetDisabled()) then
		limit = self.textbox_advlimit:GetValue()
	end

	return limit
end

function PANEL:GetAdditonalOptionsVisibility()
	return self.additionaloptionsvisibility
end

function PANEL:ToggleAdditionalOptionsVisiblility()
	if self.additionaloptionsvisibility then
		self.additionaloptionsvisibility = false

		self.list_scopes:SetVisible(false)
		self.checkbox_exclusive:SetVisible(false)
	else
		self.additionaloptionsvisibility = true

		self.list_scopes:SetVisible(true)
		self.checkbox_exclusive:SetVisible(true)
	end
end

function PANEL:OnAdvLimitChanged()
	self = self:GetParent()
	if (self.textbox_advlimit:GetValue() ~= "") then
		self.slider_limit:SetDisabled(true)
	else
		self.slider_limit:SetDisabled(false)
	end

	if (self.textbox_advlimit:GetValue() ~= "" and self.textbox_search:GetValue() ~= "" and self.textbox_advlimit:GetValue() == self.textbox_search:GetValue() and self.textbox_advlimit:GetValue() ~= self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) ~= nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
	end
end

function PANEL:OnSearch()

	local self = self:GetParent()
	local text = self.textbox_search:GetValue()

	self:ReloadSuggestions()

	for k, line in pairs(self.list_suggestions:GetLines()) do
		local item = line:GetValue(1)

		if not string.match(string.lower(item), string.lower(text)) then
			self.list_suggestions:RemoveLine(k)
		end
	end

	if (table.Count(self.list_suggestions:GetLines()) < 1) then
		self.list_suggestions:SetDisabled(true)
	else
		self.list_suggestions:SetDisabled(false)
	end

	if (self.textbox_advlimit:GetValue() ~= "" and self.textbox_search:GetValue() ~= "" and self.textbox_advlimit:GetValue() == self.textbox_search:GetValue() and self.textbox_advlimit:GetValue() ~= self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) ~= nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
	end

end

function PANEL:OnItemChange(lineid, line)

end

function PANEL:OnUsergroupChange()
	local self = self:GetParent()

	self:GetDataView():Show(self:GetSelectedUsergroups())
end

function PANEL:OnScopeChange(lineid, line)

	if (self:GetParent().list_scopes.previous_line == lineid) then return end

	local self = self:GetParent()
	local scope = self.list_scopes

	for _, parts in pairs(Scope:GetTypes("parts")) do
		for _, part_name in pairs(parts) do
			if self[part_name] then
				self[part_name]:SetVisible(false)
			end
		end
	end

	for _, tbl in pairs(Scope:GetTypes()) do
		if tbl.parts and (tbl.print == scope:GetSelected()[1]:GetValue(1)) then
			for _, part_name in pairs(tbl.parts) do
				if self[part_name] then
					local part = self[part_name]
					part:SetVisible(true)
				end
			end
		end
	end

	scope.previous_line = lineid
end

function PANEL:OnAddClick()
	self = self:GetParent()
	if (table.Count(self:GetSelectedUsergroups()) < 1) then return end
	if (table.Count(self:GetSelectedSuggestions()) < 1) then return end

	local usergroups = self:GetSelectedUsergroups()
	local suggestions = self:GetSelectedSuggestions()

	local access = self.Command.Add
	local data = { usergroups, suggestions, self:GetLimit(), self:GetIsExclusive(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Adding data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) < 1) then return end

	WUMA.SetProgress(self.Command.DataID, "Deleting data", 0.2)

	for _, v in pairs(items) do
		WUMA.SendCommand(self.Command.Delete, { v:GetUserGroup(), v:GetString() })
	end
end

function PANEL:OnEditClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) ~= 1) then return end

	local usergroup = { items[1]:GetUserGroup() }
	local string = { items[1]:GetString() }

	if (string == self:GetLimit()) then
		return
	end

	local access = self.Command.Edit
	local data = { usergroup, string, self:GetLimit(), self:GetIsExclusive(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Editing data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleAdditionalOptionsVisiblility()
	self:GetParent():InvalidateLayout()
end

vgui.Register("WUMA_Limits", PANEL, 'DPanel');
