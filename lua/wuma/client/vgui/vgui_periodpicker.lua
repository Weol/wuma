
local PANEL = {}

function PANEL:Init()

	self.from_hour = vgui.Create("WTextbox", self)
	self.from_hour:SetDefault("hh")
	self.from_hour:SetNumeric(true)
	self.from_hour:SetMinMaxNumeric(0, 23)
	
	self.from_minute = vgui.Create("WTextbox", self)
	self.from_minute:SetDefault("mm")
	self.from_minute:SetNumeric(true)
	self.from_minute:SetMinMaxNumeric(0, 59)

	self.until_hour = vgui.Create("WTextbox", self)
	self.until_hour:SetDefault("hh")
	self.until_hour:SetNumeric(true)
	self.until_hour:SetMinMaxNumeric(0, 23)

	self.until_minute = vgui.Create("WTextbox", self)
	self.until_minute:SetDefault("mm")
	self.until_minute:SetNumeric(true)
	self.until_minute:SetMinMaxNumeric(0, 59)	
	
	self:SetSize(38+36, 38+20)
	
end

function PANEL:PerformLayout()
	self.from_hour:SetPos(0, 9)
	self.from_hour:SetSize(36, 20)
	
	self.from_minute:SetPos(38, 9)
	self.from_minute:SetSize(36, 20)
	
	self.until_hour:SetPos(0, 38)
	self.until_hour:SetSize(36, 20)
	
	self.until_minute:SetPos(38, 38)
	self.until_minute:SetSize(36, 20)
end

function PANEL:Paint()
	draw.DrawText("from", "WUMATextSmall", 29, 0, Color(0, 0, 0, 150))
	draw.DrawText("until", "WUMATextSmall", 29, 29, Color(0, 0, 0, 150))
end
	
function PANEL:GetArgument()
	if (self.from_hour:GetValue() == "") or (self.from_minute:GetValue() == "") or (self.until_hour:GetValue() == "") or (self.until_minute:GetValue() == "") then return nil end
	
	if (tonumber(self.from_hour:GetValue()) == nil) or (tonumber(self.from_minute:GetValue()) == nil) or (tonumber(self.until_hour:GetValue()) == nil) or (tonumber(self.until_minute:GetValue()) == nil) then return nil end
	
	return {from = tonumber(self.from_hour:GetValue())*3600+tonumber(self.from_minute:GetValue())*60, to = tonumber(self.until_hour:GetValue())*3600+tonumber(self.until_minute:GetValue())*60}
end
	
vgui.Register("WPeriodPicker", PANEL, 'DPanel');