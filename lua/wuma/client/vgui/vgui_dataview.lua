
local PANEL = {}

function PANEL:Init()
	self.PropertyViewer = vgui.Create("WPropertyView", self)
	self.PropertyViewer:SetSize(120, 200)

	self.Keys = {}
	self.Groups = {}
	self.SortedData = {}
	self.DataRegistry = {}
	self.DataTable = function() return {} end
end

function PANEL:SortByColumn(ColumnID, Desc)

	table.Copy(self.Sorted, self.Lines)

	table.sort(self.Sorted, function(a, b)

		if (Desc) then
			a, b = b, a
		end

		local aval = a:GetSortValue(ColumnID) || a:GetColumnText(ColumnID)
		local bval = b:GetSortValue(ColumnID) || b:GetColumnText(ColumnID)

		return aval < bval

	end)

	self:SetDirty(true)
	self:InvalidateLayout()

end

function PANEL:GetSelectedItems()
	local selected = self:GetSelected()
	
	local tbl = {}
	for _, v in pairs(selected) do
		table.insert(tbl, self.DataTable()[v.id])
	end
	
	return tbl
end

function PANEL:SetSortFunction(func)
	self.SortFunction = func
end

function PANEL:SetDisplayFunction(func)
	self.DisplayFunction = func
end
 
function PANEL:SetRightClickFunction(func) 
	self.RightClickFunction = func
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
			line.Paint = function(panel, w, h)
				line.old_paint(panel, w, h)
				if panel.mark then
					surface.SetDrawColor(color)
					surface.DrawRect(0, 0, w, h)
				end
			end
		end
	elseif (line.mark) then
		line.mark = nil
	end
end

function PANEL:CheckHighlights()	
	if self.HighlightFunction then
		for group, lns in pairs(self.DataRegistry) do
			for id, line in pairs(lns) do
				local data = {}
				for _, v in pairs(line.Columns) do
					table.insert(data, v.Value)
				end
				
				if self.DataTable()[id] then
					self:CheckHighlight(line, data, self.DataTable()[id]) 
				end
			end
		end
	end
end
 
function PANEL:OnRowRightClick() 
	if self.RightClickFunction then
		local item = self:GetSelectedItems()[1]
		
		if item then
			local tbl = self.RightClickFunction(item)
			
			self.PropertyViewer:SetProperties(tbl)

			local x, y = self:CursorPos()
			if (y+self.PropertyViewer:GetTall() > self:GetTall()) then y = (y-self.PropertyViewer:GetTall()) end
			self.PropertyViewer:Show(x, y)
		end
	end
end

function PANEL:AddViewLine(id)
	local item = self.DataTable()[id]

	if item then
		local data, datav = self.DisplayFunction(item)

		local line = self:AddLine(unpack(data))
		line.id = id
		
		if self.HighlightFunction then self:CheckHighlight(line, data, self.DataTable()[id]) end
		
		if datav then line.Data = datav end
		
		self.DataRegistry[self.Keys[id]] = self.DataRegistry[self.Keys[id]] or {}
		self.DataRegistry[self.Keys[id]][id] = line
		
		self:OnViewChanged()
	else
		self.Keys[id] = nil
		if self.Groups[self.Keys[id]] then
			self.Groups[self.Keys[id]][key] = nil
			if (table.Count(self.Groups[self.Keys[id]]) < 1) then
				self.Groups[self.Keys[id]] = nil
			end
		end
	end
end

function PANEL:RemoveViewLine(id)
	local line = self.DataRegistry[self.Keys[id]][id]
	self:RemoveLine(line:GetID())
	self.DataRegistry[self.Keys[id]][id] = nil

	self:OnViewChanged()
end

function PANEL:OnViewChanged() 

end

function PANEL:OnDataUpdate() 

end

function PANEL:Sort(key, item)
	local group = self.SortFunction(item)
	
	self.Keys[key] = group
	self.Groups[group] = self.Groups[group] or {}
	self.Groups[group][key] = 1 --Its really the key we are saving
	
	return group
end

function PANEL:Show(id)
	if not istable(id) then id = {id} end
	self.CurrentGroup = id

	for group, lns in pairs(self.DataRegistry) do
		if not table.HasValue(id, group) then 
			for key, line in pairs(lns) do
				self:RemoveViewLine(key)
			end
			self.DataRegistry[group] = nil
		end
	end
	
	for _, group in pairs(id) do
		if not self.DataRegistry[group] then
			self.DataRegistry[group] = {}
			for key, _ in pairs(self.Groups[group] or {}) do
				self:AddViewLine(key)
			end
		end
	end
end

function PANEL:ClearView()
	self.SortedData = {}
	self.DataRegistry = {}
	self:Clear()
	
	self:SortAll()
end

function PANEL:SortAll()
	self.Groups = {}
	self.Keys = {}

 	for k, v in pairs(self.DataTable()) do
		self:Sort(k, v)
	end
end

function PANEL:SetDataTable(func)
	self.DataTable = func
	self.SortedData = {}
	self.DataRegistry = {}
	self:Clear()
	
	self:SortAll()
end

function PANEL:UpdateDataTable(update)
	for key, value in pairs(update) do	
		if not isstring(value) then
			self:Sort(key, value)

			if self.DataRegistry[self.Keys[key]] and self.DataRegistry[self.Keys[key]][key] then
				local line = self.DataRegistry[self.Keys[key]][key]
				local data, datav = self.DisplayFunction(self.DataTable()[key])
				
				for k, v in pairs(data) do
					line:SetColumnText(k, v)
				end
				line.Data = datav or {}
				
				self:InvalidateLayout()
			elseif self.DataRegistry[self.Keys[key]] then
				self:AddViewLine(key)
			end
		else
			if self.DataRegistry[self.Keys[key]] and self.DataRegistry[self.Keys[key]][key] then
				self:RemoveViewLine(key)
			end
		end
	end
	self:CheckHighlights()
	self:OnDataUpdate()
end

function PANEL:GetDataTable()				
	return self.DataTable()
end

vgui.Register("WDataView", PANEL, 'DListView');