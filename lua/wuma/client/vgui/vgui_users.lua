
local PANEL = {}

AccessorFunc(PANEL, "restrictions", "RestrictionsPanel")
AccessorFunc(PANEL, "limits", "LimitsPanel")
AccessorFunc(PANEL, "loadouts", "LoadoutsPanel")
AccessorFunc(PANEL, "Users", "Users")
AccessorFunc(PANEL, "CachedCalls", "CachedCalls")

PANEL.FETCH_COUNT = 50

function PANEL:Init()

	self.CachedCalls = {}
	self.ExhaustedSearches = {}
	self.Users = {}

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnEnter = function() self:OnLookup(self.textbox_search:GetValue()) end

	local old_OnLoseFocus = self.textbox_search.OnLoseFocus
	self.textbox_search.OnLoseFocus = function(entry)
		self:OnLookup(self.textbox_search:GetValue())
		return old_OnLoseFocus(entry)
	end

	--Search button
	self.button_search = vgui.Create("DButton", self)
	self.button_search:SetText("")
	self.button_search:SetIcon("icon16/magnifier.png")
	self.button_search.DoClick = function() self:OnLookup(self.textbox_search:GetValue()) end

	--Back button
	self.button_back = vgui.Create("DButton", self)
	self.button_back:SetText("Back")
	self.button_back:SetVisible(false)
	self.button_back.DoClick = function() self:OnBackClick() end

	--Restrictions button
	self.button_restrictions = vgui.Create("DButton", self)
	self.button_restrictions:SetText("Restrictions")
	self.button_restrictions.DoClick = function() self:OnRestrictionsClick() end
	self.button_restrictions:SetDisabled(true)

	--Limits button
	self.button_limits = vgui.Create("DButton", self)
	self.button_limits:SetText("Limits")
	self.button_limits.DoClick = function() self:OnLimitsClick() end
	self.button_limits:SetDisabled(true)

	--Loadouts button
	self.button_loadouts = vgui.Create("DButton", self)
	self.button_loadouts:SetText("Loadouts")
	self.button_loadouts.DoClick = function() self:OnLoadoutsClick() end
	self.button_loadouts:SetDisabled(true)

	--Items list
	self.list_items = vgui.Create("WListView", self)
	self.list_items:SetMultiSelect(false)
	self.list_items:AddColumn("Nick")
	self.list_items:AddColumn("SteamID")
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Last Online")
	self.list_items.OnItemSelected = function(_, item) return self:OnUserSelected(item) end
	self.list_items.OnViewChanged = function() return self:OnViewChanged() end
	self.list_items:SetClassifyFunction(function(...) return self:ClassifyUser(...) end)
	self.list_items:SetSortGroupingFunction(function(...) return self:SortGrouping(...) end)
	self.list_items:SetFilterFunction(function(...) return self:Filter(...) end)

	local old_SortByColumn = self.list_items.SortByColumn
	function self.list_items:SortByColumn(column_id, _)
		if (column_id == 4) then
			old_SortByColumn(self, column_id, true)
		end
	end

	--Restrictions panel
	self.restrictions = vgui.Create("WUMA_Restrictions", self)
	self.restrictions:SetVisible(false)
	self.restrictions.list_items.Columns[1]:SetName("User")
	self.restrictions.list_usergroups:SetVisible(false)
	self.restrictions.GetUsergroupDisplay = function(_, usergroup)
		if (usergroup == self:GetSelectedUserSteamId()) then
			return self:GetSelectedUserNick()
		end
	end
	self.restrictions.GetSelectedUsergroups = function()
		return {self:GetSelectedUserSteamId()}
	end

	self.restrictions.old_ClassifyFunction = self.restrictions.list_items:GetClassifyFunction()
	self.restrictions.list_items:SetClassifyFunction(function(...)
		local response = {self.restrictions.old_ClassifyFunction(...)}
		response[2][1] = self:GetSelectedUserNick()
		return response[1], response[2], response[3], response[4], response[5]
	end)

	--Limits panel
	self.limits = vgui.Create("WUMA_Limits", self)
	self.limits:SetVisible(false)
	self.limits.list_usergroups:SetVisible(false)
	self.restrictions.list_items.Columns[1]:SetName("User")
	self.limits.GetSelectedUsergroups = function()
		return {self:GetSelectedUserSteamId()}
	end

	self.limits.old_ClassifyFunction = self.limits.list_items:GetClassifyFunction()
	self.limits.list_items:SetClassifyFunction(function(...)
		local response = {self.limits.old_ClassifyFunction(...)}
		if (WUMA.IsSteamID(response[2][1])) then
			response[2][1] = self:GetSelectedUserNick()
		end
		return response[1], response[2], response[3], response[4], response[5]
	end)

	--Loadouts panel
	self.loadouts = vgui.Create("WUMA_Loadouts", self)
	self.loadouts:SetVisible(false)
	self.loadouts.list_usergroups:SetVisible(false)
	self.loadouts.GetSelectedUsergroups = function()
		return {self:GetSelectedUserSteamId()}
	end

	self.loadouts.old_ClassifyFunction = self.loadouts.list_items:GetClassifyFunction()
	self.loadouts.list_items:SetClassifyFunction(function(...)
		local response = {self.loadouts.old_ClassifyFunction(...)}
		response[2][1] = self:GetSelectedUserNick()
		return response[1], response[2], response[3], response[4], response[5]
	end)

	--User label
	self.label_user = vgui.Create("DLabel", self)
	self.label_user:SetText("NO_USER")
	self.label_user:SetTextColor(Color(0, 0, 0))
	self.label_user:SetVisible(false)

	self.list_items:Show({"lookup", "online"})

	--List footer
	self.items_footer = vgui.Create("DPanel")

	self.load_button = vgui.Create("DButton", self.items_footer)
	self.load_button:SetText("Load more users")
	self.load_button:SetSize(130, 25)
	self.load_button.DoClick = function() self:OnLoadMoreUsers() end

	self.items_footer.load_button = self.load_button

	function self.items_footer:SizeToContentsY()
		self:SetTall(10 + self.load_button:GetTall() + 10)
	end

	local list = self.list_items
	function self.items_footer:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(0, 0, w, h)

		if (self.y > 0) then
			surface.SetDrawColor(82, 82, 82, 255)
			surface.DrawLine(0, 0, w, 0)
		end

		local _, y = self:LocalToScreen(0, h)
		local _, y2 = list:LocalToScreen(0, list:GetTall())
		if (y + 1 ~= y2) then
			surface.SetDrawColor(82, 82, 82, 255)
			surface.DrawLine(0, h - 1, w, h - 1)
		end
	end

	function self.items_footer:PerformLayout(w, h)
		self.load_button:SetPos(w / 2 - self.load_button:GetWide() / 2, h / 2 - self.load_button:GetTall() / 2)
	end

	self.list_items:AddPanel(self.items_footer, BOTTOM)
