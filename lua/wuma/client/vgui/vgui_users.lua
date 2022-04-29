local PANEL = {}

PANEL.TabName = "Users"
PANEL.TabIcon = "icon16/drive_user.png"

function PANEL:Init()

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnTextChanged = self.OnSearch

	--Search button
	self.button_search = vgui.Create("DButton", self)
	self.button_search:SetText("")
	self.button_search:SetIcon("icon16/magnifier.png")
	self.button_search.DoClick = self.OnLookup

	--back button
	self.button_back = vgui.Create("DButton", self)
	self.button_back:SetText("Back")
	self.button_back.DoClick = self.OnBackClick

	--Restrictions button
	self.button_restrictions = vgui.Create("DButton", self)
	self.button_restrictions:SetText("Restrictions")
	self.button_restrictions.DoClick = self.OnRestrictionsClick
	self.button_restrictions:SetDisabled(true)

	--Limits button
	self.button_limits = vgui.Create("DButton", self)
	self.button_limits:SetText("Limits")
	self.button_limits.DoClick = self.OnLimitsClick
	self.button_limits:SetDisabled(true)

	--Loadouts button
	self.button_loadouts = vgui.Create("DButton", self)
	self.button_loadouts:SetText("Loadouts")
	self.button_loadouts.DoClick = self.OnLoadoutsClick
	self.button_loadouts:SetDisabled(true)

	--Items list
	self.list_items = vgui.Create("WDataView", self)
	self.list_items:SetMultiSelect(false)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Nick")
	self.list_items:AddColumn("SteamID")
	self.list_items:AddColumn("Last Online")
	self.list_items.OnRowSelected = self.OnUserSelected
	self.list_items.OnViewChange = function()
		self.list_items:SortByColumn(4)
	end

	local old_sortby = self.list_items.SortByColumn
	self.list_items.SortByColumn = function(panel, column)
		panel.SortedColumn = column
		old_sortby(panel, column)
	end

	local function highlight(line, data, datav)
		if WUMA.ServerUsers[datav.steamid] then return Color(0, 255, 0, 120) else return nil end
	end

	self.list_items:SetHighlightFunction(highlight)

	--Restrictions panel
	self.restrictions = vgui.Create("WUMA_Restrictions", self)
	self.restrictions:SetVisible(false)
	self.restrictions.list_usergroups:SetVisible(false)
	self.restrictions.GetSelectedUsergroups = function()
		return { self:GetSelectedUser() }
	end
	self.restrictions:GetDataView().Columns[1]:SetName("User")

	self.restrictions.Command.Add = "restrictuser"
	self.restrictions.Command.Delete = "unrestrictuser"
	self.restrictions.Command.Edit = "restrictuser"

	local display = function(data)
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end
		if scope and istable(scope) and scope.type and Scope.types[scope.type] then scope = Scope.types[scope.type].print end

		local nick = "ERROR"
		if WUMA.LookupUsers[data.parent] then nick = WUMA.LookupUsers[data.parent].nick elseif WUMA.ServerUsers[data.parent] then nick = WUMA.ServerUsers[data.parent]:Nick() end

		return { nick, data.print or data.string, scope }
	end
	self.restrictions:GetDataView():SetDisplayFunction(display)

	WUMA.GUI.AddHook(WUMA.USERDATAUPDATE, "WUMAUsersRestrictionUpdate", function(user, type, update)
		if (user == self:GetSelectedUser()) and (type == Restriction:GetID()) then
			if not (self.restrictions:GetDataView():GetDataTable() == WUMA.UserData[self:GetSelectedUser()].Restrictions) then
				self.restrictions:GetDataView():SetDataTable(function() return WUMA.UserData[self:GetSelectedUser()].Restrictions end)
			else
				self.restrictions:GetDataView():UpdateDataTable(update)
			end
		end
	end)

	--Limits panel
	self.limits = vgui.Create("WUMA_Limits", self)
	self.limits:SetVisible(false)
	self.limits.list_usergroups:SetVisible(false)
	self.limits.GetSelectedUsergroups = function()
		return { self:GetSelectedUser() }
	end
	self.restrictions:GetDataView().Columns[1]:SetName("User")

	self.limits.Command.Add = "setuserlimit"
	self.limits.Command.Delete = "unsetuserlimit"
	self.limits.Command.Edit = "setuserlimit"

	local display = function(data)
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end

		if scope and istable(scope) and scope.type and Scope.types[scope.type] then scope = Scope.types[scope.type].print end

		local nick = "ERROR"
		if WUMA.LookupUsers[data.parent] then nick = WUMA.LookupUsers[data.parent].nick elseif WUMA.ServerUsers[data.parent] then nick = WUMA.ServerUsers[data.parent]:Nick() end

		local sort_limit = data.limit
		if isnumber(sort_limit) then sort_limit = -sort_limit else sort_limit = -1 end

		local limit = data.limit
		if ((tonumber(limit) or 1) < 0) then limit = "∞" end

		return { nick, data.print or data.string, limit, scope }, { nil, nil, sort_limit, 0 }
	end
	self.limits:GetDataView():SetDisplayFunction(display)

	local sort = function(data)
		return self:GetSelectedUser()
	end
	self.limits:GetDataView():SetSortFunction(sort)

	WUMA.GUI.AddHook(WUMA.USERDATAUPDATE, "WUMAUsersLimitUpdate", function(user, type, update)
		if (user == self:GetSelectedUser()) and (type == Limit:GetID()) then
			if not (self.limits:GetDataView():GetDataTable() == WUMA.UserData[self:GetSelectedUser()].Limits) then
				self.limits:GetDataView():SetDataTable(function() return WUMA.UserData[self:GetSelectedUser()].Limits end)
			else
				self.limits:GetDataView():UpdateDataTable(update)
			end
		end
	end)

	--Loadouts panel
	self.loadouts = vgui.Create("WUMA_Loadouts", self)
	self.loadouts:SetVisible(false)
	self.loadouts.list_usergroups:SetVisible(false)
	self.loadouts.GetSelectedUsergroups = function()
		return { self:GetSelectedUser() }
	end
	self.loadouts.GetCurrentLoadout = function()
		if (WUMA.UserData[self:GetSelectedUser()]) then
			return WUMA.UserData[self:GetSelectedUser()].Loadouts
		end
	end


	self.loadouts.Command.Add = "adduserloadout"
	self.loadouts.Command.Delete = "removeuserloadout"
	self.loadouts.Command.Edit = "adduserloadout"
	self.loadouts.Command.Clear = "clearuserloadout"
	self.loadouts.Command.Primary = "setuserprimaryweapon"
	self.loadouts.Command.Enforce = "setuserenforceloadout"

	local display = function(data)
		local scope = "Permanent"
		if data.scope then scope = data.scope end

		local nick = "ERROR"
		if WUMA.LookupUsers[data.usergroup] then nick = WUMA.LookupUsers[data.usergroup].nick elseif WUMA.ServerUsers[data.usergroup] then nick = WUMA.ServerUsers[data.usergroup]:Nick() end

		local secondary = data.secondary or -1
		if (secondary < 0) then
			secondary = "def"
		end

		local primary = data.primary or -1
		if (primary < 0) then
			primary = "def"
		end

		return { nick, data.print or data.class, primary, secondary, scope }, { 0, nil, -(data.primary or 0), -(data.secondary or 0) }
	end
	self.loadouts:GetDataView():SetDisplayFunction(display)

	local sort = function(data)
		return self:GetSelectedUser()
	end
	self.loadouts:GetDataView():SetSortFunction(sort)

	WUMA.GUI.AddHook(WUMA.USERDATAUPDATE, "WUMAUsersLoadoutUpdate", function(user, type, update)
		if (user == self:GetSelectedUser()) and (type == Loadout:GetID()) then
			if not (self.loadouts:GetDataView():GetDataTable() == WUMA.UserData[self:GetSelectedUser()].LoadoutWeapons) then
				self.loadouts:GetDataView():SetDataTable(function() return WUMA.UserData[self:GetSelectedUser()].LoadoutWeapons end)
			else
				self.loadouts:GetDataView():UpdateDataTable(update)
			end
		end
	end)

	--User label
	self.label_user = vgui.Create("DLabel", self)
	self.label_user:SetText("NO_USER")
	self.label_user:SetTextColor(Color(0, 0, 0))
	self.label_user:SetVisible(true)

	local highlight = function(line, data, datav)
		if WUMA.ServerUsers[datav.steamid] then return Color(0, 255, 0, 120) end
	end
	self.list_items:SetHighlightFunction(highlight)

	local display = function(user)
		local data, sort

		local get_server_time = WUMA.GetServerTime or os.time

		data = { user.usergroup, user.nick, user.steamid, os.date("%d/%m/%Y %H:%M", user.t) }
		sort = { tonumber(table.KeyFromValue(WUMA.ServerGroups, user.usergroup) or "1") or 1, 1, 1, tonumber((get_server_time() - user.t) or "1") }

		return data, sort
	end
	self:GetDataView():SetDisplayFunction(display)

	local sort = function(data)
		local text = self.textbox_search:GetValue()
		if (text ~= "" and text ~= self.textbox_search:GetDefault()) then

			local column = "nick"
			if (string.lower(string.Left(text, 6)) == "steam_") then column = "steamid" end

			local item = data[column]
			local succ, err = pcall(function()
				local matched = string.match(string.lower(item), string.lower(text))
			end)

			if succ then
				if string.match(string.lower(item), string.lower(text)) then
					return "kek"
				end
			end
			return "false"
		end
		return "kek"
	end
	self:GetDataView():SetSortFunction(sort)

	local function updateUserList()
		self:GetDataView():SetDataTable(function() return WUMA.LookupUsers end)
		self:GetDataView():SortAll()

		self:GetDataView():Show("kek")
		self.list_items:SortByColumn(self.list_items.SortedColumn or 4)
	end

	WUMA.GUI.AddHook(WUMA.LOOKUPUSERSUPDATE, "VGUIUsersUserListHook1", updateUserList)
	WUMA.GUI.AddHook(WUMA.SERVERUSERSUPDATE, "VGUIUsersUserListHook2", updateUserList)

