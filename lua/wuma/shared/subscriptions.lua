
WUMA.RPC = WUMA.RPC or {}

if SERVER then
    WUMA.Subscriptions = WUMA.Subscriptions or {}
    WUMA.Subscribable = WUMA.Subscribable or {}
end

WUMA.RPC.Subscribe = WUMARPCFunction:New{
	name = "subscribe",
	privilage = "wuma gui",
	description = "Subscribe to some server data",
    func = function(player, type, ...)
        local varargs = {...}
        if type then
            if not WUMA.Subscribable[type] then
                return WUMADebug("Player %s (%s) issued invalid subscription (%s)", player:Nick(), player:SteamID(), type)
            end

            local id = table.concat({type, ...}, "_")

            WUMA.Subscriptions[id] = WUMA.Subscriptions[id] or {}
            WUMA.Subscriptions[id][player:SteamID()] = player

            WUMA.Subscribable[type](player, unpack(varargs))

            local steamid = player:SteamID()

            player.WUMASubscriptions = player.WUMASubscriptions or {}
            player.WUMASubscriptions[id] = function()
                WUMA.Subscriptions[id][steamid] = nil

                if table.IsEmpty(WUMA.Subscriptions[id]) then
                    WUMA.Subscriptions[id] = nil
                end

                player.WUMASubscriptions[id] = nil
            end
        end
    end
}

WUMA.RPC.Unsubscribe = WUMARPCFunction:New{
	name = "unsubscribe",
	privilage = "wuma gui",
	description = "Unsubscribe from some server data",
    func = function(player, type, ...)
        local id = table.concat({type, ...}, "_")

        if player.WUMASubscriptions[id] then
            player.WUMASubscriptions[id]()
        end
    end
}

WUMA.RPC.FlushSubscriptions = WUMARPCFunction:New{
	name = "flush_subscriptions",
	privilage = "wuma gui",
	description = "Unsubscribe from all server data",
    func = function(player)
        if player.WUMASubscriptions then
            for _, f in pairs(player.WUMASubscriptions) do
                f()
            end
        end
    end
}
hook.Add("PlayerDisconnected", "WUMA_SUBSCRIPTIONS_PlayerDisconnected", WUMA.RPC.Subscribe)

if CLIENT then return end --Clients should only load the RPC functions

------------------
-- RESTRICTIONS --
------------------
WUMA.Subscribable.restrictions = function(player, parent)
    local restrictions = WUMA.Restrictions[parent] or WUMA.ReadRestrictions(parent)
    if restrictions then
        WUMARPC(player, "WUMA.OnRestrictionsUpdate", parent, restrictions, {})
    end
end

local function restrictionAdded(_, restriction)
    local subscribers = WUMA.Subscriptions["restrictions_" .. restriction:GetParent()]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnRestrictionsUpdate", restriction:GetParent(), {[restriction:GetType() .. "_" .. restriction:GetItem()] = restriction}, {})
    end
end
hook.Add("WUMAOnRestrictionAdded", "WUMA_SUBSCRIPTIONS_WUMARestrictionAdded", restrictionAdded)

local function restrictionRemoved(_, parent, type, item)
    local subscribers = WUMA.Subscriptions["restrictions_" .. parent]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnRestrictionsUpdate", parent, {}, {type .. "_" .. item})
    end
end
hook.Add("WUMAOnRestrictionRemoved", "WUMA_SUBSCRIPTIONS_WUMARestrictionRemoved", restrictionRemoved)

------------
-- LIMITS --
------------
WUMA.Subscribable.limits = function(player, parent)
    local limits = WUMA.Limits[parent] or WUMA.ReadLimits(parent)
    if limits then
        WUMARPC(player, "WUMA.OnLimitsUpdate", parent, limits, {})
    end
end

local function limitAdded(_, limit)
    local subscribers = WUMA.Subscriptions["limits_" .. limit:GetParent()]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLimitsUpdate", limit:GetParent(), {[limit:GetItem()] = limit}, {})
    end
end
hook.Add("WUMAOnLimitAdded", "WUMA_SUBSCRIPTIONS_WUMALimitAdded", limitAdded)

local function limitRemoved(_, parent, item)
    local subscribers = WUMA.Subscriptions["limits_" .. parent]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLimitsUpdate", parent, {}, {item})
    end
end
hook.Add("WUMAOnLimitRemoved", "WUMA_SUBSCRIPTIONS_WUMALimitRemoved", limitRemoved)

--------------
-- LOADOUTS --
--------------
WUMA.Subscribable.loadouts = function(player, parent)
    local loadouts = WUMA.Loadouts[parent] or WUMA.ReadLoadouts(parent)
    if loadouts then
        WUMARPC(player, "WUMA.OnLoadoutsUpdate", parent, loadouts, {})
    end
end

local function loadoutAdded(_, loadout)
    local subscribers = WUMA.Subscriptions["loadouts_" .. loadout:GetParent()]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLoadoutsUpdate", loadout:GetParent(), {[loadout:GetClass()] = loadout}, {})
    end
