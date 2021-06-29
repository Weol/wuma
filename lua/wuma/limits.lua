

WUMA.UserLimitStrings = WUMA.UserLimitStrings or {}
WUMA.Limits = WUMA.Limits or {}

WUMA.ExcludeLimits = CreateConVar("wuma_exclude_limits", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Exclude wuma limits from normal gamemode limits", 0, 1)

local function insertLimit(limit)
	WUMASQL(
		[[REPLACE INTO `WUMALimits` (`parent`, `item`, `limit`, `is_exclusive`) VALUES ("%s", "%s", "%s", %s);]],
		limit:GetParent(),
		limit:GetItem(),
		limit:GetLimit(),
		limit:GetIsExclusive() or "NULL"
	)
end

local function deleteLimit(parent, item)
	WUMASQL([[DELETE FROM `WUMALimits` WHERE `parent` == "%s" and `item` == "%s"]],
		parent,
		item
	)
end

function WUMA.AddLimit(caller, parent, item, limit, is_exclusive)
	if (item == limit) then error("item and limit cannot be the same") end
	if (tonumber(item) ~= nil) then error("item cannot be numeric") end

	if (string.sub(item, 0, 7) == "models/") then
		item = string.lower(item)
	end

	local limit = Limit:New{item=item, parent=parent, limit=limit, is_exclusive=is_exclusive}

	local old_limit
	if WUMA.Limits[parent] or player.GetBySteamID(parent) or WUMA.IsUsergroupConnected(parent) then
		WUMA.Limits[parent] = WUMA.Limits[parent] or {}

		old_limit = WUMA.Limits[parent][item]

		WUMA.Limits[parent][item] = limit
	end

	if old_limit then
		limit:Recover(old_limit)
	end

	insertLimit(limit)

	hook.Call("WUMAOnLimitAdded", nil, caller, limit)
end

function WUMA.RemoveLimit(caller, parent, item)
	if WUMA.Limits[parent] then
		local limit = WUMA.Limits[parent][item]
		if limit then
			limit:Purge()
		end

		WUMA.Limits[parent][item] = nil

		if table.IsEmpty(WUMA.Limits[parent]) then
			WUMA.Limits[parent] = nil
		end
	end

	deleteLimit(parent, item)

	hook.Call("WUMAOnLimitRemoved", nil, caller, parent, item)
end

function WUMA.ReadLimits(parent)
	local limits = WUMASQL([[SELECT * FROM `WUMALimits` WHERE `parent` == "%s"]], parent)
	if limits then
		local preprocessed = {}
		for _, args in pairs(limits) do
			args.is_exclusive = (args.is_exclusive ~= "NULL") and tobool(args.is_exclusive)
			args.limit = (tonumber(args.limit) ~= nil) and tonumber(args.limit) or args.limit
			local limit = Limit:New(args)
			preprocessed[limit:GetItem()] = limit
		end
		return preprocessed
	end
end

local function userDisconnected(user)
	WUMA.Limits[user:SteamID()] = nil
end
hook.Add("PlayerDisconnected", "WUMA_LIMITS_PlayerDisconnected", userDisconnected)

local function playerInitialSpawn(player)
	if not WUMA.Limits[player:SteamID()] then
		WUMA.Limits[player:SteamID()] = WUMA.ReadLimits(player:SteamID())
	end
end
hook.Add("PlayerInitialSpawn", "WUMA_LIMITS_PlayerInitialSpawn", playerInitialSpawn)

function WUMA.GetTotalLimits(user_id, str)
	local exclude = WUMA.ExcludeLimits:GetBool()

	if not exclude then return 0 end

	return (WUMA.UserLimitStrings[user_id] or {})[str] or 0
end

function WUMA.ChangeTotalLimits(user_id, string, delta)
	if not WUMA.UserLimitStrings[user_id] then
		WUMA.UserLimitStrings[user_id] = {}
	end

	local value = WUMA.UserLimitStrings[user_id][string] or 0
	if (value + delta < 1) then
		WUMA.UserLimitStrings[user_id][string] = nil
		if (table.Count(WUMA.UserLimitStrings[user_id]) == 0) then
			WUMA.UserLimitStrings[user_id] = nil
		end
	else
		WUMA.UserLimitStrings[user_id][string] = value + delta
	end

	local ply = player.GetBySteamID(user_id)
	if ply then
		ply:SetNWInt("Count.TotalLimits." .. string, WUMA.UserLimitStrings[user_id] and WUMA.UserLimitStrings[user_id][string] or 0)
	end
end