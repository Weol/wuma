
local PANEL = {}

PANEL.TabName = "Settings"
PANEL.TabIcon = "gui/silkicons/wrench"

function PANEL:Init()
	
	self.server_settings = vgui.Create("DPanel", self)
	
	self.server_settings.header = vgui.Create("DPanel", self.server_settings)
	self.server_settings.header.Paint = function(panel, w, h) 
		draw.DrawText("Server settings", "DermaDefaultBold", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) 
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0,h-1,w,h-1)
	end
	
	self.log_level = vgui.Create("DPanel",self.server_settings)
	self.log_level.Paint = function(panel,w, h) draw.DrawText("Log level", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.log_level.combobox = vgui.Create("DComboBox",self.log_level)
	self.log_level.combobox:AddChoice("None",0)
	self.log_level.combobox:AddChoice("Normal",1)
	self.log_level.combobox:AddChoice("Debug",2)
	self.log_level.combobox:SetSortItems(false)
	self.log_level.combobox.OnSelect = function(panel, index, value, data) WUMA.OnSettingsUpdate("log_level",data) end 
	 
	self.echo_changes = vgui.Create("DPanel",self.server_settings)
	self.echo_changes.Paint = function(panel,w, h) draw.DrawText("Echo changes to", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.echo_changes.combobox = vgui.Create("DComboBox",self.echo_changes)
	self.echo_changes.combobox:AddChoice("Nobody",0)
	self.echo_changes.combobox:AddChoice("Access",1)
	self.echo_changes.combobox:AddChoice("Everyone",2)
	self.echo_changes.combobox:AddChoice("Relevant",3)
	self.echo_changes.combobox:SetSortItems(false)
	self.echo_changes.combobox.OnSelect = function(panel, index, value, data) WUMA.OnSettingsUpdate("echo_changes",data) end 
	
	self.checkbox_echo_chat = vgui.Create("DCheckBoxLabel",self.server_settings)
	self.checkbox_echo_chat:SetText("Echo changes to chat")
	self.checkbox_echo_chat:SetTextColor(Color(0,0,0))
	self.checkbox_echo_chat:SetValue(false)
	self.checkbox_echo_chat.OnChange = function(panel,bool) WUMA.OnSettingsUpdate("echo_to_chat",bool) end 
	 
	self.adv_settings = vgui.Create("DPanel", self)
	
	self.adv_settings.header = vgui.Create("DPanel", self.adv_settings)
	self.adv_settings.header.Paint = function(panel, w, h) 
		draw.DrawText("Advanced server settings", "DermaDefaultBold", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) 
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0,h-1,w,h-1)
	end
	
	self.net_send_interval = vgui.Create("DPanel", self.adv_settings)
	self.net_send_interval.Paint = function(panel, w, h) draw.DrawText("Net send interval", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.net_send_interval.wang = vgui.Create("DNumberWang", self.net_send_interval)
	self.net_send_interval.wang:SetMinMax(0,86400)
	self.net_send_interval.wang:SetDecimals(2)
	self.net_send_interval.wang.OnChange = function(panel) WUMA.OnSettingsUpdate("net_send_interval",panel:GetValue()) end
	 
	self.net_send_size = vgui.Create("DPanel", self.adv_settings)
	self.net_send_size.Paint = function(panel, w, h) draw.DrawText("Net send size", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.net_send_size.wang = vgui.Create("DNumberWang", self.net_send_size)
	self.net_send_size.wang:SetMinMax(1,100000)
	self.net_send_size.wang:SetDecimals(2)
	self.net_send_size.wang.OnChange = function(panel) WUMA.OnSettingsUpdate("net_send_size",panel:GetValue()) end
	
	self.data_save_delay = vgui.Create("DPanel", self.adv_settings)
	self.data_save_delay.Paint = function(panel, w, h) draw.DrawText("Data save delay", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.data_save_delay.wang = vgui.Create("DNumberWang", self.data_save_delay)
	self.data_save_delay.wang:SetMinMax(1,86400)
	self.data_save_delay.wang:SetDecimals(0)
	self.data_save_delay.wang.OnChange = function(panel) WUMA.OnSettingsUpdate("data_save_delay",panel:GetValue()) end

	self.client_settings = vgui.Create("DPanel", self)
	
	self.client_settings.header = vgui.Create("DPanel", self.client_settings)
	self.client_settings.header.Paint = function(panel, w, h) 
		draw.DrawText("Client settings", "DermaDefaultBold", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) 
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0,h-1,w,h-1)
	end
	
	self.checkbox_request = vgui.Create("DCheckBoxLabel",self.client_settings)
	self.checkbox_request:SetText("Request all data on join")
	self.checkbox_request:SetTextColor(Color(0,0,0))
	self.checkbox_request:SetValue(false)
	self.checkbox_request.OnChange = function(panel,bool) GetConVar("wuma_request_on_join"):SetBool(bool) end 
	self.checkbox_request:SetValue(GetConVar("wuma_request_on_join"):GetBool())
	
	self.autounsubscribe = vgui.Create("DPanel",self.client_settings)
	self.autounsubscribe.Paint = function(panel,w, h) 
		draw.DrawText("Auto-unsubscribe to data", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) 
	end
	self.autounsubscribe.combobox = vgui.Create("DComboBox",self.autounsubscribe)
	self.autounsubscribe.combobox:AddChoice("Never",-1)
	self.autounsubscribe.combobox:AddChoice("1 hour",60*60)
	self.autounsubscribe.combobox:AddChoice("30 minutes",60*30)
	self.autounsubscribe.combobox:AddChoice("15 minutes",60*15)
	self.autounsubscribe.combobox:AddChoice("5 minutes",60*5)
	self.autounsubscribe.combobox:AddChoice("1 minutes",60)
	self.autounsubscribe.combobox:AddChoice("Instantly",0)
	self.autounsubscribe.combobox:SetSortItems(false)
	self.autounsubscribe.combobox.OnSelect = function(panel, index, value, data) GetConVar("wuma_autounsubscribe"):SetInt(data) end 
	self:SelectChoiceByData(self.autounsubscribe.combobox,GetConVar("wuma_autounsubscribe"):GetInt())
	
	self.autounsubscribe_user = vgui.Create("DPanel",self.client_settings)
	self.autounsubscribe_user.Paint = function(panel,w, h) draw.DrawText("Auto-unsubscribe to user data", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.autounsubscribe_user.combobox = vgui.Create("DComboBox",self.autounsubscribe_user)
	self.autounsubscribe_user.combobox:AddChoice("Never",-1)
	self.autounsubscribe_user.combobox:AddChoice("1 hour",60*60)
	self.autounsubscribe_user.combobox:AddChoice("30 minutes",60*30)
	self.autounsubscribe_user.combobox:AddChoice("15 minutes",60*15)
	self.autounsubscribe_user.combobox:AddChoice("5 minutes",60*5)
	self.autounsubscribe_user.combobox:AddChoice("1 minutes",60)
	self.autounsubscribe_user.combobox:AddChoice("Instantly",0)
	self.autounsubscribe_user.combobox:SetSortItems(false)
	self.autounsubscribe_user.combobox.OnSelect = function(panel, index, value, data) GetConVar("wuma_autounsubscribe_user"):SetInt(data) end 
	self:SelectChoiceByData(self.autounsubscribe_user.combobox,GetConVar("wuma_autounsubscribe_user"):GetInt())
	
	self.buttons = vgui.Create("DPanel",self.client_settings)
	
	self.buttons.flush_data = vgui.Create("DButton",self.buttons)
	self.buttons.flush_data.DoClick = function(panel) WUMA.FlushData() end 
	self.buttons.flush_data:SetText("Flush data")
	
	self.buttons.flush_user_data = vgui.Create("DButton",self.buttons)
	self.buttons.flush_user_data.DoClick = function(panel) WUMA.FlushUserData() end 
	self.buttons.flush_user_data:SetText("Flush user data")
	
	self.buttons.fetch_data = vgui.Create("DButton",self.buttons)
	self.buttons.fetch_data.DoClick = function(panel) WUMA.FetchData() end 
	self.buttons.fetch_data:SetText("Fetch data")
	
	self.inheritance_settings = vgui.Create("DPanel", self)
	
	self.inheritance_settings.header = vgui.Create("DPanel", self.inheritance_settings)
	self.inheritance_settings.header.Paint = function(panel, w, h) 
		draw.DrawText("Inheritance settings", "DermaDefaultBold", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) 
		surface.SetDrawColor(Color(159, 163, 167, 255))
		surface.DrawLine(0,h-1,w,h-1)
	end
	
	self.inheritance_target = vgui.Create("DPanel",self.inheritance_settings)
	self.inheritance_target.Paint = function(panel,w, h) draw.DrawText("Select inheritance for", "DermaDefault", 0, h/2-7, Color(0,0,0), TEXT_ALIGN_LEFT) end
	self.inheritance_target.combobox = vgui.Create("DComboBox",self.inheritance_target)
	for _, usergroup in pairs (WUMA.ServerGroups) do
		self.inheritance_target.combobox:AddChoice(usergroup, _, true)
	end
	
	WUMA.GUI.AddHook(WUMA.USERGROUPSUPDATE,"WUMASettubsGUIUsergroupUpdateHook",function()
		self.inheritance_target.combobox:Clear()
		for _, usergroup in pairs (WUMA.ServerGroups) do
			self.inheritance_target.combobox:AddChoice(usergroup, _, true)
		end
	end)
	self.inheritance_target.combobox:SetSortItems(false)
	
end

function PANEL:PerformLayout(w,h)

	self.server_settings:SetPos(0,0)
	self.server_settings:SetSize(self:GetWide()/2-3,self:GetTall()/2-3)
	
	self.server_settings.header:SetTall(20)
	self.server_settings.header:DockMargin(5,0,5,0)
	self.server_settings.header:Dock(TOP)
	
	self.log_level:SetTall(22)
	self.log_level:DockMargin(5,5,5,0)
	self.log_level:Dock(TOP)
	self.log_level.combobox:SetWide(self.log_level:GetWide()/2)
	self.log_level.combobox:SetPos(self.log_level:GetWide()-self.log_level.combobox:GetWide(),0)
	
	self.echo_changes:SetTall(22)
	self.echo_changes:DockMargin(5,5,5,0)
	self.echo_changes:Dock(TOP)
	self.echo_changes.combobox:SetWide(self.echo_changes:GetWide()/2)
	self.echo_changes.combobox:SetPos(self.echo_changes:GetWide()-self.echo_changes.combobox:GetWide(),0)
	
	self.checkbox_echo_chat:DockMargin(5,5,5,0)
	self.checkbox_echo_chat:Dock(TOP)
	
	self.adv_settings:SetPos(0,self:GetTall()/2+3)
	self.adv_settings:SetSize(self:GetWide()/2-3,self:GetWide()/2-3)
	
	self.adv_settings.header:SetTall(20)
	self.adv_settings.header:DockMargin(5,0,5,0)
	self.adv_settings.header:Dock(TOP)

	self.net_send_interval:SetTall(22)
	self.net_send_interval:DockMargin(5,5,5,0)
	self.net_send_interval:Dock(TOP)
	self.net_send_interval.wang:SetWide(self.net_send_interval:GetWide()/4)
	self.net_send_interval.wang:SetPos(self.net_send_interval:GetWide()-self.net_send_interval.wang:GetWide(),0)
	
	self.net_send_size:SetTall(22)
	self.net_send_size:DockMargin(5,5,5,0)
	self.net_send_size:Dock(TOP)
	self.net_send_size.wang:SetWide(self.net_send_size:GetWide()/4)
	self.net_send_size.wang:SetPos(self.net_send_size:GetWide()-self.net_send_size.wang:GetWide(),0)
	
	self.data_save_delay:SetTall(22)
	self.data_save_delay:DockMargin(5,5,5,0)
	self.data_save_delay:Dock(TOP)
	self.data_save_delay.wang:SetWide(self.data_save_delay:GetWide()/4)
	self.data_save_delay.wang:SetPos(self.data_save_delay:GetWide()-self.data_save_delay.wang:GetWide(),0)
	
	self.client_settings:SetPos(self:GetWide()/2+3,0)
	self.client_settings:SetSize(self:GetWide()/2-3,self:GetTall()/2-3)
	
	self.client_settings.header:SetTall(20)
	self.client_settings.header:DockMargin(5,0,5,0)
	self.client_settings.header:Dock(TOP)
	
	self.checkbox_request:DockMargin(5,5,5,0)
	self.checkbox_request:Dock(TOP)
	
	self.autounsubscribe:SetTall(22)
	self.autounsubscribe:DockMargin(5,5,5,0)
	self.autounsubscribe:Dock(TOP)
	self.autounsubscribe.combobox:SetWide(self.autounsubscribe:GetWide()/5*2)
	self.autounsubscribe.combobox:SetPos(self.autounsubscribe:GetWide()-self.autounsubscribe.combobox:GetWide(),0)
	
	self.autounsubscribe_user:SetTall(22)
	self.autounsubscribe_user:DockMargin(5,5,5,0)
	self.autounsubscribe_user:Dock(TOP)
	self.autounsubscribe_user.combobox:SetWide(self.autounsubscribe_user:GetWide()/5*2)
	self.autounsubscribe_user.combobox:SetPos(self.autounsubscribe_user:GetWide()-self.autounsubscribe_user.combobox:GetWide(),0)
	
	self.buttons:SetTall(49)
	self.buttons:DockMargin(5,0,5,5)
	self.buttons:Dock(BOTTOM)
	
	self.buttons.fetch_data:Dock(TOP)
	
	self.buttons.flush_data:SetWide(self.buttons.fetch_data:GetWide()/2-2)
	self.buttons.flush_data:SetPos(0,self.buttons:GetTall()-self.buttons.flush_user_data:GetTall())
	
	self.buttons.flush_user_data:SetWide(self.buttons.fetch_data:GetWide()/2-2)
	self.buttons.flush_user_data:SetPos(self.buttons.flush_data:GetWide()+4,self.buttons:GetTall()-self.buttons.flush_user_data:GetTall())
	
	self.inheritance_settings:SetPos(self:GetWide()/2+3,self:GetTall()/2+2)
	self.inheritance_settings:SetSize(self:GetWide()/2-3,self:GetTall()/2-2)
	
	self.inheritance_settings.header:SetTall(20)
	self.inheritance_settings.header:DockMargin(5,0,5,0)
	self.inheritance_settings.header:Dock(TOP)
	
	self.inheritance_target:SetTall(22)
	self.inheritance_target:DockMargin(5,5,5,0)
	self.inheritance_target:Dock(TOP)
	self.inheritance_target.combobox:SetWide(self.autounsubscribe:GetWide()/5*2)
	self.inheritance_target.combobox:SetPos(self.autounsubscribe:GetWide()-self.autounsubscribe.combobox:GetWide(),0)
	
	self.inheritance_target:SetTall(22)
	self.inheritance_target:DockMargin(5,5,5,0)
	self.inheritance_target:Dock(TOP)
	self.inheritance_target.combobox:SetWide(self.inheritance_target:GetWide()/5*2)
	self.inheritance_target.combobox:SetPos(self.inheritance_target:GetWide()-self.inheritance_target.combobox:GetWide(),0)
	
end

function PANEL:Paint(w,h)
	surface.SetDrawColor(159, 163, 167, 255)
	surface.DrawRect(0,0,w,h)
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
 
function PANEL:UpdateSettings(settings)
	self:SelectChoiceByData(self.log_level.combobox,tonumber(settings.log_level))
	self:SelectChoiceByData(self.echo_changes.combobox,tonumber(settings.echo_changes))
	self.net_send_interval.wang:SetValue(tonumber(settings.net_send_interval))
	self.net_send_size.wang:SetValue(tonumber(settings.net_send_size))
	self.data_save_delay.wang:SetValue(tonumber(settings.data_save_delay))
	self.checkbox_echo_chat:SetValue(tonumber(settings.echo_to_chat))
end

vgui.Register("WUMA_Settings", PANEL, 'DPanel');

