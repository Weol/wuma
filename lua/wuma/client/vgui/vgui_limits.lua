
local PANEL = {}

PANEL.DataTable = {}

function PANEL:SetDataTable(tbl)
	self.DataTable = tbl
end

function PANEL:UpdateDataTable(tbl,tbl2)
	local datatable = tbl2 or self.DataTable
	for k,v in pairs(tbl) do
		if not self.DataTable[k] then
			self.DataTable[k] = v
		end
	end
end

function PANEL:GetTabName()
	return "Limits"
end

function PANEL:GetTabIcon()
	return "gui/silkicons/user"
end

vgui.Register("WUMA_Restriction", PANEL, 'DPanel');