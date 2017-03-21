
local PANEL = {}

PANEL.TabName = "Limits"
PANEL.TabIcon = "icon16/table.png"

function PANEL:Init()

	self.Command = {}
	self.Command.Add = "setlimit"
	self.Command.Delete = "unsetlimit"
	self.Command.Edit = "setlimit"

	//Limit chooser
	self.slider_limit = vgui.Create("WSlider",self)
	self.slider_limit:SetMinMax(1,300)
	self.slider_limit:SetText("Limit")
	--{parent=self,decimals=0,min=1,max=1000,x=5,y=5,w=100,h=37,text="Limit"}
	
	//Adv. Limit textbox
	self.textbox_advlimit = vgui.Create("WTextbox",self)
	self.textbox_advlimit:SetDefault("Adv. Limit")
	self.textbox_advlimit.OnChange = self.OnAdvLimitChanged
	--{parent=self,default="Adv. Limit",text_changed=self.OnAdvLimitChanged,relative=self.slider_limit,relative_align=3,x=0,y=5,w=100,h=20} 
	
	//Usergroups list
	self.list_usergroups = vgui.Create("DListView",self)
	self.list_usergroups:SetMultiSelect(true)
	self.list_usergroups:AddColumn("Usergroups")
	self.list_usergroups.OnRowSelected = self.OnUsergroupChange
	--{parent=self,multiselect=true,text="Usergroups",onrowselected=self.OnUsergroupChange,populate=WUMA.ServerGroups,select=1,relative=self.list_types,relative_align=3,x=0,y=5,w=self.list_types:GetWide(),h=(self:GetTall()-5)-(self:y(self.list_types)+self.list_types:GetTall()+5),sortable=false} 
	
	//Search bar
	self.textbox_search = vgui.Create("WTextbox",self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = self.OnSearch
	--{parent=self,default="Search..",text_changed=self.OnSearch,align=2,x=self:GetWide()-5,y=5,w=130,h=20} 
	
	//Settings button
	self.button_settings = vgui.Create("DButton",self)
	self.button_settings:SetIcon("icon16/cog.png")
	self.button_settings.DoClick = self.OnSettingsClick
	--{parent=self,icon="icon16/cog.png",onclick=self.OnSettingsClick,align=4,x=self:GetWide()-5,y=self:GetTall()-5,w=25,h=25}
	
	//Edit button
	self.button_edit = vgui.Create("DButton",self)
	self.button_edit:SetText("Edit")
	self.button_edit.DoClick = self.OnEditClick
	--{parent=self,text="Edit",onclick=self.OnEditClick,relative=self.button_settings,align=2,x=-5,y=0,w=self.textbox_search:GetWide()-30,h=25}
	
	//Delete button
	self.button_delete = vgui.Create("DButton",self)
	self.button_delete:SetText("Delete")
	self.button_delete.DoClick = self.OnDeleteClick
	
	--{parent=self,text="Delete",onclick=self.OnDeleteClick,align=3,relative=self.button_edit,x=0,y=-5,w=self.textbox_search:GetWide(),h=self.button_edit:GetTall()}

	//Add button
	self.button_add = vgui.Create("DButton",self)
	self.button_add:SetText("Add")
	self.button_add.DoClick = self.OnAddClick
	
	--{parent=self,text="Add",onclick=self.OnAddClick,align=3,relative=self.button_delete,x=0,y=-5,w=self.textbox_search:GetWide(),h=self.button_edit:GetTall()}
	
	//Suggestion list
	self.list_suggestions = vgui.Create("DListView",self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)
	self.list_suggestions.OnRowRightClick = function(panel) 
		panel:ClearSelection()
	end
	--{parent=self,multiselect=true,text="Items",relative=self.textbox_search,relative_align=3,x=0,y=5,w=self.textbox_search:GetWide(),h=self:GetTall()-((self:y(self.textbox_search)+self.textbox_search:GetTall()+15)+(self:GetTall()-(self:y(self.button_add)+5)))} 

	//Items list
	self.list_items = vgui.Create("WDataView",self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Limit")
	self.list_items:AddColumn("Scope")
	self.list_items.OnRowSelected = self.OnItemChange
	
	local highlight = function(line,data,datav)
		if (tonumber(datav[3]) == nil) then
			local id = Limit.GenerateID(Limit,datav.usergroup,datav.string)
			local id_p = Limit.GenerateID(Limit,_,datav.string)
			if not self:GetDataView():GetDataTable()[id] and not self:GetDataView():GetDataTable()[id_p] then return Color(255,0,0,120); else return nil end
		end
	end
	self:GetDataView():SetHighlightFunction(highlight)
	--{parent=self,multiselect=true,text="Usergroup",relative=self.list_types,relative_align=2,x=5,y=0,w=self:GetWide()-((self.list_types:GetWide()+10)+(self.textbox_search:GetWide()+10)),h=self:GetTall()-10,onrowselected=self.OnItemChange} 

	//Scope list
	self.list_scopes = vgui.Create("DListView",self)
	self.list_scopes:SetMultiSelect(true)
	self.list_scopes:AddColumn("Scope")
	self.list_scopes:SetMultiSelect(false)
	self.list_scopes.OnRowSelected = self.OnScopeChange
	--{parent=self,multiselect=false,select="Normal",text="Scope",onrowselected=self.OnScopeChange,populate=table.Add({"Permanent"},Scope:GetTypes("print")),relative=self.list_usergroups,relative_align=4,align=3,x=5,y=0,w=120,visible=false,sortable=false} 

		//date_chooser list
		self.date_chooser = vgui.Create("WDatePicker",self)	
		self.date_chooser:SetVisible(false)
		--{parent=self,relative=self.list_scopes,relative_align=2,x=5,y=0,visible=false}
		
		//time_chooser list
		self.time_chooser = vgui.Create("WDurationSlider",self)
		self.time_chooser:SetVisible(false)
		--{parent=self,decimals=0,min=0,max=1440,relative=self.list_scopes,relative_align=2,x=5,y=0,visible=false}
		
		//period_chooser list
		self.period_chooser = vgui.Create("WPeriodPicker",self)
		self.period_chooser:SetVisible(false)
		--{parent=self,decimals=0,min=0,max=1440,relative=self.list_scopes,relative_align=2,x=5,y=0,visible=false}
		
		//map_chooser 
		self.map_chooser = vgui.Create("WMapPicker",self)
		self.map_chooser:SetVisible(false)
		--{parent=self,options=WUMA.Maps,relative=self.list_scopes,relative_align=2,x=5,y=0,w=125,visible=false}
	
	//Allow checkbox
	self.checkbox_exclusive = vgui.Create("DCheckBoxLabel",self)
	self.checkbox_exclusive:SetText("Exclusive limit")
	self.checkbox_exclusive:SetTextColor(Color(0,0,0))
	self.checkbox_exclusive:SetValue(false)
	self.checkbox_exclusive:SetVisible(false)
		
	local sort = function(data)
		if not data.usergroup then return false end
		if not table.HasValue(self:GetSelectedUsergroups(),data.usergroup) then return false end 
		if not data.limit then return false end
		
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end

		if scope and istable(scope) and scope.type and Scope.types[scope.type] then scope = Scope.types[scope.type].print end
		
		local limit_sort = data.limit
		if isnumber(sort_limit) then sort_limit = -sort_limit else sort_limit = -1 end
		
		local limit = data.limit
		if ((tonumber(limit) or 0) < 0) then limit = "∞" end
		
		return {data.usergroup, data.print or data.string, limit, scope},{table.KeyFromValue(WUMA.ServerGroups,data.usergroup),_,limit_sort,0}
	end
	self:GetDataView():SetSortFunction(sort)
	
	local right_click = function(item)
		local tbl = {}
		tbl[1] = {"Item",item:GetString()}
		tbl[2] = {"Usergroup",item:GetUserGroup()}
		tbl[3] = {"Limit",item:Get()}
		tbl[5] = {"Scope",item:GetScope() or "Permanent"}
		if item:IsExclusive() then tbl[5] = {"Exlusive"} else tbl[5] = {"Inclusive"} end
		
		return tbl
	end
	self:GetDataView():SetRightClickFunction(right_click)

	self:PopulateList("list_usergroups",WUMA.ServerGroups,true,true)
	self:PopulateList("list_scopes",table.Add({"Permanent"},Scope:GetTypes("print")),true)
	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE,"WUMARestrictionsGUIUsergroupUpdateHook2",function() 
		self:PopulateList("list_usergroups",WUMA.ServerGroups,true,true)
	end)
	
	WUMA.GUI.AddHook(WUMA.MAPSUPDATE,"WUMALimitsGUIScopeMapsUpdateHook",function() 
		self.map_chooser:AddOptions(WUMA.Maps)
	end)
	
end

function PANEL:PerformLayout()

	self.slider_limit:SetPos(5,5)
	self.slider_limit:SetDecimals(0)
	self.slider_limit:SetSize(100,40)

	self.textbox_advlimit:SetPos(5,self.slider_limit.y+self.slider_limit:GetTall()+5)
	self.textbox_advlimit:SetSize(self.slider_limit:GetWide(),20)
	
	self.list_usergroups:SetPos(5,self.textbox_advlimit.y+self.textbox_advlimit:GetTall()+5)
	self.list_usergroups:SetSize(self.slider_limit:GetWide(),self:GetTall()-self.list_usergroups.y-5)

	self.textbox_search:SetSize(130,20)
	self.textbox_search:SetPos((self:GetWide()-5)-self.textbox_search:GetWide(),5)

	self.button_settings:SetSize(25,25)
	self.button_settings:SetPos((self:GetWide()-5)-self.button_settings:GetWide(),(self:GetTall()-5)-self.button_settings:GetTall())

	self.button_edit:SetSize(self.textbox_search:GetWide()-(self.button_settings:GetWide()+5),25)
	self.button_edit:SetPos((self.button_settings.x-10)-self.button_edit:GetWide()+5,self.button_settings.y)

	self.button_delete:SetSize(self.textbox_search:GetWide(),25)
	self.button_delete:SetPos(self.button_edit.x,(self.button_edit.y-5)-self.button_delete:GetTall())

	self.button_add:SetSize(self.textbox_search:GetWide(),25)
	self.button_add:SetPos(self.button_delete.x,(self.button_delete.y-5)-self.button_delete:GetTall())   

	self.list_suggestions:SetPos(self.textbox_search.x,self.textbox_search.y+self.textbox_search:GetTall()+5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(),self.button_add.y-self.list_suggestions.y-5)

	self.list_items:SetPos(self.slider_limit.x+5+self.slider_limit:GetWide(),5)
	
	if self:GetAdditonalOptionsVisibility() then
		self.list_items:SetSize(self.textbox_search.x-self.list_items.x-5,self:GetTall()-10 - (#(self.list_scopes:GetLines() or {}) * 17 + self.list_scopes:GetHeaderHeight() + 1) - 25)
	else
		self.list_items:SetSize(self.textbox_search.x-self.list_items.x-5,self:GetTall()-10)
	end
	
	self.checkbox_exclusive:SetPos(self.list_scopes.x,self.list_items.y+self.list_items:GetTall()+5)
	
	self.list_scopes:SetPos(self.list_items.x,self.checkbox_exclusive.y+self.checkbox_exclusive:GetTall()+5)
	self.list_scopes:SizeToContents()
	self.list_scopes:SetWide(120)

		self.date_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)

		self.time_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)
		self.time_chooser:SetSize(120,40)

		self.period_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)

		self.map_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)

	self:ReloadSuggestions()
		
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

