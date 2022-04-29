local PANEL = {}

PANEL.TabName = "Restrictions"
PANEL.TabIcon = "icon16/shield.png"

function PANEL:Init()

	self.Command = {}
	self.Command.Add = "restrict"
	self.Command.Delete = "unrestrict"
	self.Command.Edit = "restrict"
	self.Command.DataID = Restriction:GetID()

	--Restriction types list
	self.list_types = vgui.Create("DListView", self)
	self.list_types:SetMultiSelect(false)
	self.list_types:AddColumn("Types")
	self.list_types:SetSortable(false)
	self.list_types.OnRowSelected = self.OnTypeChange

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

	--Items list
	self.list_items = vgui.Create("WDataView", self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Scope")
	self.list_items.OnRowSelected = self.OnItemChange
	self.list_items.OnViewChanged = self.OnDataViewChanged

	--Progress bar
	self.progress = vgui.Create("WProgressBar", self)
	self.progress:SetVisible(false)
	WUMA.GUI.AddHook(WUMA.PROGRESSUPDATE, "WUMARestrictionsProgressUpdate", function(id, msg)
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

		local tbl = {}
		for _, group in pairs(self:GetSelectedUsergroups()) do
			table.insert(tbl, group .. ":::" .. self:GetSelectedType())
		end
		self:GetDataView():Show(tbl)
	end

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
	self.checkbox_allow = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_allow:SetText("Anti-Restriction")
	self.checkbox_allow:SetTextColor(Color(0, 0, 0))
	self.checkbox_allow:SetValue(false)
	self.checkbox_allow:SetVisible(false)

	--All checkbox
	self.checkbox_all = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_all:SetText("Restrict type")
	self.checkbox_all:SetTextColor(Color(0, 0, 0))
	self.checkbox_all:SetValue(false)
	self.checkbox_all:SetVisible(false)
	self.checkbox_all.OnChange = self.OnRestrictAllCheckboxChanged

	local display = function(data)
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end

		return { data.usergroup, data.print or data.string, scope or "Permanent" }, { table.KeyFromValue(WUMA.ServerGroups, data.usergroup) }
	end
	self:GetDataView():SetDisplayFunction(display)

	local group = function(data)
		return data:GetUserGroup() .. ":::" .. data:GetType()
	end
	self:GetDataView():SetSortFunction(group)

	local right_click = function(item)
		local tbl = {}
		tbl[1] = { "Item", item.string }
		tbl[2] = { "Usergroup", item.usergroup }
		tbl[3] = { "Type", item.type }
		tbl[4] = { "Scope", item.scope or "Permanent" }
		if item:GetAllow() then tbl[5] = { "Anti-Restriction" } end

		return tbl
	end
	self:GetDataView():SetRightClickFunction(right_click)

	self:PopulateList("list_types", Restriction:GetTypes("print"), true, true)
	self:PopulateList("list_usergroups", WUMA.ServerGroups, true, true)
	self:PopulateList("list_scopes", table.Add({ "Permanent" }, Scope:GetTypes("print")), true)
	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE, "WUMARestrictionsGUIUsergroupUpdateHook", function()
		self:PopulateList("list_usergroups", WUMA.ServerGroups, true, true)
	end)

	WUMA.GUI.AddHook(WUMA.MAPSUPDATE, "WUMARestrictionsGUIScopeMapsUpdateHook", function()
		self.map_chooser:AddOptions(WUMA.Maps)
	end)

end

function PANEL:PerformLayout()

	self.list_types:SetPos(5, 5)
	self.list_types:SizeToContents()
	self.list_types:SetWide(100)

	self.list_usergroups:SetPos(5, self.list_types.y + self.list_types:GetTall() + 5)
	self.list_usergroups:SetSize(self.list_types:GetWide(), self:GetTall() - self.list_usergroups.y - 5)

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

	self.progress:SetPos(self.list_usergroups.x + 5 + self.list_usergroups:GetWide(), 5)
	self.progress:SetWide(self.textbox_search.x - self.list_items.x - 5)
	if (self.progress:IsVisible()) then
		self.progress:SetTall(16)
	else
		self.progress:SetTall(0)
		self.progress.y = 0
	end

	self.list_items:SetPos(self.list_types.x + 5 + self.list_types:GetWide(), self.progress.y + self.progress:GetTall() + 5)

	if self:GetAdditonalOptionsVisibility() then
		self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10 - (#(self.list_scopes:GetLines() or {}) * 17 + self.list_scopes:GetHeaderHeight() + 1) - 25)
	else
		self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10)
	end

	self.checkbox_allow:SetPos(self.list_scopes.x, self.list_items.y + self.list_items:GetTall() + 5)

	self.checkbox_all:SetPos(self.checkbox_allow.x + self.checkbox_allow:GetWide() + 5, self.list_items.y + self.list_items:GetTall() + 5)

	self.list_scopes:SetPos(self.list_items.x, self.checkbox_allow.y + self.checkbox_allow:GetTall() + 5)
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

function PANEL:ReloadSuggestions(type)
	if not self.list_suggestions then return end
	local items = Restriction:GetTypes()[type].items

	if not items then
		self.list_suggestions:SetDisabled(true)
		self.list_suggestions:Clear()
	else
		self.list_suggestions:SetDisabled(false)

		self:PopulateList("list_suggestions", items(), true)
	end
end

function PANEL:OnDataViewChanged()
	self = self:GetParent()

	local old_onchange = self.checkbox_all.OnChange
	self.checkbox_all.OnChange = function() end

	self.checkbox_all:SetValue(false)
	for group, lns in pairs(self:GetDataView().DataRegistry) do
		for id, line in pairs(lns) do
			if self:GetDataView():GetDataTable()[id] and (self:GetDataView():GetDataTable()[id]:IsGeneral()) then
				self.checkbox_all:SetValue(true)
				self.checkbox_all.OnChange = old_onchange
				self:GetDataView():SetDisabled(true)

				return
			end
		end
	end

	self.checkbox_all:SetValue(false)
	self:GetDataView():SetDisabled(false)
	self.checkbox_all.OnChange = old_onchange

end

function PANEL:GetSelectedType()
	if not self.list_types:GetSelected()[1] then return false end
	for k, v in pairs(Restriction:GetTypes()) do
		if (v.print == self.list_types:GetSelected()[1]:GetValue(1)) then
			return k
		end
	end
end

function PANEL:GetSelectedSuggestions()
	if not self.list_suggestions:GetSelectedLine() then
		local typ = self:GetSelectedType()
		if not Restriction:GetTypes()[typ].items then
			return { self.textbox_search:GetValue() }
		else
			return {}
		end
	end
	local tbl = {}
	for _, v in pairs(self.list_suggestions:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end

	return tbl
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

function PANEL:GetAntiSelected()
	if self.checkbox_allow:GetChecked() then
		return 1
	else
		return 0
	end
end

function PANEL:GetAdditonalOptionsVisibility()
	return self.additionaloptionsvisibility
end

function PANEL:ToggleAdditionalOptionsVisiblility()
	if self.additionaloptionsvisibility then
		self.additionaloptionsvisibility = false

		self.list_scopes:SetVisible(false)
		self.checkbox_allow:SetVisible(false)
		self.checkbox_all:SetVisible(false)
	else
		self.additionaloptionsvisibility = true

		self.list_scopes:SetVisible(true)
		self.checkbox_allow:SetVisible(true)
		self.checkbox_all:SetVisible(true)
	end
end

function PANEL:OnSearch()

	local self = self:GetParent()

	local text = self.textbox_search:GetValue()

	if (text ~= "") then

		self:ReloadSuggestions(self:GetSelectedType())

		for k, line in pairs(self.list_suggestions:GetLines()) do
			local item = line:GetValue(1)
			if not string.match(string.lower(item), string.lower(text)) then
				self.list_suggestions:RemoveLine(k)
			end
		end

		self.list_suggestions:SetDisabled((table.Count(self.list_suggestions:GetLines()) == 0))
	elseif (text == "") then
		self:ReloadSuggestions(self:GetSelectedType())
	end

end

function PANEL:OnItemChange(lineid, line)

end

function PANEL:OnTypeChange(lineid, line)

	local self = self:GetParent()

	if (self.list_types.previous_line == lineid) then return end

	if not self.textbox_search then return end

	self:ReloadSuggestions(self:GetSelectedType())

	self.textbox_search.default = Restriction:GetTypes()[self:GetSelectedType()].search
	self.textbox_search:SetText("")
	self.textbox_search:OnLoseFocus()

	self.list_suggestions.VBar:SetScroll(0)
	self.list_suggestions:SelectFirstItem()

	local tbl = {}
	for _, group in pairs(self:GetSelectedUsergroups()) do
		table.insert(tbl, group .. ":::" .. self:GetSelectedType())
	end
	self:GetDataView():Show(tbl)

	self.list_types.previous_line = lineid

end

function PANEL:OnUsergroupChange()
	local self = self:GetParent()

	local tbl = {}
	for _, group in pairs(self:GetSelectedUsergroups()) do
		table.insert(tbl, group .. ":::" .. self:GetSelectedType())
	end

	self:GetDataView():Show(tbl)
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

function PANEL:OnRestrictAllCheckboxChanged(checked)
	self = self:GetParent()

	local access = self.Command.Delete
	if checked then
		access = self.Command.Add
	end

	if not self:GetSelectedUsergroups() then return end
	if not self:GetSelectedType() then return end

	local usergroups = self:GetSelectedUsergroups()
	if table.Count(usergroups) == 1 then usergroups = usergroups[1] end

	local type = self:GetSelectedType()

	local data = { usergroups, type, 0, self:GetAntiSelected(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Adding data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnAddClick()
	self = self:GetParent()
	if not self:GetSelectedType() then return end
	if (table.Count(self:GetSelectedUsergroups()) < 1) then return end

	local usergroups = self:GetSelectedUsergroups()
	if table.Count(usergroups) == 1 then usergroups = usergroups[1] end

	local suggestions = self:GetSelectedSuggestions()
	if (table.Count(suggestions) == 1) then
		suggestions = suggestions[1]
	elseif (table.Count(suggestions) == 0) then
		suggestions = self.textbox_search:GetValue()
	end

	local type = self:GetSelectedType()

	local access = self.Command.Add
	local data = { usergroups, type, suggestions, self:GetAntiSelected(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Adding data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) < 1) then return end

	local type = self:GetSelectedType()

	WUMA.SetProgress(self.Command.DataID, "Deleting data", 0.2)

	for _, v in pairs(items) do
		WUMA.SendCommand(self.Command.Delete, { v:GetUserGroup(), type, v:GetString() })
	end
end

function PANEL:OnEditClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if items and (table.Count(items) ~= 1) then return end

	local access = self.Command.Edit
	local data = { items[1]:GetUserGroup(), items[1]:GetType(), items[1]:GetString(), self:GetAntiSelected(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Editing data", 0.2)

	WUMA.SendCommand(access, data, true)
end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleAdditionalOptionsVisiblility()
	self:GetParent():InvalidateLayout()
end

vgui.Register("WUMA_Restrictions", PANEL, 'DPanel');
