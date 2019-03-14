
local PANEL = {}

function PANEL:Init()

	self.close_button = vgui.Create("DButton", self)
	self.close_button:SetText("")
	self.close_button.DoClick = function(button) WUMA.GUI.Toggle() end
	self.close_button.Paint = function(button, w, h) 	
		draw.RoundedBox(3, 0, 0, w, 7, Color(59, 59, 59))	
		draw.RoundedBox(3, 1, 1, w-2, 7, Color(167, 171, 175))
		draw.RoundedBox(3, 2, 2, w-4, 7, Color(156, 160, 163))
		
		surface.SetDrawColor(Color(59, 59, 59))		
		surface.DrawRect(0, 5, w, h-6)	
		surface.SetDrawColor(Color(167, 171, 175))
		surface.DrawRect(1, 5, w-2, h-6)
		surface.SetDrawColor(Color(156, 160, 163))
		surface.DrawRect(2, 5, w-4, h)
		
		surface.SetDrawColor(button.Highlight or Color(59, 59, 59))
		surface.DrawLine(12-1, 7, 21-1, 16)
		surface.DrawLine(13-1, 7, 21-1, 15)
		surface.DrawLine(12-1, 8, 20-1, 16)
		
		surface.DrawLine(20-1, 7, 11-1, 16)
		surface.DrawLine(19-1, 7, 11-1, 15)
		surface.DrawLine(20-1, 8, 12-1, 16)
	end
	self.close_button.OnCursorEntered = function(button) button.Highlight = Color(42, 115, 180);button:Paint(button:GetSize()) end
	self.close_button.OnCursorExited = function(button) button.Highlight = Color(59, 59, 59);button:Paint(button:GetSize()) end
	
end

function PANEL:PerformLayout(w, h)

	local ActiveTab = self:GetActiveTab()
	local Padding = self:GetPadding()

	if (not IsValid(ActiveTab)) then return end

	-- Update size now, so the height is definitiely right.
	ActiveTab:InvalidateLayout(true)

	--self.tabScroller:StretchToParent(Padding, 0, Padding, nil)
	self.tabScroller:SetTall(ActiveTab:GetTall())

	local ActivePanel = ActiveTab:GetPanel()

	for k, v in pairs(self.Items) do

		if (v.Tab:GetPanel() == ActivePanel) then

			v.Tab:GetPanel():SetVisible(true)
			v.Tab:SetZPos(100)

		else

			v.Tab:GetPanel():SetVisible(false)
			v.Tab:SetZPos(1)

		end

		v.Tab:ApplySchemeSettings()

	end

	if (not ActivePanel.NoStretchX) then
		ActivePanel:SetWide(self:GetWide() - Padding * 2)
	else
		ActivePanel:CenterHorizontal()
	end

	if (not ActivePanel.NoStretchY) then
		local _, y = ActivePanel:GetPos()
		ActivePanel:SetTall(self:GetTall() - y - Padding)
	else
		ActivePanel:CenterVertical()
	end

	ActivePanel:InvalidateLayout()

	-- Give the animation a chance
	self.animFade:Run()
	
	self.close_button:SetSize(31, 22)
	self.close_button:SetPos(self:GetWide() - self.close_button:GetWide() - 3, 0)
	
	if self.showexitbutton then self.close_button:SetVisible(true) else self.close_button:SetVisible(false) end
		
end

function PANEL:SetShowExitButton(bool)
	self.showexitbutton = bool
end

function PANEL:OnTabChange(tab)

end

local disregard_first = true
function PANEL:SetActiveTab(active)

	if (self.m_pActiveTab == active) then return end

	if (self.m_pActiveTab) then

		if (self:GetFadeTime() > 0) then

			self.animFade:Start(self:GetFadeTime(), { OldTab = self.m_pActiveTab, NewTab = active })

		else

			self.m_pActiveTab:GetPanel():SetVisible(false)

		end
	end

	self.m_pActiveTab = active
	self:InvalidateLayout()

	if not disregard_first then
		self:OnTabChange(active:GetText())
	else
		disregard_first = nil
	end

end

vgui.Register("WPropertySheet", PANEL, 'DPropertySheet');