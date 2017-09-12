
local PANEL = {}

PANEL.DataTable = {}
PANEL.DataRegistry = {}
PANEL.DataGroupRegistry = {}
PANEL.GroupedData = {}
PANEL.SortFunction = nil
PANEL.RightClickFunction = nil
PANEL.HighlightFunction = nil

function PANEL:Init()
	self.PropertyViewer = vgui.Create("WPropertyView",self)
	self.PropertyViewer:SetSize(120,200)
end

function PANEL:GetSelectedItems()
	local selected = self:GetSelected()
	
	local tbl = {}
	for id, line in pairs(self.DataRegistry) do
		for _, v in pairs(selected) do
			if (v == line) then
				table.insert(tbl,self.DataTable[id])
			end
		end
	end
	
	return tbl
end
 
function PANEL:SetHighlightFunction(func) 
	self.HighlightFunction = func
end
 
function PANEL:CheckHighlight(line, data, datav) 
	local color = self.HighlightFunction(line, data, datav)
	if color then
		line.mark = true
		if not line.old_paint then
			line.old_paint = line.Paint
			line.Paint = function(panel,w,h)
				line.old_paint(panel,w,h)
				if panel.mark then
					surface.SetDrawColor(color)
					surface.DrawRect(0,0,w,h)
				end
			end
		end
	elseif (line.mark) then
		line.mark = nil
	end
end
 
function PANEL:SetRightClickFunction(func) 
	self.RightClickFunction = func
end

function PANEL:OnRowRightClick() 
	if self.RightClickFunction then
		local item = self:GetSelectedItems()[1]
		
		local tbl = self.RightClickFunction(item)
		
		self.PropertyViewer:SetProperties(tbl)

		local x, y = self:CursorPos()
		if (y+self.PropertyViewer:GetTall() > self:GetTall()) then y = (y-self.PropertyViewer:GetTall()) end
		self.PropertyViewer:Show(x,y)
	end
end

function PANEL:AddViewLine(id,data,datav)
	local line = self:AddLine(unpack(data))
	
	if self.HighlightFunction then self:CheckHighlight(line,data,self.DataTable[id]) end
	
	if datav then line.Data = datav end
	self.DataRegistry[id] = line
	
	self:OnViewChanged()
end

function PANEL:RemoveViewLine(id)
	if isstring(id) then
		local line = self.DataRegistry[id]
		self:RemoveLine(line:GetID())
		self.DataRegistry[id] = nil
		line = nil
	end
	
	self:OnViewChanged()
end

function PANEL:OnViewChanged() 

end

function PANEL:OnDataUpdate() 

end

function PANEL:SetSortFunction(func)
	self.SortFunction = func
end

function PANEL:GetSortFunction()
	return self.SortFunction
end

function PANEL:SortItem(item)	
	if not self.SortFunction then return false end
	if not item or isstring(item) then return false end
	return self.SortFunction(item)
end

function PANEL:SortData(groups)
	if groups and self.GroupedData then
		self:SortGroupedData(groups) 
		return
	end
	
	for id, data in pairs(self.DataTable) do
		if isstring(data) then 
			data = nil 
		else
			local sort, sortv = self:SortItem(data)
			
			if sort then
				if not self.DataRegistry[id] then
					self:AddViewLine(id,sort,sortv)
				end
			else
				if self.DataRegistry[id] then
					self:RemoveViewLine(id)
				end
			end
		end
	end
	
	self.VBar:SetScroll(0)
end

function PANEL:SortGroupedData(groups)
	if not istable(groups) then groups = {groups} end

	if (table.Count(self.DataGroupRegistry) == 0) and (table.Count(self.DataRegistry) > 0) then 
		self:Clear()
		self.DataRegistry = {}
	else 
		for group, _ in pairs(self.DataGroupRegistry) do
			if not table.HasValue(groups, group) then
				for id, _ in pairs(self.GroupedData[group] or {}) do
					if self.DataRegistry[id] then
						self:RemoveViewLine(id)
					end
				end
				self.DataGroupRegistry[group] = nil
			end
		end
	end
	
	for _, group in pairs(groups) do
		for id, _ in pairs(self.GroupedData[group] or {}) do
			local data = self.DataTable[id]
			if isstring(data) then 
				data = nil 
			else
				local sort, sortv = self:SortItem(data)
				
				if sort then
					if not self.DataRegistry[id] then
						self:AddViewLine(id,sort,sortv)
					end
				else
					if self.DataRegistry[id] then
						self:RemoveViewLine(id)
					end
				end
			end
		end		
		self.DataGroupRegistry[group] = 1
	end 
	self.VBar:SetScroll(0)
end

function PANEL:SetDataTable(tbl)
	self.DataTable = tbl or {}
	self.DataRegistry = {}
	self:Clear()
	
	for id, data in pairs(self.DataTable) do
		if isstring(data) then data = nil end
		local sort, sortv = self:SortItem(data)
		if sort then
			self:AddViewLine(id,sort,sortv)
		end
	end
	
	self:GroupBy()
	self:OnDataUpdate()
end

function PANEL:GetDataTable()				
	return self.DataTable or {}
end

function PANEL:CheckHighlights()	
	if self.HighlightFunction then
		for id, line in pairs(self.DataRegistry) do
			local data = {}
			for _, v in pairs(line.Columns) do
				table.insert(data,v.Value)
			end
			
			self:CheckHighlight(line,data,self.DataTable[id]) 
		end
	end
end

function PANEL:SetGroupFunction(func)
	self.GroupFunction = func
end

function PANEL:GroupItem(item, id) 
	if not self.GroupFunction then return end
	local group = self.GroupFunction(item)
	if not group then return end
	if not self.GroupedData[group] then self.GroupedData[group] = {} end
	self.GroupedData[group][id] = 1  --Its really the key we are saving
end

function PANEL:GroupBy()
	if not self.GroupFunction then return end
	self.GroupedData = {}
	for id, item in pairs(self.DataTable) do
		self:GroupItem(item, id)
	end
end

function PANEL:UpdateDataTable(tbl)
	if not tbl then return end
	if (table.Count(self.DataTable) < 1) then self:SetDataTable(tbl) return end
	
	for id, data in pairs(tbl) do
		local sort, sortv = self:SortItem(data)
		if self.DataRegistry[id] then
			local line = self.DataRegistry[id]
			if istable(data) and sort then
				for i, _ in pairs(line.Columns) do
					line:SetValue(i,sort[i])
					if sortv and sortv[i] then line:SetSortValue(i,sortv[i]) end
				end
				self.DataTable[id] = data
				self:GroupItem(data, id)
			elseif (data == WUMA.DELETE) then
				if line:IsLineSelected() then line:SetSelected(false) end
				self:RemoveViewLine(id)
				self.DataTable[id] = nil
			end
		elseif sort then
			self.DataTable[id] = data
			self:GroupItem(data, id)
			self:AddViewLine(id,sort,sortv)
		end
	end
	
	self:OnDataUpdate()
	self:CheckHighlights()
	
end

vgui.Register("WDataView", PANEL, 'DListView');