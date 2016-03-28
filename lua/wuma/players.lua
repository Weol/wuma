
WUMA = WUMA or {}

function WUMA.InitializeUser(user)
	WUMA.AssignRestrictions(user)
	WUMA.AssignLimits(user)
	WUMA.AssignLoadout(user)
	
	WUMA.AssignUserRegulations(user)
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

function WUMA.GetUsers(group)
	if not group then return false end
	local tbl = false
	for _,ply in pairs(player.GetAll()) do 
		if (string.lower(ply:GetUserGroup()) == string.lower(group)) then 
			tbl = tbl or {}
			table.insert(tbl,ply) 
		end
	end
	return tbl
end

function WUMA.UserToTable(user)
	if (string.lower(type(user)) == "table") then
		return user
	else
		return {user}
	end
end

function WUMA.IsSteamID(steamid)
	return ULib.isValidSteamID( steamid )
end

function WUMA.PlayerDisconnected(user)

end
hook.Add( "PlayerDisconnected", "WUMAPlayerDisconnected", WUMA.PlayerDisconnected, -2 )

function WUMA.PlayerLoadout(user)
	return user:GiveLoadout()
end
hook.Add( "PlayerLoadout", "WUMAPlayerLoadout", WUMA.PlayerLoadout, -1 )

function WUMA.PlayerInitialSpawn(user)
	WUMA.InitializeUser(user) 
end
hook.Add( "ULibLocalPlayerReady", "WUMAPlayerInitialSpawn", WUMA.PlayerInitialSpawn, -2 )

function WUMA.UCLChanged()
	for _,user in pairs(player.GetAll()) do
		if not user.WUMAPreviousGroup or (user.WUMAPreviousGroup and not(user.WUMAPreviousGroup == user:GetUserGroup())) then
			user:RefreshGroupRestrictions()
			user:RefreshGroupLimits()
			WUMA.RefreshLoadout(user)
			user.WUMAPreviousGroup = user:GetUserGroup()
		end 
	end
end
hook.Add( "UCLChanged", "WUMAUCLChanged", WUMA.UCLChanged )
