
local PANEL = {}

AccessorFunc(PANEL, "max_numeric", "MaxNumeric", FORCE_NUMBER)
AccessorFunc(PANEL, "min_numeric", "MinNumeric", FORCE_NUMBER)

function PANEL:Init()
	self.default_color = Color(150, 150, 150)
end

function PANEL:SetDefault(default)
	self.default = default
	self:OnLoseFocus()
end

function PANEL:GetDefault()
	return self.default
end

function PANEL:SetMinMaxNumeric(min, max)
	self:SetMinNumeric(min)
	self:SetMaxNumeric(max)
end

function PANEL:OnTextChanged()
	local valid = pcall(string.match, "abcdefghijklmnopqrstuvwxyz1234567890()123", self:GetText()) --To check if pattern is valid, these are not the only characters allowed
	if not valid then return end

	self.HistoryPos = 0

	if (self:GetUpdateOnType()) then
		self:UpdateConvarValue()
		self:OnValueChange(self:GetText())
	end

	if (IsValid(self.Menu) and not noMenuRemoval) then
		self.Menu:Remove()
	end

	local tab = self:GetAutoComplete(self:GetText())
	if (tab) then
		self:OpenAutoComplete(tab)
	end

	self:OnChange()
	
end

function PANEL:RefreshDefault()
	if self:GetDefault() then
		local text = self:GetValue()
		if (not text) or (text == "") then
			self:SetText(self:GetDefault())
			self:SetTextColor(self.default_color)
		end
	end
end

function PANEL:OnLoseFocus()
	if self:GetDefault() then
		local text = self:GetValue()
		if (not text) or (text == "") then
			self:SetText(self:GetDefault())
			self:SetTextColor(self.default_color)
		end
	end
	
	if self:GetNumeric() and (self:GetValue() ~= "") and (self:GetValue() ~= self:GetDefault()) then
		if self:GetMinNumeric() then
			if (tonumber(self:GetValue()) < self:GetMinNumeric()) then self:SetText(self:GetMinNumeric()) end
		end
		
		if self:GetMaxNumeric() then
			if (tonumber(self:GetValue()) > self:GetMaxNumeric()) then self:SetText(self:GetMaxNumeric()) end
		end
	end
	
	self:UpdateConvarValue()
	hook.Call("OnTextEntryLoseFocus", nil, self)
	self:FocusLost()
	
end

function PANEL:FocusLost()

end

function PANEL:OnGetFocus()
	if self:GetDefault() then
		local text = self:GetValue()
		if (text == self:GetDefault()) then
			self:SetText("")
			self:SetTextColor(Color(0, 0, 0))
		else
			self:SetTextColor(Color(0, 0, 0))
			self:SelectAll()
		end
	end
	
	hook.Run("OnTextEntryGetFocus", self)
end

vgui.Register("WTextbox", PANEL, 'DTextEntry');
