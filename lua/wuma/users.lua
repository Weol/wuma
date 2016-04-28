
WUMA = WUMA or {}
WUMA.Users = {}

function WUMA.InitializeUser(user)
	WUMA.AssignRestrictions(user)
	WUMA.AssignLimits(user)
	WUMA.AssignLoadout(user)
	
	WUMA.AssignUserRegulations(user)
	
	if not user:HasWUMATables() then
		WUMA.AddLookup(user)
	end
	
	if WUMA.HasAccess(user) then 
		WUMA.NET.USERS(user)
	end
end

function WUMA.AssignUserRegulations(user)
	WUMA.AssignUserRestrictions(user)
	WUMA.AssignUserLimits(user)
	WUMA.AssignUserLoadout(user)
end

function WUMA.AssignUserRestrictions(user)
	if WUMA.CheckUserFileExists(user,Restriction) then
		local tbl = WUMA.GetSavedRestrictions(user)
		for _,obj in pairs(tbl) do
			user:AddRestriction(obj)
		end
	end
end

function WUMA.AssignUserLimits(user)
	if WUMA.CheckUserFileExists(user,Limit) then
		local tbl = WUMA.GetSavedLimits(user)
		for _,obj in pairs(tbl) do
			user:AddLimit(obj)
		end
	end
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
	for _,player in pairs(players) do
		func(player)
	end
end

function WUMA.GetUserData(user)
	if (string.lower(type(user)) == "string") then
		if not WUMA.IsSteamID(user) then
			if not steamid then return false end
		end

		local restrictions = false
		local limits = false
		local loadout = false
		
		if WUMA.CheckUserFileExists(user,Restriction) then restrictions = WUMA.ReadUserRestrictions(user) end
		if WUMA.CheckUserFileExists(user,Limit) then limits = WUMA.ReadUserLimits(user) end
		if WUMA.CheckUserFileExists(user,Loadout) then loadout = WUMA.ReadUserLoadout(user) end
	
		if not restrictions and not limits and not loadout then return false end
			
		return {
			restrictions = restrictions
			limits = limits
			loadout = loadout
		}
	else
		return user:GetWUMAData()
	end
end

function WUMA.GetUsers(group)
	if not group then return player.GetAll() end	

	--Check for normal usergroup
	if (string.lower(type(group)) == "string") then
		for _,ply in pairs(player.GetAll()) do 
			if (string.lower(ply:GetUserGroup()) == string.lower(group)) then 
				tbl = tbl or {}
				table.insert(tbl,ply) 
			end
		end
		return tbl
	end
	
end

function WUMA.GetAuthorizedUsers()
	local users = {}
	for _,user in pairs(player.GetAll()) do
		if WUMA.HasAccess(user) then
			table.insert(users,user)
		end
	end
	return users
end

function WUMA.HasAccess(user)
	return ULib.ucl.query(user, WUMA.ULXGUI)
end

function WUMA.UserToTable(user)
	if (string.lower(type(user)) == "table") then
		return user
	else
		return {user}
	end
end

function WUMA.IsSteamID(steamid)
	return ULib.isValidSteamID(steamid)
end

function WUMA.GetUserGroups()
	local tbl = {}
	for k, v in pairs(ULib.ucl.groups) do
		table.insert(tbl,k)
	end
	return tbl
end

function WUMA.PlayerDisconnected(user)
	WUMA.RemoveUser(user)
end
hook.Add("PlayerDisconnected", "WUMAPlayerDisconnected", WUMA.PlayerDisconnected, -2)

function WUMA.PlayerLoadout(user)
	return user:GiveLoadout()
end
hook.Add("PlayerLoadout", "WUMAPlayerLoadout", WUMA.PlayerLoadout, -1)

function WUMA.PlayerInitialSpawn(user)
	WUMA.InitializeUser(user) 
	WUMA.AddUser(user)
end
hook.Add("ULibLocalPlayerReady", "WUMAPlayerInitialSpawn", WUMA.PlayerInitialSpawn, -2)

function WUMA.UCLChanged()
	for _,user in pairs(player.GetAll()) do
		if not user.WUMAPreviousGroup or (user.WUMAPreviousGroup and not(user.WUMAPreviousGroup == WUMA.GetUserGroupuser())) then
			WUMA.RefreshGroupRestrictions(user)
			WUMA.RefreshGroupLimits(user)
			WUMA.RefreshLoadout(user)
			user.WUMAPreviousGroup = user:GetUserGroup()
		end 
	end
end
hook.Add("UCLChanged", "WUMAUCLChanged", WUMA.UCLChanged)
