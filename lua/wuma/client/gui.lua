
WUMA.GUI = WUMA.GUI or {}

if not WUMA.HasCreatedFonts then
	surface.CreateFont("WUMATextSmall", {
		font = "Arial",
		size = 10,
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true
	})
end
WUMA.HasCreatedFonts = true

function WUMA.GUI.Initialize()

	--Create EditablePanel
	WUMA.GUI.Base = vgui.Create("EditablePanel")
	WUMA.GUI.Base:SetSize(ScrW()*0.40, ScrH()*0.44)
	WUMA.GUI.Base:SetPos(ScrW()/2-WUMA.GUI.Base:GetWide()/2, ScrH()/2-WUMA.GUI.Base:GetTall()/2)
	WUMA.GUI.Base:SetVisible(false)

	--Create propertysheet
	WUMA.GUI.PropertySheet = vgui.Create("WPropertySheet", WUMA.GUI.Base)
	WUMA.GUI.PropertySheet:SetSize(WUMA.GUI.Base:GetSize())
	WUMA.GUI.PropertySheet:SetPos(0, 0)
	WUMA.GUI.PropertySheet:SetShowExitButton(true)

	function WUMA.GUI.PropertySheet:OnCloseButtonPressed()
		WUMA.GUI.Toggle()
	end

	--Create panels
	WUMA.GUI.SettingsTab = vgui.Create("WUMA_Settings", WUMA.GUI.PropertySheet)

	--Restrictions
	WUMA.GUI.RestrictionsTab = vgui.Create("WUMA_Restrictions", WUMA.GUI.PropertySheet)

	--WUMA.GUI.LimitsTab = vgui.Create("WUMA_Limits", WUMA.GUI.PropertySheet)
	--WUMA.GUI.LoadoutsTab = vgui.Create("WUMA_Loadouts", WUMA.GUI.PropertySheet)
	--WUMA.GUI.UsersTab = vgui.Create("WUMA_Users", WUMA.GUI.PropertySheet)

	WUMA.GUI.PropertySheet.OnTabChange = function(_, tab_name) WUMA.OnTabChange(tab_name) end

	--Adding panels to PropertySheet
	WUMA.GUI.PropertySheet:AddSheet("Settings", WUMA.GUI.SettingsTab, "icon16/shield.png")
	WUMA.GUI.PropertySheet:AddSheet("Restrictions", WUMA.GUI.RestrictionsTab, WUMA.GUI.RestrictionsTab.TabIcon)
	--WUMA.GUI.PropertySheet:AddSheet("Limits", WUMA.GUI.LimitsTab, WUMA.GUI.LimitsTab.TabIcon)
	--WUMA.GUI.PropertySheet:AddSheet("Loadouts", WUMA.GUI.LoadoutsTab, WUMA.GUI.LoadoutsTab.TabIcon)
	--WUMA.GUI.PropertySheet:AddSheet("Users", WUMA.GUI.UsersTab, WUMA.GUI.UsersTab.TabIcon)

	--WUMA.GUI.UsersTab.OnExtraChange = function(_, type, steamid) WUMA.OnUserTabChange(type, steamid) end

	hook.Call("OnWUMAInitialized", nil, WUMA.GUI.PropertySheet)

end
hook.Add("InitPostEntity", "WUMA_GUI_InitPostEntity", function() timer.Simple(2, WUMA.GUI.Initialize) end)

function WUMA.GUI.Toggle()
	if WUMA.GUI.Base:IsVisible() then
		WUMA.GUI.Hide()
	else
		WUMA.GUI.Show()
	end
end

function WUMA.GUI.Show()
	if not table.IsEmpty(WUMA.GUI.Base:GetChildren()) then
		WUMA.OnTabChange(WUMA.GUI.ActiveTab or WUMA.GUI.SettingsTab.TabName)

		WUMA.GUI.Base:SetVisible(true)
		WUMA.GUI.Base:MakePopup()
	end
end

function WUMA.GUI.Hide()
	if not table.IsEmpty(WUMA.GUI.Base:GetChildren()) then
		WUMA.GUI.Base:SetVisible(false)
	end
end

local initialized_tabs = {}
function WUMA.OnTabChange(tabname)
	if (tabname == "Settings" and not initialized_tabs[tabname]) then
		WUMA.GUI.InitializeSettingsTab()
		--initialized_tabs[tabname] = true
	elseif (tabname == "Restrictions" and not initialized_tabs[tabname]) then
		WUMA.GUI.InitializeRestrictionsTab()
		--initialized_tabs[tabname] = true
	end
end

function WUMA.OnUserTabChange(type, steamid)

end

