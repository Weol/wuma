
WUMA = WUMA or {}
WUMA.Users = {}

function WUMA.InitializeUser(user)
	WUMA.AssignRestrictions(user)
	WUMA.AssignLimits(user)
	WUMA.AssignLoadout(user)
	
	WUMA.AssignUserRegulations(user)
	
	if user:HasWUMAData() then
		WUMA.AddLookup(user)
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
			steamid = user,
			restrictions = restrictions,
			limits = limits,
			loadout = loadout
		}
	else
		return user:GetWUMAData()
	end
end

function WUMA.GetUsers(group)
	if not group then return player.GetAll() end	

	--Check for normal usergroup
	if isstring(group) then
		local tbl = {}
		for _,ply in pairs(player.GetAll()) do 
			if (string.lower(ply:GetUserGroup()) == string.lower(group)) then 
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

function WUMA.HasAccess(user,access_str)
	return ULib.ucl.query(user,access_str or WUMA.ULXGUI)
end

function WUMA.UserToTable(user)
	if (string.lower(type(user)) == "table") then
		return userw
	else
		return {user}
	end
end

function WUMA.IsSteamID(steamid)
	return ULib.isValidSteamID(steamid)
end

function WUMA.GetUserGroups()
	local hierchy = {}

	local function recursive(tbl)
		for group, tbl in pairs(tbl) do
			if istable(tbl) and table.Count(tbl) then
				table.insert(hierchy,group)
				recursive(tbl)
			else
				table.insert(hierchy,group)
			end
		end
	end 
	recursive(ULib.ucl.getInheritanceTree())

	local hierchy_reverse = {}
	for k, v in pairs(hierchy) do
		hierchy_reverse[table.Count(hierchy)-(k-1)] = v
	end
	
	return hierchy_reverse
end

function WUMA.PlayerLoadout(user)
	return user:GiveLoadout()
end
hook.Add("PlayerLoadout", "WUMAPlayerLoadout", WUMA.PlayerLoadout, -1)

function WUMA.PlayerInitialSpawn(user)
	WUMA.InitializeUser(user) 
end
hook.Add("UCLAuthed", "WUMAPlayerInitialSpawn", WUMA.PlayerInitialSpawn, -2)

function WUMA.PlayerNameChange(user,old,new)
	WUMA.AddLookup(user)
	WUMA.SendInformation(WUMA.NET.WHOIS(user:SteamID()))
end
hook.Add("ULibPlayerNameChanged", "WUMAPlayerNameChange", WUMA.PlayerNameChange, -1)

WUMA.UCLTables = {}
WUMA.UCLTables.Usergrous = WUMA.GetUserGroups()
function WUMA.UCLChanged()
	if not (table.Count(WUMA.UCLTables.Usergrous) == WUMA.GetUserGroups()) then
		hook.Call(WUMA.USERGROUPSUPDATEHOOK, _, WUMA.GetUserGroups())
	end

	for _,user in pairs(player.GetAll()) do
		if not user.WUMAPreviousGroup or (user.WUMAPreviousGroup and not(user.WUMAPreviousGroup == user:GetUserGroup())) then
			WUMA.RefreshGroupRestrictions(user)
			WUMA.RefreshGroupLimits(user)
			WUMA.RefreshLoadout(user)
			user.WUMAPreviousGroup = user:GetUserGroup()
		end 
	end
end
hook.Add("UCLChanged", "WUMAUCLChanged", WUMA.UCLChanged)
