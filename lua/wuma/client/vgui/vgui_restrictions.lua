
local PANEL = {}

PANEL.TabName = "Restrictions"
PANEL.TabIcon = "gui/silkicons/shield"

function PANEL:Init()
	
	self.Command = {}
	self.Command.Add = "restrict"
	self.Command.Delete = "unrestrict"
	self.Command.Edit = "unrestrict"
	
	//Restriction types list
	self.list_types = vgui.Create("DListView",self)
	self.list_types:SetMultiSelect(false)
	self.list_types:AddColumn("Types")
	self.list_types:SetSortable(false)
	self.list_types.OnRowSelected = self.OnTypeChange
	--{parent=self,multiselect=false,text="Types",onrowselected=self.OnTypeChange,populate=Restriction:GetTypes("print"),select="Entity",x=5,y=5,size_to_content_y=true,w=100,sortable=false}

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
	--{parent=self,multiselect=true,text="Items",relative=self.textbox_search,relative_align=3,x=0,y=5,w=self.textbox_search:GetWide(),h=self:GetTall()-((self:y(self.textbox_search)+self.textbox_search:GetTall()+15)+(self:GetTall()-(self:y(self.button_add)+5)))} 

	//Items list
	self.list_items = vgui.Create("WDataView",self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Scope")
	self.list_items.OnRowSelected = self.OnItemChange
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
	self.checkbox_allow = vgui.Create("DCheckBoxLabel",self)
	self.checkbox_allow:SetText("Anti-Restriction")
	self.checkbox_allow:SetTextColor(Color(0,0,0))
	self.checkbox_allow:SetValue(false)
	self.checkbox_allow:SetVisible(false)
	
	--{parent=self,text="Anti Restriction",checked=0,align=3,relative=self.list_scopes,x=0,y=-5,visible=false} 
	
	local sort = function(data)
		if not data.usergroup or not data.type then return false end
		if not table.HasValue(self:GetSelectedUsergroups(),data.usergroup) then return false end 
		if not (self:GetSelectedType() == data.type) then return false end
		
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end
		if scope and istable(scope) and scope.type and Scope.types[scope.type] then scope = Scope.types[scope.type].print end
		
		return {data.usergroup, data.print or data.string, scope},{table.KeyFromValue(WUMA.ServerGroups,data.usergroup)}
	end
		
	self:GetDataView():SetSortFunction(sort)

	local right_click = function(item)
		local tbl = {}
		tbl[1] = {"Item",item:GetString()}
		tbl[2] = {"Usergroup",item:GetUserGroup()}
		tbl[3] = {"Type",item:GetType()}
		tbl[4] = {"Scope",item:GetScope() or "Permanent"}
		if item:GetAllow() then tbl[5] = {"Anti-Restriction"} end
		
		return tbl
	end

	self:GetDataView():SetRightClickFunction(right_click)
	
	self:PopulateList("list_types",Restriction:GetTypes("print"),true,true)
	self:PopulateList("list_usergroups",WUMA.ServerGroups,true,true)
	self:PopulateList("list_scopes",table.Add({"Permanent"},Scope:GetTypes("print")),true)
	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE,"WUMARestrictionsGUIUsergroupUpdateHook",function() 
		self:PopulateList("list_usergroups",WUMA.ServerGroups,true,true)
	end)
	
	WUMA.GUI.AddHook(WUMA.MAPSUPDATE,"WUMARestrictionsGUIScopeMapsUpdateHook",function() 
		self.map_chooser:AddOptions(WUMA.Maps)
	end)
		
end

