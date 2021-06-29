
WUMA.Inheritance = WUMA.Inheritance or {}

function WUMA.GetInheritsLimitsFrom(parent)
	local inheritsFrom = WUMA.Inheritance["limits"] and  WUMA.Inheritance["limits"][parent]
	if inheritsFrom then
		return inheritsFrom
	end
end

function WUMA.GetInheritsRestrictionsFrom(parent)
	local inheritsFrom = WUMA.Inheritance["restrictions"] and  WUMA.Inheritance["restrictions"][parent]
	if inheritsFrom then
		return inheritsFrom
	end
end

function WUMA.GetInheritsLoadoutFrom(parent)
	local inheritsFrom = WUMA.Inheritance["loadout"] and  WUMA.Inheritance["loadout"][parent]
	if inheritsFrom then
		return inheritsFrom
	end
end

function WUMA.LoadInheritance()
	local inheritances = WUMASQL([[SELECT * FROM `WUMAInheritance`]])
	if inheritances then
		for _, row in pairs(inheritances) do
			WUMA.Inheritance[row.type] = WUMA.Inheritance[row.type] or {}
			WUMA.Inheritance[row.type][row.usergroup] = row.inheritFrom
		end
	end
end

function WUMA.SetUsergroupInheritance(caller, type, usergroup, inheritFrom)
	WUMA.Inheritance[type] = WUMA.Inheritance[type] or {}
	WUMA.Inheritance[type][usergroup] = inheritFrom

	WUMASQL(
		[[REPLACE INTO `WUMAInheritance` (`type`, `usergroup`, `inheritFrom`) VALUES ("%s", "%s", "%s")]],
		type,
		usergroup,
		inheritFrom
	)

	hook.Call("WUMAOnInheritanceChanged", nil, caller, type, usergroup, inheritFrom)
end

function WUMA.UnsetUsergroupInheritance(caller, type, usergroup)
	if WUMA.Inheritance[type] and WUMA.Inheritance[type][usergroup] then
		WUMA.Inheritance[type][usergroup] = nil

		WUMASQL(
			[[DELETE FROM `WUMAInheritance` WHERE `type` = "%s" AND `usergroup` = "%s"]],
			type,
			usergroup
		)

		hook.Call("WUMAOnInheritanceChanged", nil, caller, type, usergroup, nil)
	end
end