end

function PANEL:SortGrouping(user)
	if self.list_items:GetKeys()["online_" .. user.steamid] then
		return 1, "Online players"
	end
	return 2, "Offline players"
end

function PANEL:Filter(user)
	if (user.group == "lookup") then
		return not self.list_items:GetKeys()["online_" .. user.steamid]
	end
	return true
end

function PANEL:ClassifyUser(user)
	local last_online = os.date("%d/%m/%Y %H:%M", user.t + WUMA.GetServerTimeOffset())

	local highlight
	if (user.group == "online") or self.list_items:GetKeys()["online_" .. user.steamid] then
		highlight = Color(0, 255, 0, 120)
		last_online = "Online"
	end

	local columns = {user.nick, user.steamid, user.usergroup, last_online}
	local sort = {user.nick, user.steamid, user.usergroup, user.t}

	return user.group, columns, sort, highlight
end

function PANEL:PerformLayout(w, h)
	self.textbox_search:SetSize(120, 20)
	self.textbox_search:SetPos(5, 5)

	self.button_search:SetSize(self.textbox_search:GetTall(), self.textbox_search:GetTall())
	self.button_search:SetPos(self.textbox_search.x+self.textbox_search:GetWide()+5, 5)

	self.button_back:SetSize(70, self.textbox_search:GetTall())
	self.button_back:SetPos(5, 5)

	self.button_loadouts:SetSize(70, self.textbox_search:GetTall())
	self.button_loadouts:SetPos(w-self.button_loadouts:GetWide()-5, 5)

	self.button_limits:SetSize(50, self.textbox_search:GetTall())
	self.button_limits:SetPos(self.button_loadouts.x-self.button_limits:GetWide()-5, 5)

	self.button_restrictions:SetSize(80, self.textbox_search:GetTall())
	self.button_restrictions:SetPos(self.button_limits.x-self.button_restrictions:GetWide()-5, 5)

	self.limits:SetSize(w, h-25)
	self.limits:SetPos(0, 25)

	self.loadouts:SetSize(w, h-25)
	self.loadouts:SetPos(0, 25)

	self.restrictions:SetSize(w, h-25)
	self.restrictions:SetPos(0, 25)

	self.label_user:SizeToContents()
	self.label_user:SetTall(self.button_back:GetTall())
	self.label_user:SetPos(w-self.label_user:GetWide()-5, 5)

	self.list_items:SetSize(w-10, h-(self.textbox_search.y+self.textbox_search:GetTall())-10)
	self.list_items:SetPos(5, self.textbox_search.y+self.textbox_search:GetTall()+5)
end

function PANEL:GetSelectedUserSteamId()
	local selected_items = self.list_items:GetSelectedItems()
	if table.IsEmpty(selected_items) then return end

	return selected_items[1].steamid
end

function PANEL:GetSelectedUserNick()
	local selected_items = self.list_items:GetSelectedItems()
	if table.IsEmpty(selected_items) then return end

	return selected_items[1].nick