end

function PANEL:PerformLayout()
	if not self:IsExtraVisible() then
		self.textbox_search:SetSize(120, 20)
		self.textbox_search:SetPos(5, 5)

		self.button_search:SetSize(self.textbox_search:GetTall(), self.textbox_search:GetTall())
		self.button_search:SetPos(self.textbox_search.x + self.textbox_search:GetWide() + 5, 5)

		self.button_back:SetSize(70, self.textbox_search:GetTall())
		self.button_back:SetPos(self:GetWide() + 5, 5)

		self.button_loadouts:SetSize(70, self.textbox_search:GetTall())
		self.button_loadouts:SetPos(self:GetWide() - self.button_loadouts:GetWide() - 5, 5)

		self.button_limits:SetSize(50, self.textbox_search:GetTall())
		self.button_limits:SetPos(self.button_loadouts.x - self.button_limits:GetWide() - 5, 5)

		self.button_restrictions:SetSize(80, self.textbox_search:GetTall())
		self.button_restrictions:SetPos(self.button_limits.x - self.button_restrictions:GetWide() - 5, 5)

		self.limits:SetSize(self:GetWide(), self:GetTall() - 25)
		self.limits:SetPos(self:GetWide(), 25)

		self.loadouts:SetSize(self:GetWide(), self:GetTall() - 25)
		self.loadouts:SetPos(self:GetWide(), 25)

		self.restrictions:SetSize(self:GetWide(), self:GetTall() - 25)
		self.restrictions:SetPos(self:GetWide(), 25)

		self.label_user:SizeToContents()
		self.label_user:SetTall(self.button_back:GetTall())
		self.label_user:SetPos(self:GetWide() - self.label_user:GetWide() - 5 + self:GetWide(), 5)

		self.list_items:SetSize(self:GetWide() - 10, self:GetTall() - (self.textbox_search.y + self.textbox_search:GetTall()) - 10)
		self.list_items:SetPos(5, self.textbox_search.y + self.textbox_search:GetTall() + 5)
	elseif not self.isanimating then
		local offset = self:GetWide()

		self.textbox_search:SetSize(120, 20)
		self.textbox_search:SetPos(5 - offset, 5)

		self.button_search:SetSize(self.textbox_search:GetTall(), self.textbox_search:GetTall())
		self.button_search:SetPos(self.textbox_search.x + self.textbox_search:GetWide() + 5 - offset, 5)

		self.button_back:SetSize(70, self.textbox_search:GetTall())
		self.button_back:SetPos(self:GetWide() + 5 - offset, 5)

		self.button_loadouts:SetSize(70, self.textbox_search:GetTall())
		self.button_loadouts:SetPos(self:GetWide() - self.button_loadouts:GetWide() - 5 - offset, 5)

		self.button_limits:SetSize(50, self.textbox_search:GetTall())
		self.button_limits:SetPos(self.button_loadouts.x - self.button_limits:GetWide() - 5 - offset, 5)

		self.button_restrictions:SetSize(80, self.textbox_search:GetTall())
		self.button_restrictions:SetPos(self.button_limits.x - self.button_restrictions:GetWide() - 5 - offset, 5)

		self.limits:SetSize(self:GetWide(), self:GetTall() - 25)
		self.limits:SetPos(self:GetWide() - offset, 25)

		self.loadouts:SetSize(self:GetWide(), self:GetTall() - 25)
		self.loadouts:SetPos(self:GetWide() - offset, 25)

		self.restrictions:SetSize(self:GetWide(), self:GetTall() - 25)
		self.restrictions:SetPos(self:GetWide() - offset, 25)

		self.label_user:SizeToContents()
		self.label_user:SetTall(self.button_back:GetTall())
		self.label_user:SetPos(self:GetWide() - self.label_user:GetWide() - 5 + self:GetWide() - offset, 5)

		self.list_items:SetSize(self:GetWide() - 10, self:GetTall() - (self.textbox_search.y + self.textbox_search:GetTall()) - 10)
		self.list_items:SetPos(5 - offset, self.textbox_search.y + self.textbox_search:GetTall() + 5)
	end
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

