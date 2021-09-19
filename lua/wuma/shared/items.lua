
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

local entities_cache
function WUMA.GetEntities()
	if entities_cache then return entities_cache end

	local entities = {}

	for k, v in pairs(list.Get("SpawnableEntities")) do
		entities[k] = k
	end

	for k, v in pairs(WUMA.GetAdditionalEntities()) do
		entities[v] = v
	end

	entities_cache = entities

	return entities
end

local npcs_cache
function WUMA.GetNPCs()
	if npcs_cache then return npcs_cache end

	local npcs = {}

	for k, v in pairs(list.Get("NPC")) do
		npcs[k] = k
	end

	npcs_cache = npcs

	return npcs
end

local vehicles_cache
function WUMA.GetVehicles()
	if vehicles_cache then return vehicles_cache end

	local vehicles = {}

	for k, v in pairs(list.Get("Vehicles")) do
		vehicles[k] = k
	end

	for k, v in pairs(list.Get("simfphys_vehicles")) do
		vehicles[k] = k
	end

	vehicles_cache = vehicles

	return vehicles
end

local tools_cache
function WUMA.GetTools()
	if tools_cache then return tools_cache end

	local tools = {}

	for k, v in pairs(weapons.GetStored('gmod_tool').Tool) do
		tools[k] = k
	end

	tools_cache = tools

	return tools
end

local weapons_cache
function WUMA.GetWeapons()
	if weapons_cache then return weapons_cache end

	local weapons = {}

	for k, v in pairs(list.Get("Weapon")) do
		if v.Spawnable then
			weapons[k] = k
		end
	end

	weapons_cache = weapons

	return weapons
end

function WUMA.GetStandardLimits()
	local tbl = {}
	for k, v in pairs(cleanup.GetTable()) do
		tbl[v] = v
	end
	return tbl
end

local all_cache
function WUMA.GetAllItems()
	if all_cache then return all_cache end

	local tbl = {}
	tbl = table.Merge(tbl, WUMA.GetEntities())
	tbl = table.Merge(tbl, WUMA.GetNPCs())
	tbl = table.Merge(tbl, WUMA.GetVehicles())
	tbl = table.Merge(tbl, WUMA.GetTools())
	tbl = table.Merge(tbl, WUMA.GetWeapons())
	tbl = table.Merge(tbl, WUMA.GetStandardLimits())

	all_cache = tbl

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