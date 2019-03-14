
local PANEL = {}

function PANEL:Init()
	local slider = vgui.Create("DSlider", self)
	local label = vgui.Create("DLabel", self)
	local wang = vgui.Create("DNumberWang", self)
	
	label:SetTextColor(Color(0, 0, 0, 255))
	
	slider:SetLockY(0.5)
	slider:SetTrapInside(true)
	Derma_Hook(slider, "Paint", "Paint", "NumSlider")
	
	wang.OnValueChanged = function(panel, val)
		val = math.Clamp(tonumber(val), wang:GetMin(), wang:GetMax())
	
		if self.min_override and (val == wang:GetMin()) then 
			wang:SetText(self.min_override[2])
		elseif self.max_override and (val == wang:GetMax()) then
			wang:SetText(self.max_override[2])
		end
		
		slider:SetSlideX(val/wang:GetMax())
	end
	
	slider.TranslateValues = function(panel, x, y) 
		wang:SetFraction(x)
		
		return x, y
	end
	
	self.slider = slider
	self.label = label
	self.wang = wang
	
end

function PANEL:Paint()

end

function PANEL:GetValue()
	local value = self.wang:GetValue()

	if self.max_override then
		if (self.wang:GetText() == self.max_override[2]) then value = self.max_override[1] end
	end
	
	if self.min_override then
		if (self.wang:GetText() == self.min_override[2]) then value = self.min_override[1] end
	end
	
	return value
end

function PANEL:SetDecimals(decimals)
	self.wang:SetDecimals(decimals)
end

function PANEL:SetText(text)
	self.label:SetText(text)
end

function PANEL:SetMinMax(min, max)
	self.wang:SetMinMax(min, max)
end

function PANEL:SetMinOverride(min, text) 
	self.min_override = {min, text}
end

function PANEL:SetMaxOverride(max, text) 
	self.max_override = {max, text}
end

function PANEL:SetMinMaxOverride(min, max) 
	self:SetMaxOverride(max)
	self:SetMinOverride(min)
end

function PANEL:GetSlider()
	return self.slider
end

function PANEL:GetLabel()
	return self.label
end

function PANEL:GetWang()
	return self.wang
end

function PANEL:PerformLayout()

	self.wang:SetWide(40)
	self.wang:SetPos(self:GetWide()-self.wang:GetWide(), 0)
	
	self.label:SetPos(8, 3)
	self.label:SizeToContents()
	
	self.slider:SetSize(self:GetWide(), 16)
	self.slider:SetPos(0, self:GetTall()-self.slider:GetTall())

end

vgui.Register("WSlider", PANEL, 'DPanel');