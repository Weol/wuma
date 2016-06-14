
local PANEL = {}

PANEL.DataTable = {}

function PANEL:RegisterToData() 
	
end

function PANEL:SetDataTable(tbl)
	self.DataTable = tbl
end

function PANEL:GetDataTable()				
	return self.DataTable or {}
end

function PANEL:UpdateDataTable(tbl)
	if not self.DataTable then self:SetDataTable(tbl) return end

	for k,v in pairs(self:GetDataTable()) do
		if (v != WUMA_DATA_SEGMENT) then 
			self:UpdateDataTable(v)
		else
			self.DataTable[k] = v
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