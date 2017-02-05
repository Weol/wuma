
local function checkPlayerSpawn(ply, ent, entTable) 
	WUMADebug("checkPlayerSpawn(%s, %s, %s)",tostring(ply),tostring(ent),tostring(entTable))

	if (istable(ent)) then
		ent = ent.Class
	end

	if (ent == "prop_physics") then return nil end
	
	local ret = nil
		
	--Check if ent is restricted in all the different types
	if (table.HasValue(WUMA.GetWeapons(),ent)) and (WUMA.PlayerSpawnSWEP( ply, ent, ent ) == false) then ret = false end 
		
	if (table.HasValue(WUMA.GetVehicles(),ent)) and (WUMA.PlayerSpawnVehicle( ply, _, ent ) == false) then ret = false end
		
	if (table.HasValue(WUMA.GetEntities(),ent)) and (WUMA.PlayerSpawnSENT( ply, ent ) == false) then ret = false end
		
	if (table.HasValue(WUMA.GetNPCs(),ent)) and (WUMA.PlayerSpawnNPC( ply, ent ) == false) then ret = false  end

	return ret

end

if AdvDupe then
	AdvDupe.AdminSettings.AddEntCheckHook( "WUMACheckPlayerDuplicate", checkPlayerSpawn )
end

if AdvDupe2 then
	hook.Add("PlayerSpawnentity", "WUMAPlayerSpawnentity", checkPlayerSpawn)

	--[[
	hook.Add("AdvDupe_FinishPasting", "WUMAAdvDupeFinishedPasting", function(data) 
		local user = data[1].Player
		if user then
			for _,entity in pairs(data[1].Createdentities) do 
			
				local str = entity:GetClass()
				local model = false
				
				if (string.lower(entity:GetClass()) == "prop_physics" or string.lower(entity:GetClass()) == "prop_ragdoll") then
					str = entity:GetModel()
					model = entity:GetModel()
				elseif (string.lower(entity:GetClass()) == "prop_effect") then  
					str = entity:GetTable()[7]
				elseif (entity:GetTable().VehicleName) then  
					str = entity:GetTable().VehicleName
				end
				
				if !ply:CheckLimit(str,true) then
					entity:Remove()
				elseif not model then	
					local haslimit, limit = TIIP.URM.HasURMLimit(ply,str)
					if haslimit then
						if (type(limit) == "string") then
							ply:AddCount(limit,entity)
						end
					
						ply:AddCount(haslimit,entity)
					end
				end
				
			end
		end
	end)
	--]]
end