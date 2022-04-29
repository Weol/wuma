WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
WUMA.ServerGroups = WUMA.ServerGroups or {}
WUMA.ServerUsers = WUMA.ServerUsers or {}
WUMA.LookupUsers = WUMA.LookupUsers or {}
WUMA.UserData = WUMA.UserData or {}
WUMA.Restrictions = WUMA.Restrictions or {}
WUMA.AdditionalEntities = WUMA.AdditionalEntities or {}
WUMA.PersonalRestrictions = WUMA.PersonalRestrictions or {}
WUMA.Limits = WUMA.Limits or {}
WUMA.Loadouts = WUMA.Loadouts or {}
WUMA.LoadoutWeapons = WUMA.LoadoutsWeapons or {}
WUMA.Maps = WUMA.Maps or {}
WUMA.ServerSettings = WUMA.ServerSettings or {}
WUMA.ClientSettings = WUMA.ClientSettings or {}
WUMA.CVarLimits = WUMA.CVarLimits or {}
WUMA.Inheritance = {}

--Hooks
WUMA.USERGROUPSUPDATE = "WUMAUserGroupsUpdate"
WUMA.LOOKUPUSERSUPDATE = "WUMALookupUsersUpdate"
WUMA.SERVERUSERSUPDATE = "WUMAServerUsersUpdate"
WUMA.USERDATAUPDATE = "WUMAUserDataUpdate"
WUMA.MAPSUPDATE = "WUMAMapsUpdate"
WUMA.SETTINGSUPDATE = "WUMASettingsUpdate"
WUMA.INHERITANCEUPDATE = "WUMAInheritanceUpdate"
WUMA.PERSONALLOADOUTRESTRICTIONSUPDATE = "WUMAPersonalLoadoutRestrictionsUpdate"
WUMA.CVARLIMITSUPDATE = "WUMALimitsUpdate"
WUMA.PROGRESSUPDATE = "WUMAProgressUpdate"

WUMA.RESTRICTIONUPDATE = "WUMARestrictionUpdate"
WUMA.LIMITUPDATE = "WUMALimitUpdate"
WUMA.LOADOUTUPDATE = "WUMALoadoutUpdate"

--CVars
CreateClientConVar("wuma_autounsubscribe", "-1", true, false, "Time in seconds before unsubscribing from data. -1 = Never.")
CreateClientConVar("wuma_autounsubscribe_user", "900", true, false, "Time in seconds before unsubscribing from data. -1 = Never.")
CreateClientConVar("wuma_request_on_join", "0", true, false, "Wether or not to request data on join")

--Data update
function WUMA.ProcessDataUpdate(id, data)
	WUMADebug("Process Data Update: (%s)", id)

	hook.Call(WUMA.PROGRESSUPDATE, nil, id, "Processing data")

	if (id == Restriction:GetID()) then
		WUMA.UpdateRestrictions(data)
	end

	if (id == Limit:GetID()) then
		WUMA.UpdateLimits(data)
	end

	if (id == Loadout:GetID()) then
		WUMA.UpdateLoadouts(data)
	end

	local private = string.find(id, ":::")
	if private then
		WUMA.UpdateUser(string.sub(id, private + 3), string.sub(id, 1, private - 1), data)
	end

end

--Data update
local compressedBuffer = {}
function WUMA.ProcessCompressedData(id, data, await, index)

	if await or compressedBuffer[id] then
		hook.Call(WUMA.PROGRESSUPDATE, nil, id, "Recieving data (" .. index .. ")")
	end

	if compressedBuffer[id] then
		compressedBuffer[id] = compressedBuffer[id] .. data
		if not await then
			data = compressedBuffer[id]
			compressedBuffer[id] = nil
		else
			return
		end
	elseif await then
		compressedBuffer[id] = data
		return
	end

	WUMADebug("Processing compressed data. Size: %s", string.len(data))

	hook.Call(WUMA.PROGRESSUPDATE, nil, id, "Decompressing data")

	local uncompressed_data = util.Decompress(data)

	if not uncompressed_data then
		WUMADebug("Failed to uncompress data! Size: %s", string.len(data))
		hook.Call(WUMA.PROGRESSUPDATE, nil, id, "Decompress failed! Flush data and try again")
		return
	end
	WUMADebug("Data sucessfully decompressed. Size: %s", string.len(uncompressed_data))

	local tbl = util.JSONToTable(uncompressed_data)

	WUMA.ProcessDataUpdate(id, tbl)
end

function WUMA.UpdateRestrictions(update)

	for id, tbl in pairs(update) do
		if istable(tbl) then
			tbl = Restriction:new(tbl)
			WUMA.Restrictions[id] = tbl
		else
			WUMA.Restrictions[id] = nil
		end

		update[id] = tbl
	end

	hook.Call(WUMA.RESTRICTIONUPDATE, nil, update)
