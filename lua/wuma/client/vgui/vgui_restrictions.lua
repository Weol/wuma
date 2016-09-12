
local PANEL = {}

PANEL.TabName = "Restrictions"
PANEL.TabIcon = "gui/silkicons/shield"

function PANEL:CreateChildren()
	
	//Restriction types list
	self.list_types = WUMA.CreateList{parent=self,multiselect=false,text="Types",onrowselected=self.OnTypeChange,populate=Restriction:GetTypes("print"),select="Entity",x=5,y=5,size_to_content_y=true,w=100,sortable=false}

	//Usergroups list
	self.list_usergroups = WUMA.CreateList{parent=self,multiselect=true,text="Usergroups",onrowselected=self.OnUsergroupChange,populate=WUMA.ServerGroups,select=1,relative=self.list_types,relative_align=3,x=0,y=5,w=self.list_types:GetWide(),h=(self:GetTall()-self.list_types:GetTall())-15,sortable=false} 
	
	hook.Add( WUMA.USERGROUPSUPDATE , "WUMAVGUIRestrictionsUserGroupsList", function() 
		WUMA.PopulateList(self.list_usergroups,WUMA.ServerGroups,true) 
	end )
	
	//Search bar
	self.textbox_search = WUMA.CreateTextbox{parent=self,default="Search..",text_changed=self.OnSearch,align=2,x=self:GetWide()-5,y=5,w=130,h=20} 
	
	//Settings button
	self.button_settings = WUMA.CreateButton{parent=self,icon="icon16/cog.png",onclick=self.OnSettingsClick,align=4,x=self:GetWide()-5,y=self:GetTall()-5,w=25,h=25}
	
	//Edit button
	self.button_edit = WUMA.CreateButton{parent=self,text="Edit",onclick=self.OnEditClick,relative=self.button_settings,align=2,x=-5,y=0,w=self.textbox_search:GetWide()-30,h=25}
	
	//Delete button
	self.button_delete = WUMA.CreateButton{parent=self,text="Delete",onclick=self.OnDeleteClick,align=3,relative=self.button_edit,x=0,y=-5,w=self.textbox_search:GetWide(),h=self.button_edit:GetTall()}

	//Add button
	self.button_add = WUMA.CreateButton{parent=self,text="Add",onclick=self.OnAddClick,align=3,relative=self.button_delete,x=0,y=-5,w=self.textbox_search:GetWide(),h=self.button_edit:GetTall()}
	
	//Suggestion list
	self.list_suggestions = WUMA.CreateList{parent=self,multiselect=true,text="Items",relative=self.textbox_search,relative_align=3,x=0,y=5,w=self.textbox_search:GetWide(),h=self:GetTall()-((self:y(self.textbox_search)+self.textbox_search:GetTall()+15)+(self:GetTall()-(self:y(self.button_add)+5)))} 

	//Items list
	self.list_items = WUMA.CreateList{parent=self,multiselect=true,text="Usergroup",relative=self.list_types,relative_align=2,x=5,y=0,w=self:GetWide()-((self.list_types:GetWide()+10)+(self.textbox_search:GetWide()+10)),h=self:GetTall()-10,onrowselected=self.OnItemChange} 
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Scope")

	//Scope list
	self.list_scopes = WUMA.CreateList{parent=self,multiselect=false,select="Normal",text="Scope",onrowselected=self.OnScopeChange,populate=table.Add({"Permanent"},Scope:GetTypes("print")),relative=self.list_usergroups,relative_align=4,align=3,x=5,y=0,w=120,visible=false,sortable=false} 

		//date_chooser list
		self.date_chooser = WUMA.CreateDateChooser{parent=self,relative=self.list_scopes,relative_align=2,x=5,y=0,visible=false}
		
		//time_chooser list
		self.time_chooser = WUMA.CreateTimeChooser{parent=self,decimals=0,min=0,max=1440,relative=self.list_scopes,relative_align=2,x=5,y=0,visible=false}
		
		//period_chooser list
		self.period_chooser = WUMA.CreatePeriodChooser{parent=self,decimals=0,min=0,max=1440,relative=self.list_scopes,relative_align=2,x=5,y=0,visible=false}
		
		//map_chooser 
		self.map_chooser = WUMA.CreateMapChooser{parent=self,options=WUMA.Maps,relative=self.list_scopes,relative_align=2,x=5,y=0,w=125,visible=false}
	
	hook.Add( WUMA.MAPSUPDATE , "WUMAVGUIRestrictionsMapsUpdate", function() 
		self.map_chooser:Clear()
		self.map_chooser:AddOptions(WUMA.Maps)
	end )

	//Allow checkbox
	self.checkbox_allow = WUMA.CreateCheckbox{parent=self,text="Anti Restriction",checked=0,align=3,relative=self.list_scopes,x=0,y=-5,visible=false} 
	
	self.list_types:SelectFirstItem()
	
end

function PANEL:CreateDataView()

	local sort = function(data)
		if not data.usergroup or not data.type then return false end
		if not table.HasValue(self:GetSelectedUsergroups(),data.usergroup) then return false end 
		if not (self:GetSelectedType() == data.type) then return false end
		
		local scope = "Permanent"
		if data:GetScope() then
			scope = data:GetScope():GetPrint2()
		end
		if scope and istable(scope) and scope.type and Scope.types[scope.type] then scope = Scope.types[scope.type].print end
		
		return {data.usergroup, data.print or data.string, scope}
	end
		
	self:SetDataView(self.list_items)
	self:SetSortFunction(sort)

	local right_click = function(item)
		local tbl = {}
		tbl[1] = {"Item",item:GetString()}
		tbl[2] = {"Usergroup",item:GetUsergroup()}
		tbl[3] = {"Type",item:GetType()}
		tbl[4] = {"Scope",item:GetScope() or "Permanent"}
		if item:GetAllow() then tbl[5] = {"Anti-Restriction"} end
		
		return tbl
	end

	self:SetRightClickData(right_click)
