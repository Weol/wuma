
WUMA = WUMA or {}

if SERVER then
	WUMA.EchoChanges = WUMA.CreateConVar("wuma_echo_changes", "2", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "0 = Nobody, 1 = Access, 2 = Everybody, 3 = Relevant")
	WUMA.EchoToChat = WUMA.CreateConVar("wuma_echo_to_chat", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable / disable echo in chat.")

	function WUMA.RegisterCommands(commands)
		local privliges = CAMI.GetPrivileges()

		for _, command in pairs(commands) do
			local privligeName = "wuma " .. command:GetPrivilage()
			if not privliges[privligeName] then
				CAMI.RegisterPrivilege{Name = privligeName, MinAccess = "superadmin", Description = command:GetHelp()}
			end
		end
	end

	function WUMA.EchoFunction(args, affected, caller)

		if not args then return end

		local msg = args[1]
		table.remove(args, 1)

		local str = string.format(msg, caller:Nick(), unpack(args))

		if WUMA.EchoChanges then
			if (WUMA.EchoChanges:GetInt() == 1) then
				WUMA.GetAuthorizedUsers(function(users)
					for _, user in pairs(users) do
						if WUMA.EchoToChat:GetBool() then
							user:ChatPrint(str)
						else
							user:PrintMessage(HUD_PRINTCONSOLE, str)
						end
					end
				end)
			elseif (WUMA.EchoChanges:GetInt() == 2) then
				for _, user in pairs(player.GetAll()) do
					if WUMA.EchoToChat:GetBool() then
						user:ChatPrint(str)
					else
						user:PrintMessage(HUD_PRINTCONSOLE, str)
					end
				end
			elseif (WUMA.EchoChanges:GetInt() == 3) then
				if affected and istable(affected) then
					for _, user in pairs(affected) do
						if WUMA.EchoToChat:GetBool() then
							user:ChatPrint(str)
						else
							user:PrintMessage(HUD_PRINTCONSOLE, str)
						end
					end
				end
			end
		end

		WUMALog(str)
	end
end

WUMA.Commands = {}

WUMA.Commands.Restrict = WUMACommand:New{name = "restrict", help = "Restrict something from a usergroup"}
WUMA.Commands.Restrict:SetFunction(WUMA.AddRestriction)
WUMA.Commands.Restrict:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.Restrict:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.Restrict:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.Restrict:AddOptionalArgument(WUMACommand.NUMBER)
WUMA.Commands.Restrict:AddOptionalArgument(WUMACommand.SCOPE)

WUMA.Commands.RestrictUser = WUMACommand:New{name = "restrictuser", help = "Restrict something from a player"}
WUMA.Commands.RestrictUser:SetFunction(WUMA.AddUserRestriction)
WUMA.Commands.RestrictUser:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.RestrictUser:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.RestrictUser:AddOptionalArgument(WUMACommand.STRING)
WUMA.Commands.RestrictUser:AddOptionalArgument(WUMACommand.NUMBER)
WUMA.Commands.RestrictUser:AddOptionalArgument(WUMACommand.SCOPE)

WUMA.Commands.Unrestrict = WUMACommand:New{name = "unrestrict", help = "Unrestrict something from a usergroup"}
WUMA.Commands.Unrestrict:SetFunction(WUMA.RemoveRestriction)
WUMA.Commands.Unrestrict:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.Unrestrict:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.Unrestrict:AddOptionalArgument(WUMACommand.STRING)

WUMA.Commands.UnrestrictUser = WUMACommand:New{name = "unrestrictuser", help = "Unrestrict something from a player"}
WUMA.Commands.UnrestrictUser:SetFunction(WUMA.RemoveUserRestriction)
WUMA.Commands.UnrestrictUser:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.UnrestrictUser:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.UnrestrictUser:AddOptionalArgument(WUMACommand.STRING)

WUMA.Commands.SetLimit = WUMACommand:New{name = "setlimit", help = "Set somethings limit."}
WUMA.Commands.SetLimit:SetFunction(WUMA.AddLimit)
WUMA.Commands.SetLimit:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.SetLimit:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.SetLimit:AddRequiredArgument(WUMACommand.ANY)
WUMA.Commands.SetLimit:AddOptionalArgument(WUMACommand.BOOLEAN)
WUMA.Commands.SetLimit:AddOptionalArgument(WUMACommand.SCOPE)

WUMA.Commands.SetUserLimit = WUMACommand:New{name = "setuserlimit", help = "Set the limit something for a player"}
WUMA.Commands.SetUserLimit:SetFunction(WUMA.AddUserLimit)
WUMA.Commands.SetUserLimit:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.SetUserLimit:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.SetUserLimit:AddRequiredArgument(WUMACommand.ANY)
WUMA.Commands.SetUserLimit:AddOptionalArgument(WUMACommand.BOOLEAN)
WUMA.Commands.SetUserLimit:AddOptionalArgument(WUMACommand.SCOPE)

WUMA.Commands.UnsetLimit = WUMACommand:New{name = "unsetlimit", help = "Unset somethings limit."}
WUMA.Commands.UnsetLimit:SetFunction(WUMA.RemoveLimit))
WUMA.Commands.UnsetLimit:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.UnsetLimit:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.UnsetUserLimit = WUMACommand:New{name = "unsetuserlimit", help = "Unset the limit something for a player"}
WUMA.Commands.UnsetUserLimit:SetFunction(WUMA.RemoveUserLimit)
WUMA.Commands.UnsetUserLimit:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.UnsetUserLimit:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.AddLoadout = WUMACommand:New{name = "addloadout", help = "Add a weapon to a usergroups loadout."}
WUMA.Commands.AddLoadout:SetFunction(WUMA.AddLoadoutWeapon)
WUMA.Commands.AddLoadout:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.AddLoadout:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.AddLoadout:AddRequiredArgument(WUMACommand.NUMBER)
WUMA.Commands.AddLoadout:AddRequiredArgument(WUMACommand.NUMBER)
WUMA.Commands.AddLoadout:AddRequiredArgument(WUMACommand.BOOLEAN)
WUMA.Commands.AddLoadout:AddOptionalArgument(WUMACommand.SCOPE)

