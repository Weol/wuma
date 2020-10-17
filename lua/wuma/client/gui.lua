
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

	surface.CreateFont("WUMAText", {
		font = "Arial",
		size = 15,
		weight = 500,
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

	local function asd()

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

		--Limits
		WUMA.GUI.LimitsTab = vgui.Create("WUMA_Limits", WUMA.GUI.PropertySheet)

		--Loadouts
		WUMA.GUI.LoadoutsTab = vgui.Create("WUMA_Loadouts", WUMA.GUI.PropertySheet)

		--Users
		WUMA.GUI.UsersTab = vgui.Create("WUMA_Users", WUMA.GUI.PropertySheet)

		WUMA.GUI.PropertySheet.OnTabChange = function(_, tab_name) WUMA.OnTabChange(tab_name) end

		--Adding panels to PropertySheet
		WUMA.GUI.PropertySheet:AddSheet("Settings", WUMA.GUI.SettingsTab, "icon16/wrench.png")
		WUMA.GUI.PropertySheet:AddSheet("Restrictions", WUMA.GUI.RestrictionsTab, "icon16/shield.png")
		WUMA.GUI.PropertySheet:AddSheet("Limits", WUMA.GUI.LimitsTab, "icon16/table.png")
		WUMA.GUI.PropertySheet:AddSheet("Loadouts", WUMA.GUI.LoadoutsTab, "icon16/bomb.png")
		WUMA.GUI.PropertySheet:AddSheet("Users", WUMA.GUI.UsersTab, "icon16/drive_user.png")

		--WUMA.GUI.UsersTab.OnExtraChange = function(_, type, steamid) WUMA.OnUserTabChange(type, steamid) end
	end

	asd()

	concommand.Add("reload_wuma", function()
		WUMA.FlushSubscriptions()
		WUMA.GUI.PropertySheet:Remove()

		asd()
	end)

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
	if (WUMA.GUI.PropertySheet:GetParent() == WUMA.GUI.Base) then
		WUMA.OnTabChange(WUMA.GUI.ActiveTab or "Settings")

		WUMA.GUI.Base:SetVisible(true)
		WUMA.GUI.Base:MakePopup()
	end
end

function WUMA.GUI.Hide()
	if (WUMA.GUI.PropertySheet:GetParent() == WUMA.GUI.Base) then
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
	elseif (tabname == "Limits" and not initialized_tabs[tabname]) then
		WUMA.GUI.InitializeLimitsTab()
		--initialized_tabs[tabname] = true
	elseif (tabname == "Loadouts" and not initialized_tabs[tabname]) then
		WUMA.GUI.InitializeLoadoutTab()
		--initialized_tabs[tabname] = true
	elseif (tabname == "Users" and not initialized_tabs[tabname]) then
		WUMA.GUI.InitializeUsersTab()
		--initialized_tabs[tabname] = true
	end
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
		WUMA.GUI.SettingsTab:NotifyExludeLimitsChanged(new)
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

	function WUMA.GUI.RestrictionsTab:OnAddRestrictions(usergroups, selected_type, suggestions, is_anti)
		WUMA.RPC.Restrict:Transaction(usergroups, selected_type, suggestions, is_anti)
	end

	function WUMA.GUI.RestrictionsTab:OnDeleteRestrictions(usergroups, types, items)
		WUMA.RPC.Unrestrict:Transaction(usergroups, types, items)
	end

	function WUMA.GUI.RestrictionsTab:OnUsergroupSelected(usergroup)
		WUMA.Subscribe{
			args = {
				"restrictions",
				usergroup,
			},
			id = self,
			callback = function(limits, parent, updated, deleted)
				self:NotifyRestrictionsChanged(limits, parent, updated, deleted)
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

		WUMA.Subscribe{args = {"inheritance"}, callback = function(inheritance)
			local current = inheritance["restrictions"] and inheritance["restrictions"][usergroup]
			while current do
				WUMA.Subscribe{
					args = {
						"restrictions",
						current,
					},
					id = self,
					callback = function(limits, parent, updated, deleted)
						self:NotifyRestrictionsChanged(limits, parent, updated, deleted)
					end
				}

				WUMA.Subscribe{
					args = {
						"settings",
						current,
					},
					id = self,
					callback = function(settings, parent, _, _)
						self:NotifySettingsChanged(parent, settings)
					end
				}

				current = inheritance["restrictions"] and inheritance["restrictions"][current]
			end

			self:NotifyInheritanceChanged(inheritance)
		end}

	end

	WUMA.Subscribe{args = {"usergroups"}, callback = function(usergroups)
		WUMA.GUI.RestrictionsTab:NotifyUsergroupsChanged(usergroups)
	end}
end

function WUMA.GUI.InitializeLimitsTab()
	function WUMA.GUI.LimitsTab:OnAddLimits(usergroups, suggestions, limit, is_exclusive)
		WUMA.RPC.SetLimit:Transaction(usergroups, suggestions, limit, is_exclusive)
	end

	function WUMA.GUI.LimitsTab:OnDeleteLimits(usergroups, items)
		WUMA.RPC.UnsetLimit:Transaction(usergroups, items)
	end

	function WUMA.GUI.LimitsTab:OnUsergroupSelected(usergroup)
		WUMA.Subscribe{
			args = {
				"limits",
				usergroup,
			},
			id = self,
			callback = function(limits, parent, updated, deleted)
				self:NotifyLimitsChanged(limits, parent, updated, deleted)
			end
		}

		WUMA.Subscribe{args = {"inheritance"}, callback = function(inheritance)
			local current = inheritance["limits"] and inheritance["limits"][usergroup]
			while current do
				WUMA.Subscribe{
					args = {
						"limits",
						current,
					},
					id = self,
					callback = function(limits, parent, updated, deleted)
						self:NotifyLimitsChanged(limits, parent, updated, deleted)
					end
				}

				current = inheritance["limits"] and inheritance["limits"][current]
			end

			self:NotifyInheritanceChanged(inheritance)
		end}
	end

	WUMA.Subscribe{args = {"usergroups"}, callback = function(usergroups)
		WUMA.GUI.LimitsTab:NotifyUsergroupsChanged(usergroups)
	end}
end

function WUMA.GUI.InitializeLoadoutTab()

	function WUMA.GUI.LoadoutsTab:OnAddWeapon(usergroups, weapons, primary_ammo, secondary_ammo)
		WUMA.RPC.AddLoadout:Transaction(usergroups, weapons, primary_ammo, secondary_ammo)
	end

	function WUMA.GUI.LoadoutsTab:OnDeleteWeapon(usergroups, weapons)
		WUMA.RPC.RemoveLoadout:Transaction(usergroups, weapons)
	end

	function WUMA.GUI.LoadoutsTab:OnCopyPlayerLoadout(usergroups, steamid)
		WUMA.RPC.CopyPlayerLoadout:Transaction(usergroups, steamid)
	end

	function WUMA.GUI.LoadoutsTab:OnPrimaryWeaponSet(usergroups, weapon)
		WUMA.RPC.SetPrimaryWeapon:Transaction(usergroups, weapon)
	end

	function WUMA.GUI.LoadoutsTab:OnIgnoreRestrictionsChanged(usergroups, ignore_restrictions)
		WUMA.RPC.SetLoadoutIgnoreRestrictions:Transaction(usergroups, ignore_restrictions)
	end

	function WUMA.GUI.LoadoutsTab:OnEnforceLoadoutChanged(usergroups, enforce)
		WUMA.RPC.SetEnforceLoadout:Transaction(usergroups, enforce)
	end

	function WUMA.GUI.LoadoutsTab:OnUsergroupSelected(usergroup)
		WUMA.Subscribe{
			args = {
				"loadouts",
				usergroup,
			},
			id = self,
			callback = function(weapons, parent, updated, deleted)
				self:NotifyWeaponsChanged(weapons, parent, updated, deleted)
			end
		}

		WUMA.Subscribe{
			args = {
				"settings",
				usergroup,
			},
			id = self,
			callback = function(settings, parent, updated, deleted)
				self:NotifySettingsChanged(parent, settings, updated, deleted)
			end
		}
	end

	WUMA.Subscribe{args = {"usergroups"}, callback = function(usergroups)
		WUMA.GUI.LoadoutsTab:NotifyUsergroupsChanged(usergroups)
	end}
end

function WUMA.GUI.InitializeUsersTab()
	function WUMA.GUI.UsersTab:OnRestrictionsDisplayed(panel, steamid)
		WUMA.GUI.InitializeUserRestrictionsTab(panel, steamid)
	end

	function WUMA.GUI.UsersTab:OnLimitsDisplayed(panel, steamid)
		WUMA.GUI.InitializeUserLimitsTab(panel, steamid)
	end

	function WUMA.GUI.UsersTab:OnLoadoutsDisplayed(panel, steamid)
		WUMA.GUI.InitializeUserLoadoutsTab(panel, steamid)
	end

	function WUMA.GUI.UsersTab:OnSearchUsers(limit, offset, search, callback)
		WUMA.RPC.Lookup:Invoke(limit, offset, search, callback)
	end

	WUMA.Subscribe{
		args = {
			"online"
		},
		id = WUMA.GUI.UsersTab,
		callback = function(users, updated, deleted)
			WUMA.GUI.UsersTab:NotifyLookupUsersChanged(users, "online", updated, deleted)
		end
	}

	WUMA.Subscribe{
		args = {
			"lookup"
		},
		id = WUMA.GUI.UsersTab,
		callback = function(users, updated, deleted)
			WUMA.GUI.UsersTab:NotifyLookupUsersChanged(users, "lookup", updated, deleted)
		end
	}

	WUMA.RPC.Lookup:Invoke(WUMA.GUI.UsersTab.FETCH_COUNT, 0, nil, function(users)
		local mapped = {}
		for i, user in ipairs(users) do
			mapped[user.steamid] = user
		end

		WUMA.GUI.UsersTab:NotifyLookupUsersChanged(mapped, "lookup", mapped, {})
	end)
end

function WUMA.GUI.InitializeUserRestrictionsTab(panel, steamid)
	function panel:OnWhitelistChanged(usergroups, type, is_whitelist)
		WUMA.RPC.SetUserRestrictionsWhitelist:Transaction(usergroups, type, is_whitelist)
	end

	function panel:OnRestrictAllChanged(usergroups, type, restrict_all)
		WUMA.RPC.RestrictUserType:Transaction(usergroups, type, restrict_all)
	end

	function panel:OnAddRestrictions(usergroups, selected_type, suggestions, is_anti)
		WUMA.RPC.RestrictUser:Transaction(usergroups, selected_type, suggestions, is_anti)
	end

	function panel:OnDeleteRestrictions(usergroups, types, items)
		WUMA.RPC.UnrestrictUser:Transaction(usergroups, types, items)
	end

	WUMA.Subscribe{
		args = {
			"restrictions",
			steamid,
		},
		id = panel,
		callback = function(restrictions, parent, updated, deleted)
			panel:NotifyRestrictionsChanged(restrictions, parent, updated, deleted)
		end
	}

	WUMA.Subscribe{
		args = {
			"settings",
			steamid,
		},
		id = panel,
		callback = function(settings, parent, _, _)
			panel:NotifySettingsChanged(parent, settings)
		end
	}

	local ply = player.GetBySteamID(steamid)
	local usergroup = ply and ply:GetUserGroup()

	if usergroup then
		WUMA.Subscribe{
			args = {
				"restrictions",
				usergroup,
			},
			id = panel,
			callback = function(limits, parent, updated, deleted)
				panel:NotifyRestrictionsChanged(limits, parent, updated, deleted)
			end
		}

		WUMA.Subscribe{
			args = {
				"settings",
				usergroup,
			},
			id = panel,
			callback = function(settings, parent, _, _)
				panel:NotifySettingsChanged(parent, settings)
			end
		}
	end

	WUMA.Subscribe{args = {"inheritance"}, callback = function(inheritance)
		local current = inheritance["restrictions"] and inheritance["restrictions"][usergroup]
		while current do
			WUMA.Subscribe{
				args = {
					"restrictions",
					current,
				},
				id = panel,
				callback = function(limits, parent, updated, deleted)
					panel:NotifyRestrictionsChanged(limits, parent, updated, deleted)
				end
			}

			WUMA.Subscribe{
				args = {
					"settings",
					current,
				},
				id = panel,
				callback = function(settings, parent, _, _)
					panel:NotifySettingsChanged(parent, settings)
				end
			}

			current = inheritance["restrictions"] and inheritance["restrictions"][current]
		end

		if inheritance ["restrictions"] then
			inheritance["restrictions"][steamid] = ply:GetUserGroup()
		end

		panel:NotifyInheritanceChanged(inheritance)
	end}
end

function WUMA.GUI.InitializeUserLimitsTab(panel, steamid)
	function panel:OnAddLimits(usergroups, suggestions, limit, is_exclusive)
		WUMA.RPC.SetUserLimit:Transaction(usergroups, suggestions, limit, is_exclusive)
	end

	function panel:OnDeleteLimits(usergroups, items)
		WUMA.RPC.UnsetUserLimit:Transaction(usergroups, items)
	end

	WUMA.Subscribe{
		args = {
			"limits",
			steamid,
		},
		id = panel,
		callback = function(limits, parent, updated, deleted)
			panel:NotifyLimitsChanged(limits, parent, updated, deleted)
		end
	}

	local ply = player.GetBySteamID(steamid)
	local usergroup = ply and ply:GetUserGroup()

	if usergroup then
		WUMA.Subscribe{
			args = {
				"limits",
				usergroup,
			},
			id = panel,
			callback = function(limits, parent, updated, deleted)
				panel:NotifyLimitsChanged(limits, parent, updated, deleted)
			end
		}
	end

	WUMA.Subscribe{args = {"inheritance"}, callback = function(inheritance)
		local ply = player.GetBySteamID(steamid)
		local current = inheritance["limits"] and inheritance["limits"][usergroup]
		while current do
			WUMA.Subscribe{
				args = {
					"limits",
					current,
				},
				id = panel,
				callback = function(limits, parent, updated, deleted)
					panel:NotifyLimitsChanged(limits, parent, updated, deleted)
				end
			}

			current = inheritance["limits"] and inheritance["limits"][current]
		end

		if inheritance ["limits"] then
			inheritance["limits"][steamid] = ply:GetUserGroup()
		end

		panel:NotifyInheritanceChanged(inheritance)
	end}
end

function WUMA.GUI.InitializeUserLoadoutsTab(panel, steamid)
	function panel:OnAddWeapon(usergroups, weapons, primary_ammo, secondary_ammo)
		WUMA.RPC.AddUserLoadout:Transaction(usergroups, weapons, primary_ammo, secondary_ammo)
	end

	function panel:OnDeleteWeapon(usergroups, weapons)
		WUMA.RPC.RemoveUserLoadout:Transaction(usergroups, weapons)
	end

	function panel:OnCopyPlayerLoadout(usergroups, steamid)
		WUMA.RPC.UserCopyPlayerLoadout:Transaction(usergroups, steamid)
	end

	function panel:OnPrimaryWeaponSet(usergroups, weapon)
		WUMA.RPC.SetUserPrimaryWeapon:Transaction(usergroups, weapon)
	end

	function panel:OnIgnoreRestrictionsChanged(usergroups, ignore_restrictions)
		WUMA.RPC.SetUserLoadoutIgnoreRestrictions:Transaction(usergroups, ignore_restrictions)
	end

	function panel:OnEnforceLoadoutChanged(usergroups, enforce)
		WUMA.RPC.SetUserEnforceLoadout:Transaction(usergroups, enforce)
	end

	WUMA.Subscribe{
		args = {
			"loadouts",
			steamid,
		},
		id = panel,
		callback = function(weapons, parent, updated, deleted)
			panel:NotifyWeaponsChanged(weapons, parent, updated, deleted)
		end
	}

	WUMA.Subscribe{
		args = {
			"settings",
			steamid,
		},
		id = panel,
		callback = function(settings, parent, updated, deleted)
			panel:NotifySettingsChanged(parent, settings, updated, deleted)
		end
	}
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