
WUMA.Inheritance = WUMA.Inheritance or {}

function WUMA.LoadInheritance()
	local inheritances = WUMASQL([[SELECT * FROM `WUMAInheritance`]])
	if inheritances then
		for _, row in inheritances do

		end
	end
end

function WUMA.SetUsergroupInheritance(caller, type, usergroup, inheritFrom)
	WUMA.Inheritance[type] = WUMA.Inheritance[type] or {}
	WUMA.Inheritance[type][usergroup] = inheritFrom

	WUMASQL(
		[[INSERT INTO `WUMAInheritance` (`type`, `usergroup`, `inheritFrom`) VALUES ("%s", "%s", "%s")]],
		type,
		usergroup,
		inheritFrom
	)

	hook.Call("WUMAInheritanceChanged", nil, caller, type, usergroup, inheritFrom)
end

function WUMA.UnsetUsergroupInheritance(caller, type, usergroup)
	if WUMA.Inheritance[type] and WUMA.Inheritance[type][usergroup] then
		WUMA.Inheritance[type][usergroup] = nil

		WUMASQL(
			[[DELETE FROM `WUMAInheritance` WHERE `type` = "%s" AND `usergroup` = "%s"]],
			type,
			usergroup
		)

		hook.Call("WUMAInheritanceChanged", nil, caller, type, usergroup, nil)
	end
end

function WUMA.GetUsergroupAncestor(type, usergroup)
	return WUMA.Inheritance[string.format("%s_%s", type, usergroup)]
end