WUMA.Commands.AddUserLoadout = WUMACommand:New{name = "adduserloadout", help = "Add a weapon to a users loadout."}
WUMA.Commands.AddUserLoadout:SetFunction(WUMA.AddUserLoadoutWeapon)
WUMA.Commands.AddUserLoadout:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.AddUserLoadout:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.AddUserLoadout:AddRequiredArgument(WUMACommand.NUMBER)
WUMA.Commands.AddUserLoadout:AddRequiredArgument(WUMACommand.NUMBER)
WUMA.Commands.AddUserLoadout:AddRequiredArgument(WUMACommand.BOOLEAN)
WUMA.Commands.AddUserLoadout:AddOptionalArgument(WUMACommand.SCOPE)

WUMA.Commands.RemoveLoadout = WUMACommand:New{name = "removeloadout", help = "Remove a weapon from a usergroups loadout."}
WUMA.Commands.RemoveLoadout:SetFunction(WUMA.RemoveLoadoutWeapon)
WUMA.Commands.RemoveLoadout:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.RemoveLoadout:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.RemoveUserLoadout = WUMACommand:New{name = "removeuserloadout", help = "Restrict something from a usergroup."}
WUMA.Commands.RemoveUserLoadout:SetFunction(WUMA.RemoveUserLoadoutWeapon)
WUMA.Commands.RemoveUserLoadout:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.RemoveUserLoadout:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.ClearLoadout = WUMACommand:New{name = "clearloadout", help = "Clear a usergroups loadout."}
WUMA.Commands.ClearLoadout:SetFunction(WUMA.ClearLoadout)
WUMA.Commands.ClearLoadout:AddRequiredArgument(WUMACommand.USERGROUP)

WUMA.Commands.ClearUserLoadout = WUMACommand:New{name = "clearuserloadout", help = "Clear a user loadout."}
WUMA.Commands.ClearUserLoadout:SetFunction(WUMA.ClearUserLoadout)
WUMA.Commands.ClearUserLoadout:AddRequiredArgument(WUMACommand.STEAMID)

WUMA.Commands.SetPrimaryWeapon = WUMACommand:New{name = "setprimaryweapon", help = "Set a groups primary weapon."}
WUMA.Commands.SetPrimaryWeapon:SetFunction(WUMA.SetLoadoutPrimaryWeapon)
WUMA.Commands.SetPrimaryWeapon:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.SetPrimaryWeapon:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.SetUserPrimaryWeapon = WUMACommand:New{name = "setuserprimaryweapon", help = "Set a users primary weapon."}
WUMA.Commands.SetUserPrimaryWeapon:SetFunction(WUMA.SetUserLoadoutPrimaryWeapon)
WUMA.Commands.SetUserPrimaryWeapon:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.SetUserPrimaryWeapon:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.SetEnforceLoadout = WUMACommand:New{name = "setenforceloadout", help = "Set a groups primary weapon."}
WUMA.Commands.SetEnforceLoadout:SetFunction(WUMA.SetEnforceLoadout)
WUMA.Commands.SetEnforceLoadout:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.SetEnforceLoadout:AddRequiredArgument(WUMACommand.BOOLEAN)