function PANEL:GetSelectedUser()
	if self:GetDataView():GetLine(self:GetDataView():GetSelectedLine()) then
		return self:GetDataView():GetLine(self:GetDataView():GetSelectedLine()):GetColumnText(3)
	end
end

function PANEL:IsExtraVisible()
	return self.isextravisible
end

function PANEL:ToggleExtra()
	if self:IsExtraVisible() then
		for _, child in pairs(self:GetChildren()) do
			child:SetPos(child.x + self:GetWide(), child.y)
		end
		self.isextravisible = false

		self.label_user:SetVisible(false)
	else
		for _, child in pairs(self:GetChildren()) do
			child:SetPos(child.x - self:GetWide(), child.y)
		end
		self.isextravisible = true

		self.label_user:SetVisible(true)

		local data = self:GetDataView():GetSelectedItems()[1]
		if data then
			if istable(data) then
				self.label_user:SetText(string.format("Selected user: %s (%s)", data.nick, data.steamid))
			elseif data:IsValid() then
				self.label_user:SetText(string.format("Selected user: %s (%s)", data:Nick(), data:SteamID()))
			end
			self:InvalidateLayout()
		end
	end
end

function PANEL:OnUserSelected(this)
	self = self:GetParent()

	self.button_restrictions:SetDisabled(false)
	self.button_loadouts:SetDisabled(false)
	self.button_limits:SetDisabled(false)
