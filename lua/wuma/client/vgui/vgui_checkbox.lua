
local PANEL = {}

function PANEL:Init()
	self.m_iVal = 1
end

function PANEL:SetValue(value)
	self.m_iVal = value
	
	self:OnChange(value)
end

function PANEL:GetValue()
	return self.m_iVal
end

function PANEL:Paint()	
	draw.RoundedBox(2, 0, 0, self:GetTall(), self:GetTall(), Color(0, 0, 0, 200))
	draw.RoundedBox(2, 1, 1, self:GetTall()-2, self:GetTall()-2, Color(255, 255, 255, 255))
	
	local color = Color(0, 0, 0, 255)
	
	if (self:GetValue() < 0) then
		surface.SetDrawColor(Color(189, 118, 118, 255))
	
		surface.DrawLine(3, 3, self:GetTall() - 3, self:GetTall() - 3)
		surface.DrawLine(4, 3, self:GetTall() - 3, self:GetTall() - 4)
		surface.DrawLine(3, 4, self:GetTall() - 4, self:GetTall() - 3)
		
		surface.DrawLine(self:GetTall() - 4, 3, 2, self:GetTall() - 3)
		surface.DrawLine(self:GetTall() - 5, 3, 2, self:GetTall() - 4)
		surface.DrawLine(self:GetTall() - 4, 4, 3, self:GetTall() - 3)
	elseif (self:GetValue() == 0) then
		draw.RoundedBox(2, 3, 3, self:GetTall() - 6, self:GetTall() - 6, Color(0, 0, 0, 210))
	end
end

function PANEL:OnChange(val)
	
end

function PANEL:OnMousePressed()
	if (self:GetValue() ~= -1) then
		self:SetValue(-1)
	else
		self:SetValue(1)
	end
	self:Paint()
end

vgui.Register("WCheckBox", PANEL, 'DPanel');