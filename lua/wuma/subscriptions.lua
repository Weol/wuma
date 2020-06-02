
subscriptions = {}

function WUMA.RPC.Subscribe(player, type, ...)
    local varargs = {...}
    if type then
        if not WUMA.Subscriptions[type] then return WUMADebug("Player %s (%s) issued invalid subscription (%s)", player:Nick(), player:SteamID(), table.concat(varargs, ", ")) end
        CAMI.PlayerHasAccess(player, "wuma gui", function(allow)
            if allow then
                subscriptions[type](player, unpack(varargs))

                local id = type .. "_" .. table.concat(varargs, "_")
                local steamid = player:SteamID()
                WUMA.Subscriptions[id] = WUMA.Subscriptions[id] or {}
                WUMA.Subscriptions[id][steamid] = player

                player.WUMASubscriptions = player.WUMASubscriptions or {}
                player.WUMASubscriptions[id] = function()
                    WUMA.Subscriptions[id][steamid] = nil

                    if table.IsEmpty(WUMA.Subscriptions[id]) then
                        WUMA.Subscriptions[id] = nil
                    end

                    player.WUMASubscriptions[id] = nil
                end
            else
                WUMADebug("Unauthorized player %s (%s) failed to subscribe to %s event, insufficent privilages", player:Nick(), player:SteamID(), type)
            end
        end)
    end
end

function WUMA.RPC.Unsubscribe(player, type, ...)
    local varargs = {...}
    local id = type .. "_" .. table.concat(varargs, "_")

    if player.WUMASubscriptions[id] then
        player.WUMASubscriptions[id]()
    end
end

function WUMA.RPC.FlushUserSubscriptions(user)
    if user.WUMASubscriptions then
        for _, f in pairs(user.WUMASubscriptions) do
            f()
        end
    end
end
hook.Add("PlayerDisconnected", "WUMAPlayerDisconnectedSubscription", WUMA.RPC.FlushUserSubscriptions)

------------------
-- RESTRICTIONS --
------------------
WUMA.RPC.SubscribeToRestrictions(player, parent)
    WUMA.Subscriptions.restrictions[parent] = WUMA.Subscriptions.restrictions[parent] or {}
    WUMA.Subscriptions.restrictions[parent][player:SteamID()] = player

    local restrictions = WUMA.Restrictions[parent] or WUMA.ReadRestrictions(parent)
    if restrictions then
        WUMARPC(player, "WUMA.OnRestrictionsUpdate", parent, restrictions, {})
    end
end

WUMA.RPC.UnsubscribeToRestrictions(player, parent)

end

local function restrictionAdded(restriction)
    local subscribers = WUMA.Subscriptions["restrictions"] and WUMA.Subscriptions["restrictions"][restriction:GetParent()]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnRestrictionsUpdate", restriction:GetParent(), {[restriction:GetType() .. "_" .. restriction:GetItem()] = restriction}, {})
    end
end
hook.Add("WUMARestrictionAdded", "WUMARestrictionAddedSubscription", restrictionAdded)

local function restrictionRemoved(_, parent, type, item)
    local subscribers = WUMA.Subscriptions["restrictions"] and WUMA.Subscriptions["restrictions"][parent]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnRestrictionsUpdate", parent, {}, {type .. "_" .. item})
    end
end
hook.Add("WUMARestrictionRemoved", "WUMARestrictionRemovedSubscription", restrictionRemoved)

------------
-- LIMITS --
------------
subscriptions.limits = function(player, parent)
    assert(parent)

    local limits = WUMA.Limits[parent] or WUMA.ReadLimits(parent)
    if limits then
        WUMARPC(player, "WUMA.OnLimitsUpdate", limits, {})
    end
end

local function limitAdded(limit)
    local subscribers = WUMA.Subscriptions["limits"] and WUMA.Subscriptions["limits"][limit:GetParent()]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLimitsUpdate", limit:GetParent(), {[limit:GetItem()] = limit}, {})
    end
end
hook.Add("WUMALimitAdded", "WUMALimitAddedSubscription", limitAdded)

