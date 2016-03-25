
TIIP = TIIP or {}

function TIIP.InitializeUser(user)
	TIIP.AssignRestrictions(user)
	TIIP.AssignLimits(user)
	--TIIP.AssignLoadout(user)
	
	TIIP.AssignUserRegulations(user)
end

function TIIP.AssignUserRegulations(user)
	TIIP.AssignUserRestrictions(user)
end

function TIIP.AssignUserRestrictions(user)
	if TIIP.CheckUserFileExists(user) then
		local tbl = TIIP.GetSavedRestrictions(user)
		for _,obj in pairs(tbl) do
			user:AddRestriction(obj)
		end
	end
end

function TIIP.UpdateUsergroup(group,func)
	local players = TIIP.GetUsers(group)
	if not players then return false end
	for _,player in pairs(players) do
		func(player)
	end
end

function TIIP.GetUsers(group)
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

function TIIP.IsSteamID(steamid)
	return ULib.isValidSteamID( steamid )
end

function TIIP.PlayerDisconnected(user)

end
hook.Add( "PlayerDisconnected", "TIIPPlayerDisconnected", TIIP.PlayerDisconnected, -2 )

function TIIP.PlayerInitialSpawn(user)
	TIIP.InitializeUser(user) 
end
hook.Add( "ULibLocalPlayerReady", "TIIPPlayerInitialSpawn", TIIP.PlayerInitialSpawn, -2 )

function TIIP.UCLChanged()
	for _,user in pairs(player.GetAll()) do
		if not user.TIIPPreviousGroup or (user.TIIPPreviousGroup and not(user.TIIPPreviousGroup == user:GetUserGroup())) then
			user:RefreshGroupRestrictions()
			user.TIIPPreviousGroup = user:GetUserGroup()
		end 
	end
end
hook.Add( "UCLChanged", "TIIPPlayerInitialSpawn", TIIP.UCLChanged )
