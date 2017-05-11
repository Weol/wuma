
local PANEL = {}

PANEL.DataTable = {}
PANEL.DataRegistry = {}
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
end

function PANEL:RemoveViewLine(id)
	if isstring(id) then
		local line = self.DataRegistry[id]
		self:RemoveLine(line:GetID())
		self.DataRegistry[id] = nil
		line = nil
	end
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

function PANEL:SortData()
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
end

function PANEL:GetDataTable()				
	return self.DataTable or {}
end

function PANEL:CheckHighlights()				
	for id, line in pairs(self.DataRegistry) do
		local data = {}
		for _, v in pairs(line.Columns) do
			table.insert(data,v.Value)
		end
		
		if self.HighlightFunction then self:CheckHighlight(line,data,self.DataTable[id]) end 
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
			elseif (data == WUMA.DELETE) then
				if line:IsLineSelected() then line:SetSelected(false) end
				self:RemoveViewLine(id)
				self.DataTable[id] = nil
		end
		elseif sort then
			self.DataTable[id] = data
			self:AddViewLine(id,sort,sortv)
		end
	end
	
	self:CheckHighlights()
	
end

vgui.Register("WDataView", PANEL, 'DListView');