end

function PANEL:OnExtraChange(id)
end

function PANEL:OnRestrictionsClick()
	self = self:GetParent()

	self.loadouts:SetVisible(false)
	self.limits:SetVisible(false)

	self.restrictions:SetVisible(true)

	WUMA.UserData[self:GetSelectedUser()] = WUMA.UserData[self:GetSelectedUser()] or {}
	WUMA.UserData[self:GetSelectedUser()].Restrictions = WUMA.UserData[self:GetSelectedUser()].Restrictions or {}

	self.restrictions:GetDataView():SetDataTable(function() return WUMA.UserData[self:GetSelectedUser()].Restrictions end)
	self.restrictions:GetDataView():Show(self:GetSelectedUser() .. ":::" .. self.restrictions:GetSelectedType())

	self.restrictions.Command.DataID = Restriction:GetID() .. ":::" .. self:GetSelectedUser()

	self:OnExtraChange(Restriction:GetID(), self:GetSelectedUser())

	self:ToggleExtra()
end

function PANEL:OnLimitsClick()
	self = self:GetParent()

	self.loadouts:SetVisible(false)
	self.restrictions:SetVisible(false)

	self.limits:SetVisible(true)

	WUMA.UserData[self:GetSelectedUser()] = WUMA.UserData[self:GetSelectedUser()] or {}
	WUMA.UserData[self:GetSelectedUser()].Limits = WUMA.UserData[self:GetSelectedUser()].Limits or {}

	self.limits:GetDataView():SetDataTable(function() return WUMA.UserData[self:GetSelectedUser()].Limits end)
	self.limits:GetDataView():Show(self:GetSelectedUser())

	self.limits.Command.DataID = Limit:GetID() .. ":::" .. self:GetSelectedUser()

	self:OnExtraChange(Limit:GetID(), self:GetSelectedUser())

	self:ToggleExtra()
