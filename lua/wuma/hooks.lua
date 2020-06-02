
WUMA = WUMA or {}

--Hooks
WUMA.USERRESTRICTIONADDED = "WUMAUserRestrictionAdded"
WUMA.USERRESTRICTIONREMOVED = "WUMAUserRestrictionRemoved"

function WUMA.PlayerSpawnSENT(player, sent)
	if not player or not sent then return end
	if (player:CheckRestriction("entity", sent) == false) then return false end
	if (player:CheckLimit("sents", sent) == false) then return false end
end
hook.Add("PlayerSpawnSENT", "WUMAPlayerSpawnSENT", WUMA.PlayerSpawnSENT, -1)

function WUMA.PlayerSpawnedSENT(player, ent)
	if not player or not ent then return end
	player:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSENT", "WUMAPlayerSpawnedProp", WUMA.PlayerSpawnedSENT, -2)

function WUMA.PlayerSpawnProp(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (player:CheckRestriction("prop", mdl) == false) then return false end
	if (player:CheckLimit("props", mdl) == false) then return false end
end
hook.Add("PlayerSpawnProp", "WUMAPlayerSpawnProp", WUMA.PlayerSpawnProp, -1)

function WUMA.PlayerSpawnedProp(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	player:AddCount("props", ent, model)
end
hook.Add("PlayerSpawnedProp", "WUMAPlayerSpawnedProp", WUMA.PlayerSpawnedProp, -2)

function WUMA.CanTool(player, tr, tool)
	if not player or not tool then return end
	return player:CheckRestriction("tool", tool)
end
hook.Add("CanTool", "WUMACanTool", WUMA.CanTool, -1)

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
hook.Add("PlayerUse", "WUMAPlayerUse", WUMA.PlayerUse)

function WUMA.PlayerSpawnEffect(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (player:CheckRestriction("effect", mdl) == false) then return false end
	if (player:CheckLimit("effects", mdl) == false) then return false end
end
hook.Add("PlayerSpawnEffect", "WUMAPlayerSpawnEffect", WUMA.PlayerSpawnEffect, -1)

function WUMA.PlayerSpawnedEffect(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	ent.WUMAModel = model
	player:AddCount("effects", ent, model)
end
hook.Add("PlayerSpawnedEffect", "WUMAPlayerSpawnedEffect", WUMA.PlayerSpawnedEffect, -2)

function WUMA.PlayerSpawnNPC(player, npc, weapon)
	if not player or not npc then return end
	if (player:CheckRestriction("npc", npc) == false) then return false end
	if (player:CheckLimit("npcs", npc) == false) then return false end
end
hook.Add("PlayerSpawnNPC", "WUMAPlayerSpawnNPC", WUMA.PlayerSpawnNPC, -1)

function WUMA.PlayerSpawnedNPC(player, ent)
	if not player or not ent then return end
	player:AddCount("npcs", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedNPC", "WUMAPlayerSpawnedNPC", WUMA.PlayerSpawnedNPC, -2)

function WUMA.PlayerSpawnRagdoll(player, mdl)
	if not player or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (player:CheckRestriction("ragdoll", mdl) == false) then return false end
	if (player:CheckLimit("ragdolls", mdl) == false) then return false end
end
hook.Add("PlayerSpawnRagdoll", "WUMAPlayerSpawnRagdoll", WUMA.PlayerSpawnRagdoll, -1)

function WUMA.PlayerSpawnedRagdoll(player, model, ent)
	if not player or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	player:AddCount("ragdolls", ent, model)
end
hook.Add("PlayerSpawnedRagdoll", "WUMAPlayerSpawnedRagdoll", WUMA.PlayerSpawnedRagdoll, -2)

function WUMA.PlayerSpawnSWEP(player, class, weapon)
	if not player or not class then return end
	if (player:CheckRestriction("swep", class) == false) then return false end
	if (player:CheckLimit("sents", class) == false) then return false end
end
hook.Add("PlayerSpawnSWEP", "WUMAPlayerSpawnSWEP", WUMA.PlayerSpawnSWEP, -1)

function WUMA.PlayerGiveSWEP(player, class, weapon)
	if not player or not class then return end
	if (player:CheckRestriction("swep", class) == false) then return false end
	player:DisregardNextPickup(class)
end
hook.Add("PlayerGiveSWEP", "WUMAPlayerGiveSWEP", WUMA.PlayerGiveSWEP, -1)

function WUMA.PlayerSpawnedSWEP(player, ent)
	if not player or not ent then return end
	player:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSWEP", "WUMAPlayerSpawnedSWEP", WUMA.PlayerSpawnedSWEP, -2)

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
hook.Add("PlayerCanPickupWeapon", "WUMAPlayerCanPickupWeapon", WUMA.PlayerCanPickupWeapon, -1)

function WUMA.PlayerSpawnVehicle(player, mdl, name, vehicle_table)
	if not player or not name then return end
	if (player:CheckRestriction("vehicle", name) == false) then return false end
	if (player:CheckLimit("vehicles", name) == false) then return false end
end
hook.Add("PlayerSpawnVehicle", "WUMAPlayerSpawnVehicle", WUMA.PlayerSpawnVehicle, -1)

function WUMA.PlayerSpawnedVehicle(player, ent)
	if not player or not ent then return end
	player:AddCount("vehicles", ent, ent:GetTable().VehicleName)
end
hook.Add("PlayerSpawnedVehicle", "WUMAPlayerSpawnedVehicle", WUMA.PlayerSpawnedVehicle, -2)

function WUMA.PlayerCanProperty(player, property, ent)
	if not player or not property then return end
	if (player:CheckRestriction("property", property) == false) then return false end
end
hook.Add("CanProperty", "WUMAPlayerCanProperty", WUMA.PlayerCanProperty, -1)

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
hook.Add("PhysgunPickup", "WUMAPlayerPhysgunPickup", WUMA.PlayerPhysgunPickup, -1)
hook.Add("CanPlayerUnfreeze", "WUMACanPlayerUnfreeze", WUMA.PlayerPhysgunPickup, -1)