
local PANEL = {}

AccessorFunc(PANEL, "settings", "Settings")

function PANEL:Init()

	self:SetSettings({})

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

	--Allow checkbox
	self.checkbox_ignore = vgui.Create("WCheckBoxLabel", self)
	self.checkbox_ignore:SetText("Ignore restrictions")
	self.checkbox_ignore:SetValue(-1)
	self.checkbox_ignore:SetTextColor(Color(0, 0, 0))
	self.checkbox_ignore.OnChange = function(_, val) self:OnIgnoreRestrictionsCheckboxChanged(val) end

	--Enforce checkbox
	self.checkbox_enforce = vgui.Create("WCheckBoxLabel", self)
	self.checkbox_enforce:SetText("Extend existing loadout")
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
	self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, h - self.checkbox_ignore:GetTall() - 20)

	self.checkbox_ignore:SetPos(self.list_items.x + 5, self.list_items.y + self.list_items:GetTall() + 5)

	self.checkbox_enforce:SetPos(self.checkbox_ignore.x + self.checkbox_ignore:GetWide() + 10, self.checkbox_ignore.y)
end

function PANEL:ClassifyWeapon(weapon)
	local icon

	local settings = self:GetSettings()
	if settings[weapon:GetParent()] and settings[weapon:GetParent()]["loadout_primary_weapon"] == weapon:GetClass() then
		icon = {"icon16/star.png", "This is the primary weapon"}
	end

	local primary_ammo = weapon:GetPrimaryAmmo()
	if (primary_ammo < 0) then primary_ammo = "default" end

	local secondary_ammo = weapon:GetSecondaryAmmo()
	if (secondary_ammo < 0) then secondary_ammo = "default" end

	return weapon:GetParent(), {weapon:GetParent(), weapon:GetClass(), primary_ammo, secondary_ammo}, nil, nil, icon
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
	self.list_usergroups:Clear()
	for _, usergroup in pairs(usergroups) do
		self.list_usergroups:AddLine(usergroup)
	end
	self.list_usergroups:SelectFirstItem()
end

function PANEL:NotifySettingsChanged(parent, new_settings, updated, deleted)
	local settings = self:GetSettings()

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

	self:ReloadSettings()
end

function PANEL:ReloadSettings()
	local usergroups = self:GetSelectedUsergroups()

	self.DisregardSettingsChange = true

	local settings = self:GetSettings()

	self.checkbox_enforce:SetValue(-1)
	self.checkbox_ignore:SetValue(-1)

	local prev_loadout_enforce
	local prev_loadout_ignore_restrictions

	local first = true

	local lock_enforce = false
	local lock_ignore_restrictions = false
	for _, usergroup in pairs(usergroups) do
		local loadout_enforce = settings[usergroup] and settings[usergroup]["loadout_enforce"]
		local loadout_ignore_restrictions = settings[usergroup] and settings[usergroup]["loadout_ignore_restrictions"]

		if not first and not lock_enforce and loadout_enforce ~= prev_loadout_enforce then
			self.checkbox_enforce:SetValue(0)
			lock_enforce = true
		elseif not lock_enforce and loadout_enforce then
			self.checkbox_enforce:SetValue(1)
		end

		if not first and not lock_ignore_restrictions and loadout_ignore_restrictions ~= prev_loadout_ignore_restrictions then
			self.checkbox_ignore:SetValue(0)
			lock_ignore_restrictions = true
		elseif not lock_ignore_restrictions and loadout_ignore_restrictions then
			self.checkbox_ignore:SetValue(1)
		end

		prev_loadout_ignore_restrictions = loadout_ignore_restrictions
		prev_loadout_enforce = loadout_enforce
		first = false
	end

	for _, weapon in pairs(self.list_items:GetSelectedItems()) do
		self:OnItemSelected(weapon)
	end

	self.DisregardSettingsChange = false
end

function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_primary:SetDisabled(false)
		self.button_delete:SetDisabled(false)
	else
		self.button_primary:SetDisabled(true)
		self.button_delete:SetDisabled(true)
	end
end

function PANEL:OnItemSelected(weapon)
	self.button_primary:SetText("Set primary")

	self.button_primary:SetDisabled(false)
	self.button_delete:SetDisabled(false)

	local settings = self:GetSettings()
	if settings[weapon:GetParent()] and settings[weapon:GetParent()]["loadout_primary_weapon"] == weapon:GetClass() then
		self.button_primary:SetText("Unset primary")
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
end

function PANEL:OnUsergroupsChanged()
	for _, group in pairs(self:GetSelectedUsergroups()) do
		self:OnUsergroupSelected(group)
	end
	self:ReloadSettings()
	self.list_items:Show(self:GetSelectedUsergroups())
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

function PANEL:OnIgnoreRestrictionsCheckboxChanged(checked)
	if (checked == 0) or self.DisregardSettingsChange then
		return
	else
		checked = (checked == 1)
	end

	local usergroups = self:GetSelectedUsergroups()

	self:OnIgnoreRestrictionsChanged(usergroups, checked)
end

--luacheck: push no unused args
function PANEL:OnIgnoreRestrictionsChanged(usergroups, ignore_restrictions)
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

	local settings = self:GetSettings()

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