end

function PANEL:NotifyLookupUsersChanged(users, key, updated, deleted)
	if users and (users ~= self.list_items:GetDataSources()[key]) then
		for _, user in pairs(users) do
			user.group = key
		end

		self.list_items:AddDataSource(key, users)
	else
		for _, user in pairs(updated) do
			user.group = key
		end

		self.list_items:UpdateDataSource(key, updated, deleted)
	end

	self.list_items:SortByColumn(4)
	self.list_items:FilterAll()
end

function PANEL:OnUserSelected(user)
	self.button_restrictions:SetDisabled(false)
	self.button_loadouts:SetDisabled(false)
	self.button_limits:SetDisabled(false)

	self.label_user:SetText(string.format("Selected user: %s (%s)", user.nick, user.steamid))
end

function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_restrictions:SetDisabled(false)
		self.button_limits:SetDisabled(false)
		self.button_loadouts:SetDisabled(false)
	else
		self.button_restrictions:SetDisabled(true)
		self.button_limits:SetDisabled(true)
		self.button_loadouts:SetDisabled(true)
	end
end

function PANEL:OnRestrictionsClick()
	for _, child in pairs(self:GetChildren()) do
		child:SetVisible(false)
	end

	self.restrictions:SetVisible(true)
	self.button_back:SetVisible(true)
	self.label_user:SetVisible(true)

	self:OnRestrictionsDisplayed(self.restrictions, self:GetSelectedUserSteamId())

	self.restrictions:OnUsergroupsChanged()
end

--luacheck: push no unused args
function PANEL:OnRestrictionsDisplayed(panel, steamid)
	--For override
end
--luacheck: pop

function PANEL:OnLimitsClick()
	for _, child in pairs(self:GetChildren()) do
		child:SetVisible(false)
	end

	self.limits:SetVisible(true)

	self.button_back:SetVisible(true)
	self.label_user:SetVisible(true)

	self:OnLimitsDisplayed(self.limits,  self:GetSelectedUserSteamId())

	self.limits:OnUsergroupsChanged()
end

--luacheck: push no unused args
function PANEL:OnLimitsDisplayed(panel, steamid)
	--For override
end
--luacheck: pop

function PANEL:OnLoadoutsClick()
	for _, child in pairs(self:GetChildren()) do
		child:SetVisible(false)
	end

	self.loadouts:SetVisible(true)
	self.button_back:SetVisible(true)
	self.label_user:SetVisible(true)

	self:OnLoadoutsDisplayed(self.loadouts, self:GetSelectedUserSteamId())

	self.loadouts:OnUsergroupsChanged()
end

--luacheck: push no unused args
function PANEL:OnLoadoutsDisplayed(panel, steamid)
	--For override
end
--luacheck: pop

function PANEL:OnBackClick()
	for _, child in pairs(self:GetChildren()) do
		child:SetVisible(true)
	end

	self.restrictions:SetVisible(false)
	self.limits:SetVisible(false)
	self.loadouts:SetVisible(false)
	self.button_back:SetVisible(false)
	self.label_user:SetVisible(false)
end

--luacheck: push no unused args
function PANEL:OnSearchUsers(limit, offset, search, callback)
	--For override
end
--luacheck: pop

function PANEL:OnLoadMoreUsers()
	local search = self.textbox_search:GetValue()

	if (search == "") then search = nil end

	self:SearchUsers(self.FETCH_COUNT, table.Count(self.list_items:GetGroups()[search or "lookup"]), search)
end

function PANEL:ShowKey(key)
	self.list_items:Show((key == "lookup") and {"lookup", "online"} or key)
	self.list_items:SortByColumn(4)

	if self.ExhaustedSearches[key] then
		self.load_button:SetText("No more users found")
		self.load_button:SetDisabled(true)
	else
		self.load_button:SetText("Load more users")
		self.load_button:SetDisabled(false)
	end
end

function PANEL:SearchUsers(limit, offset, search)
	local cache_key = table.concat({limit, offset, search}, "_")
	local key = search or "lookup"

	if not self:GetCachedCalls()[cache_key] then
		self:OnSearchUsers(limit, offset, search, function(users)
			local tbl = {}
			for _, v in pairs(users) do
				tbl[v.steamid] = v
			end

			if (table.Count(users) < self.FETCH_COUNT) then
				self.ExhaustedSearches[key] = true
				self.load_button:SetText("No more users found")
				self.load_button:SetDisabled(true)
			end

			self:NotifyLookupUsersChanged(nil, key, tbl, {})
			self:GetCachedCalls()[cache_key] = true

			self:ShowKey(key)
		end)
	else
		self:ShowKey(key)
	end
end

function PANEL:OnLookup(text)
	if (text ~= "") then
		self:SearchUsers(self.FETCH_COUNT, 0, text)
	else
		self:ShowKey("lookup")
	end
end

vgui.Register("WUMA_Users", PANEL, 'DPanel');