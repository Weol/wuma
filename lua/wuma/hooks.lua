
WUMA = WUMA or {}

--Hooks
WUMA.USERRESTRICTIONADDED = "WUMAUserRestrictionAdded"
WUMA.USERRESTRICTIONREMOVED = "WUMAUserRestrictionRemoved"

function WUMA.PlayerSpawnSENT(ply, sent)
	--WUMADebug("WUMA.PlayerSpawnSENT(%s, %s)", tostring(ply) or "NIL", tostring(sent) or "NIL")
	if not ply or not sent then return end
	if (ply:CheckRestriction("entity", sent) == false) then return false end
	if (ply:CheckLimit("sents", sent) == false) then return false end
end
hook.Add("PlayerSpawnSENT", "WUMAPlayerSpawnSENT", WUMA.PlayerSpawnSENT, -1)

function WUMA.PlayerSpawnedSENT(ply, ent)
	--WUMADebug("WUMA.PlayerSpawnedSENT(%s, %s)", tostring(ply) or "NIL", tostring(sent) or "NIL")
	if not ply or not ent then return end
	ply:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSENT", "WUMAPlayerSpawnedProp", WUMA.PlayerSpawnedSENT, -2)

function WUMA.PlayerSpawnProp(ply, mdl)
	--WUMADebug("WUMA.PlayerSpawnProp(%s, %s)", tostring(ply) or "NIL", tostring(mdl) or "NIL")
	if not ply or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (ply:CheckRestriction("prop", mdl) == false) then return false end
	if (ply:CheckLimit("props", mdl) == false) then return false end
end
hook.Add("PlayerSpawnProp", "WUMAPlayerSpawnProp", WUMA.PlayerSpawnProp, -1)

function WUMA.PlayerSpawnedProp(ply, model, ent)
	--WUMADebug("WUMA.PlayerSpawnedProp(%s, %s, %s)", tostring(ply) or "NIL", tostring(model) or "NIL", tostring(ent) or "NIL")
	if not ply or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	ply:AddCount("props", ent, model)
end
hook.Add("PlayerSpawnedProp", "WUMAPlayerSpawnedProp", WUMA.PlayerSpawnedProp, -2)

function WUMA.CanTool(ply, tr, tool)
	--WUMADebug("WUMA.CanTool(%s, %s, %s)", tostring(ply) or "NIL", tostring(tr) or "NIL", tostring(tool) or "NIL")
	if not ply or not tool then return end
	return ply:CheckRestriction("tool", tool)
end
hook.Add("CanTool", "WUMACanTool", WUMA.CanTool, -1)

function WUMA.PlayerUse(ply, ent)
	--WUMADebug("WUMA.PlayerUse(%s, %s)", tostring(ply) or "NIL", tostring(ent) or "NIL")
	if not ply or not ent then return end
	if ent:GetTable().VehicleName then ent = ent:GetTable().VehicleName else ent = ent:GetClass() end
	return ply:CheckRestriction("use", ent)
end
hook.Add("PlayerUse", "WUMAPlayerUse", WUMA.PlayerUse)

function WUMA.PlayerSpawnEffect(ply, mdl)
	--WUMADebug("WUMA.PlayerSpawnEffect(%s, %s)", tostring(ply) or "NIL", tostring(mdl) or "NIL")
	if not ply or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (ply:CheckRestriction("effect", mdl) == false) then return false end
	if (ply:CheckLimit("effects", mdl) == false) then return false end
end
hook.Add("PlayerSpawnEffect", "WUMAPlayerSpawnEffect", WUMA.PlayerSpawnEffect, -1)

function WUMA.PlayerSpawnedEffect(ply, model, ent)
	--WUMADebug("WUMA.PlayerSpawnedEffect(%s, %s, %s)", tostring(ply) or "NIL", tostring(model) or "NIL", tostring(ent) or "NIL")
	if not ply or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	ply:AddCount("effects", ent, model)
end
hook.Add("PlayerSpawnedEffect", "WUMAPlayerSpawnedEffect", WUMA.PlayerSpawnedEffect, -2)

function WUMA.PlayerSpawnNPC(ply, npc, weapon)
	--WUMADebug("WUMA.PlayerSpawnNPC(%s, %s, %s)", tostring(ply) or "NIL", tostring(npc) or "NIL", tostring(weapon) or "NIL")
	if not ply or not npc then return end
	if (ply:CheckRestriction("npc", npc) == false) then return false end
	if (ply:CheckLimit("npcs", npc) == false) then return false end
end
hook.Add("PlayerSpawnNPC", "WUMAPlayerSpawnNPC", WUMA.PlayerSpawnNPC, -1)