end

function WUMA.UpdateLimits(update)

	for id, tbl in pairs(update) do
		if istable(tbl) then
			tbl = Limit:new(tbl)
			WUMA.Limits[id] = tbl
		else
			WUMA.Limits[id] = nil
		end

		update[id] = tbl
	end

	hook.Call(WUMA.LIMITUPDATE, nil, update)

end

function WUMA.UpdateLoadouts(update)

	if (table.Count(update) < 1) then
		hook.Call(WUMA.LOADOUTUPDATE, nil, {})
		return
	end

	for usergroup, loadout in pairs(update) do
		local weapons = {}
		local deletions = {}

		if istable(loadout) and (table.Count(loadout) > 0) then
			for class, weapon in pairs(loadout.weapons) do
				if isstring(weapon) then
					deletions[usergroup .. "_" .. class] = weapon
					WUMA.LoadoutWeapons[usergroup .. "_" .. class] = nil
					WUMA.Loadouts[usergroup]:SetWeapon(class, nil)
				end
			end

			local loadout = Loadout:new(loadout)

			if not WUMA.Loadouts[usergroup] then
				WUMA.Loadouts[usergroup] = loadout

				for class, weapon in pairs(loadout:GetWeapons()) do
					weapon.usergroup = usergroup
					WUMA.LoadoutWeapons[usergroup .. "_" .. class] = weapon
					weapons[usergroup .. "_" .. class] = weapon
				end
			else
				for k, v in pairs(WUMA.Loadouts[usergroup]) do
					if not istable(v) then
						WUMA.Loadouts[usergroup][k] = loadout[k]
					end
				end

				for k, v in pairs(loadout) do
					if not istable(v) and not WUMA.Loadouts[usergroup][k] then
						WUMA.Loadouts[usergroup][k] = loadout[k]
					end
				end

				for class, weapon in pairs(loadout:GetWeapons()) do
					weapon.usergroup = usergroup
					WUMA.LoadoutWeapons[usergroup .. "_" .. class] = weapon
					WUMA.Loadouts[usergroup]:SetWeapon(class, weapon)
					weapons[usergroup .. "_" .. class] = weapon
				end
			end
		elseif not istable(loadout) then
			WUMA.Loadouts[usergroup] = nil
			for class, v in pairs(WUMA.Loadouts[usergroup]:GetWeapons()) do
				weapons[class] = WUMA.DELETE
				WUMA.LoadoutWeapons[usergroup .. "_" .. class] = nil
			end
		end

		if WUMA.Loadouts[usergroup] and (WUMA.Loadouts[usergroup]:GetWeaponCount() < 1) then
			WUMA.Loadouts[usergroup] = nil
		end

		hook.Call(WUMA.LOADOUTUPDATE, nil, table.Merge(weapons, deletions))
	end

end

function WUMA.UpdateUser(id, enum, data)
	WUMA.UserData[id] = WUMA.UserData[id] or {}

	if (enum == Restriction:GetID()) then
		WUMA.UpdateUserRestrictions(id, data)
	end

	if (enum == Limit:GetID()) then
		WUMA.UpdateUserLimits(id, data)
	end

	if (enum == Loadout:GetID()) then
		WUMA.UpdateUserLoadouts(id, data)
	end

	if (enum == "PersonalLoadoutRestrictions") then
		WUMA.UpdatePersonalLoadoutRestrictions(id, data)
	end

end

function WUMA.UpdateUserRestrictions(user, update)
	WUMA.UserData[user].Restrictions = WUMA.UserData[user].Restrictions or {}

	for id, tbl in pairs(update) do
		if istable(tbl) then
			tbl = Restriction:new(tbl)
			tbl.usergroup = user
			tbl.parent = user

			WUMA.UserData[user].Restrictions[id] = tbl
		else
			WUMA.UserData[user].Restrictions[id] = nil
		end

		update[id] = tbl
	end

	hook.Call(WUMA.USERDATAUPDATE, nil, user, Restriction:GetID(), update)
end

function WUMA.UpdateUserLimits(user, update)
	WUMA.UserData[user].Limits = WUMA.UserData[user].Limits or {}

	for id, tbl in pairs(update) do
		if istable(tbl) then
			tbl = Limit:new(tbl)
			tbl.parent = user
			tbl.usergroup = user

			WUMA.UserData[user].Limits[id] = tbl
		else
			WUMA.UserData[user].Limits[id] = nil
		end

		update[id] = tbl
	end

	hook.Call(WUMA.USERDATAUPDATE, nil, user, Limit:GetID(), update)

end

