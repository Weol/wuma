

function WUMA.PlayerSpawnSENT(player, sent)
	if not player or not sent then return end
	if (player:CheckRestriction("entity", sent) == false) then return false end
	if (player:CheckLimit("sents", sent) == false) then return false end
end
hook.Add("PlayerSpawnSENT", "WUMA_HOOKS_PlayerSpawnSENT", WUMA.PlayerSpawnSENT, -1)

function WUMA.PlayerSpawnedSENT(player, ent)
	if not player or not ent then return end
	player:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSENT", "WUMA_HOOKS_PlayerSpawnedSENT", WUMA.PlayerSpawnedSENT, -2)

function WUMA.PlayerSpawnProp(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (player:CheckRestriction("prop", mdl) == false) then return false end
	if (player:CheckLimit("props", mdl) == false) then return false end
end
hook.Add("PlayerSpawnProp", "WUMA_HOOKS_PlayerSpawnProp", WUMA.PlayerSpawnProp, -1)

function WUMA.PlayerSpawnedProp(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	player:AddCount("props", ent, model)
end
hook.Add("PlayerSpawnedProp", "WUMA_HOOKS_PlayerSpawnedProp", WUMA.PlayerSpawnedProp, -2)

function WUMA.CanTool(player, tr, tool)
	if not player or not tool then return end
	return player:CheckRestriction("tool", tool)
end
hook.Add("CanTool", "WUMA_HOOKS_CanTool", WUMA.CanTool, -1)

local use_last = {}
function WUMA.PlayerUse(player, ent)
	if not player or not ent then return end

	if (use_last[player:SteamID()] and os.time() < use_last[player:SteamID()].time) then
		if (use_last[player:SteamID()].returned == false) then return false end
	else
		if ent:GetTable().VehicleName then ent = ent:GetTable().VehicleName else ent = ent:GetClass() end

		use_last[player:SteamID()] = {
			returned = player:CheckRestriction("use", ent),
			time = os.time() + 2
		}

		if (use_last[player:SteamID()].returned == false) then return false end
	end
end
hook.Add("PlayerUse", "WUMA_HOOKS_PlayerUse", WUMA.PlayerUse)

function WUMA.PlayerSpawnEffect(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (player:CheckRestriction("effect", mdl) == false) then return false end
	if (player:CheckLimit("effects", mdl) == false) then return false end
end
hook.Add("PlayerSpawnEffect", "WUMA_HOOKS_PlayerSpawnEffect", WUMA.PlayerSpawnEffect, -1)

function WUMA.PlayerSpawnedEffect(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	ent.WUMAModel = model
	player:AddCount("effects", ent, model)
end
hook.Add("PlayerSpawnedEffect", "WUMA_HOOKS_PlayerSpawnedEffect", WUMA.PlayerSpawnedEffect, -2)

function WUMA.PlayerSpawnNPC(player, npc, weapon)
	if not player or not npc then return end
	if (player:CheckRestriction("npc", npc) == false) then return false end
	if (player:CheckLimit("npcs", npc) == false) then return false end
end
hook.Add("PlayerSpawnNPC", "WUMA_HOOKS_PlayerSpawnNPC", WUMA.PlayerSpawnNPC, -1)

function WUMA.PlayerSpawnedNPC(player, ent)
	if not player or not ent then return end
	player:AddCount("npcs", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedNPC", "WUMA_HOOKS_PlayerSpawnedNPC", WUMA.PlayerSpawnedNPC, -2)

function WUMA.PlayerSpawnRagdoll(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (player:CheckRestriction("ragdoll", mdl) == false) then return false end
	if (player:CheckLimit("ragdolls", mdl) == false) then return false end
end
hook.Add("PlayerSpawnRagdoll", "WUMA_HOOKS_PlayerSpawnRagdoll", WUMA.PlayerSpawnRagdoll, -1)

function WUMA.PlayerSpawnedRagdoll(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	player:AddCount("ragdolls", ent, model)
end
hook.Add("PlayerSpawnedRagdoll", "WUMA_HOOKS_PlayerSpawnedRagdoll", WUMA.PlayerSpawnedRagdoll, -2)

function WUMA.PlayerSpawnSWEP(player, class, weapon)
	if not player or not class then return end
	if (player:CheckRestriction("swep", class) == false) then return false end
	if (player:CheckLimit("sents", class) == false) then return false end
end
hook.Add("PlayerSpawnSWEP", "WUMA_HOOKS_PlayerSpawnSWEP", WUMA.PlayerSpawnSWEP, -1)

function WUMA.PlayerGiveSWEP(player, class, weapon)
	if not player or not class then return end
	if (player:CheckRestriction("swep", class) == false) then return false end
	player:DisregardNextPickup(class)
end
hook.Add("PlayerGiveSWEP", "WUMA_HOOKS_PlayerGiveSWEP", WUMA.PlayerGiveSWEP, -1)

function WUMA.PlayerSpawnedSWEP(player, ent)
	if not player or not ent then return end
	player:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSWEP", "WUMA_HOOKS_PlayerSpawnedSWEP", WUMA.PlayerSpawnedSWEP, -2)

local pickup_last = {}
function WUMA.PlayerCanPickupWeapon(player, weapon)
	if not player or not weapon then return end

	if (pickup_last[player:SteamID()] and os.time() < pickup_last[player:SteamID()].time) then
		if (pickup_last[player:SteamID()].returned == false) then return false end
	else
		pickup_last[player:SteamID()] = {
			returned = player:CheckRestriction("pickup", weapon:GetClass()),
			time = os.time() + 2
		}

		if (pickup_last[player:SteamID()].returned == false) then return false end
	end
end
hook.Add("PlayerCanPickupWeapon", "WUMA_HOOKS_PlayerCanPickupWeapon", WUMA.PlayerCanPickupWeapon, -1)

function WUMA.PlayerSpawnVehicle(player, mdl, name, vehicle_table)
	if not player or not name then return end
	if (player:CheckRestriction("vehicle", name) == false) then return false end
	if (player:CheckLimit("vehicles", name) == false) then return false end
end
hook.Add("PlayerSpawnVehicle", "WUMA_HOOKS_PlayerSpawnVehicle", WUMA.PlayerSpawnVehicle, -1)

function WUMA.PlayerSpawnedVehicle(player, ent)
	if not player or not ent then return end
	player:AddCount("vehicles", ent, ent:GetTable().VehicleName)
end
hook.Add("PlayerSpawnedVehicle", "WUMA_HOOKS_PlayerSpawnedVehicle", WUMA.PlayerSpawnedVehicle, -2)

function WUMA.PlayerCanProperty(player, property, ent)
	if not player or not property then return end
	if (player:CheckRestriction("property", property) == false) then return false end
end
hook.Add("CanProperty", "WUMA_HOOKS_CanProperty", WUMA.PlayerCanProperty, -1)

local physgun_last_return = {}
local physgun_last_time = {}
function WUMA.PlayerPhysgunPickup(player, ent)
	if not player or not ent then return end

	if (physgun_last_time[player:SteamID()] and os.time() < physgun_last_time[player:SteamID()]) then
		if (physgun_last_return[player:SteamID()] == false) then return false end
	else
		local class = ent:GetClass()
		if (class == "prop_ragdoll" or class == "prop_physics") then
			class = ent:GetModel()
		elseif (class == "prop_effect") then
			class = ent.WUMAModel
		elseif (ent:GetTable().VehicleName) then
			class = ent:GetTable().VehicleName
		end

		physgun_last_return[player:SteamID()] = player:CheckRestriction("physgrab", class)
		physgun_last_time[player:SteamID()] = os.time() + 2

		if (physgun_last_return[player:SteamID()] == false) then return false end
	end
end
hook.Add("PhysgunPickup", "WUMA_HOOKS_PhysgunPickup", WUMA.PlayerPhysgunPickup, -1)
hook.Add("CanPlayerUnfreeze", "WUMA_HOOKS_CanPlayerUnfreeze", WUMA.PlayerPhysgunPickup, -1)