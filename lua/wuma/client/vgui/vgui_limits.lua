
local PANEL = {}

function PANEL:Init()

	self.Inheritance = {}

	--Limit chooser
	self.slider_limit = vgui.Create("WSlider", self)
	self.slider_limit:SetMinMax(1, 300)
	self.slider_limit:SetText("Limit")
	self.slider_limit:SetMaxOverride(-1, "∞")

	--Adv. Limit textbox
	self.textbox_advlimit = vgui.Create("WTextbox", self)
	self.textbox_advlimit:SetDefault("Adv. Limit")
	self.textbox_advlimit.OnChange = function() self:OnAdvLimitChanged(self.textbox_advlimit:GetValue()) end

	--Usergroups list
	self.list_usergroups = vgui.Create("DListView", self)
	self.list_usergroups:SetMultiSelect(true)
	self.list_usergroups:AddColumn("Usergroups")
	self.list_usergroups.OnRowSelected = function(_, lineid, line) self:OnUsergroupsChanged(lineid, line) end

	--Search bar
	self.textbox_search = vgui.Create("WTextbox", self)
	self.textbox_search:SetDefault("Search..")
	self.textbox_search.OnChange = function() self:OnSearch(self.textbox_search:GetValue()) end

	--Delete button
	self.button_delete = vgui.Create("DButton", self)
	self.button_delete:SetText("Delete")
	self.button_delete:SetDisabled(true)
	self.button_delete.DoClick = function() self:OnDeleteClick() end

	--Add button
	self.button_add = vgui.Create("WCollapsableButton", self)
	self.button_add:SetText("Add limit")
	self.button_add:SetInnerPadding(0, 5)
	self.button_add.DoClick = function() self:OnAddClick() end

	--Add exclusive button
	self.button_add_exlusive = vgui.Create("DButton", self)
	self.button_add_exlusive:SetText("Add exclusive limit")
	self.button_add_exlusive.DoClick = function() self:OnAddExclusiveClick() end

	self.button_add:AddButton(self.button_add_exlusive)

	--Suggestion list
	self.list_suggestions = vgui.Create("DListView", self)
	self.list_suggestions:SetMultiSelect(true)
	self.list_suggestions:AddColumn("Items")
	self.list_suggestions:SetSortable(true)

	--Items list
	self.list_items = vgui.Create("WListView", self)
	self.list_items:AddColumn("Usergroup")
	self.list_items:AddColumn("Item")
	self.list_items:AddColumn("Limit")
	self.list_items.OnItemSelected = function(_, item) return self:OnItemSelected(item) end
	self.list_items.OnViewChanged = function() return self:OnViewChanged() end
	self.list_items:SetClassifyFunction(function(...) return self:ClassifyLimit(...) end)
	self.list_items:SetSortGroupingFunction(function(...) return self:SortGrouping(...) end)

	--List footer
	self.items_footer = vgui.Create("DPanel")
	self.items_footer:SetVisible(false)

	self.footer_label = vgui.Create("DLabel", self.items_footer)
	self.footer_label:SetText("Not showing inherited limits when several usergroups are selected")
	self.footer_label:SizeToContents()
	self.footer_label:SetTextColor(Color(0, 0, 0))
	self.footer_label.DoClick = function() self:OnLoadMoreUsers() end

	self.items_footer.footer_label = self.footer_label

	function self.items_footer:SizeToContentsY()
		self:SetTall(10 + self.footer_label:GetTall())
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
		self.footer_label:SetPos(w / 2 - self.footer_label:GetWide() / 2, h / 2 - self.footer_label:GetTall() / 2)
	end

	self.list_items:AddPanel(self.items_footer)

	self:ReloadSuggestions()

end

function PANEL:PerformLayout(w, h)
	self.slider_limit:SetPos(5, 5)
	self.slider_limit:SetDecimals(0)
	self.slider_limit:SetSize(100, 40)

	self.textbox_advlimit:SetPos(5, self.slider_limit.y + self.slider_limit:GetTall() + 5)
	self.textbox_advlimit:SetSize(self.slider_limit:GetWide(), 20)

	self.list_usergroups:SetPos(5, self.textbox_advlimit.y + self.textbox_advlimit:GetTall() + 5)
	self.list_usergroups:SetSize(self.slider_limit:GetWide(), h - self.list_usergroups.y-5)

	self.textbox_search:SetSize(130, 20)
	self.textbox_search:SetPos(w - self.textbox_search:GetWide() - 5, 5)

	self.button_delete:SetSize(self.textbox_search:GetWide(), 25)
	self.button_delete:SetPos(self.textbox_search.x, h - self.button_delete:GetTall() - 5)

	self.button_add:SetWide(self.textbox_search:GetWide())
	self.button_add:SetPos(self.button_delete.x, (self.button_delete.y - 5) - self.button_add:GetTall())

	self.list_suggestions:SetPos(self.textbox_search.x, self.textbox_search.y+self.textbox_search:GetTall()+5)
	self.list_suggestions:SetSize(self.textbox_search:GetWide(), self.button_add.y-self.list_suggestions.y-5)

	self.list_items:SetPos(self.slider_limit.x + self.slider_limit:GetWide() + 5, 5)
	self.list_items:SetSize(self.textbox_search.x - self.list_items.x - 5, self:GetTall() - 10)
end

function PANEL:SortGrouping(limit)
	if (table.Count(self:GetSelectedUsergroups()) == 1) then
		local selected = self:GetSelectedUsergroups()[1]
		for i, group in ipairs(self.Inheritance[selected] or {}) do
			if (group == limit:GetParent()) then
				return i + 1, "Inherited from " .. group, true
			end
		end
	end
	return 1
end

