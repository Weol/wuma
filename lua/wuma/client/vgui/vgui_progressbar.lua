
local PANEL = {}

function PANEL:Init() 
	self.progress = 0
	self.label = ""
end

function PANEL:SetProgress(progress)
	self.progress = progress
end

function PANEL:GetProgress()
	return self.progress
end

function PANEL:SetText(text)
	self.label = text
end

function PANEL:GetText()
	return self.label
end

function PANEL:PerformLayout()
	self:Paint()
end

function PANEL:Paint()

	local w, h = self:GetSize()
	local bar_w = math.Clamp((w/4) - ((self.progress + (w/4)) - (w - 4)), 0, (w/4))
	
	surface.SetDrawColor(0, 0, 0, 170)
	draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 100))

	if (self.progress >= w - 4) then self.progress = 2 end
	
	self.progress = self.progress + 2
	if (self.progress + bar_w >= (w - 4)) then
		draw.RoundedBox(4, 2, 2, (w/4) - bar_w, h-4, Color(0, 255, 0, 190))
	end
	draw.RoundedBox(4, self.progress, 2, bar_w, h-4, Color(0, 255, 0, 190))

	surface.SetFont("DefaultSmall")
	local label_w, label_h = surface.GetTextSize(self.label)
	surface.SetTextColor(0, 0, 0, 255)
	surface.SetTextPos(w/2 - label_w/2, h/2 - label_h/2)
	surface.DrawText(self.label)
	
end

vgui.Register("WProgressBar", PANEL, "DPanel")