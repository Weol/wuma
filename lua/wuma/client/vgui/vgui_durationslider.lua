
local PANEL = {}

function PANEL:Init()

	local options = {
		Minutes = {max=1440, default=30, time=60, select=true},
		Hours = {max=168, default=12, time=60*60},
		Days = {max=365, default=3, time=3600*24},
		Weeks = {max=52, default=2, time=3600*60*24*7},
		Months = {max=60, default=3, time=math.Round(52/12*(3600*60*24*7))},
		Years = {max=5, default=1, time=3600*60*24*365}
	}

	local slider = vgui.Create("DSlider", self)
	slider:SetLockY(0.5)
	slider:SetTrapInside(true)
	
	local combobox = vgui.Create("DComboBox", self)
	wang = vgui.Create("DNumberWang", self)
	wang:SetDecimals(0)
	
	wang.OnValueChanged = function(panel, val)
		val = math.Clamp(tonumber(val), 0, combobox:GetOptionData(combobox:GetSelectedID()).max)
		slider:SetSlideX(1/combobox:GetOptionData(combobox:GetSelectedID()).max*val)
	end
	
	Derma_Hook(slider, "Paint", "Paint", "NumSlider")
	slider.TranslateValues = function(panel, x, y) 
		wang:SetValue(math.Round(combobox:GetOptionData(combobox:GetSelectedID()).max*x))
		return x, y
	end
	
	combobox.OnSelect = function(panel, index, value, data)
		wang:SetMinMax(1, data.max)
		wang:SetValue(data.default)
		slider:SetSlideX(1/data.max*data.default)
	end
	
	for option, data in pairs(options) do
		combobox:AddChoice(option, data, data.select)
	end
	
	self.slider = slider
	self.combobox = combobox
	self.wang = wang
	
	self:SizeToChildren()
end

function PANEL:PerformLayout()
	self.wang:SetWide(40)
	self.wang:SetPos(self:GetWide()-self.wang:GetWide(), 0)
	
	self.slider:SetWide(self:GetWide())
	self.slider:SetHeight(16)
	self.slider:SetPos(0, self:GetTall()-self.slider:GetTall())
	
	self.combobox:SetPos(0, 0)
	self.combobox:SetSize(60, 20)
end
	
function PANEL:GetArgument()
	if not self.combobox:GetSelected() then return nil end

	local text, data = self.combobox:GetSelected()

	return math.Round(data.time*self.wang:GetValue())
end

vgui.Register("WDurationSlider", PANEL, 'DPanel');