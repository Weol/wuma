
local PANEL = {}

AccessorFunc(PANEL, "HoverMessage", "HoverMessage")

function PANEL:Init()
	self.m_iVal = -1
end

function PANEL:SetValue(value)
	if isbool(value) then
		value = value and 1 or -1
	end
	self.m_iVal = math.Clamp(value, -1, 1)

	self:OnChange(self.m_iVal)
end

function PANEL:GetValue()
	return self.m_iVal
end

function PANEL:Paint()
	draw.RoundedBox(2, 0, 0, self:GetTall(), self:GetTall(), Color(0, 0, 0, 200))
	draw.RoundedBox(2, 1, 1, self:GetTall()-2, self:GetTall()-2, Color(255, 255, 255, 255))

	if (self:GetValue() > 0) then
		surface.SetDrawColor(Color(203, 230, 203, 255))
		surface.DrawRect(3, 5, 1, 1)
		surface.DrawRect(10, 3, 1, 1)
		surface.DrawRect(10, 7, 1, 1)
		surface.DrawRect(11, 6, 1, 1)
		surface.DrawRect(3, 9, 1, 1)
		surface.DrawRect(4, 10, 1, 1)
		surface.DrawRect(4, 6, 1, 1)
		surface.DrawRect(5, 11, 1, 1)
		surface.DrawRect(5, 7, 1, 1)
		surface.DrawRect(6, 11, 1, 1)
		surface.DrawRect(6, 7, 1, 1)
		surface.DrawRect(7, 10, 1, 1)
		surface.DrawRect(7, 6, 1, 1)
		surface.DrawRect(8, 5, 1, 1)
		surface.DrawRect(8, 9, 1, 1)
		surface.DrawRect(9, 4, 1, 1)
		surface.DrawRect(9, 8, 1, 1)

		surface.SetDrawColor(Color(118, 189, 118, 255))
		surface.DrawRect(10, 4, 1, 1)
		surface.DrawRect(10, 5, 1, 1)
		surface.DrawRect(10, 6, 1, 1)
		surface.DrawRect(11, 3, 1, 1)
		surface.DrawRect(11, 4, 1, 1)
		surface.DrawRect(11, 5, 1, 1)
		surface.DrawRect(3, 6, 1, 1)
		surface.DrawRect(3, 7, 1, 1)
		surface.DrawRect(3, 8, 1, 1)
		surface.DrawRect(4, 7, 1, 1)
		surface.DrawRect(4, 8, 1, 1)
		surface.DrawRect(4, 9, 1, 1)
		surface.DrawRect(5, 10, 1, 1)
		surface.DrawRect(5, 8, 1, 1)
		surface.DrawRect(5, 9, 1, 1)
		surface.DrawRect(6, 10, 1, 1)
		surface.DrawRect(6, 8, 1, 1)
		surface.DrawRect(6, 9, 1, 1)
		surface.DrawRect(7, 7, 1, 1)
		surface.DrawRect(7, 8, 1, 1)
		surface.DrawRect(7, 9, 1, 1)
		surface.DrawRect(8, 6, 1, 1)
		surface.DrawRect(8, 7, 1, 1)
		surface.DrawRect(8, 8, 1, 1)
		surface.DrawRect(9, 5, 1, 1)
		surface.DrawRect(9, 6, 1, 1)
		surface.DrawRect(9, 7, 1, 1)
	elseif (self:GetValue() == 0) then
		draw.RoundedBox(2, 3, 3, self:GetTall() - 6, self:GetTall() - 6, Color(0, 0, 0, 200))
	else
		surface.SetDrawColor(Color(189, 118, 118, 255))

		surface.DrawLine(3, 3, self:GetTall() - 3, self:GetTall() - 3)
		surface.DrawLine(4, 3, self:GetTall() - 3, self:GetTall() - 4)
		surface.DrawLine(3, 4, self:GetTall() - 4, self:GetTall() - 3)

		surface.DrawLine(self:GetTall() - 4, 3, 2, self:GetTall() - 3)
		surface.DrawLine(self:GetTall() - 5, 3, 2, self:GetTall() - 4)
		surface.DrawLine(self:GetTall() - 4, 4, 3, self:GetTall() - 3)
	end
end

--luacheck: push no unused args
function PANEL:OnChange(val)
	--For override
end
--luacheck: pop

function PANEL:OnMousePressed()
	if (self:GetValue() ~= -1) then
		self:SetValue(-1)
	else
		self:SetValue(1)
	end
	self:Paint()
end

vgui.Register("WCheckBox", PANEL, 'DPanel');