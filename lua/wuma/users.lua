
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.Users = {}
WUMA.UserLimitsCache = {}

WUMA.PersonalLoadoutCommand = WUMA.CreateConVar("wuma_personal_loadout_chatcommand", "!loadout", FCVAR_ARCHIVE, "Chat command to open the loadout selector")

function WUMA.InitializeUser(user)
	WUMA.AssignRestrictions(user)
	WUMA.AssignLimits(user)

	WUMA.AddLookup(user)
end

function WUMA.AssignUserRegulations(user)
	WUMA.AssignUserRestrictions(user)
	WUMA.AssignUserLimits(user)
	WUMA.AssignUserLoadout(user)
end

function WUMA.AssignRestrictions(user, usergroup)
	WUMA.AssignUsergroupRestrictions(user, usergroup)
	WUMA.AssignUserRestrictions(user)
end

function WUMA.AssignUsergroupRestrictions(user, usergroup)
	local usergroup = usergroup or user:GetUserGroup()
	local restrictions = WUMA.UsergroupRestrictions[usergroup] or {}

	for id, _ in pairs(restrictions) do
		local object = WUMA.Restrictions[id]
		if (object:GetUserGroup() == usergroup) and not user:GetRestriction(object:GetType(), object:GetString()) then
			user:AddRestriction(object:Clone())
		end
	end

	if WUMA.GetUsergroupAncestor(Restriction:GetID(), usergroup) then
		WUMA.AssignUsergroupRestrictions(user, WUMA.GetUsergroupAncestor(Restriction:GetID(), usergroup))
	end
end

function WUMA.AssignUserRestrictions(user)
	if WUMA.CheckUserFileExists(user, Restriction) then
		local tbl = WUMA.GetSavedRestrictions(user)
		for _, obj in pairs(tbl) do
			user:AddRestriction(obj)
		end
	end
end

function WUMA.AssignLimits(user, usergroup)
	local cache = WUMA.UserLimitsCache[user:SteamID()]
	if cache then
		user:SetLimitCache(cache)
	end

	WUMA.AssignUsergroupLimits(user, usergroup)
	WUMA.AssignUserLimits(user)
end

function WUMA.AssignUsergroupLimits(user, usergroup)
	local usergroup = usergroup or user:GetUserGroup()
	local limits = WUMA.UsergroupLimits[usergroup] or {}

	for id, _ in pairs(limits) do
		local object = WUMA.Limits[id]
		if not object then
			WUMADebug(id)
		end
		if (object:GetUserGroup() == usergroup) and not user:HasLimit(object:GetID(true)) then
			user:AddLimit(object:Clone())
		end
	end

	if WUMA.GetUsergroupAncestor(Limit:GetID(), usergroup) then
		WUMA.AssignUsergroupLimits(user, WUMA.GetUsergroupAncestor(Limit:GetID(), usergroup))
	end
end

function WUMA.AssignUserLimits(user)
	if WUMA.CheckUserFileExists(user, Limit) then
		local tbl = WUMA.GetSavedLimits(user)
		for id, obj in pairs(tbl) do
			user:AddLimit(obj)
		end
	end
end

function WUMA.AssignLoadout(user, usergroup)
	WUMA.AssignUsergroupLoadout(user, usergroup)
	WUMA.AssignUserLoadout(user)
end

function WUMA.AssignUsergroupLoadout(user, usergroup)
	local usergroup = usergroup or user:GetUserGroup()

	if not(WUMA.Loadouts[usergroup]) then return end

	local loadout = WUMA.Loadouts[usergroup]:Clone()

	user:SetLoadout(loadout)
end

function WUMA.AssignUserLoadout(user)
	if WUMA.HasPersonalLoadout(user) then
		local tbl = WUMA.GetSavedLoadout(user)
		user:SetLoadout(tbl)
	end
end

function WUMA.UpdateUsergroup(group, func)
	local players = WUMA.GetUsers(group)
	if not players then return {} end
	for _, user in pairs(players) do
		func(user)
	end
	return players
end

function WUMA.GetUserData(user, typ)
	if not isstring(user) then user = user:SteamID() end

	if not WUMA.IsSteamID(user) then return false end

	local restrictions = false
	local limits = false
	local loadout = false

	if typ then
		if (typ == Restriction:GetID() and WUMA.CheckUserFileExists(user, Restriction)) then
			return WUMA.ReadUserRestrictions(user)
		elseif (typ == Limit:GetID() and WUMA.CheckUserFileExists(user, Limit)) then
			return WUMA.ReadUserLimits(user)
		elseif (typ == Loadout:GetID() and WUMA.CheckUserFileExists(user, Loadout)) then
			return WUMA.ReadUserLoadout(user)
		else
			return false
		end
	end

	if WUMA.CheckUserFileExists(user, Restriction) then restrictions = WUMA.ReadUserRestrictions(user) end
	if WUMA.CheckUserFileExists(user, Limit) then limits = WUMA.ReadUserLimits(user) end
	if WUMA.CheckUserFileExists(user, Loadout) then loadout = WUMA.ReadUserLoadout(user) end

	if not restrictions and not limits and not loadout then return false end

	return {
		steamid = user,
		restrictions = restrictions,
		limits = limits,
		loadout = loadout
	}
