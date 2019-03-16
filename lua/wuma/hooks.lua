
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

--Hooks
WUMA.USERRESTRICTIONADDED = "WUMAUserRestrictionAdded"
WUMA.USERRESTRICTIONREMOVED = "WUMAUserRestrictionRemoved"

function WUMA.PlayerSpawnSENT(ply, sent)
	if not ply or not sent then return end
	if (ply:CheckRestriction("entity", sent) == false) then return false end
	if (ply:CheckLimit("sents", sent) == false) then return false end
end
hook.Add("PlayerSpawnSENT", "WUMAPlayerSpawnSENT", WUMA.PlayerSpawnSENT, -1)

function WUMA.PlayerSpawnedSENT(ply, ent)
	if not ply or not ent then return end
	ply:AddCount("sents", ent, ent:GetClass()) 
end
hook.Add("PlayerSpawnedSENT", "WUMAPlayerSpawnedProp", WUMA.PlayerSpawnedSENT, -2)

function WUMA.PlayerSpawnProp(ply, mdl)
	if not ply or not mdl then return end
	if (ply:CheckRestriction("prop", mdl) == false) then return false end
	if (ply:CheckLimit("props", mdl) == false) then return false end
end
hook.Add("PlayerSpawnProp", "WUMAPlayerSpawnProp", WUMA.PlayerSpawnProp, -1)

function WUMA.PlayerSpawnedProp(ply, model, ent)
	if not ply or not model or not ent then return end
	ply:AddCount("props", ent, model)
end
hook.Add("PlayerSpawnedProp", "WUMAPlayerSpawnedProp", WUMA.PlayerSpawnedProp, -2)

function WUMA.CanTool(ply, tr, tool)
	if not ply or not tool then return end
	return ply:CheckRestriction("tool", tool)
end
hook.Add("CanTool", "WUMACanTool", WUMA.CanTool, -1)

function WUMA.PlayerUse(ply, ent)
	if not ply or not ent then return end
	if ent:GetTable().VehicleName then ent = ent:GetTable().VehicleName else ent = ent:GetClass() end
	return ply:CheckRestriction("use", ent)
end
hook.Add("PlayerUse", "WUMAPlayerUse", WUMA.PlayerUse)

function WUMA.PlayerSpawnEffect(ply, mdl)
	if not ply or not mdl then return end
	if (ply:CheckRestriction("effect", mdl) == false) then return false end
	if (ply:CheckLimit("effects", mdl) == false) then return false end
end
hook.Add("PlayerSpawnEffect", "WUMAPlayerSpawnEffect", WUMA.PlayerSpawnEffect, -1)

function WUMA.PlayerSpawnedEffect(ply, model, ent)
	if not ply or not model or not ent then return end
	ply:AddCount("effects", ent, model)
end
hook.Add("PlayerSpawnedEffect", "WUMAPlayerSpawnedEffect", WUMA.PlayerSpawnedEffect, -2)

function WUMA.PlayerSpawnNPC(ply, npc, weapon)
	if not ply or not npc then return end
	if (ply:CheckRestriction("npc", npc) == false) then return false end
	if (ply:CheckLimit("npcs", npc) == false) then return false end
end
hook.Add("PlayerSpawnNPC", "WUMAPlayerSpawnNPC", WUMA.PlayerSpawnNPC, -1)

function WUMA.PlayerSpawnedNPC(ply, ent)
	if not ply or not ent then return end
	ply:AddCount("npcs", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedNPC", "WUMAPlayerSpawnedNPC", WUMA.PlayerSpawnedNPC, -2)

function WUMA.PlayerSpawnRagdoll(ply, mdl)
	if not ply or not mdl then return end
	if (ply:CheckRestriction("ragdoll", mdl) == false) then return false end
	if (ply:CheckLimit("ragdolls", mdl) == false) then return false end
end
hook.Add("PlayerSpawnRagdoll", "WUMAPlayerSpawnRagdoll", WUMA.PlayerSpawnRagdoll, -1)

function WUMA.PlayerSpawnedRagdoll(ply, model, ent)
	if not ply or not model or not ent then return end
	ply:AddCount("ragdolls", ent, model)
end
hook.Add("PlayerSpawnedRagdoll", "WUMAPlayerSpawnedRagdoll", WUMA.PlayerSpawnedRagdoll, -2)

function WUMA.PlayerSpawnSWEP(ply, class, weapon)
	if not ply or not class then return end
	if (ply:CheckRestriction("swep", class) == false) then return false end
	if (ply:CheckLimit("sents", class) == false) then return false end
end
hook.Add("PlayerSpawnSWEP", "WUMAPlayerSpawnSWEP", WUMA.PlayerSpawnSWEP, -1)

function WUMA.PlayerGiveSWEP(ply, class, weapon)
	if not ply or not class then return end
	if (ply:CheckRestriction("swep", class) == false) then return false end
	ply:DisregardNextPickup(class)
end
hook.Add("PlayerGiveSWEP", "WUMAPlayerGiveSWEP", WUMA.PlayerGiveSWEP, -1)

function WUMA.PlayerSpawnedSWEP(ply, ent)
	if not ply or not ent then return end
	ply:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSWEP", "WUMAPlayerSpawnedSWEP", WUMA.PlayerSpawnedSWEP, -2)

local pickup_last
function WUMA.PlayerCanPickupWeapon(ply, weapon)
	if not ply or not weapon then return end
	if ply:ShouldDisregardPickup(weapon:GetClass()) then return end
	return ply:CheckRestriction("pickup", weapon:GetClass())
end
hook.Add("PlayerCanPickupWeapon", "WUMAPlayerCanPickupWeapon", WUMA.PlayerCanPickupWeapon, -1)

function WUMA.PlayerSpawnVehicle(ply, mdl, name, vehicle_table)
	if not ply or not name then return end
	if (ply:CheckRestriction("vehicle", name) == false) then return false end
	if (ply:CheckLimit("vehicles", name) == false) then return false end
end
hook.Add("PlayerSpawnVehicle", "WUMAPlayerSpawnVehicle", WUMA.PlayerSpawnVehicle, -1)

function WUMA.PlayerSpawnedVehicle(ply, ent)
	if not ply or not ent then return end
	ply:AddCount("vehicles", ent, ent:GetTable().VehicleName)
end
hook.Add("PlayerSpawnedVehicle", "WUMAPlayerSpawnedVehicle", WUMA.PlayerSpawnedVehicle, -2)

function WUMA.PlayerCanProperty(ply, property, ent)
	if not ply or not property then return end

	MsgN(property)
	if (ply:CheckRestriction("property", property) == false) then return false end
end
hook.Add( "CanProperty", "WUMAPlayerCanProperty", WUMA.PlayerCanProperty, -1)