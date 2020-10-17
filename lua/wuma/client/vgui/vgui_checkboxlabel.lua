
local PANEL = {}

AccessorFunc(PANEL, "m_iIndent", "Indent")
AccessorFunc(PANEL, "HoverMessage", "HoverMessage")

function PANEL:Init()
	self:SetTall(16)

	self.Button = vgui.Create("WCheckBox", self)
	self.Button.OnChange = function(_, val) self:OnChange(val) end
	self.Button.OnCursorMoved = function(panel, x, y) self:OnCursorMoved(x + panel.x, y + panel.y) end
	self.Button.OnCursorExited = function() self:OnCursorExited() end

	local old_SetValue = self.Button.SetValue
	self.Button.SetValue = function(panel, val)
		if not self:GetDisabled() then
			old_SetValue(panel, val)
		end
	end

	self.Label = vgui.Create("DLabel", self)
	self.Label:SetMouseInputEnabled(true)
	self.Label.DoClick = function() self.Button:OnMousePressed() end
	self.Label.OnCursorMoved = function(panel, x, y) self:OnCursorMoved(x + panel.x, y + panel.y) end
	self.Label.OnCursorExited = function() self:OnCursorExited() end

	local parent = self
	while (parent:GetParent():GetClassName() ~= "CGModBase") do
		parent = parent:GetParent()
	end

	self.hover_panel = vgui.Create("DPanel", parent)
	self.hover_panel:SetVisible(false)

	self.hover_label = vgui.Create("DLabel", self.hover_panel)
	self.hover_label:SetTextColor(Color(0, 0, 0))
	self.hover_label:SetZPos(32767)

	function self.hover_panel:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local padding = 5
	local label = self.hover_label
	function self.hover_panel:PerformLayout(_, _)
		label:SizeToContents()

		self:SetSize(label:GetWide() + padding * 2, label:GetTall() + padding * 2)

		label:SetPos(padding, padding)
	end
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

function PANEL:SetDisabled( bDisabled )
	self.m_bDisabled = bDisabled

	if ( bDisabled ) then
		self:SetAlpha( 150 )
		self:SetMouseInputEnabled( true )
	else
		self:SetAlpha( 255 )
		self:SetMouseInputEnabled( true )
	end
end

function PANEL:SetTextColor(color)
	self.Label:SetTextColor(color)
end

function PANEL:OnCursorMoved(x, y)
	if self:GetHoverMessage() then
		self.hover_label:SetText(self:GetHoverMessage())

		local g_x, g_y = self:LocalToScreen(x, y)
		local a_x, a_y = self.hover_panel:GetParent():ScreenToLocal(g_x - self.hover_panel:GetWide() / 2, g_y - self.hover_panel:GetTall() - 2)

		a_x = math.Clamp(a_x, 2, self.hover_panel:GetParent():GetWide() - self.hover_panel:GetWide() - 2)
		a_y = math.Clamp(a_y, 2, self.hover_panel:GetParent():GetTall() - self.hover_panel:GetTall() - 2)

		self.hover_panel:SetPos(a_x, a_y)
		self.hover_panel:SetVisible(true)
	end
end

function PANEL:OnCursorExited()
	self.hover_panel:SetVisible(false)
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