function PANEL:ReloadSuggestions()
	if not self.list_suggestions then return end

	self:PopulateList("list_suggestions",WUMA.GetAllItems(),true)
	
	self.list_suggestions.VBar:SetScroll(0)
end

function PANEL:GetSelectedSuggestions()
	if not self.list_suggestions:GetSelected() or (table.Count(self.list_suggestions:GetSelected()) < 1) then 
		if (self.textbox_search:GetValue() ~= "" and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) then
			return {self.textbox_search:GetValue()}
		end 
	else	
		local tbl = {}
		for _,v in pairs(self.list_suggestions:GetSelected()) do
			table.insert(tbl,v:GetColumnText(1))
		end		
		return tbl
	end
	return {false}
end

function PANEL:GetSelectedUsergroups()
	if not self.list_usergroups:GetSelected() then return false end
	
	local tbl = {}
	for _,v in pairs(self.list_usergroups:GetSelected()) do
		table.insert(tbl,v:GetColumnText(1))
	end		

	return tbl
end

function PANEL:GetSelectedScope()
	if not self or not self.list_scopes or not self.list_scopes:GetSelected() or (table.Count(self.list_scopes:GetSelected()) < 1) then return nil end
	
	local selected = self.list_scopes:GetSelected()[1]:GetValue(1)	
	local scope = nil
	
	if (selected == "Permanent") then return nil end
	
	for k,v in pairs(Scope:GetTypes()) do
		if (v.print == selected) then
			local data = false
			if v.parts then
				if not self[v.parts[1]]:GetArgument() then return nil end
					
				data = self[v.parts[1]]:GetArgument()

				if v.processdata then data = v.processdata(data) end
			end

			scope = {type=k,data=data}
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
	
	local limit = self.slider_limit.wang:GetValue()
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
	
	if (self.textbox_advlimit:GetValue() != "" and self.textbox_search:GetValue() != "" and self.textbox_advlimit:GetValue() == self.textbox_search:GetValue() and self.textbox_advlimit:GetValue() != self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() != self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) != nil) then
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
		if not string.match(string.lower(item),string.lower(text)) then
			self.list_suggestions:RemoveLine(k)
		end
	end
	
	if (table.Count(self.list_suggestions:GetLines()) < 1) then
		self.list_suggestions:SetDisabled(true)
	else
		self.list_suggestions:SetDisabled(false)
	end
	
	if (self.textbox_advlimit:GetValue() != "" and self.textbox_search:GetValue() != "" and self.textbox_advlimit:GetValue() == self.textbox_search:GetValue() and self.textbox_advlimit:GetValue() != self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() != self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) != nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
	end
	
