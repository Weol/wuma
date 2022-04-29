WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.Restrictions = WUMA.Restrictions or {}
WUMA.UsergroupRestrictions = WUMA.UsergroupRestrictions or {}

function WUMA.LoadRestrictions()
	local saved, tbl = WUMA.GetSavedRestrictions() or {}, {}

	for _, restriction in pairs(saved) do
		local id = restriction:GetID()
		local usergroup = restriction:GetUserGroup()
		WUMA.Restrictions[id] = restriction

		if not WUMA.UsergroupRestrictions[usergroup] then WUMA.UsergroupRestrictions[usergroup] = {} end
		WUMA.UsergroupRestrictions[usergroup][id] = true --Its really the key we are saving
	end
end

function WUMA.GetSavedRestrictions(user)
	local tbl = {}

	if (user) then
		tbl = WUMA.ReadUserRestrictions(user)
	else
		local saved = util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory .. "restrictions.txt")) or {}

		for key, obj in pairs(saved) do
			if istable(obj) then
				tbl[key] = Restriction:new(obj)
			end
		end
	end

	return tbl
end

function WUMA.ReadUserRestrictions(user)
	if not isstring(user) then user = user:SteamID() end

	local tbl = {}

	local saved = util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user, Restriction))) or {}

	for key, obj in pairs(saved) do
		obj.parent = user
		tbl[key] = Restriction:new(obj)
	end

	return tbl
end

function WUMA.GetRestrictions(user)
	if user and not isstring(user) then
		return user:GetRestrictions()
	elseif user and isstring(user) then
		return WUMA.Restrictions[user]
	else
		return WUMA.Restrictions
	end
end

function WUMA.RestrictionsExist()
	if (table.Count(WUMA.Restrictions) > 0) then return true end
end

function WUMA.HasRestriction(usergroup, type, item)
	if isstring(usergroup) then
		if WUMA.GetSavedRestrictions()[Restriction:GenerateID(type, usergroup, item)] then return true end
	else
		if WUMA.GetSavedRestrictions()[usergroup:GetID()] then return true end
	end
	return false
end

function WUMA.AddRestriction(caller, usergroup, type, item, anti, scope)

	if (type == "prop" or type == "effect" or type == "ragdoll") and isstring(item) then
		item = string.lower(item) --Models are always lower case
	end

	local restriction = Restriction:new({ type = type, string = item, usergroup = usergroup, allow = anti, scope = scope })

	WUMA.Restrictions[restriction:GetID()] = restriction

	if not WUMA.UsergroupRestrictions[restriction:GetUserGroup()] then WUMA.UsergroupRestrictions[restriction:GetUserGroup()] = {} end
	WUMA.UsergroupRestrictions[restriction:GetUserGroup()][restriction:GetID()] = true

	local affected = WUMA.UpdateUsergroup(usergroup, function(ply)
		ply:AddRestriction(restriction:Clone())
	end)

	local function recursive(group)
		local heirs = WUMA.GetUsergroupHeirs(Restriction:GetID(), group)
		for _, heir in pairs(heirs) do
			if not WUMA.Restrictions[Restriction:GenerateID(type, heir, item)] then
				WUMA.UpdateUsergroup(heir, function(ply)
					ply:AddRestriction(restriction)
				end)
				recursive(heir)
			end
		end
	end

	recursive(usergroup)

	WUMA.AddClientUpdate(Restriction, function(tbl)
		tbl[restriction:GetID()] = restriction:GetBarebones()
		return tbl
	end)

	WUMA.ScheduleDataUpdate(Restriction:GetID(), function(tbl)
		tbl[restriction:GetID()] = restriction:GetBarebones()
		return tbl
	end)

	WUMA.InvalidateCache(Restriction:GetID())

	return affected

end

