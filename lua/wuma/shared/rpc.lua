
if SERVER then
	WUMA.EchoChanges = CreateConVar("wuma_echo_changes", "2", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "0 = Nobody, 1 = Access, 2 = Everybody", 0, 2)
	WUMA.EchoToChat = CreateConVar("wuma_echo_to_chat", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable / disable echo in chat.", 0, 1)

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

WUMA.RPC = WUMA.RPC or {}

WUMA.RPC.Lookup = WUMARPCFunction:New{
	name = "lookup",
	privilage = "wuma gui",
	description = "Lookup users",
	func = function(_, ...) return WUMA.Lookup(...) end,
	validator = function(limit, offset, search)
		assert(isnumber(limit))
		assert(isnumber(offset))
		assert(not search or isstring(search))
	end
}

WUMA.RPC.Restrict = WUMARPCFunction:New{
	name = "restrict",
	privilage = "wuma restrict",
	description = "Restrict something from a usergroup",
	func = WUMA.AddRestriction,
	validator = function(usergroup, restriction_type, item, is_anti)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isstring(item))
		assert(isbool(is_anti))
	end
}

WUMA.RPC.RestrictUser = WUMARPCFunction:New{
	name = "restrictuser",
	privilage = "wuma restrictuser",
	description = "Restrict something from a player",
	func = WUMA.AddRestriction,
	validator = function(steamid, restriction_type, item, is_anti)
		assert(WUMA.IsSteamID(steamid))
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isstring(item))
		assert(isbool(is_anti))
	end
}

WUMA.RPC.Unrestrict = WUMARPCFunction:New{
	name = "unrestrict",
	privilage = "wuma unrestrict",
	description = "Unrestrict something from a usergroup",
	func = WUMA.RemoveRestriction,
	validator = function(usergroup, restriction_type, item)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isstring(item))
	end
}

WUMA.RPC.UnrestrictUser = WUMARPCFunction:New{
	name = "unrestrictuser",
	privilage = "wuma unrestrictuser",
	description = "Unrestrict something from a player",
	func = WUMA.RemoveRestriction,
	validator = function(steamid, restriction_type, item)
		assert(WUMA.IsSteamID(steamid))
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isstring(item))
	end
}

WUMA.RPC.RestrictType = WUMARPCFunction:New{
	name = "restricttype",
	privilage = "wuma restrict",
	description = "Restrict a type from a usergroup",
	func = WUMA.SetTypeRestriction,
	validator = function(usergroup, restriction_type, restrict)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isbool(restrict))
	end
}

WUMA.RPC.RestrictUserType = WUMARPCFunction:New{
	name = "restrictusertype",
	privilage = "wuma restrictuser",
	description = "Restrict a type from a player",
	func = WUMA.SetTypeRestriction,
	validator = function(steamid, restriction_type, restrict)
		assert(WUMA.IsSteamID(steamid))
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isbool(restrict))
	end
}

WUMA.RPC.SetRestrictionsWhitelist = WUMARPCFunction:New{
	name = "setrestrictionswhitelist",
	privilage = "wuma restrict",
	description = "Set whether or not the the restriction list of a usergroup should be a whitelist",
	func = WUMA.SetTypeIsWhitelist,
	validator = function(usergroup, restriction_type, iswhitelist)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isbool(iswhitelist))
	end
}

WUMA.RPC.SetUserRestrictionsWhitelist = WUMARPCFunction:New{
	name = "setuserrestrictionswhitelist",
	privilage = "wuma restrictuser",
	description = "Set whether or not the the restriction list of a player should be a whitelist",
	func = WUMA.SetTypeIsWhitelist,
	validator = function(steamid, restriction_type, iswhitelist)
		assert(WUMA.IsSteamID(steamid))
		assert(WUMA.RestrictionTypes[restriction_type])
		assert(isbool(iswhitelist))
	end
}

WUMA.RPC.SetLimit = WUMARPCFunction:New{
	name = "setlimit",
	privilage = "wuma setlimit",
	description = "Set the limit of something for a usergroup",
	func = WUMA.AddLimit,
	validator = function(usergroup, item, limit, is_exclusive)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isstring(item))
		assert(isstring(limit) or isnumber(limit))
		assert(isbool(is_exclusive))
	end
}

