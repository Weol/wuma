local function checkPlayerSpawn(ply, ent, entTable)
	if (istable(ent)) then
		ent = ent.Class
	end

	if (ent == "prop_physics") then return nil end

	local ret

	--Check if ent is restricted in all the different types
	if (WUMA.GetWeapons()[ent]) and (WUMA.PlayerSpawnSWEP(ply, ent, ent) == false) then ret = false end

	if (WUMA.GetVehicles()[ent]) and (WUMA.PlayerSpawnVehicle(ply, nil, ent) == false) then ret = false end

	if (WUMA.GetEntities()[ent]) and (WUMA.PlayerSpawnSENT(ply, ent) == false) then ret = false end

	if (WUMA.GetNPCs()[ent]) and (WUMA.PlayerSpawnNPC(ply, ent) == false) then ret = false end

	return ret

end

if AdvDupe then
	AdvDupe.AdminSettings.AddEntCheckHook("WUMACheckPlayerDuplicate", checkPlayerSpawn)
end

if AdvDupe2 then
	hook.Add("AdvDupe_FinishPasting", "WUMAAdvDupeFinishedPasting", function(data)
		local user = data[1].Player
		if user then
			for _, entity in pairs(data[1].CreatedEntities) do
				if IsValid(entity) then
					local str = entity:GetClass()
					if (string.Left(str, 5) == "gmod_") then
						convar = GetConVar("sbox_max" .. string.sub(str, 6))
						if convar then
							str = string.sub(str, 6)
						else
							convar = GetConVar("sbox_max" .. string.sub(str, 6) .. "s")
							if convar then
								str = string.sub(str, 6) .. "s"
							end
						end
					end

					if (string.lower(entity:GetClass()) == "prop_ragdoll") then
						str = entity:GetModel()
					elseif (entity:GetTable().VehicleName) then
						str = entity:GetTable().VehicleName
					end

					if user:HasLimit(str) then
						if (user:CheckLimit(nil, str) == false) then
							entity:Remove()
						else
							user:AddCount(nil, entity, str)
						end
					end
				end
			end
		end
	end)

end

local function checkDuplicatorSpawn(ply, entTable)
	local class = entTable.Class

	if (class == "prop_physics") then
		if (WUMA.PlayerSpawnProp(ply, entTable.Model) == false) then return false else return true end
	end

	local ret = true

	--Check if class is restricted in all the different types
	if (WUMA.GetWeapons()[class]) and (WUMA.PlayerSpawnSWEP(ply, class) == false) then ret = false end

	if (WUMA.GetVehicles()[class]) and (WUMA.PlayerSpawnVehicle(ply, nil, class) == false) then ret = false end

	if (WUMA.GetEntities()[class]) and (WUMA.PlayerSpawnSENT(ply, class) == false) then ret = false end

	if (WUMA.GetNPCs()[class]) and (WUMA.PlayerSpawnNPC(ply, class) == false) then ret = false end

	return ret

end

local old_CreateEntityFromTable = old_CreateEntityFromTable or duplicator.CreateEntityFromTable
duplicator.CreateEntityFromTable = function(ply, entTable)
	local ret

	if ply and ply:IsValid() and ply:IsPlayer() then
		ProtectedCall(function()
			if checkDuplicatorSpawn(ply, entTable) then
				ret = old_CreateEntityFromTable(ply, entTable)
			end
		end)
	else
		ret = old_CreateEntityFromTable(ply, entTable)
	end

	return ret
end