function WUMA.PlayerSpawnedNPC(ply, ent)
	--WUMADebug("WUMA.PlayerSpawnedNPC(%s, %s)", tostring(ply) or "NIL", tostring(ent) or "NIL")
	if not ply or not ent then return end
	ply:AddCount("npcs", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedNPC", "WUMAPlayerSpawnedNPC", WUMA.PlayerSpawnedNPC, -2)

function WUMA.PlayerSpawnRagdoll(ply, mdl)
	--WUMADebug("WUMA.PlayerSpawnRagdoll(%s, %s)", tostring(ply) or "NIL", tostring(mdl) or "NIL")
	if not ply or not mdl then return end

	mdl = string.lower(mdl) --Models are alwyas lowercase

	if (ply:CheckRestriction("ragdoll", mdl) == false) then return false end
	if (ply:CheckLimit("ragdolls", mdl) == false) then return false end
end
hook.Add("PlayerSpawnRagdoll", "WUMAPlayerSpawnRagdoll", WUMA.PlayerSpawnRagdoll, -1)

function WUMA.PlayerSpawnedRagdoll(ply, model, ent)
	--WUMADebug("WUMA.PlayerSpawnedRagdoll(%s, %s, %s)", tostring(ply) or "NIL", tostring(model) or "NIL", tostring(ent) or "NIL")
	if not ply or not model or not ent then return end

	model = string.lower(model) --Models are alwyas lowercase

	ply:AddCount("ragdolls", ent, model)
end
hook.Add("PlayerSpawnedRagdoll", "WUMAPlayerSpawnedRagdoll", WUMA.PlayerSpawnedRagdoll, -2)

function WUMA.PlayerSpawnSWEP(ply, class, weapon)
	--WUMADebug("WUMA.PlayerSpawnSWEP(%s, %s, %s)", tostring(ply) or "NIL", tostring(class) or "NIL", tostring(weapon) or "NIL")
	if not ply or not class then return end
	if (ply:CheckRestriction("swep", class) == false) then return false end
	if (ply:CheckLimit("sents", class) == false) then return false end
end
hook.Add("PlayerSpawnSWEP", "WUMAPlayerSpawnSWEP", WUMA.PlayerSpawnSWEP, -1)

function WUMA.PlayerGiveSWEP(ply, class, weapon)
	--WUMADebug("WUMA.PlayerGiveSWEP(%s, %s, %s)", tostring(ply) or "NIL", tostring(class) or "NIL", tostring(weapon) or "NIL")
	if not ply or not class then return end
	if (ply:CheckRestriction("swep", class) == false) then return false end
	ply:DisregardNextPickup(class)
end
hook.Add("PlayerGiveSWEP", "WUMAPlayerGiveSWEP", WUMA.PlayerGiveSWEP, -1)

function WUMA.PlayerSpawnedSWEP(ply, ent)
	--WUMADebug("WUMA.PlayerSpawnedSWEP(%s, %s)", tostring(ply) or "NIL", tostring(ent) or "NIL")
	if not ply or not ent then return end
	ply:AddCount("sents", ent, ent:GetClass())
end
hook.Add("PlayerSpawnedSWEP", "WUMAPlayerSpawnedSWEP", WUMA.PlayerSpawnedSWEP, -2)

local pickup_last
function WUMA.PlayerCanPickupWeapon(ply, weapon)
	--WUMADebug("WUMA.PlayerCanPickupWeapon(%s, %s)", tostring(ply) or "NIL", tostring(weapon) or "NIL")
	if not ply or not weapon then return end
	if ply:ShouldDisregardPickup(weapon:GetClass()) then return end
	return ply:CheckRestriction("pickup", weapon:GetClass())
end
hook.Add("PlayerCanPickupWeapon", "WUMAPlayerCanPickupWeapon", WUMA.PlayerCanPickupWeapon, -1)

function WUMA.PlayerSpawnVehicle(ply, mdl, name, vehicle_table)
	--WUMADebug("WUMA.PlayerSpawnVehicle(%s, %s, %s, %s)", tostring(ply) or "NIL", tostring(mdl) or "NIL", tostring(name) or "NIL", tostring(vehicle_table) or "NIL")
	if not ply or not name then return end
	if (ply:CheckRestriction("vehicle", name) == false) then return false end
	if (ply:CheckLimit("vehicles", name) == false) then return false end
end
hook.Add("PlayerSpawnVehicle", "WUMAPlayerSpawnVehicle", WUMA.PlayerSpawnVehicle, -1)

function WUMA.PlayerSpawnedVehicle(ply, ent)
	--WUMADebug("WUMA.PlayerSpawnedVehicle(%s, %s)", tostring(ply) or "NIL", tostring(ent) or "NIL")
	if not ply or not ent then return end
	ply:AddCount("vehicles", ent, ent:GetTable().VehicleName)
end
hook.Add("PlayerSpawnedVehicle", "WUMAPlayerSpawnedVehicle", WUMA.PlayerSpawnedVehicle, -2)

function WUMA.PlayerCanProperty(ply, property, ent)
	--WUMADebug("WUMA.PlayerSpawnedVehicle(%s, %s, %s)", tostring(ply) or "NIL", tostring(property) or "NIL", tostring(ent) or "NIL")
	if not ply or not property then return end
	if (ply:CheckRestriction("property", property) == false) then return false end
end
hook.Add( "CanProperty", "WUMAPlayerCanProperty", WUMA.PlayerCanProperty, -1)