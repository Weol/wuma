
WUMA.Loadouts = WUMA.Loadouts or {}

WUMA.PersonalLoadoutCommand = CreateConVar("wuma_personal_loadout_chatcommand", "!loadout", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chat command to open the loadout selector")
cvars.AddChangeCallback("wuma_personal_loadout_chatcommand", function(convar, old, new)
	if (new == "") then
		convar:SetString(old)
	end
end)

--Third argument is a WUMA LoadoutWeapon, not an actual gmod swep
function WUMA.GiveWeapon(player, givenBy, weapon)
	local swep = player:Give(weapon:GetClass())
	if IsValid(swep) then
		swep.SpawnedByWUMA = givenBy

		if not swep then error("cannot get the given weapon") end

		local primary_ammo = weapon:GetPrimaryAmmo()
		local secondary_ammo = weapon:GetSecondaryAmmo()

		if (primary_ammo < 0) then primary_ammo = swep:GetMaxClip1() * 4 end
		if (primary_ammo < 0) then primary_ammo = 3 end

		if (secondary_ammo < 0) then secondary_ammo = swep:GetMaxClip2() * 4 end
		if (secondary_ammo < 0) then secondary_ammo = 3 end

		swep:SetClip1(0)
		swep:SetClip2(0)

		if (swep:GetMaxClip1() <= 0) then
			player:SetAmmo(primary_ammo, swep:GetPrimaryAmmoType())
		elseif (swep:GetMaxClip1() > primary_ammo) then
			swep:SetClip1(primary_ammo)
			player:SetAmmo(0, swep:GetPrimaryAmmoType())
		else
			player:SetAmmo(primary_ammo-swep:GetMaxClip1(), swep:GetPrimaryAmmoType())
			swep:SetClip1(swep:GetMaxClip1())
		end

		if (swep:GetMaxClip2() <= 0) then
			player:SetAmmo(secondary_ammo, swep:GetSecondaryAmmoType())
		elseif (swep:GetMaxClip2() > secondary_ammo) then
			swep:SetClip2(secondary_ammo)
			player:SetAmmo(0, swep:GetSecondaryAmmoType())
		else
			player:SetAmmo(secondary_ammo-swep:GetMaxClip2(), swep:GetSecondaryAmmoType())
			swep:SetClip2(swep:GetMaxClip2())
		end
	end
end

local function stripWeapon(player, givenBy, class)
	local swep = player:GetWeapon(class)
	if IsValid(swep) and (swep.SpawnedByWUMA == givenBy) then
		local primary_weapon = WUMA.Settings[player:GetUserGroup()] and WUMA.Settings[player:GetUserGroup()]["loadout_primary_weapon"]
		if (class == player:GetActiveWeapon()) and primary_weapon then
			player:SelectWeapon(primary_weapon)
		else
			local next_weapon = player:GetWeapons()[1]
			if next_weapon then
				player:SelectWeapon(next_weapon)
			end
		end

		player:StripWeapon(class)
	end
end

local function insertWeapon(weapon)
	WUMASQL(
		[[REPLACE INTO `WUMALoadouts` (`parent`, `class`, `primary_ammo`, `secondary_ammo`) VALUES ("%s", "%s", "%s", "%s");]],
		weapon:GetParent(),
		weapon:GetClass(),
		weapon:GetPrimaryAmmo(),
		weapon:GetSecondaryAmmo()
	)
end

local function deleteWeapon(parent, class)
	WUMASQL(
		[[DELETE FROM `WUMALoadouts` WHERE `parent` == "%s" and `class` == "%s"]],
		parent,
		class
	)
end

local function clearLoadout(parent)
	WUMASQL(
		[[DELETE FROM `WUMALoadouts` WHERE `parent` == "%s"]],
		parent
	)
end

function WUMA.SetLoadoutPrimaryWeapon(caller, parent, class)
	local current_primary = WUMA.Settings[parent] and WUMA.Settings[parent]["loadout_primary_weapon"]

	if (current_primary == class) then
		class = nil
	end

	WUMA.SetSetting(parent, "loadout_primary_weapon", class)

	hook.Call("WUMAOnLoadoutPrimaryWeaponChanged", nil, caller, parent, class)
end

function WUMA.SetEnforceLoadout(caller, parent, enforce)
	WUMA.SetSetting(parent, "loadout_enforce", enforce)

	hook.Call("WUMAOnLoadoutExtendChanged", nil, caller, parent, enforce)
end

function WUMA.AddLoadoutWeapon(caller, parent, class, primary_ammo, secondary_ammo)
	local weapon = LoadoutWeapon:New{parent=parent, class=class, primary_ammo=primary_ammo, secondary_ammo=secondary_ammo}

	if WUMA.Loadouts[parent] or player.GetBySteamID(parent) or WUMA.IsUsergroupConnected(parent) then
		WUMA.Loadouts[parent] = WUMA.Loadouts[parent] or {}
		WUMA.Loadouts[parent][weapon:GetClass()] = weapon
	end

	local players = WUMA.GetPlayers(parent)
	for steamid, player in pairs(players) do
		WUMA.GiveWeapon(player, parent, weapon)
	end

	insertWeapon(weapon)

	hook.Call("WUMAOnLoadoutAdded", nil, caller, weapon)
end

function WUMA.RemoveLoadoutWeapon(caller, parent, class)
	if WUMA.Loadouts[parent] then
		WUMA.Loadouts[parent][class] = nil
		if table.IsEmpty(WUMA.Loadouts[parent]) then
			WUMA.Loadouts[parent] = nil
		end
	end

	local players = WUMA.GetPlayers(parent)
	for steamid, player in pairs(players) do
		stripWeapon(player, parent, class)
	end

	deleteWeapon(parent, class)

	hook.Call("WUMAOnLoadoutRemoved", nil, caller, parent, class)
end

function WUMA.CopyPlayerLoadout(caller, parent, steamid)
	local ply = player.GetBySteamID(steamid)

	if not ply then error("cannot copy player loadout, player not found") end

	local weapons = {}
	for _, weapon in pairs(ply:GetWeapons()) do
		local primary = ply:GetAmmoCount(weapon:GetPrimaryAmmoType()) + (weapon:Clip1() or 0)
		local secondary = ply:GetAmmoCount(weapon:GetSecondaryAmmoType()) + (weapon:Clip2() or 0)
		table.insert(weapons, {parent, weapon:GetClass(), primary, secondary})
		WUMA.AddLoadoutWeapon(caller, parent, weapon:GetClass(), primary, secondary)
	end

	clearLoadout(parent)

	local primary = ply:GetActiveWeapon()
	if primary then
		WUMA.SetLoadoutPrimaryWeapon(caller, parent, primary:GetClass())
	end
end

function WUMA.ReadLoadouts(parent)
	local loadouts = WUMASQL([[SELECT * FROM `WUMALoadouts` WHERE `parent` == "%s"]], parent)
	if loadouts then
		local preprocessed = {}
		for _, args in pairs(loadouts) do
			--PrintTable(args)
			args.primary_ammo = tonumber(string.Replace(args.primary_ammo, "'", ""))
			args.secondary_ammo = tonumber(string.Replace(args.secondary_ammo, "'", ""))
			--PrintTable(args)
			local loadout = LoadoutWeapon:New(args)
			preprocessed[loadout:GetClass()] = loadout
		end
		return preprocessed
	end
end

local function playerLoadout(player)
	local steamid = player:SteamID()
	local usergroup = player:GetUserGroup()

	local user_extend = WUMA.Settings[steamid] and WUMA.Settings[steamid]["loadout_enforce"]
	local group_extend = WUMA.Settings[usergroup] and WUMA.Settings[usergroup]["loadout_enforce"]

	local user_primary_weapon = WUMA.Settings[steamid] and WUMA.Settings[steamid]["loadout_primary_weapon"]
	local group_primary_weapon = WUMA.Settings[usergroup] and WUMA.Settings[usergroup]["loadout_primary_weapon"]

	local default_weapon = user_primary_weapon or group_primary_weapon

	player:StripWeapons()
	player:RemoveAllAmmo()

	if WUMA.Loadouts[steamid] then
		for class, weapon in pairs(WUMA.Loadouts[steamid]) do
			default_weapon = default_weapon or weapon:GetClass()
			WUMA.GiveWeapon(player, steamid, weapon)
		end

		if not user_extend then
			player:ConCommand("cl_defaultweapon " .. default_weapon)
			player:SwitchToDefaultWeapon()

			return true
		end
	end

	if WUMA.Loadouts[usergroup] then
		for class, weapon in pairs(WUMA.Loadouts[usergroup]) do
			default_weapon = default_weapon or weapon:GetClass()
			WUMA.GiveWeapon(player, usergroup, weapon)
		end

		if not group_extend then
			player:ConCommand("cl_defaultweapon " .. default_weapon)
			player:SwitchToDefaultWeapon()

			return true
		end
	end

	if user_primary_weapon or group_primary_weapon then
		player:ConCommand("cl_defaultweapon " .. default_weapon)
	end
	player:SwitchToDefaultWeapon()
end
hook.Add("PlayerLoadout", "WUMA_LOADOUTS_PlayerLoadout", playerLoadout)

local function userDisconnected(user)
	WUMA.Loadouts[user:SteamID()] = nil
end
hook.Add("PlayerDisconnected", "WUMA_LOADOUTS_PlayerDisconnected", userDisconnected)

local function playerInitialSpawn(player)
	if not WUMA.Loadouts[player:SteamID()] then
		WUMA.Loadouts[player:SteamID()] = WUMA.ReadLoadouts(player:SteamID())
	end
end
hook.Add("PlayerInitialSpawn", "WUMA_LOADOUTS_PlayerInitialSpawn", playerInitialSpawn)

local function playerUsergroupChanged(player)
	--player:Loadout()
end
hook.Add("CAMI.PlayerUsergroupChanged", "WUMA_LOADOUTS_CAMI.PlayerUsergroupChanged", playerUsergroupChanged)