function PANEL:PerformLayout()

	self.list_types:SetPos(5,5)
	self.list_types:SizeToContents()
	self.list_types:SetWide(100)

	self.list_usergroups:SetPos(5,self.list_types.y+self.list_types:GetTall()+5)
	self.list_usergroups:SetSize(self.list_types:GetWide(),self:GetTall()-self.list_usergroups.y-5)

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

	self.list_items:SetPos(self.list_types.x+5+self.list_types:GetWide(),5)
	
	if self:GetAdditonalOptionsVisibility() then
		self.list_items:SetSize(self.textbox_search.x-self.list_items.x-5,self:GetTall()-10 - (#(self.list_scopes:GetLines() or {}) * 17 + self.list_scopes:GetHeaderHeight() + 1) - 25)
	else
		self.list_items:SetSize(self.textbox_search.x-self.list_items.x-5,self:GetTall()-10)
	end

	self.checkbox_allow:SetPos(self.list_scopes.x,self.list_items.y+self.list_items:GetTall()+5)
	
	self.list_scopes:SetPos(self.list_items.x,self.checkbox_allow.y+self.checkbox_allow:GetTall()+5)
	self.list_scopes:SizeToContents()
	self.list_scopes:SetWide(120)

		self.date_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)

		self.time_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)
		self.time_chooser:SetSize(120,40)

		self.period_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)

		self.map_chooser:SetPos(self.list_scopes.x+5+self.list_scopes:GetWide(),self.list_scopes.y)

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

function PANEL:ReloadSuggestions(type)
	if not self.list_suggestions then return end
	local items = Restriction:GetTypes()[type].items
			
	if not items then 
		self.list_suggestions:SetDisabled(true)
		self.list_suggestions:Clear()
	else
		self.list_suggestions:SetDisabled(false)
		
		self:PopulateList("list_suggestions",items(),true)
	end
end

function PANEL:GetSelectedType()
	if not self.list_types:GetSelected()[1] then return false end
	for k,v in pairs(Restriction:GetTypes()) do
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
	for _,v in pairs(self.list_suggestions:GetSelected()) do
		table.insert(tbl,v:GetColumnText(1))
	end		
	
	return tbl
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
	else
		self.additionaloptionsvisibility = true
		
		self.list_scopes:SetVisible(true)
		self.checkbox_allow:SetVisible(true)
	end
end

function PANEL:OnSearch()

	local self = self:GetParent()
		
	local text = self.textbox_search:GetValue()
	
	if not self.list_suggestions:GetDisabled() and (text != "") then
	
		self:ReloadSuggestions(self:GetSelectedType())
	
		for k, line in pairs(self.list_suggestions:GetLines()) do
			local item = line:GetValue(1)
			if not string.match(string.lower(item),string.lower(text)) then
				self.list_suggestions:RemoveLine(k)
			end
		end
	elseif (text == "") then
		self:ReloadSuggestions(self:GetSelectedType())
	end
	
end

function PANEL:OnItemChange(lineid,line)

end
 
function PANEL:OnTypeChange(lineid,line)

	local self = self:GetParent()
	
	if (self.list_types.previous_line == lineid) then return end
	
	if not self.textbox_search then return end

	self:ReloadSuggestions(self:GetSelectedType())

	self.textbox_search.default = Restriction:GetTypes()[self:GetSelectedType()].search
	self.textbox_search:SetText("")
	self.textbox_search:OnLoseFocus()

	self.list_suggestions.VBar:SetScroll(0)
	self.list_suggestions:SelectFirstItem()
	
	self.list_items:SortData()
	
	self.list_types.previous_line = lineid
	
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
	if not self:GetSelectedType() then return end
	if not self:GetSelectedSuggestions() then return end
	
	local usergroups = self:GetSelectedUsergroups()
	if table.Count(usergroups) == 1 then usergroups = usergroups[1] end
	
	local suggestions = self:GetSelectedSuggestions()
	if table.Count(suggestions) == 1 then suggestions = suggestions[1] end
		
	local type = self:GetSelectedType()
	
	local access = self.Command.Add
	local data = {usergroups,type,suggestions,self:GetAntiSelected(),self:GetSelectedScope()}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()
	
	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) < 1) then return end
	
	local usergroups = {}
	local type = self:GetSelectedType()
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
	local data = {usergroups,type,strings}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnEditClick()
	self = self:GetParent()
	
	local items = self:GetDataView():GetSelectedItems()
	if items and (table.Count(items) ~= 1) then return end
	
	local access = self.Command.Edit
	local data = {items[1]:GetUserGroup(),items[1]:GetType(),items[1]:GetString(),self:GetAntiSelected(),self:GetSelectedScope()}
	
	WUMA.SendCommand(access,data,true)
end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleAdditionalOptionsVisiblility()
	self:GetParent():InvalidateLayout()
end

vgui.Register("WUMA_Restrictions", PANEL, 'DPanel');

