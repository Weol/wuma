
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

function WUMA.GetEntities()
	return table.GetKeys(list.Get( "SpawnableEntities" ))
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
	local tbl = {
		"weapon_annabelle"
	}
	
	for k, v in pairs(list.Get( "Weapon" )) do
		table.insert(tbl,k)
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