end

function WUMA.GetUsers(group)
	if not group then
		local tbl = {}
		for _, ply in pairs(player.GetAll()) do
			tbl[ply:SteamID()] = ply
		end
		return tbl
	end

	--Check for normal usergroup
	if isstring(group) then
		local tbl = {}
		for _, ply in pairs(player.GetAll()) do
			if (ply:GetUserGroup() == group) then
				tbl[ply:SteamID()] = ply
			end
		end
		return tbl
	end
end

function WUMA.GetAuthorizedUsers(callback)
	CAMI.GetPlayersWithAccess(WUMA.WUMAGUI, callback)
end

function WUMA.HasAccess(user, callback, access)
	local access = access or WUMA.WUMAGUI

	local cb = function(bool)
		WUMA.STCache(user:SteamID()..access, bool)
		callback(bool)
		return
	end

	local cached = WUMA.STCache(user:SteamID()..access)
	if cached then return callback(cached) end
	CAMI.PlayerHasAccess(user, access or WUMA.WUMAGUI, callback)
end

function WUMA.UserToTable(user)
	if istable(user) then
		return user
	else
		return {user}
	end
end

function WUMA.IsSteamID(steamid)
	if not isstring(steamid) then return false end
	return (steamid == string.match(steamid, [[STEAM_%d:%d:%d*]]))
end

function WUMA.GetUserGroups()
	local groups = {"superadmin", "admin", "user"}
	for group, tbl in pairs(CAMI.GetUsergroups()) do
		if not table.HasValue(groups, group) then table.insert(groups, group) end
	end
	return groups
end

function WUMA.ShowWUMAMenu(ply, cmd, args)
	WUMA.HasAccess(ply, function(bool)
		if bool then
			ply:SendLua([[WUMA.GUI.Toggle()]])
		else
			ply:ChatPrint("You do not have access to this command")
		end
	end)
end
concommand.Add( "wuma_menu", WUMA.ShowWUMAMenu)

function WUMA.ShowPersonalLoadout(ply, cmd, args)
	WUMA.HasAccess(ply, function(bool)
		if bool then
			ply:SendLua([[WUMA.GUI.CreateLoadoutSelector()]])
		else
			ply:ChatPrint("You do not have access to this command")
		end
	end, "wuma personalloadout")
end
concommand.Add("wuma_loadout", WUMA.ShowPersonalLoadout)

function WUMA.UserChatCommand(user, text, public)
	if (text == WUMA.PersonalLoadoutCommand:GetString()) then
		user:SendLua([[WUMA.GUI.CreateLoadoutSelector()]])
		return ""
	end
end
hook.Add("PlayerSay", "WUMAChatCommand", WUMA.UserChatCommand)

function WUMA.UserDisconnect(user)
	WUMA.GetAuthorizedUsers(function(users) WUMA.GetStream("users"):Send(users) end)

	--Cache users limit data so they cant rejoin to reset limits
	if (user:GetLimits()) then
		user:CacheLimits()
		WUMA.UserLimitsCache[user:SteamID()] = user.LimitsCache
	end

	WUMA.AddLookup(user)
end
hook.Add("PlayerDisconnected", "WUMAPlayerDisconnected", WUMA.UserDisconnect)

function WUMA.PlayerLoadout(user)
	if not user.InitalLoadoutCheck then
		WUMA.AssignLoadout(user)
		user.InitalLoadoutCheck = true
	end
	return user:GiveLoadout()
end
hook.Add("PlayerLoadout", "WUMAPlayerLoadout", WUMA.PlayerLoadout)

function WUMA.PlayerInitialSpawn(user)
	WUMA.InitializeUser(user)
	timer.Simple(1, function()
		WUMA.GetAuthorizedUsers(function(users) WUMA.GetStream("users"):Send(users) end)
	end)
end
hook.Add("PlayerInitialSpawn", "WUMAPlayerInitialSpawn", WUMA.PlayerInitialSpawn)

function WUMA.PlayerUsergroupChanged(user, old, new, source)
	WUMA.RefreshGroupRestrictions(user,new)
	WUMA.RefreshGroupLimits(user,new)
	WUMA.RefreshLoadout(user,new)
end
hook.Add("CAMI.PlayerUsergroupChanged", "WUMAPlayerUsergroupChanged", WUMA.PlayerUsergroupChanged)

function WUMA.UsergroupsChanged()
	timer.Simple(2, function()
		WUMA.GetAuthorizedUsers(function(users) WUMA.GetStream("groups"):Send(users) end)
	end)
end
hook.Add("CAMI.OnUsergroupRegistered", "WUMAPlayerUsergroupChanged", WUMA.UsergroupsChanged)
hook.Add("CAMI.OnUsergroupUnregistered", "WUMAPlayerUsergroupChanged", WUMA.UsergroupsChanged)