end

function PANEL:OnItemChange(lineid,line)

end

function PANEL:OnUsergroupChange()
	local self = self:GetParent()
	
	self:GetDataView():SortData()
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
	if not self:GetSelectedUsergroups() then return end
	if not self:GetSelectedSuggestions() then return end
	
	local usergroups = self:GetSelectedUsergroups()
	if table.Count(usergroups) == 1 then usergroups = usergroups[1] end
	
	local suggestions = self:GetSelectedSuggestions()
	if table.Count(suggestions) == 1 then suggestions = suggestions[1] end
	
	local access = self.Command.Add
	local data = {usergroups,suggestions,self:GetLimit(),self:GetIsExclusive(),self:GetSelectedScope()}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()
	
	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) < 1) then return end
	
	local usergroups = {}
	local strings = {}
	
	for _, v in pairs(items) do
		if not table.HasValue(usergroups,v:GetUserGroup()) then
			table.insert(usergroups,v:GetUserGroup())	
		end
		
		if not table.HasValue(strings,v:GetString()) then
			table.insert(strings,v:GetString())	
		end
	end
	
	local access = self.Command.Delete
	local data = {usergroups,strings}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnEditClick()
	self = self:GetParent()
	
	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) ~= 1) then return end
	
	local usergroup = {items[1]:GetUserGroup()}
	local string = {items[1]:GetString()}

	if (string == self:GetLimit()) then
		return
	end
	
	local access = self.Command.Edit
	local data = {usergroup,string,self:GetLimit(),self:GetIsExclusive(),self:GetSelectedScope()}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleAdditionalOptionsVisiblility()
	self:GetParent():InvalidateLayout()
end

vgui.Register("WUMA_Limits", PANEL, 'DPanel');