WUMA.RPC.SetUserLimit = WUMARPCFunction:New{
	name = "setuserlimit",
	privilage = "wuma setuserlimit",
	description = "Set the limit of something for a player",
	func = WUMA.AddLimit,
	validator = function(steamid, item, limit, is_exclusive)
		assert(WUMA.IsSteamID(steamid))
		assert(isstring(item))
		assert(isstring(limit) or isnumber(limit))
		assert(isbool(is_exclusive))
	end
}

WUMA.RPC.UnsetLimit = WUMARPCFunction:New{
	name = "unsetlimit",
	privilage = "wuma unsetlimit",
	description = "Remove a limit from a usergroup",
	func = WUMA.RemoveLimit,
	validator = function(usergroup, item)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isstring(item))
	end
}

WUMA.RPC.UnsetUserLimit = WUMARPCFunction:New{
	name = "unsetuserlimit",
	privilage = "wuma unsetuserlimit",
	description = "Remove a limit from a player",
	func = WUMA.RemoveLimit,
	validator = function(steamid, item)
		assert(WUMA.IsSteamID(steamid))
		assert(isstring(item))
	end
}

WUMA.RPC.AddLoadout = WUMARPCFunction:New{
	name = "addloadout",
	privilage = "wuma addloadout",
	description = "Add a weapon to a usergroup's loadout",
	func = WUMA.AddLoadoutWeapon,
	validator = function(usergroup, weapon, primary_ammo, secondary_ammo)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isstring(weapon))
		assert(isnumber(primary_ammo))
		assert(isnumber(secondary_ammo))
	end
}

WUMA.RPC.AddUserLoadout = WUMARPCFunction:New{
	name = "adduserloadout",
	privilage = "wuma adduserloadout",
	description = "Add a weapon to a player's loadout",
	func = WUMA.AddLoadoutWeapon,
	validator = function(steamid, weapon, primary_ammo, secondary_ammo)
		assert(WUMA.IsSteamID(steamid))
		assert(isstring(weapon))
		assert(isnumber(primary_ammo))
		assert(isnumber(secondary_ammo))
	end
}

WUMA.RPC.RemoveLoadout = WUMARPCFunction:New{
	name = "removeloadout",
	privilage = "wuma removeloadout",
	description = "Remove a weapon from a usergroups's loadout",
	func = WUMA.RemoveLoadoutWeapon,
	validator = function(usergroup, weapon)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isstring(weapon))
	end
}

WUMA.RPC.RemoveUserLoadout = WUMARPCFunction:New{
	name = "removeuserloadout",
	privilage = "wuma removeuserloadout",
	description = "Remove a weapon from a player's loadout",
	func = WUMA.RemoveLoadoutWeapon,
	validator = function(steamid, weapon)
		assert(WUMA.IsSteamID(steamid))
		assert(isstring(weapon))
	end
}

WUMA.RPC.SetPrimaryWeapon = WUMARPCFunction:New{
	name = "setprimaryweapon",
	privilage = "wuma setprimaryweapon",
	description = "Set a usergroup's primary weapon (spawn weapon)",
	func = WUMA.SetLoadoutPrimaryWeapon,
	validator = function(usergroup, weapon)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isstring(weapon))
	end
}

WUMA.RPC.SetUserPrimaryWeapon = WUMARPCFunction:New{
	name = "setuserprimaryweapon",
	privilage = "wuma setuserprimaryweapon",
	description = "Set a usergroup's primary weapon (spawn weapon)",
	func = WUMA.SetLoadoutPrimaryWeapon,
	validator = function(steamid, weapon)
		assert(WUMA.IsSteamID(steamid))
		assert(isstring(weapon))
	end
}

WUMA.RPC.SetEnforceLoadout = WUMARPCFunction:New{
	name = "setenforceloadout",
	privilage = "wuma setenforceloadout",
	description = "Set whether or not a usergroup's loadout should be enforced (whether or not the weapons in the loadout should extend a usergroup's loadout or replace it)",
	func = WUMA.SetEnforceLoadout,
	validator = function(usergroup, enforce)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isbool(enforce))
	end
}

WUMA.RPC.SetUserEnforceLoadout = WUMARPCFunction:New{
	name = "setuserenforceloadout",
	privilage = "wuma setuserenforceloadout",
	description = "Set whether or not a players's loadout should be enforced (whether or not the weapons in the loadout should extend a players's loadout or replace it)",
	func = WUMA.SetEnforceLoadout,
	validator = function(steamid, enforce)
		assert(WUMA.IsSteamID(steamid))
		assert(isbool(enforce))
	end
}

