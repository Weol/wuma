
local PANEL = {}

function PANEL:Init()
	local slider = vgui.Create("DSlider", self)
	local label = vgui.Create("DLabel", self)
	local wang = vgui.Create( "DNumberWang", self )
	
	label:SetTextColor(Color(0,0,0,255))
	
	slider:SetLockY( 0.5 )
	slider:SetTrapInside( true )
	Derma_Hook( slider, "Paint", "Paint", "NumSlider" )
	
	wang.OnValueChanged = function(panel,val)
		val = math.Clamp(tonumber(val),wang:GetMin(),wang:GetMax())
		slider:SetSlideX(val/wang:GetMax())
	end
	
	slider.TranslateValues = function(panel,x,y) 
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
	return self.wang:GetValue()
end

function PANEL:SetDecimals(decimals)
	self.wang:SetDecimals(decimals)
end

function PANEL:SetText(text)
	self.label:SetText(text)
end

function PANEL:SetMinMax(min, max)
	self.wang:SetMinMax(min,max)
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
	self.wang:SetPos(self:GetWide()-self.wang:GetWide(),0)
	
	self.label:SetPos(8,3)
	self.label:SizeToContents()
	
	self.slider:SetSize(self:GetWide(),16)
	self.slider:SetPos(0,self:GetTall()-self.slider:GetTall())

end


vgui.Register("WSlider", PANEL, 'DPanel');