local function limitRemoved(_, parent, item)
    local subscribers = WUMA.Subscriptions["limits"] and WUMA.Subscriptions["limits"][parent]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLimitsUpdate", parent, {}, {item})
    end
end
hook.Add("WUMALimitRemoved", "WUMALimitRemovedSubscription", limitRemoved)

--------------
-- LOADOUTS --
--------------
subscriptions.loadouts = function(player, parent)
    assert(parent)

    local loadouts = WUMA.Loadouts[parent] or WUMA.ReadLoadouts(parent)
    if loadouts then
        WUMARPC(player, "WUMA.OnLoadoutsUpdate", loadouts, {})
    end
end

local function loadoutAdded(loadout)
    local subscribers = WUMA.Subscriptions["loadouts"] and WUMA.Subscriptions["loadouts"][loadout:GetParent()]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLoadoutsUpdate", loadout:GetParent(), {[loadout:GetClass()] = loadout}, {})
    end
end
hook.Add("WUMALoadoutAdded", "WUMALoadoutAddedSubscription", loadoutAdded)

local function loadoutRemoved(_, parent, class)
    local subscribers = WUMA.Subscriptions["loadouts"] and WUMA.Subscriptions["loadouts"][parent]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnLoadoutsUpdate", parent, {}, {class})
    end
end
hook.Add("WUMALoadoutRemoved", "WUMALoadoutRemovedSubscription", loadoutRemoved)

--------------
-- SETTINGS --
--------------
subscriptions.settings = function(player, parent)
    assert(parent)

    local settings = WUMA.Settings[parent] or WUMA.ReadSettings(parent)
    if settings then
        WUMARPC(player, "WUMA.OnSettingsUpdate", settings, {})
    end
end

local function settingChanged(parent, key, value)
    local subscribers = WUMA.Subscriptions["settings"] and WUMA.Subscriptions["settings"][parent]

    if subscribers then
        if (value == nil) then
            WUMARPC(subscribers, "WUMA.OnSettingsUpdate", parent, {}, {key})
        else
            WUMARPC(subscribers, "WUMA.OnSettingsUpdate", parent, {[key] = value}, {})
        end
    end
end
hook.Add("WUMASettingChanged", "WUMASettingChangedSubscription", settingChanged)

----------------
-- SERVERINFO --
----------------
subscriptions.serverinfo = function(player)
    WUMARPC(player, "WUMA.OnUsergroupUpdate", CAMI.GetUsergroups(), {})
    for type, inheritance in pairs(WUMA.Inheritance) do
        WUMARPC(player, "WUMA.OnInheritanceUpdate", type, inheritance, {})
    end
    WUMARPC(player, "WUMA.OnMapsUpdate", {file.Find("maps/*.bsp", "GAME")}, {})
end

local function usergroupRegistered(usergroup)
    local subscribers = WUMA.Subscriptions["serverinfo"]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnUsergroupUpdate", {usergroup}, {})
    end
end
hook.Add("CAMI.OnUsergroupRegistered", "OnUsergroupRegisteredSubscription", usergroupRegistered)

local function usergroupUnregistered(usergroup)
    local subscribers = WUMA.Subscriptions["serverinfo"]

    if subscribers then
        WUMARPC(subscribers, "WUMA.OnUsergroupUpdate", {}, {usergroup})
    end
end
hook.Add("CAMI.OnUsergroupUnregistered", "OnUsergroupUnregisteredSubscription", usergroupUnregistered)

local function inheritanceChanged(type, usergroup, inheritFrom)
    local subscribers = WUMA.Subscriptions["serverinfo"]

    if subscribers then
        if inheritFrom then
            WUMARPC(subscribers, "WUMA.OnInheritanceUpdate", type, {[usergroup] = inheritFrom}, {})
        else
            WUMARPC(subscribers, "WUMA.OnInheritanceUpdate", type, {}, {usergroup})
        end
    end
end
hook.Add("WUMAInheritanceChanged", "WUMAInheritanceChangedSubscription", inheritanceChanged)