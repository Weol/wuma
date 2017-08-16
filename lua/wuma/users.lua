
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.Users = {}

WUMA.UserLimitsCache = {}
WUMA.HasUserAccessNetworkBool = "WUMAHasAccess"

function WUMA.InitializeUser(user)
	WUMA.AssignRestrictions(user)
	WUMA.AssignLimits(user)
	WUMA.AssignLoadout(user)

	if user:HasWUMAData() then
		WUMA.AddLookup(user)
	end
	
	WUMA.HasAccess(user, function(bool) 
		user:SetNWBool( WUMA.HasUserAccessNetworkBool, bool )
	end)	
end

function WUMA.AssignUserRegulations(user)
	WUMA.AssignUserRestrictions(user)
	WUMA.AssignUserLimits(user)
	WUMA.AssignUserLoadout(user)
end

function WUMA.AssignRestrictions(user)	
	WUMA.AssignUsergroupRestrictions(user)
	WUMA.AssignUserRestrictions(user)
end

function WUMA.AssignUsergroupRestrictions(user,usergroup)	
	for _,object in pairs(WUMA.Restrictions) do
		if (object:GetUserGroup() == (usergroup or user:GetUserGroup())) then
			user:AddRestriction(object:Clone())
		end
	end
end

function WUMA.AssignUserRestrictions(user)
	if WUMA.CheckUserFileExists(user,Restriction) then
		local tbl = WUMA.GetSavedRestrictions(user)
		for _,obj in pairs(tbl) do
			user:AddRestriction(obj)
		end
	end
end

function WUMA.AssignLimits(user)
	WUMA.AssignUsergroupLimits(user)
	WUMA.AssignUserLimits(user)
	
	local cache = WUMA.UserLimitsCache[user:SteamID()]
	if cache then
		for _, object in pairs(cache) do
			object:CallOnEmpty("WUMADeleteCache", nil)
			user:AddLimit(object)
		end
		WUMA.UserLimitsCache[user:SteamID()] = nil
	end
end


function WUMA.AssignUsergroupLimits(user, usergroup)
	for id, object in pairs(WUMA.Limits) do
		if (object:GetUserGroup() == (usergroup or user:GetUserGroup())) then
			user:AddLimit(object:Clone())
		end
	end
end

function WUMA.AssignUserLimits(user)
	if WUMA.CheckUserFileExists(user,Limit) then
		local tbl = WUMA.GetSavedLimits(user)
		for id, obj in pairs(tbl) do
			user:AddLimit(obj)
		end
	end
end

function WUMA.AssignLoadout(user, usergroup)
	WUMA.AssignUsergroupLoadout(user)
	WUMA.AssignUserLoadout(user)
end

function WUMA.AssignUsergroupLoadout(user, usergroup)
	if not(WUMA.Loadouts[(usergroup or user:GetUserGroup())]) then return end
	
	local loadout = WUMA.Loadouts[(usergroup or user:GetUserGroup())]:Clone()
	
	user:SetLoadout(loadout)
end

function WUMA.AssignUserLoadout(user)
	if WUMA.HasPersonalLoadout(user) then
		local tbl = WUMA.GetSavedLoadout(user)
		user:SetLoadout(tbl)
	end
end

function WUMA.UpdateUsergroup(group,func)
	local players = WUMA.GetUsers(group)
	if not players then return false end
	for _,user in pairs(players) do
		func(user)
	end
	return players
end

function WUMA.GetUserData(user,typ)
	if not isstring(user) then user = user:SteamID() end
	
	if not WUMA.IsSteamID(user) then return false end

	local restrictions = false
	local limits = false
	local loadout = false
	
	if typ then
		if (typ == Restriction:GetID() and WUMA.CheckUserFileExists(user,Restriction)) then
			return WUMA.ReadUserRestrictions(user)
		elseif (typ == Limit:GetID() and WUMA.CheckUserFileExists(user,Limit)) then 
			return WUMA.ReadUserLimits(user)
		elseif (typ == Loadout:GetID() and WUMA.CheckUserFileExists(user,Loadout)) then 
			return WUMA.ReadUserLoadout(user)
		else
			return false
		end
	end
	
	if WUMA.CheckUserFileExists(user,Restriction) then restrictions = WUMA.ReadUserRestrictions(user) end
	if WUMA.CheckUserFileExists(user,Limit) then limits = WUMA.ReadUserLimits(user) end
	if WUMA.CheckUserFileExists(user,Loadout) then loadout = WUMA.ReadUserLoadout(user) end

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
		for _,ply in pairs(player.GetAll()) do 
			tbl[ply:SteamID()] = ply
		end
		return tbl
	end	

	--Check for normal usergroup
	if isstring(group) then
		local tbl = {}
		for _,ply in pairs(player.GetAll()) do 
			if (string.lower(ply:GetUserGroup()) == string.lower(group)) then 
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
	CAMI.PlayerHasAccess(user, access or WUMA.WUMAGUI, callback)
end

function WUMA.UserToTable(user)
	if (string.lower(type(user)) == "table") then
		return user
	else
		return {user}
	end
end

function WUMA.IsSteamID(steamid)
	if not isstring(steamid) then return false end
	return (steamid == string.match(steamid,[[STEAM_%d:%d:%d*]]))
end

function WUMA.GetUserGroups()
	local groups = {"superadmin","admin","user"}
	for group, tbl in pairs(CAMI.GetUsergroups()) do
		if not table.HasValue(groups,group) then table.insert(groups,group) end
	end
	return groups
end

function WUMA.UserDisconnect(user)
	--Cache users limit data so they cant rejoin to reset limits
	if (user:GetLimits()) then
		WUMA.UserLimitsCache[user:SteamID()] = user:GetLimits()
		for _, limit in pairs(user:GetLimits()) do 
			limit:CallOnEmpty("WUMADeleteCache",function(limit) 
				WUMA.UserLimitsCache[limit:GetParentID()][limit:GetID()] = nil
				if (table.Count(WUMA.UserLimitsCache[limit:GetParentID()]) < 1) then WUMA.UserLimitsCache[limit:GetParentID()] = nil end
			end)
		end
	end

	if user:HasWUMAData() then
		WUMA.AddLookup(user)
	end
end
hook.Add("PlayerDisconnected", "WUMAPlayerDisconnected", WUMA.UserDisconnect, 0)

function WUMA.PlayerLoadout(user)
	return user:GiveLoadout()
end
hook.Add("PlayerLoadout", "WUMAPlayerLoadout", WUMA.PlayerLoadout, -1)

function WUMA.PlayerInitialSpawn(user)
	WUMA.InitializeUser(user) 
	timer.Simple(1,function() WUMA.GetAuthorizedUsers(function(users) WUMA.NET.USERS:Send(users) end) end)
end
hook.Add("PlayerInitialSpawn", "WUMAPlayerInitialSpawn", WUMA.PlayerInitialSpawn, -2)

function WUMA.PlayerUsergroupChanged(user, old, new, source)
	WUMA.RefreshGroupRestrictions(user,new)
	WUMA.RefreshGroupLimits(user,new)
	WUMA.RefreshLoadout(user,new)
	
	timer.Simple(2, function()
		WUMA.HasAccess(user, function(bool) 
			user:SetNWBool(WUMA.HasUserAccessNetworkBool, bool)
			user:SendLua([[WUMA.RequestFromServer(WUMA.NET.SETTINGS:GetID())]])
		end)
	end)	
end
hook.Add("CAMI.PlayerUsergroupChanged", "WUMAPlayerUsergroupChanged", WUMA.PlayerUsergroupChanged)
