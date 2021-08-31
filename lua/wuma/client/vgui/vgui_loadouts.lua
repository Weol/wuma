
local PANEL = {}

AccessorFunc(PANEL, "settings", "Settings")
AccessorFunc(PANEL, "inheritance", "Inheritance")
AccessorFunc(PANEL, "usergroups", "Usergroups")
AccessorFunc(PANEL, "inherits_from", "InheritsFrom")
AccessorFunc(PANEL, "inherits_to", "InheritsTo")

function PANEL:Init()

	self.InheritsFrom = {}
	self.InheritsTo = {}
	self.Settings = {}

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
	self.button_setas.DoClick = function() self:OnSetAsClick() end

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

	--Primary button
	self.button_primary = vgui.Create("DButton", self)
	self.button_primary:SetText("Set Primary")
	self.button_primary.DoClick = function() self:OnPrimaryClick() end
	self.button_primary:SetDisabled(true)

	--Delete button
	self.button_delete = vgui.Create("DButton", self)
	self.button_delete:SetText("Delete")
	self.button_delete.DoClick = function() self:OnDeleteClick() end
	self.button_delete:SetDisabled(true)

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
	self.list_items:AddColumn("Weapon")
	self.list_items:AddColumn("Primary")
	self.list_items:AddColumn("Secondary")
	self.list_items.OnItemSelected = function(_, item) return self:OnItemSelected(item) end
	self.list_items.OnViewChanged = function() return self:OnViewChanged() end
	self.list_items:SetClassifyFunction(function(...) return self:ClassifyWeapon(...) end)
	self.list_items:SetSortGroupingFunction(function(...) return self:SortGrouping(...) end)

	--Enforce checkbox
	self.checkbox_enforce = vgui.Create("WCheckBoxLabel", self)
	self.checkbox_enforce:SetText("Keep gamemode loadout")
	self.checkbox_enforce:SetValue(-1)
	self.checkbox_enforce:SetTextColor(Color(0, 0, 0))
	self.checkbox_enforce.OnChange = function(_, val) self:OnEnforceCheckboxChanged(val) end

	self:ReloadSuggestions()

end

function PANEL:PerformLayout(w, h)
	self.slider_primary:SetPos(5, 5)
	self.slider_primary:SetSize(100, 40)

	self.slider_secondary:SetPos(5, self.slider_primary.y + self.slider_primary:GetTall() + 5)
	self.slider_secondary:SetSize(self.slider_primary:GetWide(), 40)

	self.button_setas:SetSize(self.slider_primary:GetWide(), 25)
	self.button_setas:SetPos(5, h - self.button_setas:GetTall() - 5)

	self.list_usergroups:SetPos(5, self.slider_secondary.y + self.slider_secondary:GetTall() + 5)
	self.list_usergroups:SetSize(self.slider_primary:GetWide(), self.button_setas.y - self.list_usergroups.y - 5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos((w - 5) - self.textbox_search:GetWide(), 5)

	self.button_primary:SetSize(self.textbox_search:GetWide(), 25)
	self.button_primary:SetPos(self.textbox_search.x, h - self.button_primary:GetTall() - 5)

	self.button_delete:SetSize(self.textbox_search:GetWide(), 25)
	self.button_delete:SetPos(self.button_add.x, self.button_primary.y - self.button_delete:GetTall() - 5)

	self.button_add:SetSize(self.textbox_search:GetWide(), 25)
	self.button_add:SetPos(self.button_primary.x, self.button_delete.y - self.button_add:GetTall() - 5)

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y + self.textbox_search:GetTall() + 5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y - self.list_suggestions.y - 5)

	self.list_items:SetPos(self.slider_primary.x + self.slider_primary:GetWide() + 5, 5)
	self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, h - self.checkbox_enforce:GetTall() - 20)

	self.checkbox_enforce:SetPos(self.list_items.x + 5, self.list_items.y + self.list_items:GetTall() + 5)
end

function PANEL:ClassifyWeapon(weapon)
	local primary_ammo = weapon:GetPrimaryAmmo()
	if (primary_ammo < 0) then primary_ammo = "default" end

	local secondary_ammo = weapon:GetSecondaryAmmo()
	if (secondary_ammo < 0) then secondary_ammo = "default" end

	return weapon:GetParent(), {weapon:GetParent(), weapon:GetClass(), primary_ammo, secondary_ammo}, nil, nil
end