end

PANEL.HasCreated = false
function PANEL:Think() 
	if not (self.HasCreated) then
		self:CreateChildren()
		self:CreateDataView()
		self.HasCreated = true
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
		
		WUMA.PopulateList(self.list_suggestions,items(),true)
	end
end

function PANEL:GetSelectedType()
	if not self.list_types:GetSelected() then return false end
	for k,v in pairs(Restriction:GetTypes()) do
		if (v.print == self.list_types:GetSelected()[1]:GetValue(1)) then
			return k
		end
	end		
end

function PANEL:GetSelectedSuggestions()
	if not self.list_suggestions:GetSelected() then return false end
	
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
		
	PrintTable(scope)
		
	return util.TableToJSON(scope)
	
end

function PANEL:GetAntiSelected()
	if self.checkbox_allow:GetChecked() then
		return 1
	else
		return 0
	end
end

PANEL.ItemListVisiblility = false
function PANEL:ToggleItemListVisiblility()
	if (self.ItemListVisiblility) then
		local w, h = self.list_items:GetWide(), self.ItemListVisiblility
		self.list_items:SizeTo(w,h,0.2)
		
		self.ItemListVisiblility = false
		
		self:ToggleAdditonalOptions()
	else
		self.ItemListVisiblility = self.list_items:GetTall()
		local w, h = self.list_items:GetWide(), self.list_items:GetTall() - (#(self.list_scopes:GetLines() or {}) * 17 + self.list_scopes:GetHeaderHeight() + 1) - 25
		self.list_items:SizeTo(w,h,0.2)
		
		self:ToggleAdditonalOptions()
	end
end

PANEL.AdditonalOptionsVisibility = false
function PANEL:ToggleAdditonalOptions()

	local scope = self.list_scopes
	local x,y = scope:GetPos()
	local height = #(scope:GetLines() or {}) * 17 + scope:GetHeaderHeight() + 1
	
	scope:SetVisible(true)
	self.checkbox_allow:SetVisible(true)
	
	if self.AdditonalOptionsVisibility then
		self.AdditonalOptionsVisibility = false
 
		scope:MoveTo(x,y+height,0.2)
		scope:SizeTo(scope:GetWide(),0,0.2)
		
		self.checkbox_allow:MoveTo(self:x(self.checkbox_allow),y+height,0.2)
		self.checkbox_allow:SizeTo(self.checkbox_allow:GetWide(),0,0.2)
		
		for _, parts in pairs(Scope:GetTypes("parts")) do 
			for _, part_name in pairs(parts) do 
				local part = self[part_name]
				if part then
					part:MoveTo(self:x(part),y+height+part:GetTall(),0.2)
					part.showing = false
				end
			end
		end
	else
		self.AdditonalOptionsVisibility = true
		
		scope:SizeTo(scope:GetWide(),height,0.2)
		scope:MoveTo(x,y-height,0.2)
		
		self.checkbox_allow:MoveTo(x,y-height-5-15,0.2)
		self.checkbox_allow:SizeTo(self.checkbox_allow:GetWide(),15,0.2)
		
		for _, parts in pairs(Scope:GetTypes("parts")) do 
			for _, part_name in pairs(parts) do 
				local part = self[part_name]
				if part then
					part:MoveTo(self:x(part),y-height,0.2)
					part.showing = false
				end
			end
		end
	end
end

function PANEL:OnSearch()

	local self = self:GetParent()
		
	local text = self.textbox_search:GetValue()
	
	if not self.list_suggestions:GetDisabled() and (text != "") then
	
		self:ReloadSuggestions(self:GetSelectedType())
	
		for k, line in pairs(self.list_suggestions:GetLines()) do
			local item = line:GetValue(1)
			if not string.match(item,text) then
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
	
	self:SortData()
	
	self.list_types.previous_line = lineid
	
end

function PANEL:OnUsergroupChange()
	local self = self:GetParent()
	
	self:SortData()
end

function PANEL:OnScopeChange(lineid, line)

	if (self:GetParent().list_scopes.previous_line == lineid) then return end

	local self = self:GetParent()
	local scope = self.list_scopes
	
	for _, parts in pairs(Scope:GetTypes("parts")) do 
		for _, part_name in pairs(parts) do 
			if self[part_name] then
				self[part_name]:MoveTo(self:x(self[part_name]),self:GetTall() + self[part_name]:GetTall()+10,0.2)
				self[part_name].showing = false
				timer.Simple(0.2, function() if not self[part_name].showing then self[part_name]:SetVisible(false) end end)
			end
		end
	end
	
	for _, tbl in pairs(Scope:GetTypes()) do
		if tbl.parts and (tbl.print == scope:GetSelected()[1]:GetValue(1)) then
			for _, part_name in pairs(tbl.parts) do
				if self[part_name] then
					local part = self[part_name]
					part:SetPos(self:x(part),self:GetTall()+part:GetTall()+10)
					part.showing = true
					part:SetVisible(true)
					part:MoveTo(self:x(part),self:y(scope),0.2)
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
	
	local access = "restrict"
	local data = {usergroups,type,suggestions,self:GetAntiSelected(),self:GetSelectedScope()}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()

	local access = "unrestrict"
end

function PANEL:OnEditClick()

end

function PANEL:OnSettingsClick()
	self:GetParent():ToggleItemListVisiblility()
end

vgui.Register("WUMA_Restrictions", PANEL, 'WUMA_Base');