function WUMA.UpdateUserLoadouts(user, loadout)
	WUMA.UserData[user].LoadoutWeapons = WUMA.UserData[user].LoadoutWeapons or {}
	local weapons = {}
	local deletions = {}

	if istable(loadout) and (table.Count(loadout) > 0) then
		for class, weapon in pairs(loadout.weapons) do
			if isstring(weapon) then
				deletions[class] = weapon
				WUMA.UserData[user].LoadoutWeapons[class] = nil
				if WUMA.UserData[user].Loadouts then WUMA.UserData[user].Loadouts:SetWeapon(class, nil) end
			end
		end

		local loadout = Loadout:new(loadout)

		if not WUMA.UserData[user].Loadouts then
			WUMA.UserData[user].Loadouts = loadout

			for class, weapon in pairs(loadout:GetWeapons()) do
				weapon.usergroup = user
				WUMA.UserData[user].LoadoutWeapons[class] = weapon
				weapons[class] = weapon
			end
		else
			for k, v in pairs(WUMA.UserData[user].Loadouts) do
				if not istable(v) then
					WUMA.UserData[user].Loadouts[k] = loadout[k]
				end
			end

			for k, v in pairs(loadout) do
				if not istable(v) and not WUMA.UserData[user].Loadouts[k] then
					WUMA.UserData[user].Loadouts[k] = loadout[k]
				end
			end

			for class, weapon in pairs(loadout:GetWeapons()) do
				weapon.usergroup = user
				WUMA.UserData[user].LoadoutWeapons[class] = weapon
				WUMA.UserData[user].Loadouts:SetWeapon(class, weapon)
				weapons[class] = weapon
			end
		end
	elseif not istable(loadout) then
		WUMA.UserData[user].Loadouts = nil
		for class, v in pairs(WUMA.UserData[user].Loadouts:GetWeapons()) do
			weapons[class] = WUMA.DELETE
			WUMA.UserData[user].LoadoutWeapons[class] = nil
		end
	end

	if WUMA.UserData[user].Loadouts and (WUMA.UserData[user].Loadouts:GetWeaponCount() < 1) then
		WUMA.UserData[user].Loadouts = nil
	end

	hook.Call(WUMA.USERDATAUPDATE, nil, user, Loadout:GetID(), table.Merge(weapons, deletions))
end

function WUMA.UpdatePersonalLoadoutRestrictions(user, update)
	for id, tbl in pairs(update) do
		if istable(tbl) then
			tbl = Restriction:new(tbl)
			tbl.usergroup = user
			tbl.parent = user

			WUMA.PersonalRestrictions[id] = tbl
		else
			WUMA.PersonalRestrictions[id] = nil
		end

		update[id] = tbl
	end

	hook.Call(WUMA.PERSONALLOADOUTRESTRICTIONSUPDATE, nil, user, update)
end

--Information update
function WUMA.ProcessInformationUpdate(enum, data)
	WUMADebug("Process Information Update:")

	if WUMA.GetStream(enum) then
		WUMA.GetStream(enum)(data)
	else
		WUMADebug("NET STREAM enum not found! (%s)", tostring(enum))
	end
end

local DisregardSettingsChange = false
function WUMA.UpdateSettings(settings)
	DisregardSettingsChange = true

	if (WUMA.GUI.Tabs.Settings) then
		WUMA.GUI.Tabs.Settings:UpdateSettings(settings)
	end

	DisregardSettingsChange = false
end

hook.Add(WUMA.SETTINGSUPDATE, "WUMAGUISettings", function(settings) WUMA.UpdateSettings(settings) end)

function WUMA.OnSettingsUpdate(setting, value)
	if not DisregardSettingsChange then
		value = util.TableToJSON({ value })

		local access = "changesettings"
		local data = { setting, value }

		WUMA.SendCommand(access, data, true)
	end
end

function WUMA.UpdateInheritance(inheritance)
	if (WUMA.GUI.Tabs.Settings) then
		WUMA.GUI.Tabs.Settings.DisregardInheritanceChange = true
		WUMA.GUI.Tabs.Settings:UpdateInheritance(inheritance)
		WUMA.GUI.Tabs.Settings.DisregardInheritanceChange = false
	end
end

hook.Add(WUMA.INHERITANCEUPDATE, "WUMAGUIInheritance", function(settings) WUMA.UpdateInheritance(settings) end)

function WUMA.OnInheritanceUpdate(enum, target, usergroup)
	if not WUMA.GUI.Tabs.Settings.DisregardInheritanceChange then
		local access = "changeinheritance"

		if (string.lower(usergroup) == "nobody") then usergroup = nil end
		local data = { enum, target, usergroup }

		WUMA.SendCommand(access, data, true)
	end
end