function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_primary:SetDisabled(false)
		self.button_delete:SetDisabled(false)
	else
		self.button_primary:SetDisabled(true)
		self.button_delete:SetDisabled(true)
	end

	local selected_usergroups = self:GetSelectedUsergroups()

	for _, line in pairs(self.list_items:GetLines()) do
		line:SetIcon(nil)
	end

	if (#selected_usergroups == 1) then
		local inheritsFrom = self:GetInheritsFrom()[selected_usergroups[1]]

		local primary_weapon = self.Settings[selected_usergroups[1]] and self.Settings[selected_usergroups[1]]["loadout_primary_weapon"]
		local primary_from = primary_weapon and selected_usergroups[1]

		if inheritsFrom and not primary_weapon then
			for _, usergroup in ipairs(inheritsFrom) do
				if primary_weapon then break end
				primary_weapon = self.Settings[usergroup] and self.Settings[usergroup]["loadout_primary_weapon"]
				primary_from = primary_weapon and usergroup
			end
		end

		local data_registry = self.list_items:GetDataRegistry()

		local primary_weapon_line = data_registry[primary_from] and data_registry[primary_from][primary_from .. "_" .. primary_weapon]
		if primary_weapon_line then
			primary_weapon_line:SetIcon({"icon16/star.png", "This is the primary weapon of " .. (self:GetUsergroupDisplay(selected_usergroups[1]) or selected_usergroups[1])})
		end

		local overriden_items = {}
		if inheritsFrom then
			for i = #inheritsFrom, 1, -1 do
				for j = i - 1, 0, -1 do
					for _, line in pairs(data_registry[inheritsFrom[i]] or {}) do
						local weapon = line:GetValue()

						local usergroup = (j >= 0) and inheritsFrom[j] or selected_usergroups[1]

						local group_key = usergroup
						local item_key = usergroup.. "_" .. weapon:GetClass()
						if not overriden_items[line] and data_registry[group_key] and data_registry[group_key][item_key] then
							overriden_items[line] = usergroup
						end
					end
				end
			end
		end

		for line, overiddenBy in pairs(overriden_items) do
			local icon = {"icon16/cancel.png", "This weapon has been overridden by " .. (self:GetUsergroupDisplay(overiddenBy) or overiddenBy)}
			line:SetIcon(icon)
		end
	else
		for _, line in ipairs(self.list_items:GetLines()) do
			local weapon = line:GetValue()

			local primary_weapon = self.Settings[weapon:GetParent()] and self.Settings[weapon:GetParent()]["loadout_primary_weapon"]
			if primary_weapon and weapon:GetClass() == primary_weapon then
				local icon = {"icon16/star.png", "This is the primary weapon of " .. (self:GetUsergroupDisplay(weapon:GetParent()) or weapon:GetParent())}
				line:SetIcon(icon)
			end
		end
	end
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

function PANEL:GetUsergroupDisplay(usergroup)
	--For use in user-restrictions
	return usergroup
end

function PANEL:ReloadSuggestions()
	self.list_suggestions:Clear()
	for k, v in pairs(WUMA.GetWeapons()) do
		self.list_suggestions:AddLine(v)
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
	if not self.list_usergroups:GetSelected() then return false end

	local tbl = {}
	for _, v in pairs(self.list_usergroups:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end

	return tbl
end

function PANEL:GetPrimaryAmmo()
	return self.slider_primary:GetValue()
end

function PANEL:GetSecondaryAmmo()
	return self.slider_secondary:GetValue()
end

function PANEL:NotifyWeaponsChanged(weapons, parent, updated, deleted)
	if (weapons ~= self.list_items:GetDataSources()[parent]) then
		self.list_items:AddDataSource(parent, weapons)
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

function PANEL:NotifySettingsChanged(parent, new_settings, updated, deleted)
	local settings = self.Settings

	local resort = {}
	if settings[parent] and settings[parent]["loadout_primary_weapon"] and table.HasValue(deleted, "loadout_primary_weapon") then
		table.insert(resort, settings[parent]["loadout_primary_weapon"])
	end

	if updated["loadout_primary_weapon"] then
		table.insert(resort, updated["loadout_primary_weapon"])

		if settings[parent] and settings[parent]["loadout_primary_weapon"] then
			table.insert(resort, settings[parent]["loadout_primary_weapon"])
		end
	end

	if table.IsEmpty(new_settings) then
		settings[parent] = nil
	else
		settings[parent] = table.Copy(new_settings)
	end

	for _, class in pairs(resort) do
		self.list_items:ReSort(parent, class)
	end

	self:ShowSelectedUsergroups(self:GetSelectedUsergroups())
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

	local settings = self.Settings

	if (#usergroups == 1) then
		local selected = usergroups[1]

		local header_function = function(weapons)
			if (table.Count(weapons) == 0) then
				return "No loadout for " .. self:GetUsergroupDisplay(selected)
			else
				return "Loadout for " .. self:GetUsergroupDisplay(selected)
			end
		end
		table.insert(groups, {selected, header_function})

		if self:GetInheritsFrom() and self:GetInheritsFrom()[selected] then
			for _, usergroup in ipairs(self:GetInheritsFrom()[selected]) do
				local header_function = function(weapons)
					if (table.Count(weapons) == 0) then
						return "No loadout inherited from " .. self:GetUsergroupDisplay(usergroup)
					else
						return "Loadout inherited from " .. self:GetUsergroupDisplay(usergroup)
					end
				end
				table.insert(groups, {usergroup, header_function, true})
			end
		end
	else
		for i, selected in ipairs(usergroups) do
			local header_function = function(weapons)
				if (table.Count(weapons) == 0) then
					return "No loadout for " .. self:GetUsergroupDisplay(selected)
				else
					return "Loadout for " .. self:GetUsergroupDisplay(selected)
				end
			end
			table.insert(groups, {selected, header_function})
		end

		self.list_items:AddPanel("Not showing inherited loadouts", BOTTOM)
	end

	if (table.Count(usergroups) > 1) then
		self.checkbox_enforce:SetValue(0)
		self.checkbox_enforce:SetDisabled(true)

		local message = "Disabled when multiple usergroups are selected"
		self.checkbox_enforce:SetHoverMessage(message)
	else
		self.DisregardSettingsChange = true

		self.checkbox_enforce:SetDisabled(false)
		self.checkbox_enforce:SetValue(-1)
		self.checkbox_enforce:SetHoverMessage(nil)

		local usergroup = self:GetSelectedUsergroups()[1]

		self.checkbox_enforce:SetValue(settings[usergroup] and settings[usergroup]["loadout_enforce"] and 1 or -1)

		if self:GetInheritsFrom()[usergroup] then
			for i, inheritsFrom in ipairs(self:GetInheritsFrom()[usergroup]) do
				if (settings[inheritsFrom] and settings[inheritsFrom]["loadout_enforce"]) then
					self.checkbox_enforce:SetValue(1)
					self.checkbox_enforce:SetDisabled(true)
					self.checkbox_enforce:SetHoverMessage("Cannot change inherited setting")
					break
				end
			end
		end

		if (self.checkbox_enforce:GetValue() == 1) then
			self.list_items:AddPanel("This loadout will not replace the gamemode loadout, weapons spawned by the gamemode will still be present", BOTTOM)
		end

		self.DisregardSettingsChange = false
	end

	self.list_items:Show(groups)
end

function PANEL:OnItemSelected(weapon)
	self.button_primary:SetText("Set primary")

	if (#self.list_items:GetSelected() > 1) then
		self.button_primary:SetDisabled(true)
	else
		self.button_primary:SetDisabled(false)

		local settings = self.Settings
		if settings[weapon:GetParent()] and settings[weapon:GetParent()]["loadout_primary_weapon"] == weapon:GetClass() then
			self.button_primary:SetText("Unset primary")
		end
	end

	self.button_delete:SetDisabled(false)
	self.button_add:SetDisabled(false)
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
end

function PANEL:OnUsergroupsChanged()
	for _, group in pairs(self:GetSelectedUsergroups()) do
		self:OnUsergroupSelected(group)
	end
	self:ShowSelectedUsergroups(self:GetSelectedUsergroups())
end

--luacheck: push no unused args
function PANEL:OnUsergroupSelected(usergroup)
	--For override
end
--luacheck: pop

function PANEL:OnEnforceCheckboxChanged(checked)
	if (checked == 0) or self.DisregardSettingsChange then
		return
	else
		checked = (checked == 1)
	end

	local usergroups = self:GetSelectedUsergroups()

	self:OnEnforceLoadoutChanged(usergroups, checked)
end

--luacheck: push no unused args
function PANEL:OnEnforceLoadoutChanged(usergroups, enforce)
	--For override
end
--luacheck: pop

function PANEL:OnPrimaryClick()
	local items = self.list_items:GetSelectedItems()
	if (table.Count(items) ~= 1) then return end
	local item = items[1]

	local usergroups = {item:GetParent()}
	local class = {item:GetClass()}

	self:OnPrimaryWeaponSet(usergroups, class)
end

--luacheck: push no unused args
function PANEL:OnPrimaryWeaponSet(usergroups, weapon)
	--For override
end
--luacheck: pop

function PANEL:OnSetAsClick()
	local usergroups = self:GetSelectedUsergroups()

	local frame = vgui.Create("DFrame")
	frame:SetSize(300, 200)
	frame:SetPos(ScrW() / 2 - frame:GetWide() / 2, ScrH() / 2 - frame:GetTall() / 2)
	frame:SetTitle("Set as...")
	frame:SetDeleteOnClose(true)

	function frame:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, Color(59, 59, 59, 255))
		draw.RoundedBox(5, 1, 1, w - 2, h - 2, Color(226, 226, 226, 255))

		draw.RoundedBox(5, 1, 1, w - 2, 25 - 1, Color(163, 165, 169, 255))
		surface.SetDrawColor(Color(163, 165, 169, 255))
		surface.DrawRect(1, 10, w- 2, 15)

		surface.SetFont("DermaDefault")
		surface.SetTextColor(0, 0, 0, 255)

		local line1, line2, line3 = "This will remove current loadout for the selected group(s)", "and replace it with the selected player's", "loadout on this menu."

		local w, _ = surface.GetTextSize(line1)
		surface.SetTextPos(frame:GetWide() / 2 - w / 2, 25)
		surface.DrawText(line1)

		local w, h = surface.GetTextSize(line2)
		surface.SetTextPos(frame:GetWide() / 2 - w / 2, 25 + h + 3)
		surface.DrawText(line2)

		local w, h = surface.GetTextSize(line3)
		surface.SetTextPos(frame:GetWide() / 2 - w / 2, 25 + h * 2 + 3 * 2)
		surface.DrawText(line3)
	end

	function frame:OnLoseFocus()
		self:Close()
	end

	local textbox = vgui.Create("WTextbox", frame)
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

		for _, ply in pairs(player.GetAll()) do
			local line = listview:AddLine(ply:Nick(), ply:GetUserGroup())
			line.Data = ply:SteamID()
		end
	end
	hook.Add("WUMA_LoudoutSetAs_PlayerDisconnected", populatePlayerList)

	function frame:OnClose()
		hook.Remove("WUMA_LoudoutSetAs_PlayerDisconnected")
	end
	populatePlayerList()

	local button = vgui.Create("DButton", frame)
	button:SetSize(100, 25)
	button:SetPos(frame:GetWide() - button:GetWide() - 5, frame:GetTall() - textbox:GetTall() - 5)
	button:SetText("Set")

	function textbox:OnChange()
		populatePlayerList()
		for k, v in pairs(listview:GetLines()) do
			local text = textbox:GetValue()
			local item = v:GetValue(1)
			if not string.match(item, text) then
				listview:RemoveLine(k)
			end
		end
	end

	function button.DoClick()
		if #listview:GetSelected() < 1 then return end

		local steamid = listview:GetSelected()[1].Data

		self:OnCopyPlayerLoadout(usergroups, steamid)
		frame:Close()
	end

	frame:SizeToContentsY()
	frame:SetVisible(true)
	frame:MakePopup()

	self.set_as_frame = frame
end

--luacheck: push no unused args
function PANEL:OnCopyPlayerLoadout(steamid)
	--For override
end
--luacheck: pop


function PANEL:OnAddClick()
	local usergroups = self:GetSelectedUsergroups()
	local suggestions = self:GetSelectedSuggestions()

	local primary_ammo = self:GetPrimaryAmmo()
	local secondary_ammo = self:GetSecondaryAmmo()

	self:OnAddWeapon(usergroups, suggestions, primary_ammo, secondary_ammo)
end

--luacheck: push no unused args
function PANEL:OnAddWeapon(usergroups, weapons, primary_ammo, secondary_ammo)
	--For override
end
--luacheck: pop

function PANEL:OnDeleteClick()
	local selected_items = self.list_items:GetSelectedItems()
	if table.IsEmpty(selected_items) then return end

	local settings = self.Settings

	local parents, items = {}, {}
	for _, item in pairs(selected_items) do
		parents[item:GetParent()] = true

		items[item:GetParent()] = items[item:GetParent()] or {}

		table.insert(items[item:GetParent()], item:GetClass())

		if settings[item:GetParent()] and settings[item:GetParent()]["loadout_primary_weapon"] == item:GetClass() then
			self:OnPrimaryWeaponSet(item:GetParent(), item:GetClass())
		end
	end

	for parent, _ in pairs(parents) do
		self:OnDeleteWeapon(parent, items[parent])
	end
end

--luacheck: push no unused args
function PANEL:OnDeleteWeapon(usergroups, weapons)
	--For override
end
--luacheck: pop

vgui.Register("WUMA_Loadouts", PANEL, 'DPanel');