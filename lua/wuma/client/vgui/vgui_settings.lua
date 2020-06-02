
local PANEL = {}

PANEL.TabName = "Settings"
PANEL.TabIcon = "icon16/wrench.png"

function PANEL:Init()

	self.server_settings = vgui.Create("DPanel", self)

	self.server_settings.header = vgui.Create("DPanel", self.server_settings)
	self.server_settings.header.Paint = function(panel, w, h)
		draw.DrawText("Server settings", "DermaDefaultBold", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0, h-1, w, h-1)
	end

	self.log_level = vgui.Create("DPanel", self.server_settings)
	self.log_level.Paint = function(panel, w, h) draw.DrawText("Log level", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.log_level.combobox = vgui.Create("DComboBox", self.log_level)
	self.log_level.combobox:AddChoice("None", 0)
	self.log_level.combobox:AddChoice("Normal", 1)
	self.log_level.combobox:AddChoice("Debug", 2)
	self.log_level.combobox:SetSortItems(false)
	self.log_level.combobox.OnSelect = function(panel, index, value, data) WUMA.OnSettingsUpdate("log_level", data) end

	self.echo_changes = vgui.Create("DPanel", self.server_settings)
	self.echo_changes.Paint = function(panel, w, h) draw.DrawText("Echo changes to", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.echo_changes.combobox = vgui.Create("DComboBox", self.echo_changes)
	self.echo_changes.combobox:AddChoice("Nobody", 0)
	self.echo_changes.combobox:AddChoice("Access", 1)
	self.echo_changes.combobox:AddChoice("Everyone", 2)
	self.echo_changes.combobox:AddChoice("Relevant", 3)
	self.echo_changes.combobox:SetSortItems(false)
	self.echo_changes.combobox.OnSelect = function(panel, index, value, data) WUMA.OnSettingsUpdate("echo_changes", data) end

	self.checkbox_echo_chat = vgui.Create("DCheckBoxLabel", self.server_settings)
	self.checkbox_echo_chat:SetText("Echo changes to chat")
	self.checkbox_echo_chat:SetTextColor(Color(0, 0, 0))
	self.checkbox_echo_chat:SetValue(false)
	self.checkbox_echo_chat.OnChange = function(panel, bool) WUMA.OnSettingsUpdate("echo_to_chat", bool) end

	self.checkbox_exclude_limits = vgui.Create("DCheckBoxLabel", self.server_settings)
	self.checkbox_exclude_limits:SetText("Exclude limits from gamemode limits")
	self.checkbox_exclude_limits:SetTextColor(Color(0, 0, 0))
	self.checkbox_exclude_limits:SetValue(false)
	self.checkbox_exclude_limits.OnChange = function(panel, bool) WUMA.OnSettingsUpdate("exclude_limits", bool) end

	self.chat_command = vgui.Create("DPanel", self.server_settings)
	self.chat_command.Paint = function(panel, w, h) draw.DrawText("Loadout chat command", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.chat_command.textbox = vgui.Create("DTextEntry", self.chat_command)

	local old_setvalue = self.chat_command.textbox.SetValue
	self.chat_command.textbox.SetValue = function(panel, value)
		panel.previousValue = value
		old_setvalue(panel, value)
	end

	local old_losefocus = self.chat_command.textbox.OnLoseFocus
	self.chat_command.textbox.OnLoseFocus = function(panel)
		old_losefocus(panel)

		local str = panel:GetValue()
		if (str ~= "") then
			WUMA.OnSettingsUpdate("personal_loadout_chatcommand", panel:GetValue())
		else
			timer.Simple(0.01, function() panel:SetValue(panel.previousValue) end)
		end
	end


	self.inheritance_settings = vgui.Create("DPanel", self)

	self.inheritance_settings.header = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_settings.header.Paint = function(panel, w, h)
		draw.DrawText("Inheritance settings", "DermaDefaultBold", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0, h-1, w, h-1)
	end

	--Inheritance target
	self.inheritance_target = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_target.Paint = function(panel, w, h) draw.DrawText("Select inheritance for", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.inheritance_target.combobox = vgui.Create("DComboBox", self.inheritance_target)

	--Restrictions
	self.inheritance_restriction = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_restriction.Paint = function(panel, w, h) draw.DrawText("Inherit restrictions from ", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.inheritance_restriction.combobox = vgui.Create("DComboBox", self.inheritance_restriction)
	self.inheritance_restriction.combobox.OnSelect = function()
		local target = self.inheritance_target.combobox:GetSelected()
		local usergroup = self.inheritance_restriction.combobox:GetSelected()

		WUMA.OnInheritanceUpdate(Restriction:GetID(), target, usergroup)
	end

	--Limits
	self.inheritance_limit = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_limit.Paint = function(panel, w, h) draw.DrawText("Inherit limits from ", "DermaDefault", 0, h/2-7, Color(0, 0, 0), TEXT_ALIGN_LEFT) end
	self.inheritance_limit.combobox = vgui.Create("DComboBox", self.inheritance_limit)
	self.inheritance_limit.combobox.OnSelect = function()
		local target = self.inheritance_target.combobox:GetSelected()
		local usergroup = self.inheritance_limit.combobox:GetSelected()

		WUMA.OnInheritanceUpdate(Limit:GetID(), target, usergroup)
	end

	local function getUsergroupHeirs(enum, usergroup)
		local tbl = {}
		for heir, ancestor in pairs(WUMA.Inheritance[enum] or {}) do
			if (ancestor == usergroup) then
				table.insert(tbl, heir)
			end
		end
		return tbl
	end

	local function getInheritanceTree(enum, usergroup)
		local tbl = {}

		for _, heir in pairs(getUsergroupHeirs(enum, usergroup)) do
			table.insert(tbl, heir)

			local heirs = getUsergroupHeirs(enum, heir)
			if (table.Count(heirs) > 0) then
				table.Add(tbl, getInheritanceTree(enum, heir))
			end
		end

		return tbl
	end

	local function populateUsergroups()
		self.DisregardInheritanceChange = true
		local text, data = self.inheritance_target.combobox:GetSelected()

		self.inheritance_restriction.combobox:Clear()
		self.inheritance_limit.combobox:Clear()

		for _, usergroup in pairs (WUMA.ServerGroups) do
			if (text ~= usergroup) then
				if not table.HasValue(getInheritanceTree(Restriction:GetID(), text), usergroup) then
					self.inheritance_restriction.combobox:AddChoice(usergroup, i)
				end

				if not table.HasValue(getInheritanceTree(Limit:GetID(), text), usergroup) then
					self.inheritance_limit.combobox:AddChoice(usergroup, i)
				end
			end
		end

		self.inheritance_restriction.combobox:AddChoice("Nobody", _, true)
		self.inheritance_limit.combobox:AddChoice("Nobody", _, true)
		self.DisregardInheritanceChange = false

		WUMA.UpdateInheritance(WUMA.Inheritance)
	end
	self.inheritance_target.combobox.OnSelect = populateUsergroups

	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE, "WUMASettubsGUIUsergroupUpdateHook", function()
		self.inheritance_target.combobox:Clear()
		for _, usergroup in pairs (WUMA.ServerGroups) do
			self.inheritance_target.combobox:AddChoice(usergroup, _, true)
		end
		populateUsergroups()
	end)
	self.inheritance_target.combobox:SetSortItems(false)

	WUMA.GUI.AddHook(WUMA.INHERITANCEUPDATE, "WUMASettingsGUIInheritanceUpdateHook", function()
		populateUsergroups()
	end)

end

function PANEL:PerformLayout(w, h)

	self.server_settings:SetPos(0, 0)
	self.server_settings:SetSize(self:GetWide()/2-3, self:GetTall()-2)

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

	self.inheritance_settings:SetPos(self:GetWide()/2+3, 0)
	self.inheritance_settings:SetSize(self:GetWide()/2-3, self:GetTall()-2)

	self.inheritance_settings.header:SetTall(20)
	self.inheritance_settings.header:DockMargin(5, 0, 5, 0)
	self.inheritance_settings.header:Dock(TOP)

	self.inheritance_target:SetTall(22)
	self.inheritance_target:DockMargin(5, 5, 5, 0)
	self.inheritance_target:Dock(TOP)
	self.inheritance_target.combobox:SetWide(self.autounsubscribe:GetWide()/5*2)
	self.inheritance_target.combobox:SetPos(self.autounsubscribe:GetWide()-self.autounsubscribe.combobox:GetWide(), 0)

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

function PANEL:SelectChoiceByData(combobox, data)
	for k, v in pairs(combobox.Data) do
		if (v == data) then
			combobox:ChooseOptionID(k)
		end
	end
end

function PANEL:SelectChoiceByText(combobox, text)
	for k, v in pairs(combobox.Choices) do
		if (v == text) then
			combobox:ChooseOption(v, k)
		end
	end
end

function PANEL:UpdateInheritance(inheritance)
	local selected = self.inheritance_target.combobox:GetSelected()

	for enum, tbl in pairs(inheritance) do
		for target, usergroup in pairs(tbl) do
			if (selected == target) then
				if (enum == Restriction:GetID()) then
					for k, v in pairs(self.inheritance_restriction.combobox.Choices) do
						if (v == usergroup) then
							self.inheritance_restriction.combobox:ChooseOptionID(k)
						end
					end
				elseif (enum == Loadout:GetID()) then
					for k, v in pairs(self.inheritance_loadout.combobox.Choices) do
						if (v == usergroup) then
							self.inheritance_loadout.combobox:ChooseOptionID(k)
						end
					end
				elseif (enum == Limit:GetID()) then
					for k, v in pairs(self.inheritance_limit.combobox.Choices) do
						if (v == usergroup) then
							self.inheritance_limit.combobox:ChooseOptionID(k)
						end
					end
				end
			end
		end
	end
end

function PANEL:UpdateSettings(settings)
	self:SelectChoiceByData(self.log_level.combobox, tonumber(settings.log_level))
	self:SelectChoiceByData(self.echo_changes.combobox, tonumber(settings.echo_changes))
	self.net_send_interval.wang:SetValue(tonumber(settings.net_send_interval))
	self.net_send_size.wang:SetValue(tonumber(settings.net_send_size))
	self.data_save_delay.wang:SetValue(tonumber(settings.data_save_delay))
	self.checkbox_echo_chat:SetValue(tonumber(settings.echo_to_chat))
	self.chat_command.textbox:SetValue(settings.personal_loadout_chatcommand)
	self.checkbox_exclude_limits:SetValue(tonumber(settings.exclude_limits))
end

vgui.Register("WUMA_Settings", PANEL, 'DPanel');
