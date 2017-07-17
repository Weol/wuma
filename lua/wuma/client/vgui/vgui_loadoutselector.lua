
local PANEL = {}

PANEL.HelpText = [[You can set your own loadout in this window. Any weapons you can spawn with are shown here, any missing weapons are either weapons that the server does not have or weapons that the server has restricted from you or your usergroup.]]

function PANEL:Init()

	self.weapons = WUMA.GetWeapons()

	self.Command = {}
	self.Command.Add = "addpersonalloadout"
	self.Command.Delete = "removepersonalloadout"
	self.Command.Edit = "addpersonalloadout"
	self.Command.Clear = "clearpersonalloadout"
	self.Command.Primary = "setpersonalprimaryweapon"

	//HelpText Label
	self.helptext_label = vgui.Create("DLabel", self)
	self.helptext_label:SetText(self.HelpText)
	self.helptext_label:SetTextColor(Color(0,0,0))
	self.helptext_label:SetAutoStretchVertical( true )
	
	//Search bar
	self.textbox_search = vgui.Create("WTextbox",self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = self.OnSearch
	--{parent=self,default="Search..",text_changed=self.OnSearch,align=2,x=self:GetWide()-5,y=5,w=130,h=20} 
	
	//Primary button
	self.button_primary = vgui.Create("DButton",self)
	self.button_primary:SetText("Set Primary")
	self.button_primary.DoClick = self.OnPrimaryClick
	
	--{parent=self,text="Set Primary",onclick=self.OnPrimaryClick,relative=self.button_settings,align=2,x=-5,y=0,w=self.textbox_search:GetWide()-30,h=25}

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
	self.list_items:AddColumn("Weapon")
	self.list_items.OnRowSelected = self.OnItemChange
	
	local highlight = function(line,data,datav)
		if datav.isprimary then return Color(0,255,0,120) else return nil end
	end
	self.list_items:SetHighlightFunction(highlight)
	--{parent=self,multiselect=true,text="Usergroup",relative=self.list_types,relative_align=2,x=5,y=0,w=self:GetWide()-((self.list_types:GetWide()+10)+(self.textbox_search:GetWide()+10)),h=self:GetTall()-10,onrowselected=self.OnItemChange} 
	
	local sort = function(data)	
		local primary = data.primary or -1
		if (tonumber(primary) < 0) then primary = "def" end
		
		local secondary = data.secondary or -1
		if (tonumber(secondary) < 0) then secondary = "def" end
	
		return {data.class},{_}
	end
		
	self:GetDataView():SetSortFunction(sort)
	
	local right_click = function(item)
		local tbl = {}
		tbl[1] = {"Item",item.class}
		tbl[2] = {"Primary",item.primary}
		tbl[3] = {"Secondary",item.secondary}
		
		return tbl
	end

	self:GetDataView():SetRightClickFunction(right_click)
	
	self:ReloadSuggestions()
	
end

function PANEL:PerformLayout()

	self.textbox_search:SetSize(130,20)
	self.textbox_search:SetPos((self:GetWide()-5)-self.textbox_search:GetWide(),5)

	self.button_primary:SetSize(self.textbox_search:GetWide(),25)
	self.button_primary:SetPos(self.textbox_search.x,self:GetTall()-self.button_primary:GetTall()-5)

	self.button_add:SetSize(self.textbox_search:GetWide()/2-3,25)
	self.button_add:SetPos(self.button_primary.x,(self.button_primary.y-5)-self.button_primary:GetTall())
	
	self.button_delete:SetSize(self.textbox_search:GetWide()/2-3,25)
	self.button_delete:SetPos(self.button_add.x+self.button_add:GetWide()+6,(self.button_primary.y-5)-self.button_primary:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x,self.textbox_search.y+self.textbox_search:GetTall()+5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(),self.button_add.y-self.list_suggestions.y-5)
	
	self.list_items:SetPos(5,5)
	self.list_items:SetSize(self:GetWide()-20-self.textbox_search:GetWide(),self:GetTall()-100)
	
	self.helptext_label:SetWide(self.list_items:GetWide())
	self.helptext_label:SetPos(5,self.list_items:GetTall() + 5)
	
	self.helptext_label:SetText("")
	local words = string.Explode(" ", self.HelpText)
	local current_line = ""
	for _, word in pairs(words) do
		self.helptext_label:SetText(self.helptext_label:GetText() .. " " .. word)
		current_line = current_line .. " " .. word
		
		surface.SetFont(self.helptext_label:GetFont())
		local w, h = surface.GetTextSize(current_line .. " " .. word)
		
		if (w > self.list_items:GetWide()-10) then
			self.helptext_label:SetText(self.helptext_label:GetText() .. "\n")
			current_line = ""
		end
	end
	
	self.list_items:SetTall(self:GetTall() - self.helptext_label:GetTall() - 15)
	self.helptext_label:SetPos(5, self.list_items:GetTall() + 10)

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

	self:PopulateList("list_suggestions",self.weapons,true)
		
	self.list_suggestions.VBar:SetScroll(0)
end

function PANEL:GetSelectedSuggestions()
	local tbl = {}
	for _,v in pairs(self.list_suggestions:GetSelected()) do
		table.insert(tbl,v:GetColumnText(1))
	end		
	return tbl
end

function PANEL:GetSelectedUsergroups()
	return LocalPlayer():SteamID()
end

function PANEL:GetPrimaryAmmo()
	if not self.slider_primary then return nil end
	
	return self.slider_primary:GetValue()
end

function PANEL:GetSecondaryAmmo()
	if not self.slider_secondary then return nil end
	
	return self.slider_secondary:GetValue()
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
	
end

function PANEL:OnItemChange(lineid,line)

end

function PANEL:OnPrimaryClick()
	self = self:GetParent()
	
	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) ~= 1) then return end
	
	local str = {items[1].class}

	local access = self.Command.Primary
	local data = {str}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnAddClick()
	self = self:GetParent()
	if not self:GetSelectedSuggestions() then return end
	
	local suggestions = self:GetSelectedSuggestions()
	if table.Count(suggestions) == 1 then suggestions = suggestions[1] end
	
	local access = self.Command.Add
	local data = {suggestions,self:GetPrimaryAmmo() or -1,self:GetSecondaryAmmo() or -1}
	
	WUMA.SendCommand(access,data)
end

function PANEL:OnDeleteClick()
	self = self:GetParent()
	
	local items = self:GetDataView():GetSelectedItems()
	if (table.Count(items) < 1) then return end
	
	local strings = {}
	
	for _, v in pairs(items) do
		if not table.HasValue(strings,v.class) then
			table.insert(strings,v.class)	
		end
	end
	
	local access = self.Command.Delete
	local data = {strings}
	
	WUMA.SendCommand(access,data)
end

vgui.Register("WUMA_PersonalLoadout", PANEL, 'DPanel');