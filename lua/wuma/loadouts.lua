
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
WUMA.Loadouts = WUMA.Loadouts or {}

function WUMA.LoadLoadouts()
	local saved, tbl = WUMA.GetSavedLoadouts() or {}, {}

	for k, v in pairs(saved) do
		tbl[v:GetUserGroup()] = v
	end

	WUMA.Loadouts = tbl
end

function WUMA.GetSavedLoadouts(user)
	local tbl = {}

	if (user) then
		tbl = WUMA.ReadUserLoadout(user)
	else
		local saved = util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."loadouts.txt")) or {}

		for key, obj in pairs(saved) do
			if istable(obj) then
				obj.parent = user
				tbl[key] = Loadout:new(obj)
			end
		end
	end

	return tbl
end

function WUMA.ReadUserLoadout(user)
	if not isstring(user) then user = user:SteamID() end

	local saved = util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user, Loadout))) or {}
	saved.parent = user

	local loadout = Loadout:new(saved)
	return loadout
end

function WUMA.GetSavedLoadout(user)
	return WUMA.GetSavedLoadouts(user)
end

function WUMA.GetLoadouts(user)
	if user and not isstring(user) then
		return user:GetLoadout()
	elseif user and isstring(user) then
		return WUMA.Loadouts[user]
	else
		return WUMA.Loadouts
	end
end

function WUMA.LoadoutsExist()
	if (table.Count(WUMA.Loadouts) > 0) then return true end
end

function WUMA.HasPersonalLoadout(user)
	return WUMA.Files.Exists(WUMA.GetUserFile(user, Loadout))
end

function WUMA.SetLoadoutPrimaryWeapon(caller, usergroup, item)
	if not(WUMA.Loadouts[usergroup]) then return false end

	local primary = WUMA.Loadouts[usergroup]:GetPrimary()
	if (WUMA.Loadouts[usergroup]:GetPrimary() == item) then item = nil end

	WUMA.Loadouts[usergroup]:SetPrimary(item)

	WUMA.ScheduleDataUpdate(Loadout:GetID(), function(tbl)
		if tbl[usergroup] then
			tbl[usergroup]:SetPrimary(item)
		end
		return tbl
	end)

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not tbl[usergroup] or not istable(tbl[usergroup]) then
			tbl[usergroup] = table.Copy(WUMA.Loadouts[usergroup])
			tbl[usergroup].weapons = {}

			return tbl
		else
			tbl[usergroup]:SetPrimary(item)
			return tbl
		end
	end)

	local affected = WUMA.UpdateUsergroup(usergroup, function(user)
		if user:HasLoadout() then
			if user:GetLoadout():IsPersonal() then
				if user:GetLoadout():GetAncestor() then
					user:GetLoadout():GetAncestor():SetPrimary(item)
				end
			else
				user:GetLoadout():SetPrimary(item)
			end
		end
	end)

	WUMA.InvalidateCache(Loadout:GetID())

	return affected, item
end

function WUMA.SetEnforceLoadout(caller, usergroup, enforce)
	if not(WUMA.Loadouts[usergroup]) then return false end

	WUMA.Loadouts[usergroup]:SetEnforce(enforce)

	WUMA.ScheduleDataUpdate(Loadout:GetID(), function(tbl)
		if tbl[usergroup] then
			tbl[usergroup]:SetEnforce(enforce)
		end
		return tbl
	end)

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not tbl[usergroup] or not istable(tbl[usergroup]) then
			tbl[usergroup] = table.Copy(WUMA.Loadouts[usergroup])
			tbl[usergroup].weapons = {}

			return tbl
		else
			tbl[usergroup]:SetEnforce(enforce)
			return tbl
		end
	end)

	local affected = WUMA.UpdateUsergroup(usergroup, function(user)
		if user:HasLoadout() then
			if user:GetLoadout():IsPersonal() then
				if user:GetLoadout():GetAncestor() then
					user:GetLoadout():GetAncestor():SetEnforce(enforce)
					if not user:GetLoadout():GetEnforce() then
						if user:GetLoadout():GetAncestor():GetEnforce() then
							user:GetLoadout():GetAncestor():Give()
						else
							WUMA.GiveLoadout(user)
						end
					end
				end
			else
				user:GetLoadout():SetEnforce(enforce)
				if not enforce then
					WUMA.GiveLoadout(user)
				end
			end
		end
	end)

	WUMA.InvalidateCache(Loadout:GetID())

	return affected
end

