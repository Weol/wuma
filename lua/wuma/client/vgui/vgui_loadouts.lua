local PANEL = {}

PANEL.TabName = "Loadouts"
PANEL.TabIcon = "icon16/bomb.png"

function PANEL:Init()

	self.Command = {}
	self.Command.Add = "addloadout"
	self.Command.Delete = "removeloadout"
	self.Command.Edit = "addloadout"
	self.Command.Primary = "setprimaryweapon"
	self.Command.Clear = "clearloadout"
	self.Command.Enforce = "setenforceloadout"
	self.Command.DataID = Loadout:GetID()

	--Primary ammo chooser
	self.slider_primary = vgui.Create("WSlider", self)
	self.slider_primary:SetMinMax(-1, 400)
	self.slider_primary:SetText("Primary")
	self.slider_primary:SetDecimals(0)
	self.slider_primary:SetMinOverride(-1, "def")

	--Secondary ammo chooser
	self.slider_secondary = vgui.Create("WSlider", self)
	self.slider_secondary:SetMinMax(-1, 400)
	self.slider_secondary:SetText("Secondary")
	self.slider_secondary:SetDecimals(0)
	self.slider_secondary:SetMinOverride(-1, "def")

	--Set as button
	self.button_setas = vgui.Create("DButton", self)
	self.button_setas:SetText("Set as..")
	self.button_setas.DoClick = self.OnSetAsClick

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

	--Primary button
	self.button_primary = vgui.Create("DButton", self)
	self.button_primary:SetText("Set Primary")
	self.button_primary.DoClick = self.OnPrimaryClick

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
	self.list_items:AddColumn("Weapon")
	self.list_items:AddColumn("Primary")
	self.list_items:AddColumn("Secondary")
	self.list_items:AddColumn("Scope")
	self.list_items.OnRowSelected = self.OnItemChange
	self.list_items.OnViewChanged = self.OnViewChanged

	local highlight = function(line, data, datav)
		if datav:GetParent():GetPrimary() and datav:GetParent():GetPrimary() == datav:GetClass() then return Color(0, 255, 0, 120) else return nil end
	end
	self.list_items:SetHighlightFunction(highlight)

	--Progress bar
	self.progress = vgui.Create("WProgressBar", self)
	self.progress:SetVisible(false)
	WUMA.GUI.AddHook(WUMA.PROGRESSUPDATE, "WUMALoadoutsProgressUpdate", function(id, msg)
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
	self.checkbox_ignore = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_ignore:SetText("Ignore Restrictions")
	self.checkbox_ignore:SetTextColor(Color(0, 0, 0))
	self.checkbox_ignore:SetValue(true)
	self.checkbox_ignore:SetVisible(false)

	--Enforce checkbox
	self.checkbox_enforce = vgui.Create("DCheckBoxLabel", self)
	self.checkbox_enforce:SetText("Enforce loadout")
	self.checkbox_enforce:SetTextColor(Color(0, 0, 0))
	self.checkbox_enforce:SetValue(true)
	self.checkbox_enforce:SetEnabled(false)
	self.checkbox_enforce:SetVisible(false)
	self.checkbox_enforce.OnChange = self.OnEnforcelCheckboxChanged

	local display = function(data)
		local scope = "Permanent"
		if data.scope then scope = data.scope end

		local primary = data.primary or -1
		if (tonumber(primary) < 0) then primary = "def" end

		local secondary = data.secondary or -1
		if (tonumber(secondary) < 0) then secondary = "def" end

		return { data.usergroup, data.class, primary, secondary, scope }, { table.KeyFromValue(WUMA.ServerGroups, data.usergroup), nil, data.primary, data.secondary }
	end
	self:GetDataView():SetDisplayFunction(display)

	local sort = function(data)
		return data.usergroup
	end
	self:GetDataView():SetSortFunction(sort)

	self:PopulateList("list_usergroups", WUMA.ServerGroups, true, true)
	self:PopulateList("list_scopes", table.Add({ "Permanent" }, Scope:GetTypes("print")), true)
	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE, "WUMARestrictionsGUIUsergroupUpdateHook3", function()
		self:PopulateList("list_usergroups", WUMA.ServerGroups, true, true)
	end)

	WUMA.GUI.AddHook(WUMA.MAPSUPDATE, "WUMALoadoutsGUIScopeMapsUpdateHook", function()
		self.map_chooser:AddOptions(WUMA.Maps)
	end)

	self:ReloadSuggestions()

