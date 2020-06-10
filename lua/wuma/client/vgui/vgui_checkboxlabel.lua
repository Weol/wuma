
local PANEL = {}

AccessorFunc(PANEL, "m_iIndent", "Indent")

function PANEL:Init()
	self:SetTall(16)

	self.Button = vgui.Create("WCheckBox", self)
	self.Button.OnChange = function(_, val) self:OnChange(val) end

	self.Label = vgui.Create("DLabel", self)
	self.Label:SetMouseInputEnabled(true)
	self.Label.DoClick = function() self.Button:OnMousePressed() end
end

function PANEL:SetDark(b)
	self.Label:SetDark(b)
end

function PANEL:SetBright(b)
	self.Label:SetBright(b)
end

function PANEL:SetValue(val)
	self.Button:SetValue(val)
end

function PANEL:GetValue()
	self.Button:GetValue()
end

function PANEL:PerformLayout()
	local x = self.m_iIndent or 0

	self.Button:SetSize(15, 15)
	self.Button:SetPos(x, math.floor((self:GetTall() - self.Button:GetTall()) / 2))

	self.Label:SizeToContents()
	self.Label:SetPos(x + self.Button:GetWide() + 9, 0)
end

function PANEL:SetTextColor(color)
	self.Label:SetTextColor(color)
end

function PANEL:SizeToContents()
	self:InvalidateLayout(true) -- Update the size of the DLabel and the X offset
	self:SetWide(self.Label.x + self.Label:GetWide())
	self:SetTall(math.max(self.Button:GetTall(), self.Label:GetTall()))
	self:InvalidateLayout() -- Update the positions of all children
end

function PANEL:SetText(text)
	self.Label:SetText(text)
	self:SizeToContents()
end

function PANEL:SetFont(font)
	self.Label:SetFont(font)
	self:SizeToContents()
end

function PANEL:GetText()
	return self.Label:GetText()
end

function PANEL:Paint()
end

--luacheck: push no unused args
function PANEL:OnChange(val)
	--For override
end
--luacheck: pop

vgui.Register("WCheckBoxLabel", PANEL, 'DPanel');