end
hook.Add("WUMAOnLoadoutAdded", "WUMA_SUBSCRIPTIONS_WUMALoadoutAdded", loadoutAdded)

local function loadoutRemoved(_, parent, class)
    local subscribers = WUMA.Subscriptions["loadouts_" .. parent]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLoadoutsUpdate", parent, {}, {class})
    end
end
hook.Add("WUMAOnLoadoutRemoved", "WUMA_SUBSCRIPTIONS_WUMALoadoutRemoved", loadoutRemoved)

--------------
-- SETTINGS --
--------------
WUMA.Subscribable.settings = function(player, parent)
    local settings = WUMA.Settings[parent] or WUMA.ReadSettings(parent)
    if settings then
        WUMARPC(player, "WUMA.OnSettingsUpdate", parent, settings, {})
    end
end

local function settingChanged(parent, key, value)
    local subscribers = WUMA.Subscriptions["settings_" .. parent]

    if subscribers then
        if value then
            WUMARPC(subscribers, "WUMA.OnSettingsUpdate", parent, {[key] = value}, {})
        else
            WUMARPC(subscribers, "WUMA.OnSettingsUpdate", parent, {}, {key})
        end
    end
end
hook.Add("WUMAOnSettingChanged", "WUMA_SUBSCRIPTIONS_WUMASettingChanged", settingChanged)

----------------
-- USERGROUPS --
----------------
WUMA.Subscribable.usergroups = function(player)
    local usergroups = {}
    for _, usergroup in pairs(table.GetKeys(CAMI.GetUsergroups())) do
        usergroups[usergroup] = usergroup
    end

    WUMARPC(player, "WUMA.OnUsergroupUpdate", usergroups, {})
end

local function usergroupRegistered(usergroup)
    local subscribers = WUMA.Subscriptions["usergroups"]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnUsergroupUpdate", {usergroup}, {})
    end
end
hook.Add("CAMI.OnUsergroupRegistered", "OnUsergroupRegisteredSubscription", usergroupRegistered)

local function usergroupUnregistered(usergroup)
    local subscribers = WUMA.Subscriptions["usergroups"]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnUsergroupUpdate", {}, {usergroup})
    end
end
hook.Add("CAMI.OnUsergroupUnregistered", "OnUsergroupUnregisteredSubscription", usergroupUnregistered)

-----------------
-- INHERITANCE --
-----------------
WUMA.Subscribable.inheritance = function(player)
    WUMARPC(player, "WUMA.OnInheritanceUpdate", nil, WUMA.Inheritance, {})
end

local function inheritanceChanged(_, type, usergroup, inheritFrom)
    local subscribers = WUMA.Subscriptions["inheritance"]
    if subscribers then
        if inheritFrom then
            WUMARPC(subscribers, "WUMA.OnInheritanceUpdate", type, {[usergroup] = inheritFrom}, {})
        else
            WUMARPC(subscribers, "WUMA.OnInheritanceUpdate", type, {}, {usergroup})
        end
    end
end
hook.Add("WUMAOnInheritanceChanged", "WUMA_SUBSCRIPTIONS_WUMAInheritanceChanged", inheritanceChanged)

----------
-- MAPS --
----------
WUMA.Subscribable.maps = function(player)
    WUMARPC(player, "WUMA.OnMapsUpdate", {file.Find("maps/*.bsp", "GAME")}, {})
end

------------------
-- ONLINE USERS --
------------------
WUMA.Subscribable.online = function(caller)
    local users = {}

    for _, ply in pairs(player.GetAll()) do
        users[ply:SteamID()] = {steamid = ply:SteamID(), nick = ply:Nick(), usergroup = ply:GetUserGroup(), t = os.time()}
    end

    WUMARPC(caller, "WUMA.OnOnlineUpdate", users, {})
end

local function playerDisconnected(player)
    WUMADebug(player:SteamID())
    local subscribers = WUMA.Subscriptions["online"]
    WUMARPC(subscribers, "WUMA.OnOnlineUpdate", {}, {player:SteamID()})
end
hook.Add("PlayerDisconnected", "WUMA_ONLINE_PlayerDisconnected", playerDisconnected)

local function playerInitialSpawn(player)
    WUMADebug(player:SteamID())
    local subscribers = WUMA.Subscriptions["online"]
    WUMARPC(subscribers, "WUMA.OnOnlineUpdate", {[player:SteamID()] = {steamid = player:SteamID(), nick = player:Nick(), usergroup = player:GetUserGroup(), t = os.time()}}, {})
end
hook.Add("PlayerInitialSpawn", "WUMA_ONLINE_PlayerInitialSpawn", playerInitialSpawn)

------------------
-- LOOKUP USERS --
------------------
local function playerDisconnected2(player)
    local subscribers = WUMA.Subscriptions["lookup"]
    WUMARPC(subscribers, "WUMA.OnLookupUpdate", {[player:SteamID()] = {steamid = player:SteamID(), nick = player:Nick(), usergroup = player:GetUserGroup(), t = os.time()}} , {})
end
hook.Add("PlayerDisconnected", "WUMA_LOOKUP_PlayerDisconnected", playerDisconnected2)