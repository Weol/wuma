-------------------
-- SUBSCRIPTIONS --
-------------------
local subscriptions = {}
local subscription_data = {}

local unique_ids = 1
function WUMA.Subscribe(...)
	local args = {...}

	local callback = table.remove(args)

	assert(isfunction(callback))

	local key = table.concat(args, "_")
	local id = "id_" .. unique_ids
	unique_ids = unique_ids + 1

	local subscribe = (subscriptions[key] == nil)

	subscriptions[key] = subscriptions[key] or {}
	subscriptions[key][id] = callback

	if subscription_data[key] then
		callback(subscription_data[key], {})
	end

	if subscribe then
		WUMARPC("Subscribe", args)
	end

	return function()
		subscriptions[key][id] = nil
		WUMARPC("Unsubscribe", args)
	end
end

function WUMA.Unsubscribe(...)
	local args = {...}

	local key = table.concat(args, "_")

	subscriptions[key] = nil
	subscription_data[key] = nil

	WUMARPC("Unsubscribe", args)
end

function WUMA.FlushSubscriptions()
	WUMARPC("FlushUserSubscriptions")

	subscriptions = {}
	subscription_data = {}
end

function WUMA.OnRestrictionsUpdate(parent, updated, deleted)
	local preprocessed = {}
	for id, restriction in pairs(updated) do
		preprocessed[id] = Restriction:New(restriction)
	end

	local key = "restrictions_" .. parent
	subscription_data[key] = subscription_data[key] or {}

	table.Merge(subscription_data[key], preprocessed)
	for _, id in pairs(deleted) do
		subscription_data[key][id] = nil
	end

	for id, f in pairs(subscriptions[key]) do
		f(subscription_data[key], preprocessed, deleted)
	end
end

function WUMA.OnLimitsUpdate(parent, updated, deleted)
	local preprocessed = {}
	for id, limit in pairs(updated) do
		preprocessed[id] = Limit:New(limit)
	end

	local key = "limits_" .. parent
	subscription_data[key] = subscription_data[key] or {}

	table.Merge(subscription_data[key], preprocessed)
	for _, id in pairs(deleted) do
		subscription_data[key][id] = nil
	end

	for id, f in pairs(subscriptions[key]) do
		f(subscription_data[key], preprocessed, deleted)
	end
end

function WUMA.OnLoadoutsUpdate(parent, updated, deleted)
	local preprocessed = {}
	for id, limit in pairs(updated) do
		preprocessed[id] = LoadoutWeapon:New(limit)
	end

	local key = "lodouts_" .. parent
	subscription_data[key] = subscription_data[key] or {}

	table.Merge(subscription_data[key], preprocessed)
	for _, id in pairs(deleted) do
		subscription_data[key][id] = nil
	end

	for id, f in pairs(subscriptions[key]) do
		f(subscription_data[key], preprocessed, deleted)
	end
end

function WUMA.OnSettingsUpdate(parent, updated, deleted)
	local key = "lodouts_" .. parent

	subscription_data[key] = subscription_data[key] or {}

	table.Merge(subscription_data[key], updated)
	for _, id in pairs(deleted) do
		subscription_data[key][id] = nil
	end

	for id, f in pairs(subscriptions[key]) do
		f(subscription_data[key], updated, deleted)
	end
end

function WUMA.OnUsergroupUpdate(updated, deleted)
	local key = "usergroups"

	subscription_data[key] = subscription_data[key] or {}

	for _, usergroup in pairs(updated) do
		subscription_data[key][usergroup] = usergroup
	end

	for _, usergroup in pairs(deleted) do
		subscription_data[key][usergroup] = nil
	end

	for id, f in pairs(subscriptions[key]) do
		f(subscription_data[key], updated, deleted)
	end
end

function WUMA.OnInheritanceUpdate(type, updated, deleted)
	local key = "inheritance"

	subscription_data[key] = subscription_data[key] or {}

	for usergroup, inheritFrom in pairs(updated) do
		subscription_data[key][type] = subscription_data[key][type] or {}
		subscription_data[key][type][usergroup] = inheritFrom
	end

	if subscription_data[key][type] then
		for _, usergroup in pairs(deleted) do
			subscription_data[key][type][usergroup] = nil
		end
	end

	for id, f in pairs(subscriptions[key]) do
		f(subscription_data[key], type, updated, deleted)
	end
end

function WUMA.OnMapsUpdate(updated, deleted)
	local key = "maps"

	subscription_data[key] = subscription_data[key] or {}

	for _, map in pairs(updated) do
		subscription_data[key][map] = map
	end

	for _, map in pairs(deleted) do
		subscription_data[key][map] = nil
	end

	for id, f in pairs(subscriptions[key]) do
		f(updated, deleted)
	end
end