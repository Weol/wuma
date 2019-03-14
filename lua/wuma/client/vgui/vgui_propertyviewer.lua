
local PANEL = {}

function PANEL:Init()
	self.Properties = {}
end

function PANEL:Show(x, y)
	self:SetPos(x, y)
	self:SetVisible(true)
end

function PANEL:OnCursorExited()	
	self:SetVisible(false)
end

function PANEL:SetProperties(properties)
	self.Properties = properties
end

function PANEL:GetProperties()
	return self.Properties or {}
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawRect(0, 0, w, h)
	
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(0, 0, w, h)

	local y = 3
	for k, v in pairs(self:GetProperties() or {}) do
		draw.DrawText(v[1]..":", "DermaDefault", 5, y, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		y=y+12
		
		if v[2] then 
			draw.DrawText(v[2], "DermaDefault", 10, 2+y, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			y=y+15
		end
		
		surface.DrawLine(0, y+5, w, y+5)
		y = y+7
		
	end 
	
	self:SetTall(y-2);
end

vgui.Register("WPropertyView", PANEL, 'DPanel');