end

function PANEL:PerformLayout()

	self.slider_primary:SetPos(5, 5)
	self.slider_primary:SetSize(100, 40)

	self.slider_secondary:SetPos(5, self.slider_primary.y + self.slider_primary:GetTall() + 5)
	self.slider_secondary:SetSize(self.slider_primary:GetWide(), 40)

	self.button_setas:SetSize(self.slider_primary:GetWide(), 25)
	self.button_setas:SetPos(5, self:GetTall() - self.button_setas:GetTall() - 5)

	self.list_usergroups:SetPos(5, self.slider_secondary.y + self.slider_secondary:GetTall() + 5)
	self.list_usergroups:SetSize(self.slider_primary:GetWide(), self.button_setas.y - self.list_usergroups.y - 5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos((self:GetWide() - 5) - self.textbox_search:GetWide(), 5)

	self.button_settings:SetSize(25, 25)
	self.button_settings:SetPos((self:GetWide() - 5) - self.button_settings:GetWide(), (self:GetTall() - 5) - self.button_settings:GetTall())

	self.button_primary:SetSize(self.textbox_search:GetWide() - (self.button_settings:GetWide() + 5), 25)
	self.button_primary:SetPos((self.button_settings.x - 10) - self.button_primary:GetWide() + 5, self.button_settings.y)

	self.button_edit:SetSize(self.textbox_search:GetWide(), 25)
	self.button_edit:SetPos(self.button_primary.x, (self.button_primary.y - 5) - self.button_delete:GetTall())

	self.button_add:SetSize(self.textbox_search:GetWide() / 2 - 3, 25)
	self.button_add:SetPos(self.button_edit.x, (self.button_edit.y - 5) - self.button_edit:GetTall())

	self.button_delete:SetSize(self.textbox_search:GetWide() / 2 - 3, 25)
	self.button_delete:SetPos(self.button_add.x + self.button_add:GetWide() + 6, (self.button_edit.y - 5) - self.button_edit:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y + self.textbox_search:GetTall() + 5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y - self.list_suggestions.y - 5)

	self.progress:SetPos(self.slider_primary.x + 5 + self.slider_primary:GetWide(), 5)
	self.progress:SetWide(self.textbox_search.x - self.list_items.x - 5)
	if (self.progress:IsVisible()) then
		self.progress:SetTall(16)
	else
		self.progress:SetTall(0)
		self.progress.y = 0
	end

	self.list_items:SetPos(self.slider_primary.x + 5 + self.slider_primary:GetWide(), self.progress.y + self.progress:GetTall() + 5)

	if self:GetAdditonalOptionsVisibility() then
		self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10 - (#(self.list_scopes:GetLines() or {}) * 17 + self.list_scopes:GetHeaderHeight() + 1) - 25)
	else
		self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10)
	end

	self.checkbox_ignore:SetPos(self.list_items.x, self.list_items.y + self.list_items:GetTall() + 5)

	self.checkbox_enforce:SetPos(self.checkbox_ignore.x + 5 + self.checkbox_ignore:GetWide(), self.list_items.y + self.list_items:GetTall() + 5)

	self.list_scopes:SetPos(self.checkbox_ignore.x, self.checkbox_ignore.y + self.checkbox_ignore:GetTall() + 5)
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

	self:PopulateList("list_suggestions", WUMA.GetWeapons(), true)

	self.list_suggestions.VBar:SetScroll(0)
end

function PANEL:GetSelectedSuggestions()
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

function PANEL:GetPrimaryAmmo()
	if not self.slider_primary then return nil end

	return self.slider_primary:GetValue()
end

function PANEL:GetSecondaryAmmo()
	if not self.slider_secondary then return nil end

	return self.slider_secondary:GetValue()
end

function PANEL:GetRespectsRestrictions()
	if self.checkbox_ignore:GetChecked() then
		return 0
	else
		return 1
	end
end

function PANEL:GetAdditonalOptionsVisibility()
	return self.additionaloptionsvisibility
end

function PANEL:ToggleAdditionalOptionsVisiblility()
	if self.additionaloptionsvisibility then
		self.additionaloptionsvisibility = false

		self.list_scopes:SetVisible(false)
		self.checkbox_ignore:SetVisible(false)
		self.checkbox_enforce:SetVisible(false)
	else
		self.additionaloptionsvisibility = true

		self.list_scopes:SetVisible(true)
		self.checkbox_ignore:SetVisible(true)
		self.checkbox_enforce:SetVisible(true)
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

end

function PANEL:GetCurrentLoadout()
	return WUMA.Loadouts[self:GetSelectedUsergroups()[1]]
end

function PANEL:OnItemChange(lineid, line)

end

function PANEL:OnViewChanged()
	self = self:GetParent()

	if (table.Count(self:GetDataView():GetLines()) > 0) then
		self.checkbox_enforce:SetDisabled(false)
		local loadout = self:GetCurrentLoadout()
		if loadout then
			local enforce = loadout:GetEnforce()

			local onchange = self.checkbox_enforce.OnChange
			self.checkbox_enforce.OnChange = function() end
			self.checkbox_enforce:SetValue(enforce)
			self.checkbox_enforce.OnChange = onchange
		end
	else
		local onchange = self.checkbox_enforce.OnChange
		self.checkbox_enforce.OnChange = function() end
		self.checkbox_enforce:SetValue(true)
		self.checkbox_enforce:SetDisabled(true)
		self.checkbox_enforce.OnChange = onchange
	end
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

function PANEL:OnEnforcelCheckboxChanged(checked)
	self = self:GetParent()

	local access = self.Command.Enforce

	local usergroups = self:GetSelectedUsergroups()
	if table.Count(usergroups) == 1 then usergroups = usergroups[1] end

	if checked then checked = 1 else checked = 0 end

	local data = { usergroups, checked }

	--WUMA.SetProgress(self.Command.DataID, "Changing data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnPrimaryClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) ~= 1) then return end

	local usergroup = { items[1].usergroup }
	local str = { items[1].class }

	local access = self.Command.Primary
	local data = { usergroup, str }

	WUMA.SetProgress(self.Command.DataID, "Setting primary", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnSetAsClick()
	local self_loadout = self:GetParent()

	local items = self_loadout:GetSelectedUsergroups()
	if (table.Count(items) ~= 1) then return end

	local frame = vgui.Create("DFrame")
	frame:SetSize(300, 200)
	frame:SetPos(ScrW() / 2 - frame:GetWide() / 2, ScrH() / 2 - frame:GetTall() / 2)
	frame:SetTitle("Set as...")
	frame:SetDeleteOnClose(true)

	frame.Paint = function(panel, w, h)
		draw.RoundedBox(5, 0, 0, w, h, Color(59, 59, 59, 255))
		draw.RoundedBox(5, 1, 1, w - 2, h - 2, Color(226, 226, 226, 255))

		draw.RoundedBox(5, 1, 1, w - 2, 25 - 1, Color(163, 165, 169, 255))
		surface.SetDrawColor(Color(163, 165, 169, 255))
		surface.DrawRect(1, 10, w - 2, 15)

		surface.SetFont("DermaDefault")
		surface.SetTextColor(0, 0, 0, 255)

		local line1, line2, line3 = "This will remove current loadout for the selected group(s)", "and replace it with the selected player's", "loadout on this menu."

		local w, h = surface.GetTextSize(line1)
		surface.SetTextPos(frame:GetWide() / 2 - w / 2, 25)
		surface.DrawText(line1)

		local w, h = surface.GetTextSize(line2)
		surface.SetTextPos(frame:GetWide() / 2 - w / 2, 25 + h + 3)
		surface.DrawText(line2)

		local w, h = surface.GetTextSize(line3)
		surface.SetTextPos(frame:GetWide() / 2 - w / 2, 25 + h * 2 + 3 * 2)
		surface.DrawText(line3)

	end

	frame.OnLoseFocus = function()
		frame:Close()
	end

	local textbox = vgui.Create("WTextbox", self)
	textbox:SetDefault("Search..")
	textbox:SetSize(130, 25)
	textbox:SetPos(5, frame:GetTall() - textbox:GetTall() - 5)

	local listview = vgui.Create("DListView", frame)
	listview:SetPos(5, 75)
	listview:SetSize(frame:GetWide() - 10, (frame:GetTall() - textbox:GetTall() - 5) - 75 - 5)
	listview:SetMultiSelect(false)
	listview:AddColumn("Player")
	listview:AddColumn("Usergroup")

	local function populatePlayerList()
		listview:Clear()

		if not WUMA.ServerUsers then return end

		local usergroups_reverse = table.Reverse(WUMA.ServerGroups)
		for k, user in pairs(WUMA.ServerUsers) do
			local line = listview:AddLine(user.nick, user.usergroup)
			line:SetSortValue(2, usergroups_reverse[user.usergroup] or -1)
			line:SetSortValue(1, k)
		end

		listview:SortByColumn(2)
	end

	WUMA.GUI.AddHook(WUMA.SERVERUSERSUPDATE, "WUMAGUILoudoutSetAsHook", populatePlayerList())

	frame.OnClose = function()
		hook.Remove("WUMAGUILoudoutSetAsHook")
	end
	populatePlayerList()

	local button = vgui.Create("DButton", frame)
	button:SetSize(100, 25)
	button:SetPos(frame:GetWide() - button:GetWide() - 5, frame:GetTall() - textbox:GetTall() - 5)
	button:SetText("Set")

	textbox.OnChange = function()
		populatePlayerList()
		for k, v in pairs(listview:GetLines()) do
			local text = textbox:GetValue()
			local item = v:GetValue(1)
			if not string.match(item, text) then
				listview:RemoveLine(k)
			end
		end
	end

	button.DoClick = function()
		if not listview:GetSelectedLine() then return end

		--Clear old loadout
		WUMA.SendCommand(self_loadout.Command.Clear, self_loadout:GetSelectedUsergroups())

		--Add new loadout
		local ply = WUMA.ServerUsers[listview:GetLines()[listview:GetSelectedLine()]:GetSortValue(1)].ent
		if not IsValid(ply) then return end

		WUMA.SetProgress(self_loadout.Command.DataID, "Adding data", 0.2)

		local weapons = {}
		local active_wep = ply:GetActiveWeapon()
		for k, v in pairs(ply:GetWeapons()) do
			local primary = ply:GetAmmoCount(v:GetPrimaryAmmoType()) + v:Clip1() or 0
			local secondary = ply:GetAmmoCount(v:GetSecondaryAmmoType()) + v:Clip2() or 0
			WUMA.SendCommand(self_loadout.Command.Add, { self_loadout:GetSelectedUsergroups(), v:GetClass(), primary, secondary })
		end

		if active_wep then
			WUMA.SendCommand(self_loadout.Command.Primary, { self_loadout:GetSelectedUsergroups(), active_wep:GetClass() })
		end

		frame:Close()

	end

	frame:SizeToContentsY()
	frame:SetVisible(true)
	frame:MakePopup()

	self_loadout.set_as_frame = frame
end

function PANEL:OnAddClick()
	self = self:GetParent()
	if (table.Count(self:GetSelectedUsergroups()) < 1) then return end
	if (table.Count(self:GetSelectedSuggestions()) < 1) then return end

	local usergroups = self:GetSelectedUsergroups()
	if table.Count(usergroups) == 1 then usergroups = usergroups[1] end

	local suggestions = self:GetSelectedSuggestions()
	if table.Count(suggestions) == 1 then suggestions = suggestions[1] end

	local access = self.Command.Add
	local data = { usergroups, suggestions, self:GetPrimaryAmmo(), self:GetSecondaryAmmo(), self:GetRespectsRestrictions(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Adding data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) < 1) then return end

	WUMA.SetProgress(self.Command.DataID, "Deleting data", 0.2)

	for _, v in pairs(items) do
		WUMA.SendCommand(self.Command.Delete, { v.usergroup, v.class })
	end
end

function PANEL:OnEditClick()
	self = self:GetParent()

	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) ~= 1) then return end

	local usergroup = { items[1].usergroup }
	local str = { items[1].class }

	local access = self.Command.Edit
	local data = { usergroup, str, self:GetPrimaryAmmo(), self:GetSecondaryAmmo(), self:GetRespectsRestrictions(), self:GetSelectedScope() }

	WUMA.SetProgress(self.Command.DataID, "Editing data", 0.2)

	WUMA.SendCommand(access, data)
end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleAdditionalOptionsVisiblility()
	self:GetParent():InvalidateLayout()
end

vgui.Register("WUMA_Loadouts", PANEL, 'DPanel');
