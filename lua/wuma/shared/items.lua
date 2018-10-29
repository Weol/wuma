
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog


local function additionalEntitiesFromDuplicatorEntityClasses() 
	if (duplicator and duplicator.EntityClasses) then
		local blacklist = {
			monster_alien_grunt = 1,
			monster_cockroach = 1,
			monster_bigmomma = 1,
			sent_keypad = 1,
			prop_physics_multiplayer = 1,
			monster_snark = 1,
			monster_bullchicken = 1,
			monster_scientist = 1,
			sent_deployableballoons = 1,
			prop_vehicle_jeep = 1,
			monster_houndeye = 1,
			monster_alien_slave = 1,
			monster_headcrab = 1,
			prop_physics = 1,
			monster_alien_controller = 1,
			prop_vehicle_prisoner_pod = 1,
			phys_magnet = 1,
			monster_gargantua = 1,
			monster_human_grunt = 1,
			monster_tentacle = 1,
			monster_human_assassin = 1,
			monster_nihilanth = 1,
			prop_vehicle_jeep_old = 1,
			monster_babycrab = 1,
			prop_vehicle_airboat = 1,
			monster_barney = 1,
			prop_ragdoll = 1,
			monster_zombie = 1
		}
	
		local additional = table.GetKeys(duplicator.EntityClasses)
		for k, v in pairs(additional) do
			if (string.Left(v, 4) == "npc_") then --Assume any entity that starts with npc_ is an npc
				additional[k] = nil
			end
			if blacklist[v] then additional[k] = nil end --Remove blacklisted entities
		end
		return additional
	end
end

local function additionalEntitiesFromDarkRP() 
	if (DarkRP and DarkRP.DarkRPEntities) then
		local additional = {}
		for k, v in pairs(DarkRP.DarkRPEntities) do
			table.insert(additional, v.ent)
		end
		return additional
	end
end

local additionalEntitiesFunctions = {
	additionalEntitiesFromDuplicatorEntityClasses,
	additionalEntitiesFromDarkRP
}

function WUMA.GetAdditionalEntities()
	if (CLIENT) then
		return WUMA.AdditionalEntities or {}
	else 
		local additional = {}
		for _, func in pairs(additionalEntitiesFunctions) do
			local success, info = pcall(function()
				local add = func()
				if add then
					table.Add(additional, add)
				end
			end)
		end
		return additional
	end
	return {}
end

function WUMA.GetEntities()
	local entities = table.GetKeys(list.Get( "SpawnableEntities" ))
	table.Add(entities, WUMA.GetAdditionalEntities())
	return entities
end

function WUMA.GetNPCs()
	return table.GetKeys(list.Get( "NPC" ))
end

function WUMA.GetVehicles()
	return table.GetKeys(list.Get( "Vehicles" ))
end

function WUMA.GetTools()
	return table.GetKeys(weapons.GetStored( 'gmod_tool' ).Tool)
end

function WUMA.GetWeapons()
	local tbl = {}

	for k, v in pairs(list.Get( "Weapon" )) do
		if v.Spawnable then
			table.insert(tbl, k)
		end
	end
	
	return tbl
end

function WUMA.GetStandardLimits()
	return cleanup.GetTable()
end

function WUMA.GetAllItems()
	local tbl = {}
	table.Add(tbl,WUMA.GetEntities())
	table.Add(tbl,WUMA.GetNPCs())
	table.Add(tbl,WUMA.GetVehicles())
	table.Add(tbl,WUMA.GetTools())
	table.Add(tbl,WUMA.GetWeapons())
	table.Add(tbl,WUMA.GetStandardLimits())
	
	return tbl
end

function WUMA.IsValidProp()
	return true
end

function WUMA.IsValidRagdoll()
	return true
end

function WUMA.IsValidEffect()
	return true
end