function WUMA.GUI.InitializeSettingsTab()
	function WUMA.GUI.SettingsTab:OnInheritanceChanged(type, usergroup, inheritFrom)
		WUMA.RPC.ChangeInheritance:Invoke(type, usergroup, inheritFrom)
	end

	function WUMA.GUI.SettingsTab:OnExludeLimitsChanged(exclude)
		WUMA.RPC.ChangeSettings:Invoke("exclude_limits", exclude)
	end

	function WUMA.GUI.SettingsTab:OnPersonalLoadoutCommandChanged(command)
		WUMA.RPC.ChangeSettings:Invoke("personal_loadout_chatcommand", command)
	end

	function WUMA.GUI.SettingsTab:OnEchoChangesComboboxChanged(echo)
		WUMA.RPC.ChangeSettings:Invoke("echo_changes", echo)
	end

	function WUMA.GUI.SettingsTab:OnEchoToChatChanged(echo)
		WUMA.RPC.ChangeSettings:Invoke("echo_to_chat", echo)
	end

	function WUMA.GUI.SettingsTab:OnLogLevelChanged(log_level)
		WUMA.RPC.ChangeSettings:Invoke("log_level", log_level)
	end

	cvars.AddChangeCallback("wuma_exclude_limits", function(_, _, new)
		WUMA.RPC.ChangeSettings:NotifyExludeLimitsChanged(new)
	end)

	cvars.AddChangeCallback("wuma_personal_loadout_chatcommand", function(_, _, new)
		WUMA.GUI.SettingsTab:NotifyPersonalLoadoutCommandChanged(new)
	end)

	cvars.AddChangeCallback("wuma_echo_changes", function(_, _, new)
		WUMA.GUI.SettingsTab:NotifyEchoChangesChanged(new)
	end)

	cvars.AddChangeCallback("wuma_echo_to_chat", function(_, _, new)
		WUMA.GUI.SettingsTab:NotifyEchoToChatChanged(new)
	end)

	cvars.AddChangeCallback("wuma_log_level", function(_, _, new)
		WUMA.GUI.SettingsTab:NotifyLogLevelChanged(new)
	end)

	WUMA.Subscribe{args = {"inheritance"}, callback = function(inheritance)
		WUMA.GUI.SettingsTab:NotifyInheritanceChanged(inheritance)
	end}

	WUMA.Subscribe{args = {"usergroups"}, callback = function(usergroups)
		WUMA.GUI.SettingsTab:NotifyUsergroupsChanged(usergroups)
	end}
end

function WUMA.GUI.InitializeRestrictionsTab()
	function WUMA.GUI.RestrictionsTab:OnWhitelistChanged(usergroups, type, is_whitelist)
		WUMA.RPC.SetRestrictionsWhitelist:Transaction(usergroups, type, is_whitelist)
	end

	function WUMA.GUI.RestrictionsTab:OnRestrictAllChanged(usergroups, type, restrict_all)
		WUMA.RPC.RestrictType:Transaction(usergroups, type, restrict_all)
	end

	function WUMA.GUI.RestrictionsTab:OnAddRestriction(usergroups, selected_type, suggestions, is_anti)
		WUMA.RPC.Restrict:Transaction(usergroups, selected_type, suggestions, is_anti)
	end

	function WUMA.GUI.RestrictionsTab:OnDeleteRestriction(usergroups, types, items)
		WUMA.RPC.Unrestrict:Transaction(usergroups, types, items)
	end

	function WUMA.GUI.RestrictionsTab:OnUsergroupSelected(usergroup)
		WUMA.Subscribe{
			args = {
				"restrictions",
				usergroup,
			},
			id = self,
			callback = function(restrictions, parent, updated, deleted)
				self:NotifyRestrictionsChanged(restrictions, parent, updated, deleted)
			end
		}

		WUMA.Subscribe{
			args = {
				"settings",
				usergroup,
			},
			id = self,
			callback = function(settings, parent, _, _)
				self:NotifySettingsChanged(parent, settings)
			end
		}
	end

	WUMA.Subscribe{args = {"usergroups"}, callback = function(usergroups)
		WUMA.GUI.RestrictionsTab:NotifyUsergroupsChanged(usergroups)
	end}
end

function WUMA.GUI.CreateLoadoutSelector()
	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW()*0.40, ScrH()*0.44)
	frame:SetPos(ScrW()/2-frame:GetWide()/2, ScrH()/2-frame:GetTall()/2)
	frame:SetTitle("Select your loadout")

	frame.OnClose = function()
		WUMA.Unsubscribe("restrictions", LocalPlayer():SteamID())
		WUMA.Unsubscribe("loadouts", LocalPlayer():SteamID())
	end

	frame.Paint = function()
		draw.RoundedBox(5, 0, 0, frame:GetWide(), frame:GetTall(), Color(59, 59, 59, 255))
		draw.RoundedBox(5, 1, 1, frame:GetWide() - 2, frame:GetTall() - 2, Color(226, 226, 226, 255))

		draw.RoundedBox(5, 1, 1, frame:GetWide()-2, 25-1, Color(163, 165, 169, 255))
		surface.SetDrawColor(Color(163, 165, 169, 255))
		surface.DrawRect(1, 10, frame:GetWide()- 2, 15)
	end

	local loadout = vgui.Create("WUMA_PersonalLoadout", frame)
	loadout:Dock(TOP)
	loadout:SetWide(frame:GetWide())
	loadout:SetTall(frame:GetTall()-35)

	loadout:GetDataView():Show(LocalPlayer():SteamID())

	frame:MakePopup()
	frame:SetVisible(true)
end