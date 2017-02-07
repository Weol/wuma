
local PANEL = {}

PANEL.DataTable = {}
PANEL.DataRegistry = {}
PANEL.DataView = nil
PANEL.SortFunction = nil
PANEL.RightClickFunction = nil

function PANEL:x(gui) 
	local x, y = gui:GetPos()
	return x
end

function PANEL:y(gui) 
	local x, y = gui:GetPos()
	return y
end

function PANEL:GetSelectedItems()
	if not self.DataView or not self.DataView:GetSelected() then return false end
	local selected = self.DataView:GetSelected()
	
	local tbl = {}
	for id, line in pairs(self.DataRegistry) do
		for k, v in pairs(self.DataView:GetSelected()) do
			if (v == line) then
				table.insert(tbl,self.DataTable[id])
			end
		end
	end
	
	return tbl
end

function PANEL:SetRightClickData(func) 
	self.RightClickFunction = func
	
	if not self.SelectedItemPropertyView then
		self.SelectedItemPropertyView = WUMA.CreatePropertyViewer{parent=self,x=0,y=0,w=120,h=200,visible=false} 
		
		self.SelectedItemPropertyView.OnCursorExited = function()	
			if self.SelectedItemPropertyView then
				self.SelectedItemPropertyView:SetVisible(false)
			end
		end
	end
end

function PANEL:SetDataView(dlistview)
	self.DataView = dlistview
	
	self.DataView.OnRowRightClick = function() 
		if self.RightClickFunction then
			local item = self:GetSelectedItems()[1]
			
			local tbl = self.RightClickFunction(item)
			
			self.SelectedItemPropertyView:SetProperties(tbl)

			local x, y = self:CursorPos()
			if (y+self.SelectedItemPropertyView:GetTall() > dlistview:GetTall()) then y = (y-self.SelectedItemPropertyView:GetTall()) end
			self.SelectedItemPropertyView:SetPos(x,y)
			self.SelectedItemPropertyView:SetVisible(true)
		end
	end
	
	self:SetDataTable(self.DataTable)
end

function PANEL:AddViewLine(id,data)
	if not self.DataView then return end
	
	local line = self.DataView:AddLine(unpack(data))
	self.DataRegistry[id] = line
end

function PANEL:RemoveViewLine(id)
	if not self.DataView then return end
	
	if isstring(id) then
		local line = self.DataRegistry[id]
		self.DataView:RemoveLine(line:GetID())
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
	if not istable(item) then return false end
	return self.SortFunction(item)
end

function PANEL:SortData()
	for id, data in pairs(self.DataTable) do
		if isstring(data) then 
			data = nil 
		else
			local sort = self:SortItem(data)
			
			if sort then
				if not self.DataRegistry[id] then
					self:AddViewLine(id,sort)
				end
			else
				if self.DataRegistry[id] then
					self:RemoveViewLine(id)
				end
			end
		end
	end
	
	if self.DataView then
		self.DataView.VBar:SetScroll(0)
	end
end

function PANEL:SetDataTable(tbl)
	self.DataTable = tbl
	
	if self.DataView then	
		for id, data in pairs(self.DataTable) do
			if isstring(data) then data = nil end
			local sort = self:SortItem(data)
			if sort then
				self:AddViewLine(id,sort)
			end
		end
	end
end

function PANEL:GetDataTable()				
	return self.DataTable or {}
end

function PANEL:UpdateDataTable(tbl)
	if (table.Count(self.DataTable) < 1) then self:SetDataTable(tbl) return end
	
	for id, data in pairs(tbl) do
		local sort = self:SortItem(data)
		if self.DataRegistry[id] then
			local line = self.DataRegistry[id]
			
			if istable(data) then
				for i, _ in pairs(line.Columns) do
					line:SetValue(i,sort[i])
				end
			else
				if (data == WUMA.DELETE) then
					if line:IsLineSelected() then line:SetSelected(false) end
					self:RemoveViewLine(id)
				end
			end
		elseif sort then
			self:AddViewLine(id,sort)
		end
	end
end

function PANEL:GetTabName()
	return self.TabName or "EMPTY"
end

function PANEL:GetTabIcon()
	return self.TabIcon or "EMPTY"
end

vgui.Register("WUMA_Base", PANEL, 'DPanel');