WUMA.Commands.SetUserEnforceLoadout = WUMACommand:New{name = "setuserenforceloadout", help = "Set a users primary weapon."}
WUMA.Commands.SetUserEnforceLoadout:SetFunction(WUMA.SetUserEnforceLoadout)
WUMA.Commands.SetUserEnforceLoadout:AddRequiredArgument(WUMACommand.STEAMID)
WUMA.Commands.SetUserEnforceLoadout:AddRequiredArgument(WUMACommand.BOOLEAN)

WUMA.Commands.ChangeSettings = WUMACommand:New{name = "changesettings", help = "Change WUMA settings"}
WUMA.Commands.ChangeSettings:SetFunction(function(caller, setting, value)
	local actual_value = util.JSONToTable(value)[1]
	local convar = GetConVar("wuma_"..setting)

	if isstring(actual_value) then
		convar:SetString(actual_value)
	elseif isnumber(actual_value) and (math.floor(actual_value) == actual_value) then
		convar:SetInt(actual_value)
	elseif isnumber(actual_value) and (math.floor(actual_value) ~= actual_value) then
		convar:SetFloat(actual_value)
	elseif isbool(actual_value) then
		if actual_value then actual_value = 1 else actual_value = 0 end
		convar:SetInt(actual_value)
	end
end)
WUMA.Commands.ChangeSettings:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.ChangeSettings:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.ChangeInheritance = WUMACommand:New{name = "changeinheritance", help = "Change WUMA settings"}
WUMA.Commands.ChangeInheritance:SetFunction(function(caller, enum, target, usergroup)
	if (usergroup) then
		WUMA.SetUsergroupInheritance(enum, target, usergroup)
	else
		WUMA.UnsetUsergroupInheritance(enum, target)
	end
end)
WUMA.Commands.ChangeInheritance:AddRequiredArgument(WUMACommand.STRING)
WUMA.Commands.ChangeInheritance:AddRequiredArgument(WUMACommand.USERGROUP)
WUMA.Commands.ChangeInheritance:AddOptionalArgument(WUMACommand.USERGROUP)

WUMA.Commands.AddPersonalLoadout = WUMACommand:New{name = "addpersonalloadout", help = "Adds a weapon to a users personal loadout.", access = "personalloadout"}
WUMA.Commands.AddPersonalLoadout:SetFunction(function(caller, item)
	WUMA.AddUserLoadoutWeapon(caller, caller, item, -1, -1, true)
end)
WUMA.Commands.AddPersonalLoadout:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.RemovePersonalLoadout = WUMACommand:New{name = "removepersonalloadout", help = "Removes a weapon from users personal loadout.", access = "personalloadout"}
WUMA.Commands.RemovePersonalLoadout:SetFunction(function(caller, item)
	WUMA.RemoveUserLoadoutWeapon(caller, caller, item)
end)
WUMA.Commands.RemovePersonalLoadout:AddRequiredArgument(WUMACommand.STRING)

WUMA.Commands.ClearPersonalLoadout = WUMACommand:New{name = "clearpersonalloadout", help = "Clear personal loadout.", access = "personalloadout"}
WUMA.Commands.ClearPersonalLoadout:SetFunction(function(caller)
	WUMA.ClearUserLoadout(caller, caller)
end)

WUMA.Commands.SetPersonalPrimaryWeapon = WUMACommand:New{name = "setpersonalprimaryweapon", help = "Sets a users own primary weapon.", access = "personalloadout"}
WUMA.Commands.SetPersonalPrimaryWeapon:SetFunction(function(caller, item)
	WUMA.SetUserLoadoutPrimaryWeapon(caller, caller, item)
end)
WUMA.Commands.SetPersonalPrimaryWeapon:AddRequiredArgument(WUMACommand.STRING)

if SERVER then
	--Register all accesses with CAMI
	WUMA.RegisterCommands(WUMA.Commands)
end