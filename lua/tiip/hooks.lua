
TIIP = TIIP or {}

function TIIP.PlayerSpawnSENT( ply, sent )
	TIIPDebug("PlayerSpawnSENT(%s,%s)",ply,sent)
	if (ply:CheckRestriction("entity",sent) == false) then return false end
	if (ply:CheckLimit("sents",sent) == false) then return false end
end
hook.Add( "PlayerSpawnSENT", "TIIPPlayerSpawnSENT", TIIP.PlayerSpawnSENT, -1 )

function TIIP.PlayerSpawnedSENT( ply, ent )
	ply:AddCount("sents",ent,ent:GetClass())
end
hook.Add( "PlayerSpawnedSENT", "TIIPPlayerSpawnedProp", TIIP.PlayerSpawnedSENT, -2 )

function TIIP.PlayerSpawnProp( ply, mdl )
	TIIPDebug("PlayerSpawnProp(%s,%s)",ply,mdl)
	if (ply:CheckRestriction("prop",mdl) == false) then return false end
	if (ply:CheckLimit("props",mdl) == false) then return false end
end
hook.Add( "PlayerSpawnProp", "TIIPPlayerSpawnProp", TIIP.PlayerSpawnProp, -1 )

function TIIP.PlayerSpawnedProp( ply, model, ent )
	ply:AddCount("props",ent,model)
end
hook.Add( "PlayerSpawnedProp", "TIIPPlayerSpawnedProp", TIIP.PlayerSpawnedProp, -2 )

function TIIP.CanTool( ply, tr, tool )
	TIIPLog("%s(%s) used tool %s on %s",ply:Name(),ply:SteamID(),tool,tr.Entity:GetModel())
	return ply:CheckRestriction("tool",tool)
end
hook.Add( "CanTool", "TIIPCanTool", TIIP.CanTool, -1 )

function TIIP.PlayerUse( ply, ent )
	if ent:GetTable().VehicleName then ent = ent:GetTable().VehicleName else ent = ent:GetClass() end
	return ply:CheckRestriction("use",ent)
end
hook.Add( "PlayerUse", "TIIPPlayerUse", TIIP.PlayerUse)

function TIIP.PlayerSpawnEffect( ply, mdl )
	TIIPDebug("PlayerSpawnEffect(%s,%s)",ply,mdl)
	if (ply:CheckRestriction("effect",mdl) == false) then return false end
	if (ply:CheckLimit("effects",mdl) == false) then return false end
end
hook.Add( "PlayerSpawnEffect", "TIIPPlayerSpawnEffect", TIIP.PlayerSpawnEffect, -1 )

function TIIP.PlayerSpawnedEffect( ply, model, ent )
	ply:AddCount("effects",ent,model)
end
hook.Add( "PlayerSpawnedEffect", "TIIPPlayerSpawnedEffect", TIIP.PlayerSpawnedEffect, -2 )

function TIIP.PlayerSpawnNPC( ply, npc, weapon )
	TIIPDebug("PlayerSpawnNPC(%s,%s)",ply,npc)
	if (ply:CheckRestriction("npc",npc) == false) then return false end
	if (ply:CheckLimit("npcs",npc) == false) then return false end
end
hook.Add( "PlayerSpawnNPC", "TIIPPlayerSpawnNPC", TIIP.PlayerSpawnNPC, -1 )

function TIIP.PlayerSpawnedNPC( ply, ent )
	ply:AddCount("npcs",ent,ent:GetClass())
end
hook.Add( "PlayerSpawnedNPC", "TIIPPlayerSpawnedNPC", TIIP.PlayerSpawnedNPC, -2 )

function TIIP.PlayerSpawnRagdoll( ply, mdl )
	TIIPDebug("PlayerSpawnRagdoll(%s,%s)",ply,mdl)
	if (ply:CheckRestriction("ragdoll",mdl) == false) then return false end
	if (ply:CheckLimit("ragdolls",mdl) == false) then return false end
end
hook.Add( "PlayerSpawnRagdoll", "TIIPPlayerSpawnRagdoll", TIIP.PlayerSpawnRagdoll, -1 )

function TIIP.PlayerSpawnedRagdoll( ply, model, ent )
	ply:AddCount("ragdolls",ent,model)
end
hook.Add( "PlayerSpawnedRagdoll", "TIIPPlayerSpawnedRagdoll", TIIP.PlayerSpawnedRagdoll, -2 )

function TIIP.PlayerSpawnSWEP( ply, class, weapon )
	TIIPDebug("PlayerSpawnSWEP(%s,%s,%s)",ply,class,weapon)
	if (ply:CheckRestriction("swep",class) == false) then return false end
	if (ply:CheckLimit("sents",class) == false) then return false end
end
hook.Add( "PlayerSpawnSWEP", "TIIPPlayerSpawnSWEP", TIIP.PlayerSpawnSWEP, -1 )
hook.Add( "PlayerGiveSWEP", "TIIPPlayerSpawnSWEP", TIIP.PlayerSpawnSWEP, -1 )

function TIIP.PlayerSpawnedSWEP( ply, ent )
	ply:AddCount("sents",ent,ent:GetClass())
end
hook.Add( "PlayerSpawnedSWEP", "TIIPPlayerSpawnedSWEP", TIIP.PlayerSpawnedSWEP, -2 )

function TIIP.PlayerCanPickupWeapon( ply, weapon )
	return ply:CheckRestriction("pickup", weapon:GetClass())
end
hook.Add( "PlayerCanPickupWeapon", "TIIPPlayerCanPickupWeapon", TIIP.PlayerCanPickupWeapon, -1 )

function TIIP.PlayerSpawnVehicle( ply, mdl, name, vehicle_table )
	TIIPDebug("PlayerSpawnVehicle(%s,%s,%s,%s)",ply, mdl, name, vehicle_table)
	if (ply:CheckRestriction("vehicle",string.lower(vehicle_table.Name)) == false) then return false end
	if (ply:CheckLimit("vehicles",string.lower(vehicle_table.Name)) == false) then return false end
end
hook.Add( "PlayerSpawnVehicle", "TIIPPlayerSpawnVehicle", TIIP.PlayerSpawnVehicle, -1 )

function TIIP.PlayerSpawnedVehicle( ply, ent )
	ply:AddCount("vehicles",ent,string.lower(ent:GetTable().VehicleName))
end
hook.Add( "PlayerSpawnedVehicle", "TIIPPlayerSpawnedVehicle", TIIP.PlayerSpawnedVehicle, -2 )