function WUMA.AddLoadoutWeapon(caller, usergroup, item, primary, secondary, respect, scope)

	WUMA.Loadouts[usergroup] = WUMA.Loadouts[usergroup] or Loadout:new({usergroup=usergroup})

	if scope then scope:SetProperty("class", item) end

	WUMA.Loadouts[usergroup]:AddWeapon(item, primary, secondary, respect, scope)

	local affected = WUMA.UpdateUsergroup(usergroup, function(user)
		if not WUMA.Loadouts[usergroup] then return end
		if not user:HasLoadout() then
			user:SetLoadout(WUMA.Loadouts[usergroup]:Clone())
			WUMA.GiveLoadout(user)
		elseif user:HasLoadout() then
			if user:GetLoadout():IsPersonal() then
				if user:GetLoadout():GetAncestor() then
					user:GetLoadout():GetAncestor():AddWeapon(item, primary, secondary, respect, scope)
				else
					user:GetLoadout():SetAncestor(WUMA.Loadouts[usergroup]:Clone())
					if not user:GetLoadout():GetEnforce() then
						user:GetLoadout():GetAncestor():Give(item)
					end
				end
			else
				user:GetLoadout():AddWeapon(item, primary, secondary, respect, scope)
			end
		end
	end)

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not tbl[usergroup] or not istable(tbl[usergroup]) then
			tbl[usergroup] = table.Copy(WUMA.Loadouts[usergroup])
			tbl[usergroup].weapons = {}
			tbl[usergroup]:SetWeapon(item, WUMA.Loadouts[usergroup]:GetWeapon(item))

			return tbl
		else
			tbl[usergroup]:SetWeapon(item, WUMA.Loadouts[usergroup]:GetWeapon(item))
			return tbl
		end
	end)

	WUMA.ScheduleDataUpdate(Loadout:GetID(), function(tbl)
		if not tbl[usergroup] then
			tbl[usergroup] = Loadout:new({usergroup=usergroup})
		end
		tbl[usergroup]:AddWeapon(item, primary, secondary, respect, scope)

		return tbl
	end)

	WUMA.InvalidateCache(Loadout:GetID())

	return affected

end

function WUMA.RemoveLoadoutWeapon(caller, usergroup, item)
	if not WUMA.Loadouts[usergroup] then return false end
	WUMA.Loadouts[usergroup]:RemoveWeapon(item)

	local affected = WUMA.UpdateUsergroup(usergroup, function(user)
		if user:HasLoadout() then
			if user:GetLoadout():IsPersonal() then
				if user:GetLoadout():GetAncestor() then
					user:GetLoadout():GetAncestor():RemoveWeapon(item)
					if (user:GetLoadout():GetAncestor():GetWeaponCount() == 0) then
						user:GetLoadout():PurgeAncestor()
					end
				end
			else
				user:GetLoadout():RemoveWeapon(item)
				if (user:GetLoadout():GetWeaponCount() == 0) then
					user:ClearLoadout()
					WUMA.GiveLoadout(user)
				end
			end
		end
	end)

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not tbl[usergroup] or not istable(tbl[usergroup]) then
			tbl[usergroup] = table.Copy(WUMA.Loadouts[usergroup])
			tbl[usergroup].weapons = {}
			tbl[usergroup]:SetWeapon(item, WUMA.DELETE)

			return tbl
		else
			tbl[usergroup]:SetWeapon(item, WUMA.DELETE)
			return tbl
		end
	end)

	WUMA.ScheduleDataUpdate(Loadout:GetID(), function(tbl)
		if tbl[usergroup] then
			tbl[usergroup]:RemoveWeapon(item)

			if (tbl[usergroup]:GetWeaponCount() < 1) then
				tbl[usergroup] = nil
			end
		end

		return tbl
	end)

	if (WUMA.Loadouts[usergroup]:GetWeaponCount() < 1) then
		WUMA.Loadouts[usergroup] = nil
	end

	WUMA.InvalidateCache(Loadout:GetID())

	return affected

end

function WUMA.ClearLoadout(caller, usergroup)
	if not WUMA.Loadouts[usergroup] then return false end

	WUMA.Loadouts[usergroup] = nil

	local affected = WUMA.UpdateUsergroup(usergroup, function(user)
		user:ClearLoadout()
		WUMA.GiveLoadout(user)
	end)

	WUMA.AddClientUpdate(Loadout, function(tbl)
		tbl[usergroup] = WUMA.DELETE
		return tbl
	end)

	WUMA.ScheduleDataUpdate(Loadout:GetID(), function(tbl)
		tbl[usergroup] = nil

		return tbl
	end)

	WUMA.InvalidateCache(Loadout:GetID())

	return affected

end

function WUMA.SetUserLoadoutPrimaryWeapon(caller, user, item)

	local affected = {}

	local loadout
	if isentity(user) then
		affected = {user}

		if not user:HasLoadout() then return false end
		if user:HasLoadout() and not user:GetLoadout():IsPersonal() then return false end
		loadout = user:GetLoadout()
	else
		if not WUMA.CheckUserFileExists(user, Loadout) then return false end
		loadout = WUMA.ReadUserLoadout(user)
	end

	local primary = loadout:GetPrimary()
	if (primary == item) then item = nil end

	loadout:SetPrimary(item)

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not istable(tbl) or not tbl._id then tbl = Loadout:new{parent=user} end
		tbl:SetPrimary(item)
		return tbl
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Loadout:GetID(), function(tbl)
		tbl:SetPrimary(item)

		return tbl
	end)

	return affected, item