end

function PANEL:OnLoadoutsClick()
	self = self:GetParent()

	self.restrictions:SetVisible(false)
	self.limits:SetVisible(false)

	self.loadouts:SetVisible(true)

	WUMA.UserData[self:GetSelectedUser()] = WUMA.UserData[self:GetSelectedUser()] or {}
	WUMA.UserData[self:GetSelectedUser()].LoadoutWeapons = WUMA.UserData[self:GetSelectedUser()].LoadoutWeapons or {}

	self.loadouts:GetDataView():SetDataTable(function() return WUMA.UserData[self:GetSelectedUser()].LoadoutWeapons end)
	self.loadouts:GetDataView():Show(self:GetSelectedUser())

	self.loadouts.Command.DataID = Loadout:GetID() .. ":::" .. self:GetSelectedUser()

	self:OnExtraChange(Loadout:GetID(), self:GetSelectedUser())

	self:ToggleExtra()
end

function PANEL:OnBackClick()
	self = self:GetParent()

	self.restrictions:SetVisible(false)
	self.limits:SetVisible(false)
	self.loadouts:SetVisible(false)

	self.restrictions:GetDataView():SetDataTable(function() return {} end)
	self.limits:GetDataView():SetDataTable(function() return {} end)
	self.loadouts:GetDataView():SetDataTable(function() return {} end)

	self:OnExtraChange("default", self:GetSelectedUser())

	self:ToggleExtra()
end

function PANEL:OnSearch()
	self:GetParent().OnLookup(self)
end

function PANEL:OnLookup()
	self = self:GetParent()

	if (self.textbox_search:GetValue() ~= "") then
		WUMA.RequestFromServer("lookup", self.textbox_search:GetValue())
	else
		self:GetDataView():ClearView()
	end

	self:GetDataView():SortAll()
	self:GetDataView():Show("kek")
	self.list_items:SortByColumn(self.list_items.SortedColumn or 4)
end

function PANEL:OnItemChange(lineid, line)
	self = self:GetParent()

	self.restrictions.Command.DataID = Restriction:GetID() .. ":::" .. self:GetSelectedUser()
	self.limits.Command.DataID = Limit:GetID() .. ":::" .. self:GetSelectedUser()
	self.loadouts.Command.DataID = Loadout:GetID() .. ":::" .. self:GetSelectedUser()
end

vgui.Register("WUMA_Users", PANEL, 'DPanel');
