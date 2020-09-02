
local PANEL = {}

AccessorFunc(PANEL, "is_collapsed", "IsCollapsed")
AccessorFunc(PANEL, "x_padding", "XPadding")
AccessorFunc(PANEL, "y_padding", "YPadding")

function PANEL:Init()
	self.buttons = {}

	self:SetInnerPadding(0, 0)
	self:SetIsCollapsed(true)

	self.button = vgui.Create("DButton", self)
	self.button.DoClick = function() self:DoClick() end

	local old_button_Paint = self.button.Paint
	self.button.Paint = function(self, w, h)
		local ret = old_button_Paint(self, w, h)

		surface.SetDrawColor(234, 234, 234, 255)
		surface.DrawLine(w - 3, 1, w - 3, h - 2)

		return ret
	end

	self.arrow = vgui.Create("DButton", self)
	self.arrow:SetIcon("icon16/bullet_arrow_down.png")
	self.arrow:SetText("")
	self.arrow.DoClick = function() self:Toggle() end

	local old_arrow_Paint = self.arrow.Paint
	self.arrow.Paint = function(self, w, h)
		local ret = old_arrow_Paint(self, w, h)

		surface.SetDrawColor(82, 82, 82, 255)
		surface.DrawLine(0, 0, 0, h)
		surface.DrawLine(0, 0, 2, 0)
		surface.DrawLine(0, h - 1, 2, h - 1)

		surface.SetDrawColor(234, 234, 234, 255)
		surface.DrawLine(0, 1, 2, 1)
		surface.DrawLine(0, h - 2, 2, h - 2)
		surface.DrawLine(1, 1, 1, h - 2)

		return ret
	end
end

function PANEL:AddButton(button)
	table.insert(self.buttons, button)
	button:SetParent(self)
end

function PANEL:SetInnerPadding(x, y)
	self:SetXPadding(x)
	self:SetYPadding(y)
end

function PANEL:DoClick()

end

function PANEL:Toggle()
	self:SetIsCollapsed(not self:GetIsCollapsed())

	if self:GetIsCollapsed() then
		self.arrow:SetIcon("icon16/bullet_arrow_down.png")
	else
		self.arrow:SetIcon("icon16/bullet_arrow_up.png")
	end

	if not self:GetIsCollapsed() then
		local last_button
		for _, button in ipairs(self.buttons) do
			button:SetVisible(not self:GetIsCollapsed())

			last_button = button
		end

		self:SizeTo(self:GetWide(), last_button.y + last_button:GetTall() + 6, 0.2)
	else
		self:SizeTo(self:GetWide(), self.button:GetTall(), 0.2, 0, -1, function()
			for _, button in ipairs(self.buttons) do
				button:SetVisible(not self:GetIsCollapsed())
			end
		end)
	end
end

function PANEL:SetText(text)
	return self.button:SetText(text)
end

function PANEL:PerformLayout(w)
	self.arrow:SetSize(24, 24)
	self.arrow:SetPos(w - self.arrow:GetWide(), 0)

	self.button:SetPos(0, 0)
	self.button:SetSize(w - self.arrow:GetWide() + 2, 24)

	local previous_button = self.button
	for _, button in ipairs(self.buttons) do
		button:SetSize(w - self:GetXPadding() * 2, self.button:GetTall())
		button:SetPos(0 + self:GetXPadding(), previous_button.y + previous_button:GetTall() + self:GetYPadding())

		previous_button = button
	end
end

function PANEL:Paint(w, h)
	if not self:GetIsCollapsed() then
		surface.SetDrawColor(82, 82, 82, 255)
		surface.DrawLine(0, h - 1, w, h - 1)
	end
end

vgui.Register("WCollapsableButton", PANEL, 'DPanel');