end

function WUMA.SetUserEnforceLoadout(caller, user, enforce)

	local steamid
	local loadout
	if isentity(user) then
		if not user:HasLoadout() then return false end
		if user:HasLoadout() and not user:GetLoadout():IsPersonal() then return false end
		user:GetLoadout():SetEnforce(enforce)

		if not enforce then
			WUMA.GiveLoadout(user)
		end
	else
	end

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not istable(tbl) or not tbl._id then tbl = Loadout:new{parent=user} end
		tbl:SetEnforce(enforce)
		return tbl
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Loadout:GetID(), function(tbl)
		tbl:SetEnforce(enforce)

		return tbl
	end)
end

function WUMA.AddUserLoadoutWeapon(caller, user, item, primary, secondary, respect, scope)

	if scope then scope:SetProperty("class", item) end

	local affected = {}

	local loadout
	if isentity(user) then
		if not user:HasLoadout() then
			local loadout = Loadout:new{parent=user}
			loadout:AddWeapon(item, primary, secondary, respect, scope)
			user:SetLoadout(loadout)
			WUMA.GiveLoadout(user)
		elseif not user:GetLoadout():IsPersonal() then
			local loadout = Loadout:new{parent=user}
			loadout:AddWeapon(item, primary, secondary, respect, scope)
			user:SetLoadout(loadout)
			WUMA.GiveLoadout(user)
		else
			user:GetLoadout():AddWeapon(item, primary, secondary, respect, scope)
		end

		affected = {user}

		loadout = user:GetLoadout()
	else
		loadout = WUMA.ReadUserLoadout(user)
	end

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not istable(tbl) or not tbl._id then tbl = Loadout:new{parent=user} end
		tbl:AddWeapon(item, primary, secondary, respect, scope)

		if loadout then
			tbl:SetEnforce(loadout:GetEnforce())
		end

		return tbl
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Loadout:GetID(), function(tbl)
		tbl:AddWeapon(item, primary, secondary, respect, scope)

		return tbl
	end)

	return affected
end

function WUMA.RemoveUserLoadoutWeapon(caller, user, item)

	if isstring(user) and WUMA.GetUsers()[user] then user = WUMA.GetUsers()[user] end
	if isentity(user) and user:HasLoadout() and user:GetLoadout():IsPersonal() then
		user:GetLoadout():RemoveWeapon(item)

		if (user:GetLoadout():GetWeaponCount() < 1) then
			user:ClearLoadout()
		end
	end

	local affected = {}

	local loadout
	if isentity(user) then
		loadout = user:GetLoadout()

		affected = {user}
	else
		loadout = WUMA.ReadUserLoadout(user)
	end

	WUMA.AddClientUpdate(Loadout, function(tbl)
		if not istable(tbl) or not tbl._id then tbl = Loadout:new{parent=user} end
		tbl:SetWeapon(item, WUMA.DELETE)

		if loadout then
			tbl:SetEnforce(loadout:GetEnforce())
		end

		return tbl
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Loadout:GetID(), function(tbl)
		tbl:RemoveWeapon(item)

		return tbl
	end)

	return affected
end

function WUMA.ClearUserLoadout(caller, user)

	local affected = {}

	if isstring(user) and WUMA.GetUsers()[user] then user = WUMA.GetUsers()[user] end
	if isentity(user) then
		user:ClearLoadout()

		affected = {user}

		WUMA.GiveLoadout(user)
	end

	WUMA.AddClientUpdate(Loadout, function(tbl)
		return WUMA.DELETE
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Loadout, function(tbl)
		tbl:SetWeapons({})

		return tbl
	end)

	if isentity(user) then
		WUMA.GiveLoadout(user)
	end

	return affected
end

function WUMA.GiveLoadout(user)
	hook.Call("PlayerLoadout", GAMEMODE, user)
end

function WUMA.RefreshLoadout(user, usergroup)
	user:ClearLoadout()

	WUMA.AssignLoadout(user, usergroup)
	WUMA.AssignUserLoadout(user)

	timer.Simple(2, function()
		WUMA.GiveLoadout(user)
	end)
end

function WUMA.RefreshUserLoadout(user)
	user:ClearLoadout()
	WUMA.AssignUserLoadout(user)
	WUMA.GiveLoadout(user)
end

function WUMA.RefreshUsergroupLoadout(user, usergroup)
	user:ClearLoadout()
	WUMA.AssignLoadout(user, usergroup)
	WUMA.GiveLoadout(user)
end

WUMA.RegisterDataID(Loadout:GetID(), "loadouts.txt", WUMA.GetSavedLoadouts, WUMA.isTableEmpty)
WUMA.RegisterUserDataID(Loadout:GetID(), "loadouts.txt", WUMA.GetSavedLoadouts, function(tbl) return (tbl:GetWeaponCount() < 1) end)