WUMA.RPC.SetLoadoutIgnoreRestrictions = WUMARPCFunction:New{
	name = "setloadoutignorerestrictions",
	privilage = "wuma setloadoutignorerestrictions",
	description = "Set whether or not a usergroup's loadout should ignore restrictions or not",
	func = WUMA.SetLoadoutIgnoreRestrictions,
	validator = function(usergroup, ignore_restrictions)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(isbool(ignore_restrictions))
	end
}

WUMA.RPC.SetUserLoadoutIgnoreRestrictions = WUMARPCFunction:New{
	name = "setuserloadoutignorerestrictions",
	privilage = "wuma setuserloadoutignorerestrictions",
	description = "Set whether or not a usergroup's loadout should ignore restrictions or not",
	func = WUMA.SetLoadoutIgnoreRestrictions,
	validator = function(steamid, ignore_restrictions)
		assert(WUMA.IsSteamID(steamid))
		assert(isbool(ignore_restrictions))
	end
}

WUMA.RPC.CopyPlayerLoadout = WUMARPCFunction:New{
	name = "copyplayerloadout",
	privilage = "wuma copyplayerloadout",
	description = "Clear a usergroup's loadout and add the weapons that an online player has on them",
	func = WUMA.CopyPlayerLoadout,
	validator = function(usergroup, steamid)
		assert(CAMI.GetUsergroups()[usergroup])
		assert(WUMA.IsSteamID(steamid))
	end
}

WUMA.RPC.UserCopyPlayerLoadout = WUMARPCFunction:New{
	name = "usercopyplayerloadout",
	privilage = "wuma usercopyplayerloadout",
	description = "Clear a user's loadout and add the weapons that an online player has on them",
	func = WUMA.CopyPlayerLoadout,
	validator = function(user, steamid)
		assert(WUMA.IsSteamID(user))
		assert(WUMA.IsSteamID(steamid))
	end
}

WUMA.RPC.ChangeSettings = WUMARPCFunction:New{
	name = "changesettings",
	privilage = "wuma changesettings",
	description = "Change a WUMA setting",
	func = function(_, setting, value)
		local convar = GetConVar("wuma_"..setting)
		if (tonumber(value) ~= nil) then
			value = tonumber(value)
			if (math.floor(value) == value) then
				convar:SetInt(value)
			else
				convar:SetFloat(value)
			end
		elseif isbool(value) then
			convar:SetBool(value)
		elseif(value == "true" or value == "false") then
			convar:SetBool(value == "true")
		else
			convar:SetString(tostring(value))
		end
	end,
	validator = function(setting, _)
		assert(isstring(setting))
	end
}

WUMA.RPC.ChangeInheritance = WUMARPCFunction:New{
	name = "changeinheritance",
	privilage = "wuma changeinheritance",
	description = "Change WUMA inheritance",
	func = function(caller, type, usergroup, inheritFrom)
		if (inheritFrom) then
			WUMA.SetUsergroupInheritance(caller, type, usergroup, inheritFrom)
		else
			WUMA.UnsetUsergroupInheritance(caller, type, usergroup)
		end
	end,
	validator = function(type, usergroup, inheritFrom)
		assert(type == "restrictions" or type == "limits")

		assert(CAMI.GetUsergroups()[usergroup])
		assert(not inheritFrom or CAMI.GetUsergroups()[inheritFrom])
	end
}

WUMA.RPC.AddPersonalLoadout = WUMARPCFunction:New{
	name = "addpersonalloadout",
	privilage = "wuma personalloadout",
	description = "Adds a weapon to the calling player's loadout",
	func = function(caller, item)
		WUMA.AddLoadoutWeapon(caller, caller, item, -1, -1, true)
	end,
	validator = function(item)
		assert(isstring(item))
	end
}

WUMA.RPC.RemovePersonalLoadout = WUMARPCFunction:New{
	name = "removepersonalloadout",
	privilage = "wuma personalloadout",
	description = "Removes a weapon to the calling player's loadout",
	func = function(caller, item)
		WUMA.RemoveLoadoutWeapon(caller, caller, item)
	end,
	validator = function(item)
		assert(isstring(item))
	end
}

WUMA.RPC.SetPersonalPrimaryWeapon = WUMARPCFunction:New{
	name = "setpersonalprimaryweapon",
	privilage = "wuma personalloadout",
	description = "Sets the primary weapon of the calling player's loadut",
	func = function(caller, item)
		WUMA.SetLoadoutPrimaryWeapon(caller, caller, item)
	end,
	validator = function(item)
		assert(isstring(item))
	end
}