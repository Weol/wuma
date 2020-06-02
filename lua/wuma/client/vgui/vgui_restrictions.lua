
local PANEL = {}

function PANEL:Init()

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
	self.list_usergroups.OnRowSelected = function(_, lineid, line) self:OnUsergroupChange(lineid, line) end

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = function() self:OnSearch(self.textbox_search:GetValue()) end

	--Delete button
	self.button_delete = vgui.Create("DButton", self)
	self.button_delete:SetText("Delete")
	self.button_delete.DoClick = function() self:OnDeleteClick() end

	--Add button
	self.button_add = vgui.Create("DButton", self)
	self.button_add:SetText("Add")
	self.button_add.DoClick = function() self:OnAddClick() end

	--Suggestion list
	self.list_suggestions = vgui.Create("DListView", self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)

	--Items list
	self.list_items = vgui.Create("WListView", self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Scope")
	self.list_items.OnRowSelected = function(_, id, line) self:OnItemSelected(id, line) end

	--Whitelist checkbox
	self.checkbox_whitelist = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_whitelist:SetText("This list is a whitelist")
	self.checkbox_whitelist:SetTextColor(Color(0, 0, 0))
	self.checkbox_whitelist:SetValue(false)
	self.checkbox_whitelist:SetVisible(false)
	self.checkbox_whitelist.OnChange = function() self:OnWhitelistCheckboxChanged(self.checkbox_whitelist:GetChecked()) end

	--All checkbox
	self.checkbox_restrictall = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_restrictall:SetTextColor(Color(0, 0, 0))
	self.checkbox_restrictall:SetValue(false)
	self.checkbox_restrictall:SetVisible(false)
	self.checkbox_restrictall.OnChange = function() self:OnRestrictAllCheckboxChanged(self.checkbox_restrictall:GetChecked()) end

	for _, type in pairs(WUMA.RestrictionTypes) do
		self.list_types:AddLine(type:GetPrint2())
	end
	self.list_types:SelectFirstItem()

	WUMA.Subscribe("usergroups", function(usergroups, added, deleted)
		list_usergroups:Clear()
		for _, usergroup in pairs(usergroups) do
			self.list_usergroups:AddLine(usergroup)
		end
		self.list_usergroups:SelectFirstItem()
	end)

end

function PANEL:PerformLayout()

	self.list_types:SetPos(5, 5)
	self.list_types:SizeToContents()
	self.list_types:SetWide(100)

	self.list_usergroups:SetPos(5, self.list_types.y+self.list_types:GetTall()+5)
	self.list_usergroups:SetSize(self.list_types:GetWide(), self:GetTall()-self.list_usergroups.y-5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos((self:GetWide()-5)-self.textbox_search:GetWide(), 5)

	self.button_delete:SetSize(self.textbox_search:GetWide(), 25)
	self.button_delete:SetPos(self.textbox_search.x,  (self:GetTall() - 5) - self.button_delete:GetTall())

	self.button_add:SetSize(self.textbox_search:GetWide(), 25)
	self.button_add:SetPos(self.button_delete.x, (self.button_delete.y - 5)-self.button_delete:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y+self.textbox_search:GetTall()+5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y-self.list_suggestions.y-5)

	self.list_items:SetPos(self.list_types.x+5+self.list_types:GetWide(), 5)
	self.list_items:SetSize(self.textbox_search.x-self.list_items.x-5, self:GetTall()-10)

	self.checkbox_whitelist:SetPos(self.list_items.x + 5, self.list_items.y+self.list_items:GetTall()+5)

	self.checkbox_restrictall:SetPos(self.checkbox_whitelist.x + self.checkbox_whitelist:GetWide() + 5, (self:GetTall() - 5 )-self.checkbox_restrictall:GetTall())

end

function PANEL:ReloadSuggestions(type)
	if self.list_suggestions then
		local items = RestrictionTypes[type]:GetItems()

		if not items then
			self.list_suggestions:SetDisabled(true)
			self.list_suggestions:Clear()
		else
			self.list_suggestions:SetDisabled(false)

			self:PopulateList("list_suggestions", items(), true)
		end
	end
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
			return {self.textbox_search:GetValue()}
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

			scope = {type=k, data=data}
			break
		end
	end

	return util.TableToJSON(scope)
end

function PANEL:OnSearch(text)

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
		table.insert(tbl, group..":::"..self:GetSelectedType())
	end
	self:GetDataView():Show(tbl)

	self.list_types.previous_line = lineid

end

function PANEL:OnUsergroupChange()
	local self = self:GetParent()

	local tbl = {}
	for _, group in pairs(self:GetSelectedUsergroups()) do
		table.insert(tbl, group..":::"..self:GetSelectedType())
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

	local data = {usergroups, type, 0, self:GetAntiSelected(), self:GetSelectedScope()}

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
	local data = {usergroups, type, suggestions, self:GetAntiSelected(), self:GetSelectedScope()}

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
		WUMA.SendCommand(self.Command.Delete, {v:GetUserGroup(), type, v:GetString()})
	end
end

function PANEL:OnEditClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if items and (table.Count(items) ~= 1) then return end

	local access = self.Command.Edit
	local data = {items[1]:GetUserGroup(), items[1]:GetType(), items[1]:GetString(), self:GetAntiSelected(), self:GetSelectedScope()}

	WUMA.SetProgress(self.Command.DataID, "Editing data", 0.2)

	WUMA.SendCommand(access, data, true)
end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleAdditionalOptionsVisiblility()
	self:GetParent():InvalidateLayout()
end

vgui.Register("WUMA_Restrictions", PANEL, 'DPanel');
