
WUMA.Loadouts = WUMA.Loadouts or {}

WUMA.PersonalLoadoutCommand = CreateConVar("wuma_personal_loadout_chatcommand", "!loadout", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chat command to open the loadout selector")
cvars.AddChangeCallback("wuma_personal_loadout_chatcommand", function(convar, old, new)
	if (new == "") then
		convar:SetString(old)
	end
end)

--Second argument is a WUMA LoadoutWeapon, not an actual gmod swep
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
		local primary_weapon = WUMA.GetSetting(player:GetUserGroup(), "loadout_primary_weapon")
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
	local current_primary = WUMA.GetSetting(parent, "loadout_primary_weapon")

	if (current_primary == class) then
		class = nil
	end

	WUMA.SetSetting(parent, "loadout_primary_weapon", class)

	hook.Call("WUMAOnLoadoutPrimaryWeaponChanged", nil, caller, parent, class)
end

function WUMA.SetEnforceLoadout(caller, parent, enforce)
	WUMA.SetSetting(parent, "loadout_enforce", enforce)

	hook.Call("WUMAOnLoadoutEnforceChanged", nil, caller, parent, enforce)
end

function WUMA.SetLoadoutIgnoreRestrictions(caller, parent, ignore)
	WUMA.SetSetting(parent, "loadout_ignore_restrictions", ignore)

	hook.Call("WUMAOnLoadoutIgnoreRestrictionsChanged", nil, caller, parent, ignore)
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

local function userDisconnected(user)
	WUMA.Loadouts[user:SteamID()] = nil

	if not WUMA.IsUsergroupConnected(user:GetUserGroup()) then
		WUMA.Loadouts[user:GetUserGroup()] = nil
	end
end
hook.Add("PlayerDisconnected", "WUMA_LOADOUTS_PlayerDisconnected", userDisconnected)

local function playerInitialSpawn(player)
	if not WUMA.Loadouts[player:GetUserGroup()] then
		WUMA.Loadouts[player:GetUserGroup()] = WUMA.ReadLoadouts(player:GetUserGroup())
	end

	if not WUMA.Loadouts[player:SteamID()] then
		WUMA.Loadouts[player:SteamID()] = WUMA.ReadLoadouts(player:SteamID())
	end
end
hook.Add("PlayerInitialSpawn", "WUMA_LOADOUTS_PlayerInitialSpawn", playerInitialSpawn)

local function playerUsergroupChanged(player)
	--player:Loadout()
end
hook.Add("CAMI.PlayerUsergroupChanged", "WUMA_LOADOUTS_CAMI.PlayerUsergroupChanged", playerUsergroupChanged)