function WUMA.RemoveRestriction(caller, usergroup, type, item)

	if (type == "prop" or type == "effect" or type == "ragdoll") and isstring(item) then
		local id = Restriction:GenerateID(type, usergroup, item)
		if not WUMA.Restrictions[id] then
			item = string.lower(item) --Models are always lower case
		end
	end

	local id = Restriction:GenerateID(type, usergroup, item)

	if not WUMA.Restrictions[id] then return end

	WUMA.Restrictions[id]:Delete()
	WUMA.Restrictions[id] = nil

	if WUMA.UsergroupRestrictions[usergroup] then
		WUMA.UsergroupRestrictions[usergroup][id] = nil
		if (table.Count(WUMA.UsergroupRestrictions[usergroup]) < 1) then WUMA.UsergroupRestrictions[usergroup] = nil end
	end

	local restriction
	local ancestor = WUMA.GetUsergroupAncestor(Restriction:GetID(), usergroup)
	while ancestor do
		restriction = WUMA.Restrictions[Restriction:GenerateID(type, ancestor, item)]
		if restriction then
			break
		end
		ancestor = WUMA.GetUsergroupAncestor(Restriction:GetID(), ancestor)
	end

	local affected = WUMA.UpdateUsergroup(usergroup, function(ply)
		ply:RemoveRestriction(Restriction:GenerateID(type, nil, item))
		if restriction then ply:AddRestriction(restriction) end
	end)

	local function recursive(group)
		local heirs = WUMA.GetUsergroupHeirs(Restriction:GetID(), group)
		for k, heir in pairs(heirs) do
			if not WUMA.Restrictions[Restriction:GenerateID(type, heir, item)] then
				WUMA.UpdateUsergroup(heir, function(ply)
					ply:RemoveRestriction(Restriction:GenerateID(type, nil, item))
					if restriction then
						ply:AddRestriction(restriction)
					end
				end)
				recursive(heir)
			end
		end
	end

	recursive(usergroup)

	WUMA.AddClientUpdate(Restriction, function(tbl)
		tbl[Restriction:GenerateID(type, usergroup, item)] = WUMA.DELETE
		return tbl
	end)

	WUMA.ScheduleDataUpdate(Restriction:GetID(), function(tbl)
		tbl[Restriction:GenerateID(type, usergroup, item)] = nil

		return tbl
	end)

	WUMA.InvalidateCache(Restriction:GetID())

	return affected
end

function WUMA.AddUserRestriction(caller, user, type, item, anti, scope)
	if (type == "prop" or type == "effect" or type == "ragdoll") and isstring(item) then
		item = string.lower(item) --Models are always lower case
	end

	local restriction = Restriction:new({ type = type, string = item, allow = anti, scope = scope })

	local affected = {}

	if isentity(user) then
		user:AddRestriction(restriction)

		affected = { user }
		user = user:SteamID()
	end

	WUMA.AddClientUpdate(Restriction, function(tbl)
		tbl[restriction:GetID()] = restriction

		return tbl
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Restriction:GetID(), function(tbl)
		tbl[restriction:GetID()] = restriction

		return tbl
	end)

	return affected
end

function WUMA.RemoveUserRestriction(caller, user, type, item)

	if (type == "prop" or type == "effect" or type == "ragdoll") and isstring(item) then
		local id = Restriction:GenerateID(type, usergroup, item)
		if not WUMA.Restrictions[id] then
			item = string.lower(item) --Models are always lower case
		end
	end

	local id = Restriction:GenerateID(type, nil, item)

	local affected = {}

	if isstring(user) and WUMA.GetUsers()[user] then user = WUMA.GetUsers()[user] end
	if isentity(user) then
		user:RemoveRestriction(id, true)

		affected = { user }
		user = user:SteamID()
	end

	WUMA.AddClientUpdate(Restriction, function(tbl)
		tbl[id] = WUMA.DELETE

		return tbl
	end, user)

	WUMA.ScheduleUserDataUpdate(user, Restriction:GetID(), function(tbl)
		tbl[id] = nil

		return tbl
	end)

	return affected
end

function WUMA.RefreshGroupRestrictions(user, usergroup)
	user:SetRestrictions({})

	WUMA.AssignRestrictions(user, usergroup)
end

WUMA.RegisterDataID(Restriction:GetID(), "restrictions.txt", WUMA.GetSavedRestrictions, WUMA.isTableEmpty)
WUMA.RegisterUserDataID(Restriction:GetID(), "restrictions.txt", WUMA.GetSavedRestrictions, WUMA.isTableEmpty)