function PANEL:ClassifyLimit(limit)
	local icon
	if limit:GetIsExclusive() then
		icon = {"icon16/ruby.png", "This limit is an exclusive limit"}
	end

	local l = limit:GetLimit()
	if ((tonumber(l) or 0) < 0) then l = "∞" end

	return limit:GetParent(), {limit:GetParent(), limit:GetItem(), l}, nil, nil, icon
end

function PANEL:ReloadSuggestions()
	self.list_suggestions:Clear()

	if (self.textbox_search:GetValue() ~= "") then
		self.list_suggestions:AddLine(self.textbox_search:GetValue())
	end

	for _, item in pairs(WUMA.GetAllLimits()) do
		if (item ~= self.textbox_search:GetValue()) then
			self.list_suggestions:AddLine(item)
		end
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
	local tbl = {}
	for _, v in pairs(self.list_usergroups:GetSelected()) do
		table.insert(tbl, v:GetColumnText(1))
	end

	return tbl
end

function PANEL:GetLimit()
	local limit = self.slider_limit:GetValue()
	if (self.slider_limit:GetDisabled()) then
		limit = self.textbox_advlimit:GetValue()
	end

	return limit
end

function PANEL:OnAdvLimitChanged(text)
	if (text ~= "") then
		self.slider_limit:SetDisabled(true)
	else
		self.slider_limit:SetDisabled(false)
	end

	if (text ~= "" and self.textbox_search:GetValue() ~= "" and text == self.textbox_search:GetValue() and text ~= self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) ~= nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
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

	if (self.textbox_advlimit:GetValue() ~= "" and self.textbox_search:GetValue() ~= "" and self.textbox_advlimit:GetValue() == self.textbox_search:GetValue() and self.textbox_advlimit:GetValue() ~= self.textbox_advlimit:GetDefault() and self.textbox_search:GetValue() ~= self.textbox_search:GetDefault()) or (tonumber(self.textbox_search:GetValue()) ~= nil) then
		self.button_add:SetDisabled(true)
	else
		self.button_add:SetDisabled(false)
	end
end

function PANEL:OnViewChanged()
	if (#self.list_items:GetSelectedItems() > 0) then
		self.button_delete:SetDisabled(false)
	else
		self.button_delete:SetDisabled(true)
	end
end

function PANEL:OnItemSelected(_)
	self.button_delete:SetDisabled(false)
end

function PANEL:NotifyLimitsChanged(limits, parent, updated, deleted)
	if (limits ~= self.list_items:GetDataSources()[parent]) then
		self.list_items:AddDataSource(parent, limits)
	else
		self.list_items:UpdateDataSource(parent, updated, deleted)
	end
end

function PANEL:NotifyInheritanceChanged(inheritance)
	inheritance = inheritance["limits"] or {}

	self.Inheritance = {}
	for usergroup, inheritsFrom in pairs(inheritance) do
		self.Inheritance[usergroup] = self.Inheritance[usergroup] or {}

		local current = inheritsFrom
		while current do
			table.insert(self.Inheritance[usergroup], current)

			current = inheritance[current]
		end
	end

	self:ShowUsergroups(self:GetSelectedUsergroups())
end

function PANEL:NotifyUsergroupsChanged(usergroups)
	self.list_usergroups:Clear()
	for _, usergroup in pairs(usergroups) do
		self.list_usergroups:AddLine(usergroup)
	end
	self.list_usergroups:SelectFirstItem()
end

--luacheck: push no unused args
function PANEL:OnItemChange(lineid, line)

end
--luacheck: pop

function PANEL:OnUsergroupsChanged()
	for _, group in pairs(self:GetSelectedUsergroups()) do
		self:OnUsergroupSelected(group)
	end

	self:ShowUsergroups(self:GetSelectedUsergroups())
end

function PANEL:ShowUsergroups(usergroups)
	local to_show = {}
	if (table.Count(usergroups) == 1) then
		for i, selected in ipairs(usergroups) do
			table.insert(to_show, selected)
			for i, group in ipairs(self.Inheritance[selected] or {}) do
				table.insert(to_show, group)
			end
		end

		self.items_footer:SetVisible(false)
	else
		for i, selected in ipairs(usergroups) do
			table.insert(to_show, selected)
		end

		self.items_footer:SetVisible(true)
	end

	self.list_items:GroupAll()
	self.list_items:Show(to_show)
end

--luacheck: push no unused args
function PANEL:OnUsergroupSelected(usergroup)
	--For override
end
--luacheck: pop

function PANEL:OnAddClick()
	local usergroups = self:GetSelectedUsergroups()
	local suggestions = self:GetSelectedSuggestions()

	local limit = self:GetLimit()

	self:OnAddLimits(usergroups, suggestions, limit, false)
end

function PANEL:OnAddExclusiveClick()
	local usergroups = self:GetSelectedUsergroups()
	local suggestions = self:GetSelectedSuggestions()

	local limit = self:GetLimit()

	self:OnAddLimits(usergroups, suggestions, limit, true)
end

--luacheck: push no unused args
function PANEL:OnAddLimits(usergroups, suggestions, limit, is_exclusive)
	--For override
end
--luacheck: pop

function PANEL:OnDeleteClick()
	local selected_items = self.list_items:GetSelectedItems()
	if table.IsEmpty(selected_items) then return end

	local parents, items = {}, {}
	for _, item in pairs(selected_items) do
		parents[item:GetParent()] = true

		items[item:GetParent()] = items[item:GetParent()] or {}

		table.insert(items[item:GetParent()], item:GetItem())
	end

	for parent, _ in pairs(parents) do
		self:OnDeleteLimits(parent, items[parent])
	end
end

--luacheck: push no unused args
function PANEL:OnDeleteLimits(usergroups, items)
	--For override
end
--luacheck: pop

vgui.Register("WUMA_Limits", PANEL, 'DPanel');