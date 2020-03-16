
WUMA.RestrictionTypes = {}

WUMA.RestrictionTypes.entity = {
    print = "Entity",
	print2 = "Entities",
	search = "Search..",
	items = function() return WUMA.GetEntities() end
}

WUMA.RestrictionTypes.prop = {
    print = "Prop",
	print2 = "Props",
	search = "Model"
}

WUMA.RestrictionTypes.npc = {
    print = "NPC",
	print2 = "NPCs",
	search = "Search..",
	items = function() return WUMA.GetNPCs() end
}

WUMA.RestrictionTypes.vehicle = {
    print = "Vehicle",
	print2 = "Vehicles",
	search = "Search..",
	items = function() return WUMA.GetVehicles() end
}

WUMA.RestrictionTypes.swep = {
    print = "Weapon",
	print2 = "Weapons",
	search = "Search..",
	items = function() return WUMA.GetWeapons() end
}

WUMA.RestrictionTypes.pickup = {
    print = "Pickup",
	print2 = "Pickups",
	search = "Search..",
	items = function() return WUMA.GetWeapons() end
}

WUMA.RestrictionTypes.effect = {
    print = "Effect",
	print2 = "Effects",
	search = "Model"
}

WUMA.RestrictionTypes.tool = {
    print = "Tool",
	print2 = "Tools",
	search = "Search..",
	items = function() return WUMA.GetTools() end
}

WUMA.RestrictionTypes.ragdoll = {
    print = "Ragdoll",
	print2 = "Ragdolls",
	search = "Model"
}

WUMA.RestrictionTypes.property = {
    print = "Property",
	print2 = "Properties",
	search = "Property"
}

WUMA.RestrictionTypes.physgrab = {
    print = "Physgrab",
	print2 = "Physgrab",
	search = "Search/Model"
}

WUMA.RestrictionTypes.use = {
    print = "Use",
	print2 = "Uses",
	search = "Search..",
	items = function()
		local tbl = {}
		table.Add(table.Add(table.Add(tbl, WUMA.GetEntities()), WUMA.GetVehicles()), WUMA.GetNPCs())
		return tbl
	end}
}