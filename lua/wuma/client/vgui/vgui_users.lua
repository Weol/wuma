
local PANEL = {}

PANEL.TabName = "Users"
PANEL.TabIcon = "gui/silkicons/user"


function PANEL:Init()
	
	//Search bar
	self.textbox_search = vgui.Create("WTextbox",self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnTextChanged = self.OnSearch
	
	//Search button
	self.button_search = vgui.Create("DButton",self)
	self.button_search:SetText("")
	self.button_search:SetIcon("icon16/magnifier.png")
	self.button_search.DoClick = self.OnLookup
	
	//back button
	self.button_back = vgui.Create("DButton",self)
	self.button_back:SetText("Back")
	self.button_back.DoClick = self.OnBackClick
	
	//Restrictions button
	self.button_restrictions = vgui.Create("DButton",self)
	self.button_restrictions:SetText("Restrictions")
	self.button_restrictions.DoClick = self.OnRestrictionsClick
	self.button_restrictions:SetDisabled(true)
	
	//Limits button
	self.button_limits = vgui.Create("DButton",self)
	self.button_limits:SetText("Limits")
	self.button_limits.DoClick = self.OnLimitsClick
	self.button_limits:SetDisabled(true)

	//Loadouts button
	self.button_loadouts = vgui.Create("DButton",self)
	self.button_loadouts:SetText("Loadouts")
	self.button_loadouts.DoClick = self.OnLoadoutsClick
	self.button_loadouts:SetDisabled(true)
	
	//Items list
	self.list_items = vgui.Create("WDataView",self) 
	self.list_items:SetMultiSelect(false)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Nick")
	self.list_items:AddColumn("SteamID")
	self.list_items:AddColumn("Last Online")
	self.list_items.OnRowSelected = self.OnUserSelected
	self.list_items.OnViewChange = function()
		self.list_items:SortByColumn()	
	end
		
	local function highlight(line,data,datav)
		if WUMA.ServerUsers[data[3]] then return Color(0,255,0,120) else return nil end
	end
	self.list_items:SetHighlightFunction(highlight)
	
	//Restrictions panel
	self.restrictions = vgui.Create("WUMA_Restrictions",self) 
	self.restrictions:SetVisible(false)
	self.restrictions.list_usergroups:SetVisible(false)
	self.restrictions.GetSelectedUsergroups = function()
		return {self:GetSelectedUser()}
	end
	self.restrictions:GetDataView().Columns[1]:SetName("User")
	
	self.restrictions.Command.Add = "restrictuser"
	self.restrictions.Command.Delete = "unrestrictuser"
	self.restrictions.Command.Edit = "restrictuser"
	
	local sort = function(data)
		if not data.type then return false end
		if not (self.restrictions:GetSelectedType() == data.type) then return false end
		if not (self:GetSelectedUser() == data.parent) then return false end
		
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end
		if scope and istable(scope) and scope.type and Scope.types[scope.type] then scope = Scope.types[scope.type].print end
		
		local nick = "ERROR"
		if WUMA.LookupUsers[data.parent] then nick = WUMA.LookupUsers[data.parent].nick elseif WUMA.ServerUsers[data.parent] then nick = WUMA.ServerUsers[data.parent]:Nick() end
		
		return {nick, data.print or data.string, scope}
	end
	self.restrictions:GetDataView():SetSortFunction(sort)
	
	//Limits panel
	self.limits = vgui.Create("WUMA_Limits",self) 
	self.limits:SetVisible(false)
	self.limits.list_usergroups:SetVisible(false)
	self.limits.GetSelectedUsergroups = function()
		return {self:GetSelectedUser()}
	end
	self.restrictions:GetDataView().Columns[1]:SetName("User")
	
	self.limits.Command.Add = "setuserlimit"
	self.limits.Command.Delete = "unsetuserlimit"
	self.limits.Command.Edit = "setuserlimit"
	
	local sort2 = function(data)
		if not data.limit then return false end
		if not (self:GetSelectedUser() == data.parent) then return false end
		
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
		
		return {nick, data.print or data.string, limit, scope},{_,_,sort_limit,0}
	end
	self.limits:GetDataView():SetSortFunction(sort2)
	
	//Loadouts panel
	self.loadouts = vgui.Create("WUMA_Loadouts",self) 
	self.loadouts:SetVisible(false)
	self.loadouts.list_usergroups:SetVisible(false)
	self.loadouts.GetSelectedUsergroups = function()
		return {self:GetSelectedUser()}
	end
	
	self.loadouts.Command.Add = "adduserloadout"
	self.loadouts.Command.Delete = "removeuserloadout"
	self.loadouts.Command.Edit = "adduserloadout"
	self.loadouts.Command.Clear = "clearuserloadout"
	self.loadouts.Command.Primary = "setuserprimaryweapon"
	
	local sort3 = function(data)
		if not (self:GetSelectedUser() == data:GetParent()) then return false end
		
		scope = "Permanent"
		if data.scope then scope = data.scope end

		local nick = "ERROR"
		if WUMA.LookupUsers[data:GetParent()] then nick = WUMA.LookupUsers[data:GetParent()].nick elseif WUMA.ServerUsers[data:GetParent()] then nick = WUMA.ServerUsers[data:GetParent()]:Nick() end
		
		local secondary = data.secondary or -1
		if (secondary < 0) then
			secondary = "def"
		end 
		
		local primary = data.primary or -1
		if (primary < 0) then
			primary = "def"
		end 
		
		return {nick, data.class, primary, secondary, scope},{0,_,-(data.primary or 0),-(data.secondary or 0)}
	end
	self.loadouts:GetDataView():SetSortFunction(sort3)
	
	//User label
	self.label_user = vgui.Create( "DLabel", self )
	self.label_user:SetText( "NO_USER" )
	self.label_user:SetTextColor(Color(0,0,0))
	self.label_user:SetVisible(true)
	
	local sort = function(user)
		local data, sort
	
		if WUMA.ServerUsers[user.steamid] then
			data = {user.usergroup,user.nick,user.steamid,os.date("%d/%m/%Y %H:%M", user.t)}
			sort = {tonumber(table.KeyFromValue(WUMA.ServerGroups,user.usergroup) or "1") or 1,1,1,tonumber((WUMA.GetTime()-user.t) or "1")}
		else 
			data = {user.usergroup,user.nick,user.steamid,os.date("%d/%m/%Y %H:%M", user.t)}
			sort = {tonumber(table.KeyFromValue(WUMA.ServerGroups,user.usergroup) or "1") or 1,1,1,tonumber((WUMA.GetTime()-user.t) or "1")}
		end
		
		local text = string.lower(self.textbox_search:GetValue())
		if (text != "" and text != string.lower(self.textbox_search:GetDefault())) then
		
			local column = 2
			if (string.Left(text, 6) == "steam_") then column = 3 end
			
			local item = data[column]
			local succ, err = pcall( function() 
				if not string.match(string.lower(item),text) then
					return false
				end
			end )
			
			if not succ then 
				return false
			else
			if not string.match(string.lower(item),text) then
					return false
				end
			end
		end
		
		return data, sort
	end
	self:GetDataView():SetSortFunction(sort)
	self:GetDataView():SortByColumn(4)
	
	local function updateUserList(tbl)
		if tbl and (table.Count(tbl) < 1) then
			self:GetDataView():SetDataTable({})
		else
			local data = table.Merge(table.Copy(WUMA.LookupUsers),WUMA.ServerUsers)
			
			self:GetDataView():SetDataTable(data)
			self:GetDataView():SortData()
			
			self:GetDataView():SelectFirstItem()
		end
		self:GetDataView():SortData()
		self:GetDataView():SortByColumn(4)
	end
	WUMA.GUI.AddHook(WUMA.LOOKUPUSERSUPDATE,"VGUIUsersUserListHook1",updateUserList)
	WUMA.GUI.AddHook(WUMA.SERVERUSERSUPDATE,"VGUIUsersUserListHook2",updateUserList)
	
	
end

function PANEL:PerformLayout()
	if not self:IsExtraVisible() then
		self.textbox_search:SetSize(120,20)
		self.textbox_search:SetPos(5,5)
		
		self.button_search:SetSize(self.textbox_search:GetTall(),self.textbox_search:GetTall())
		self.button_search:SetPos(self.textbox_search.x+self.textbox_search:GetWide()+5,5)
		
		self.button_back:SetSize(70,self.textbox_search:GetTall())
		self.button_back:SetPos(self:GetWide()+5,5)
		
		self.button_loadouts:SetSize(70,self.textbox_search:GetTall())
		self.button_loadouts:SetPos(self:GetWide()-self.button_loadouts:GetWide()-5,5)
		
		self.button_limits:SetSize(50,self.textbox_search:GetTall())
		self.button_limits:SetPos(self.button_loadouts.x-self.button_limits:GetWide()-5,5)
		
		self.button_restrictions:SetSize(80,self.textbox_search:GetTall())
		self.button_restrictions:SetPos(self.button_limits.x-self.button_restrictions:GetWide()-5,5)
		
		self.limits:SetSize(self:GetWide(),self:GetTall()-25)
		self.limits:SetPos(self:GetWide(),25)
		
		self.loadouts:SetSize(self:GetWide(),self:GetTall()-25)
		self.loadouts:SetPos(self:GetWide(),25)
		
		self.restrictions:SetSize(self:GetWide(),self:GetTall()-25)
		self.restrictions:SetPos(self:GetWide(),25)
		
		self.label_user:SizeToContents()
		self.label_user:SetTall(self.button_back:GetTall())
		self.label_user:SetPos(self:GetWide()-self.label_user:GetWide()-5+self:GetWide(),5)

		self.list_items:SetSize(self:GetWide()-10,self:GetTall()-(self.textbox_search.y+self.textbox_search:GetTall())-10)
		self.list_items:SetPos(5,self.textbox_search.y+self.textbox_search:GetTall()+5)
	elseif not self.isanimating then
		local offset = self:GetWide()
	
		self.textbox_search:SetSize(120,20)
		self.textbox_search:SetPos(5-offset,5)
		
		self.button_search:SetSize(self.textbox_search:GetTall(),self.textbox_search:GetTall())
		self.button_search:SetPos(self.textbox_search.x+self.textbox_search:GetWide()+5-offset,5)
		
		self.button_back:SetSize(70,self.textbox_search:GetTall())
		self.button_back:SetPos(self:GetWide()+5-offset,5)
		
		self.button_loadouts:SetSize(70,self.textbox_search:GetTall())
		self.button_loadouts:SetPos(self:GetWide()-self.button_loadouts:GetWide()-5-offset,5)
		
		self.button_limits:SetSize(50,self.textbox_search:GetTall())
		self.button_limits:SetPos(self.button_loadouts.x-self.button_limits:GetWide()-5-offset,5)
		
		self.button_restrictions:SetSize(80,self.textbox_search:GetTall())
		self.button_restrictions:SetPos(self.button_limits.x-self.button_restrictions:GetWide()-5-offset,5)
		
		self.limits:SetSize(self:GetWide(),self:GetTall()-25)
		self.limits:SetPos(self:GetWide()-offset,25)
		
		self.loadouts:SetSize(self:GetWide(),self:GetTall()-25)
		self.loadouts:SetPos(self:GetWide()-offset,25)
		
		self.restrictions:SetSize(self:GetWide(),self:GetTall()-25)
		self.restrictions:SetPos(self:GetWide()-offset,25)
		
		self.label_user:SizeToContents()
		self.label_user:SetTall(self.button_back:GetTall())
		self.label_user:SetPos(self:GetWide()-self.label_user:GetWide()-5+self:GetWide()-offset,5)

		self.list_items:SetSize(self:GetWide()-10,self:GetTall()-(self.textbox_search.y+self.textbox_search:GetTall())-10)
		self.list_items:SetPos(5-offset,self.textbox_search.y+self.textbox_search:GetTall()+5)
	end
end

function PANEL:GetDataView()
	return self.list_items
end

function PANEL:PopulateList(key,tbl,clear,select)
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
			child:SetPos(child.x+self:GetWide(),child.y)
		end
		self.isextravisible = false 
		
		self.label_user:SetVisible(false)
	else
		for _, child in pairs(self:GetChildren()) do
			child:SetPos(child.x-self:GetWide(),child.y)
		end 
		self.isextravisible = true
		
		self.label_user:SetVisible(true)
		
		local data = self:GetDataView():GetSelectedItems()[1]
		if data then
			if istable(data) then
				self.label_user:SetText(string.format("Selected user: %s (%s)",data.nick,data.steamid))
			elseif data:IsValid() then
				self.label_user:SetText(string.format("Selected user: %s (%s)",data:Nick(),data:SteamID()))
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
	
	if WUMA.UserData[self:GetSelectedUser()] and WUMA.UserData[self:GetSelectedUser()].Restrictions then
		self.restrictions:GetDataView():SetDataTable(WUMA.UserData[self:GetSelectedUser()].Restrictions or {})
	end

	self:OnExtraChange(Restriction:GetID(),self:GetSelectedUser())
	
	self:ToggleExtra()
end

function PANEL:OnLimitsClick()
	self = self:GetParent()
	
	self.loadouts:SetVisible(false)
	self.restrictions:SetVisible(false)
	
	self.limits:SetVisible(true)
	
	if WUMA.UserData[self:GetSelectedUser()] and WUMA.UserData[self:GetSelectedUser()].Limits then
		self.limits:GetDataView():SetDataTable(WUMA.UserData[self:GetSelectedUser()].Limits or {})
	end
	
	self:OnExtraChange(Limit:GetID(),self:GetSelectedUser())
	
	self:ToggleExtra()
end

function PANEL:OnLoadoutsClick()
	self = self:GetParent()
	
	self.restrictions:SetVisible(false)
	self.limits:SetVisible(false)
	
	self.loadouts:SetVisible(true)
	
	if WUMA.UserData[self:GetSelectedUser()] then
		self.loadouts:GetDataView():SetDataTable(WUMA.UserData[self:GetSelectedUser()].Loadouts)
	end
	
	self:OnExtraChange(Loadout:GetID(),self:GetSelectedUser())

	self:ToggleExtra()
end

function PANEL:OnBackClick()
	self = self:GetParent()
	
	self.restrictions:SetVisible(false)
	self.limits:SetVisible(false)
	self.loadouts:SetVisible(false)
	
	self.restrictions:GetDataView():SetDataTable({})
	self.limits:GetDataView():SetDataTable({})
	self.loadouts:GetDataView():SetDataTable({})
	
	self:OnExtraChange("default",self:GetSelectedUser())
	
	self:ToggleExtra()
end

function PANEL:OnSearch()
	self:GetParent().OnLookup(self)
end

	
function PANEL:OnLookup()
	self = self:GetParent()
	
	if (self.textbox_search:GetValue() != "") then
		WUMA.RequestFromServer(WUMA.NET.LOOKUP:GetID(),self.textbox_search:GetValue())
	else
		self:GetDataView():SetDataTable(WUMA.LookupUsers)
	end
end

function PANEL:OnItemChange(lineid,line)
	self = self:GetParent()														

end

vgui.Register("WUMA_Users", PANEL, 'DPanel');