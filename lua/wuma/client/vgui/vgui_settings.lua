
local PANEL = {}

PANEL.TabName = "Settings"
PANEL.TabIcon = "icon16/wrench.png"

AccessorFunc(PANEL, "usergroups", "Usergroups")
AccessorFunc(PANEL, "inheritance", "Inheritance")

function PANEL:Init()

	self:SetUsergroups({})
	self:SetInheritance({})

	local exclude_limits = GetConVar("wuma_exclude_limits")
	local personal_loadout_chatcommand = GetConVar("wuma_personal_loadout_chatcommand")
	local echo_changes = GetConVar("wuma_echo_changes")
	local echo_to_chat = GetConVar("wuma_echo_to_chat")
	local log_level = GetConVar("wuma_log_level")

	self.server_settings = vgui.Create("DPanel", self)

	self.server_settings.header = vgui.Create("DPanel", self.server_settings)
	self.server_settings.header.Paint = function(_, w, h)
		draw.DrawText("Server settings", "DermaDefaultBold", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0, h-1, w, h-1)
	end

	self.log_level = vgui.Create("DPanel", self.server_settings)
	self.log_level.Paint = function(_, _, h) draw.DrawText("Log level", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.log_level.combobox = vgui.Create("DComboBox", self.log_level)
	self.log_level.combobox:AddChoice("None", 0)
	self.log_level.combobox:AddChoice("Normal", 1)
	self.log_level.combobox:AddChoice("Debug", 2)
	self.log_level.combobox:ChooseOptionID(log_level:GetInt() + 1)
	self.log_level.combobox:SetSortItems(false)
	self.log_level.combobox.OnSelect = function(_, _, _, data) self:OnLogLevelComboboxChanged(data) end

	self.echo_changes = vgui.Create("DPanel", self.server_settings)
	self.echo_changes.Paint = function(_, _, h) draw.DrawText("Echo changes to", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.echo_changes.combobox = vgui.Create("DComboBox", self.echo_changes)
	self.echo_changes.combobox:AddChoice("Nobody", 0)
	self.echo_changes.combobox:AddChoice("Access", 1)
	self.echo_changes.combobox:AddChoice("Everyone", 2)
	self.echo_changes.combobox:ChooseOptionID(echo_changes:GetInt() + 1)
	self.echo_changes.combobox:SetSortItems(false)
	self.echo_changes.combobox.OnSelect = function(_, _, _, data) self:OnEchoChangesComboboxChanged(data) end

	self.checkbox_echo_chat = vgui.Create("DCheckBoxLabel", self.server_settings)
	self.checkbox_echo_chat:SetText("Echo changes to chat")
	self.checkbox_echo_chat:SetTextColor(Color(0, 0, 0))
	self.checkbox_echo_chat:SetValue(echo_to_chat:GetBool())
	self.checkbox_echo_chat.OnChange = function(_, bool) self:OnEchoToChatCheckboxChanged(bool) end

	self.checkbox_exclude_limits = vgui.Create("DCheckBoxLabel", self.server_settings)
	self.checkbox_exclude_limits:SetText("Exclude limits from gamemode limits")
	self.checkbox_exclude_limits:SetTextColor(Color(0, 0, 0))
	self.checkbox_exclude_limits:SetValue(exclude_limits:GetBool())
	self.checkbox_exclude_limits.OnChange = function(_, bool) self:OnExludeLimitsCheckboxChanged(bool) end

	self.chat_command = vgui.Create("DPanel", self.server_settings)
	self.chat_command.Paint = function(_, _, h) draw.DrawText("Loadout chat command", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.chat_command.textbox = vgui.Create("DTextEntry", self.chat_command)
	self.chat_command.textbox:SetValue(personal_loadout_chatcommand:GetString())

	local old_setvalue = self.chat_command.textbox.SetValue
	self.chat_command.textbox.SetValue = function(panel, value)
		panel.previousValue = value
		old_setvalue(panel, value)
	end

	local old_losefocus = self.chat_command.textbox.OnLoseFocus
	self.chat_command.textbox.OnLoseFocus = function(panel)
		old_losefocus(panel)

		local str = panel:GetValue()
		if (str ~= "" and str ~= panel.previousValue) then
			if (str ~= self.previousCommand) then
				self.previousCommand = str
				self:OnPersonalLoadoutTextboxChanged(panel:GetValue())
			end
		else
			timer.Simple(0.01, function() panel:SetValue(panel.previousValue) end)
		end
	end

	self.inheritance_settings = vgui.Create("DPanel", self)

	self.inheritance_settings.header = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_settings.header.Paint = function(_, w, h)
		draw.DrawText("Inheritance settings", "DermaDefaultBold", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0, h-1, w, h-1)
	end

	--Inheritance target
	self.inheritance_target = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_target.Paint = function(_, _, h) draw.DrawText("Select inheritance for", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.inheritance_target.combobox = vgui.Create("DComboBox", self.inheritance_target)
	self.inheritance_target.combobox:SetSortItems(false)
	self.inheritance_target.combobox.OnSelect = function() self:PopulateInheritance() end

	--Restrictions
	self.inheritance_restriction = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_restriction.Paint = function(_, _, h) draw.DrawText("Inherit restrictions from ", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.inheritance_restriction.combobox = vgui.Create("DComboBox", self.inheritance_restriction)
	self.inheritance_restriction.combobox.OnSelect = function()
		self:OnInheritanceComboboxChanged("restrictions",  self.inheritance_target.combobox:GetSelected(), self.inheritance_restriction.combobox:GetSelected())
	end

	--Limits
	self.inheritance_limit = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_limit.Paint = function(_, _, h) draw.DrawText("Inherit limits from ", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.inheritance_limit.combobox = vgui.Create("DComboBox", self.inheritance_limit)
	self.inheritance_limit.combobox.OnSelect = function()
		self:OnInheritanceComboboxChanged("limits", self.inheritance_target.combobox:GetSelected(), self.inheritance_limit.combobox:GetSelected())
	end

end

function PANEL:PerformLayout(w, h)
	self.server_settings:SetPos(0, 0)
	self.server_settings:SetSize(w/2-3, h-2)

	self.server_settings.header:SetTall(20)
	self.server_settings.header:DockMargin(5, 0, 5, 0)
	self.server_settings.header:Dock(TOP)

	self.log_level:SetTall(22)
	self.log_level:DockMargin(5, 5, 5, 0)
	self.log_level:Dock(TOP)
	self.log_level.combobox:SetWide(self.log_level:GetWide()/2)
	self.log_level.combobox:SetPos(self.log_level:GetWide()-self.log_level.combobox:GetWide(), 0)

	self.echo_changes:SetTall(22)
	self.echo_changes:DockMargin(5, 5, 5, 0)
	self.echo_changes:Dock(TOP)
	self.echo_changes.combobox:SetWide(self.echo_changes:GetWide()/2)
	self.echo_changes.combobox:SetPos(self.echo_changes:GetWide()-self.echo_changes.combobox:GetWide(), 0)

	self.checkbox_echo_chat:DockMargin(5, 5, 5, 0)
	self.checkbox_echo_chat:Dock(TOP)

	self.checkbox_exclude_limits:DockMargin(5, 5, 5, 0)
	self.checkbox_exclude_limits:Dock(TOP)

	self.chat_command:SetTall(22)
	self.chat_command:DockMargin(5, 5, 5, 5)
	self.chat_command:Dock(BOTTOM)
	self.chat_command.textbox:SetWide(self.echo_changes:GetWide()/2)
	self.chat_command.textbox:SetPos(self.echo_changes:GetWide()-self.echo_changes.combobox:GetWide(), 0)

	self.inheritance_settings:SetPos(w/2+3, 0)
	self.inheritance_settings:SetSize(w/2-3, h-2)

	self.inheritance_settings.header:SetTall(20)
	self.inheritance_settings.header:DockMargin(5, 0, 5, 0)
	self.inheritance_settings.header:Dock(TOP)

	self.inheritance_target:SetTall(22)
	self.inheritance_target:DockMargin(5, 5, 5, 0)
	self.inheritance_target:Dock(TOP)
	self.inheritance_target.combobox:SetWide(self.inheritance_target:GetWide()/5*2)
	self.inheritance_target.combobox:SetPos(self.inheritance_target:GetWide()-self.inheritance_target.combobox:GetWide(), 0)

	self.inheritance_restriction:SetTall(22)
	self.inheritance_restriction:DockMargin(5, 0, 5, 5)
	self.inheritance_restriction:Dock(BOTTOM)
	self.inheritance_restriction.combobox:SetWide(self.inheritance_restriction:GetWide()/5*2)
	self.inheritance_restriction.combobox:SetPos(self.inheritance_restriction:GetWide()-self.inheritance_restriction.combobox:GetWide(), 0)

	self.inheritance_limit:SetTall(22)
	self.inheritance_limit:DockMargin(5, 0, 5, 5)
	self.inheritance_limit:Dock(BOTTOM)
	self.inheritance_limit.combobox:SetWide(self.inheritance_limit:GetWide()/5*2)
	self.inheritance_limit.combobox:SetPos(self.inheritance_limit:GetWide()-self.inheritance_limit.combobox:GetWide(), 0)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(159, 163, 167, 255)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:NotifyUsergroupsChanged(usergroups)
	self:SetUsergroups(usergroups)

	self.inheritance_target.combobox:Clear()
	for _, usergroup in pairs(usergroups) do
		self.inheritance_target.combobox:AddChoice(usergroup, usergroup)
	end
	self.inheritance_target.combobox:ChooseOptionID(1)

	self:PopulateInheritance()
end

function PANEL:OnInheritanceComboboxChanged(type, usergroup, inheritFrom)
	if (inheritFrom == "Nobody") then inheritFrom = nil end
	if not self.DisregardChanges then
		self:OnInheritanceChanged(type, usergroup, inheritFrom)
	end
end

--luacheck: push no unused args
function PANEL:OnInheritanceChanged(type, usergroup, inheritFrom)
	--For override
end
--luacheck: pop

function PANEL:NotifyInheritanceChanged(inheritance)
	self:SetInheritance(inheritance)

	self:PopulateInheritance()
end

function PANEL:OnExludeLimitsCheckboxChanged(exclude)
	if not self.DisregardChanges then
		self:OnPersonalLoadoutCommandChanged(exclude)
	end
end

--luacheck: push no unused args
function PANEL:OnExludeLimitsChanged(exclude)
	--For override
end
--luacheck: pop

function PANEL:NotifyExludeLimitsChanged(exclude)
	self.DisregardChanges = true
	self.checkbox_exclude_limits:SetValue(exclude)
	self.DisregardChanges = nil
end

function PANEL:OnPersonalLoadoutTextboxChanged(command)
	if not self.DisregardChanges then
		self:OnPersonalLoadoutCommandChanged(command)
	end
end

--luacheck: push no unused args
function PANEL:OnPersonalLoadoutCommandChanged(command)
	--For override
end
--luacheck: pop

function PANEL:NotifyPersonalLoadoutCommandChanged(command)
	self.DisregardChanges = true
	self.chat_command.textbox:SetValue(command)
	self.DisregardChanges = nil
end

function PANEL:OnEchoChangesComboboxChanged(echo)
	if not self.DisregardChanges then
		self:OnEchoChangesChanged(echo)
	end
end

--luacheck: push no unused args
function PANEL:OnEchoChangesChanged(echo)
	--For override
end
--luacheck: pop

function PANEL:NotifyEchoChangesChanged(echo)
	self.DisregardChanges = true
	self.echo_changes.combobox:ChooseOptionID(echo + 1)
	self.DisregardChanges = nil
end

function PANEL:OnEchoToChatCheckboxChanged(echo)
	if not self.DisregardChanges then
		self:OnEchoToChatChanged(echo)
	end
end

--luacheck: push no unused args
function PANEL:OnEchoToChatChanged(echo)
	--For override
end
--luacheck: pop

function PANEL:NotifyEchoToChatChanged(echo)
	self.DisregardChanges = true
	self.checkbox_echo_chat:SetValue(echo)
	self.DisregardChanges = nil
end

function PANEL:OnLogLevelComboboxChanged(log_level)
	if not self.DisregardChanges then
		self:OnLogLevelChanged(log_level)
	end
end

--luacheck: push no unused args
function PANEL:OnLogLevelChanged(log_level)
	--For override
end
--luacheck: pop

function PANEL:NotifyLogLevelChanged(log_level)
	self.DisregardChanges = true
	self.log_level.combobox:ChooseOptionID(log_level + 1)
	self.DisregardChanges = nil
end

function PANEL:GetUsergroupHeirs(type, usergroup)
	local tbl = {}
	for heir, ancestor in pairs(self:GetInheritance()[type] or {}) do
		if (ancestor == usergroup) then
			table.insert(tbl, heir)
		end
	end
	return tbl
end

function PANEL:GetInheritanceTree(type, usergroup)
	local tbl = {}

	for _, heir in pairs(self:GetUsergroupHeirs(type, usergroup)) do
		table.insert(tbl, heir)

		local heirs = self:GetUsergroupHeirs(type, heir)
		if (table.Count(heirs) > 0) then
			table.Add(tbl, self:GetInheritanceTree(type, heir))
		end
	end

	return tbl
end

function PANEL:PopulateInheritance()
	self.DisregardChanges = true
	local text = self.inheritance_target.combobox:GetSelected()

	self.inheritance_restriction.combobox:Clear()
	self.inheritance_limit.combobox:Clear()

	for _, usergroup in pairs(self:GetUsergroups()) do
		if (text ~= usergroup) then
			if not table.HasValue(self:GetInheritanceTree("restrictions", text), usergroup) then
				self.inheritance_restriction.combobox:AddChoice(usergroup, usergroup)
			end

			if not table.HasValue(self:GetInheritanceTree("limits", text), usergroup) then
				self.inheritance_limit.combobox:AddChoice(usergroup, usergroup)
			end
		end
	end

	self.inheritance_restriction.combobox:AddChoice("Nobody", nil, true)
	self.inheritance_limit.combobox:AddChoice("Nobody", nil, true)

	local selected = self.inheritance_target.combobox:GetSelected()

	for type, tbl in pairs(self:GetInheritance()) do
		for usergroup, inheritFrom in pairs(tbl) do
			if (selected == usergroup) then
				if (type == "restrictions") then
					for k, v in pairs(self.inheritance_restriction.combobox.Choices) do
						if (v == inheritFrom) then
							self.inheritance_restriction.combobox:ChooseOptionID(k)
						end
					end
				elseif (type == "limits") then
					for k, v in pairs(self.inheritance_limit.combobox.Choices) do
						if (v == inheritFrom) then
							self.inheritance_limit.combobox:ChooseOptionID(k)
						end
					end
				end
			end
		end
	end

	self.DisregardChanges = nil
end

vgui.Register("WUMA_Settings", PANEL, 'DPanel');
