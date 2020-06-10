
WUMA.RestrictionTypes = {}

WUMA.RestrictionTypes.entity = RestrictionType:New{
	name = "entity",
    print = "Entity",
	print2 = "Entities",
	search = "Search..",
	items = function()
		return table.GetKeys(list.Get("SpawnableEntities"))
	end
}

WUMA.RestrictionTypes.prop = RestrictionType:New{
	name = "prop",
	print = "Prop",
	print2 = "Props",
	search = "Model",
	preprocessor = string.lower
}

WUMA.RestrictionTypes.npc = RestrictionType:New{
	name = "npc",
    print = "NPC",
	print2 = "NPCs",
	search = "Search..",
	items = function() return table.GetKeys(list.Get("NPC")) end
}

WUMA.RestrictionTypes.vehicle = RestrictionType:New{
	name = "vehicle",
    print = "Vehicle",
	print2 = "Vehicles",
	search = "Search..",
	items = function() return table.GetKeys(list.Get("Vehicles")) end
}

WUMA.RestrictionTypes.swep = RestrictionType:New{
	name = "swep",
    print = "Weapon",
	print2 = "Weapons",
	search = "Search..",
	items = function() return table.GetKeys(list.Get("Weapon")) end
}

WUMA.RestrictionTypes.pickup = RestrictionType:New{
	name = "pickup",
    print = "Pickup",
	print2 = "Pickups",
	search = "Search..",
	items = function() return table.GetKeys(list.Get("Weapon")) end
}

WUMA.RestrictionTypes.effect = RestrictionType:New{
	name = "effect",
    print = "Effect",
	print2 = "Effects",
	search = "Model",
	preprocessor = string.lower
}

WUMA.RestrictionTypes.tool = RestrictionType:New{
	name = "tool",
    print = "Tool",
	print2 = "Tools",
	search = "Search..",
	items = function() return table.GetKeys(weapons.GetStored('gmod_tool').Tool) end
}

WUMA.RestrictionTypes.ragdoll = RestrictionType:New{
	name = "ragdoll",
    print = "Ragdoll",
	print2 = "Ragdolls",
	search = "Model",
	preprocessor = string.lower
}

WUMA.RestrictionTypes.property = RestrictionType:New{
	name = "property",
    print = "Property",
	print2 = "Properties",
	search = "Property"
}

WUMA.RestrictionTypes.physgrab = RestrictionType:New{
	name = "physgrab",
    print = "Physgrab",
	print2 = "Physgrab",
	search = "Search/Model"
}

WUMA.RestrictionTypes.use = RestrictionType:New{
	name = "use",
    print = "Use",
	print2 = "Uses",
	search = "Search..",
	items = function()
		local merged = {}
		table.Merge(merged, list.Get("NPC"))
		table.Merge(merged, list.Get("Vehicles"))
		table.Merge(merged, list.Get("SpawnableEntities"))
		return table.GetKeys(merged)
	end
}
