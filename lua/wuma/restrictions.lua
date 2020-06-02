
WUMA.Restrictions = WUMA.Restrictions or {}
WUMA.UserRestrictions = WUMA.UserRestrictions or {}

local function insertRestriction(restriction)
	WUMASQL(
		[[INSERT INTO `WUMARestrictions` (`type`, `parent`, `item`, `is_anti`) VALUES ("%s", "%s", "%s", %s);]],
		restriction:GetType(),
		restriction:GetParent(),
		restriction:GetItem(),
		restriction:GetIsAnti() or "NULL"
	)
end

local function deleteRestriction(parent, type, item)
	WUMASQL(
		[[DELETE FROM `WUMARestrictions` WHERE `type` == "%s" AND `parent` == "%s" and `item` == "%s"]],
		type,
		parent,
		item
	)
end

function WUMA.AddRestriction(caller, parent, type, item, is_anti, scope)
	local preprocessor = type:GetPreProcessor()
	if preprocessor then
		item = preprocessor(item)
	end

	local restriction = Restriction:new{type=type:GetName(), item=item, parent=parent, is_anti=is_anti, scope=scope}

	if WUMA.Restrictions[parent] or player.GetBySteamID(parent) or WUMA.IsUsergroupConnected(parent) then
		WUMA.Restrictions[parent] = WUMA.Restrictions[parent] or {}
		WUMA.Restrictions[parent][type .. "_" .. item] = restriction
	end

	insertRestriction(restriction)

	hook.Call("WUMARestrictionAdded", nil, caller, restriction)
end

function WUMA.RemoveRestriction(caller, parent, type, item)
	local preprocessor = type:GetPreProcessor()
	if preprocessor then
		item = preprocessor(item)
	end

	if WUMA.Restrictions[parent] then
		WUMA.Restrictions[parent][type .. "_" .. item] = nil
		if table.IsEmpty(WUMA.Restrictions[parent]) then
			WUMA.Restrictions[parent] = nil
		end
	end

	deleteRestriction(parent, type, item)

	hook.Call("WUMARestrictionRemoved", nil, caller, parent, type, item)
end

function WUMA.ReadRestrictions(parent)
	local restrictions = WUMASQL([[SELECT * FROM `WUMARestrictions` WHERE `parent` == "%s"]], parent)
	if restrictions then
		local preprocessed = {}
		for _, args in pairs(restrictions) do
			local restriction = Restriction:New(args)
			preprocessed[restriction:GetType() .. "_" .. restriction:GetItem()] = restriction
		end
		return preprocessed
	end
end

local function playerInitialSpawn(player)
	if not WUMA.Restrictions[player:GetUserGroup()] then
		WUMA.Restrictions[player:GetUserGroup()] = WUMA.ReadRestrictions(player:GetUserGroup())
	end

	if not WUMA.Restrictions[player:SteamID()] then
		WUMA.Restrictions[player:SteamID()] = WUMA.ReadRestrictions(player:SteamID())
	end
end
hook.Add("PlayerInitialSpawn", "WUMAPlayerInitialSpawnRestrictions", playerInitialSpawn)