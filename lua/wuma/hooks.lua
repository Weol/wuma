

local function checkLimit(player, str, id)
	if string.Left(id, 5) == "gmod_" then
		local convar = GetConVar("sbox_max" .. string.sub(id, 6))
		if convar then
			str = string.sub(id, 6)
			id = nil
		else
			convar = GetConVar("sbox_max" .. string.sub(id, 6) .. "s")
			if convar then
				str = string.sub(id, 6) .. "s"
				id = nil
			end
		end
	end

	return player:CheckLimit(str, id)
end

local function checkRestriction(player, type, item)
	return player:CheckRestriction(type, item)
end

local function playerSpawnSENT(player, sent)
	if not player or not sent then return end
	if (checkRestriction(player, "entity", sent) == false) then return false end
	if (checkLimit(player, "sents", sent) == false) then return false end
end
hook.Add("PlayerSpawnSENT", "WUMA_HOOKS_PlayerSpawnSENT", playerSpawnSENT, -1)

local function playerSpawnedSENT(player, ent)
	if not player or not ent then return end
	player:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSENT", "WUMA_HOOKS_PlayerSpawnedSENT", playerSpawnedSENT, -2)

local function playerSpawnProp(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (checkRestriction(player, "prop", mdl) == false) then return false end
	if (checkLimit(player, "props", mdl) == false) then return false end
end
hook.Add("PlayerSpawnProp", "WUMA_HOOKS_PlayerSpawnProp", playerSpawnProp, -1)

local function playerSpawnedProp(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	player:AddCount("props", ent, model)
end
hook.Add("PlayerSpawnedProp", "WUMA_HOOKS_PlayerSpawnedProp", playerSpawnedProp, -2)

local function canTool(player, tr, tool)
	if not player or not tool then return end
	return checkRestriction(player, "tool", tool)
end
hook.Add("CanTool", "WUMA_HOOKS_CanTool", canTool, -1)

local use_last = {}
local function playerUse(player, ent)
	if not player or not ent then return end

	if (use_last[player:SteamID()] and os.time() < use_last[player:SteamID()].time) then
		if (use_last[player:SteamID()].returned == false) then return false end
	else
		if ent:GetTable().VehicleName then ent = ent:GetTable().VehicleName else ent = ent:GetClass() end

		use_last[player:SteamID()] = {
			returned = checkRestriction(player, "use", ent),
			time = os.time() + 2
		}

		if (use_last[player:SteamID()].returned == false) then return false end
	end
end
hook.Add("PlayerUse", "WUMA_HOOKS_PlayerUse", playerUse)

local function playerSpawnEffect(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (checkRestriction(player, "effect", mdl) == false) then return false end
	if (checkLimit(player, "effects", mdl) == false) then return false end
end
hook.Add("PlayerSpawnEffect", "WUMA_HOOKS_PlayerSpawnEffect", playerSpawnEffect, -1)

local function playerSpawnedEffect(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	ent.WUMAModel = model
	player:AddCount("effects", ent, model)
end
hook.Add("PlayerSpawnedEffect", "WUMA_HOOKS_PlayerSpawnedEffect", playerSpawnedEffect, -2)

local function playerSpawnNPC(player, npc, weapon)
	if not player or not npc then return end
	if (checkRestriction(player, "npc", npc) == false) then return false end
	if (checkLimit(player, "npcs", npc) == false) then return false end
end
hook.Add("PlayerSpawnNPC", "WUMA_HOOKS_PlayerSpawnNPC", playerSpawnNPC, -1)

local function playerSpawnedNPC(player, ent)
	if not player or not ent then return end
	player:AddCount("npcs", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedNPC", "WUMA_HOOKS_PlayerSpawnedNPC", playerSpawnedNPC, -2)

local function playerSpawnRagdoll(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (checkRestriction(player, "ragdoll", mdl) == false) then return false end
	if (checkLimit(player, "ragdolls", mdl) == false) then return false end
end
hook.Add("PlayerSpawnRagdoll", "WUMA_HOOKS_PlayerSpawnRagdoll", playerSpawnRagdoll, -1)

local function playerSpawnedRagdoll(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	player:AddCount("ragdolls", ent, model)
end
hook.Add("PlayerSpawnedRagdoll", "WUMA_HOOKS_PlayerSpawnedRagdoll", playerSpawnedRagdoll, -2)

local function playerSpawnSWEP(player, class, weapon)
	if not player or not class then return end
	if (checkRestriction(player, "swep", class) == false) then return false end
	if (checkLimit(player, "sents", class) == false) then return false end
end
hook.Add("PlayerSpawnSWEP", "WUMA_HOOKS_PlayerSpawnSWEP", playerSpawnSWEP, -1)

local function playerGiveSWEP(player, class, weapon)
	if not player or not class then return end
	if (checkRestriction(player, "swep", class) == false) then return false end
	player:DisregardNextPickup(class)
end
hook.Add("PlayerGiveSWEP", "WUMA_HOOKS_PlayerGiveSWEP", playerGiveSWEP, -1)

local function playerSpawnedSWEP(player, ent)
	if not player or not ent then return end
	player:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSWEP", "WUMA_HOOKS_PlayerSpawnedSWEP", playerSpawnedSWEP, -2)

local pickup_last = {}
local function playerCanPickupWeapon(player, weapon)
	if not player or not weapon then return end

	if (pickup_last[player:SteamID()] and os.time() < pickup_last[player:SteamID()].time) then
		if (pickup_last[player:SteamID()].returned == false) then return false end
	else
		pickup_last[player:SteamID()] = {
			returned = checkRestriction(player, "pickup", weapon:GetClass()),
			time = os.time() + 2
		}

		if (pickup_last[player:SteamID()].returned == false) then return false end
	end
end
hook.Add("PlayerCanPickupWeapon", "WUMA_HOOKS_PlayerCanPickupWeapon", playerCanPickupWeapon, -1)

local function playerSpawnVehicle(player, mdl, name, vehicle_table)
	if not player or not name then return end
	if (checkRestriction(player, "vehicle", name) == false) then return false end
	if (checkLimit(player, "vehicles", name) == false) then return false end
end
hook.Add("PlayerSpawnVehicle", "WUMA_HOOKS_PlayerSpawnVehicle", playerSpawnVehicle, -1)

local function playerSpawnedVehicle(player, ent)
	if not player or not ent then return end
	player:AddCount("vehicles", ent, ent:GetTable().VehicleName)
end
hook.Add("PlayerSpawnedVehicle", "WUMA_HOOKS_PlayerSpawnedVehicle", playerSpawnedVehicle, -2)

local function playerCanProperty(player, property, ent)
	if not player or not property then return end
	if (checkRestriction(player, "property", property) == false) then return false end
end
hook.Add("CanProperty", "WUMA_HOOKS_CanProperty", playerCanProperty, -1)

local function playerPhysgunPickup(player, ent)
	if not player or not ent then return end

	local class = ent:GetClass()
	if (class == "prop_ragdoll" or class == "prop_physics") then
		class = ent:GetModel()
	elseif (class == "prop_effect") then
		class = ent.WUMAModel
	elseif (ent:GetTable().VehicleName) then
		class = ent:GetTable().VehicleName
	end

	WUMADebug(class)

	if (player.physgun_last_pickup_time and player.physgun_last_pickup_class == class and os.time() < player.physgun_last_pickup_time) then
		if (player.physgun_last_return == false) then
			player.physgun_last_pickup_time = os.time() + 2
			return false
		end
	else
		player.physgun_last_return = checkRestriction(player, "physgrab", class)
		player.physgun_last_pickup_time = os.time() + 2
		player.physgun_last_pickup_class = class

		if (player.physgun_last_return == false) then return false end
	end
end
hook.Add("PhysgunPickup", "WUMA_HOOKS_PhysgunPickup", playerPhysgunPickup, -1)
hook.Add("CanPlayerUnfreeze", "WUMA_HOOKS_CanPlayerUnfreeze", playerPhysgunPickup, -1)