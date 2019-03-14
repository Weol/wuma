
local PANEL = {}

function PANEL:Init()
	self.day = vgui.Create("WTextbox", self)
	self.day:SetDefault("Day")
	self.day:SetNumeric(true)
	self.day:SetMinMaxNumeric(0, 31)
	
	self.month = vgui.Create("WTextbox", self)
	self.month:SetDefault("Month")
	self.month:SetNumeric(true)
	self.month:SetMinMaxNumeric(0, 12)

	self.year = vgui.Create("WTextbox", self)
	self.year:SetDefault("Year")
	self.year:SetNumeric(true)
	self.year:SetMinMaxNumeric(0, 3000)
	
	self:SetSize(76+36, 29)
	
end

function PANEL:PerformLayout()

	self.day:SetPos(0, 9)
	self.day:SetSize(36, 20)
	
	self.month:SetPos(38, 9)
	self.month:SetSize(36, 20)
	
	self.year:SetPos(76, 9)
	self.year:SetSize(36, 20)

end

function PANEL:ValidateDate(day, month, year)
	local epoch = os.time{year=year, month=month, day=day}
	local zeromdy = string.format("%02d/%02d/%04d", day, month, year)
	return (zeromdy == os.date('%d/%m/%Y', epoch))
end
		
function PANEL:Paint(w, h)
	local color = Color(0, 0, 0, 150)
	if (tonumber(self.day:GetValue()) ~= nil and tonumber(self.month:GetValue()) ~= nil and tonumber(self.year:GetValue()) ~= nil) then
		if not self:ValidateDate(tonumber(self.day:GetValue()), tonumber(self.month:GetValue()), tonumber(self.year:GetValue())) then
			color = Color(255, 0, 0, 150)
		end
	end

	draw.DrawText("day", "WUMATextSmall", 12, 0, color)
	draw.DrawText("month", "WUMATextSmall", 44, 0, color)
	draw.DrawText("year", "WUMATextSmall", 87, 0, color)
end

function PANEL:GetArgument()
	if (self.day:GetValue() == "") or (self.month:GetValue() == "") or (self.year:GetValue() == "") then return nil end
	
	if (tonumber(self.day:GetValue()) == nil) or (tonumber(self.month:GetValue()) == nil) or (tonumber(self.year:GetValue()) == nil) then return nil end
	
	return {day=tonumber(self.day:GetValue()), month=tonumber(self.month:GetValue()), year=tonumber(self.year:GetValue())}
end
	
vgui.Register("WDatePicker", PANEL, 'DPanel');