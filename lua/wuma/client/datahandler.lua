-------------------
-- SUBSCRIPTIONS --
-------------------
local subscribe_callbacks = {}
local unsubscribe_callbacks = {}
local subscription_data = {}
local subscription_init = {}

local unique_ids = 1
function WUMA.Subscribe(args)
	local callback = args.callback
	local on_unsubscribe = args.unsubscribe

	assert(isfunction(callback))
	assert(not on_unsubscribe or isfunction(callback))

	local key = table.concat(args.args, "_")

	local id = args.id
	if not id then
		id = "auto_generated_id_" .. unique_ids
		unique_ids = unique_ids + 1
	end

	if subscribe_callbacks[key] and subscribe_callbacks[key][id] then
		return --A subscription with this unique id already exists
	end

	if callback then
		local asd = callback
		callback = function(...)
			WUMADebug("Subscription of \"%s\":", key)
			WUMADebug({...})
			asd(...)
		end
	end

	local subscribe = (subscribe_callbacks[key] == nil)

	subscribe_callbacks[key] = subscribe_callbacks[key] or {}
	subscribe_callbacks[key][id] = callback

	if on_unsubscribe then
		unsubscribe_callbacks[key] = unsubscribe_callbacks[key] or {}
		unsubscribe_callbacks[key][id] = on_unsubscribe
	end

	if subscription_init[key] then
		subscription_init[key](callback)
	end

	if subscribe then
		WUMA.RPC.Subscribe:Invoke(unpack(args.args))

		hook.Call("WUMAOnSubscribed", nil, unpack(args.args))
	end
end

function WUMA.Unsubscribe(...)
	local args = {...}

	local key = table.concat(args, "_")

	subscribe_callbacks[key] = nil
	unsubscribe_callbacks[key] = nil
	subscription_data[key] = nil
	subscription_init[key] = nil

	for _, callback in pairs(unsubscribe_callbacks[key]) do
		callback()
	end

	WUMA.RPC.Unsubscribe:Invoke(unpack(args))
end

function WUMA.FlushSubscriptions()
	WUMA.RPC.FlushSubscriptions:Invoke()

	subscribe_callbacks = {}
	unsubscribe_callbacks = {}
	subscription_data = {}
	subscription_init = {}
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

	subscription_init[key] = function(callback)
		callback(subscription_data[key], parent, preprocessed, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key]) do
		f(subscription_data[key], parent, preprocessed, deleted)
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

	subscription_init[key] = function(callback)
		callback(subscription_data[key], parent, preprocessed, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key]) do
		f(subscription_data[key], parent, preprocessed, deleted)
	end
end

function WUMA.OnLoadoutsUpdate(parent, updated, deleted)
	local preprocessed = {}
	for id, limit in pairs(updated) do
		preprocessed[id] = LoadoutWeapon:New(limit)
	end

	local key = "loadouts_" .. parent
	subscription_data[key] = subscription_data[key] or {}

	table.Merge(subscription_data[key], preprocessed)
	for _, id in pairs(deleted) do
		subscription_data[key][id] = nil
	end

	subscription_init[key] = function(callback)
		callback(subscription_data[key], parent, preprocessed, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key] or {}) do
		f(subscription_data[key], parent, preprocessed, deleted)
	end
end

function WUMA.OnSettingsUpdate(parent, updated, deleted)
	local key = "settings_" .. parent

	subscription_data[key] = subscription_data[key] or {}

	table.Merge(subscription_data[key], updated)
	for _, id in pairs(deleted) do
		subscription_data[key][id] = nil
	end

	subscription_init[key] = function(callback)
		callback(subscription_data[key], parent, updated, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key] or {}) do
		f(subscription_data[key], parent, updated, deleted)
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

	subscription_init[key] = function(callback)
		callback(subscription_data[key], updated, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key] or {}) do
		f(subscription_data[key], updated, deleted)
	end
end

function WUMA.OnInheritanceUpdate(type, updated, deleted)
	local key = "inheritance"

	if not type then
		for type, updated in pairs(updated) do
			WUMA.OnInheritanceUpdate(type, updated, deleted)
		end
		return
	end

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

	subscription_init[key] = function(callback)
		for type, data in pairs(subscription_data[key]) do
			callback(subscription_data[key], type, data, deleted)
		end
	end

	for _, f in pairs(subscribe_callbacks[key] or {}) do
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

	subscription_init[key] = function(callback)
		callback(subscription_data[key], updated, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key] or {}) do
		f(subscription_data[key], updated, deleted)
	end
end

function WUMA.OnLookupUpdate(updated, deleted)
	local key = "lookup"

	subscription_data[key] = subscription_data[key] or {}

	for steamid, user in pairs(updated) do
		subscription_data[key][steamid] = user
	end

	for steamid, user  in pairs(deleted) do
		subscription_data[key][steamid] = nil
	end

	subscription_init[key] = function(callback)
		callback(subscription_data[key], updated, deleted)
	end

	for _, f in pairs(subscribe_callbacks[key] or {}) do
		f(subscription_data[key], updated, deleted)
	end
end