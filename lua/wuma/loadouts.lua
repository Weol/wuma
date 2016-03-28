
WUMA = WUMA or {}
WUMA.Loadouts = WUMA.Loadouts or {}

function WUMA.LoadLoadouts()
	local saved, tbl = WUMA.GetSavedLoadouts() or {}, {}

	for k,v in pairs(saved) do
		if v.usergroup then
			tbl[v.usergroup] = v
		end
	end
	
	WUMA.Loadouts = tbl
end

function WUMA.GetSavedLoadouts(user)
	local tbl = {}
	
	if (user) then
		saved = WUMA.GetCachedUserData(user,Loadout) or util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user,Loadout))) or Loadout:new()
		
		tbl = Loadout:new(saved)
	else
		saved = WUMA.GetCachedData(Loadout) or util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."loadouts.txt")) or {}

		for key,obj in pairs(saved) do
			tbl[key] = Loadout:new(obj)
		end
	end
	
	return tbl
end

function WUMA.GetSavedLoadout(user)
	return WUMA.GetSavedLoadouts(user)
end

function WUMA.GetLoadouts(user)
	if user and not isstring(user) then
		return user:GetLoadout()
	elseif user and isstring(user) then
		return WUMA.Loadouts[user]
	else
		return WUMA.Loadouts
	end
end
 
function WUMA.HasPersonalLoadout(user)
	if WUMA.GetCachedUserData(user,Loadout) or util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user,Loadout))) then return true end
	return false
end

function WUMA.SetLoadoutPrimaryWeapon(usergroup,item)
	if not(WUMA.Loadouts[usergroup]) then WUMAAlert("That usergroup has no loadout."); return end
	
	WUMA.Loadouts[usergroup]:SetPrimary(item)
	
	WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[usergroup] = tbl[usergroup]:SetPrimary(item)
		
		return tbl
	end)
	
	WUMA.UpdateUsergroup(usergroup,function(user)
		if user:HasLoadout() and not user:GetLoadout():IsPersonal() then
			user:GetLoadout():SetPrimary(item)
		end
	end )
end

function WUMA.AddLoadoutWeapon(usergroup,item,primary,secondary)
	if not(WUMA.Loadouts[usergroup]) then
		WUMA.Loadouts[usergroup] = Loadout:new({usergroup=usergroup})
	end
	
	WUMA.Loadouts[usergroup]:AddWeapon(item,primary,secondary)
	
	WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[usergroup] = tbl[usergroup] or Loadout:new({usergroup=usergroup})
		tbl[usergroup]:AddWeapon(item,primary,secondary)
		
		return tbl
	end, function() 
		WUMA.UpdateUsergroup(usergroup,function(user)
			WUMA.RefreshLoadout(user)
		end )
	end)
	
end
 
function WUMA.RemoveLoadoutWeapon(usergroup,item)
	if not WUMA.Loadouts[usergroup] then return end
	
	WUMA.Loadouts[usergroup]:RemoveWeapon(item)

	if (WUMA.Loadouts[usergroup]:GetWeaponCount() < 1) then
		WUMA.ClearLoadout(usergroup)
	else
		WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
			tbl[usergroup]:RemoveWeapon(item)
			
			return tbl
		end, function() 
			WUMA.UpdateUsergroup(usergroup,function(user)
				WUMA.RefreshLoadout(user)
			end )
		end)
	end
	
end

function WUMA.ClearLoadout(usergroup)
	if not WUMA.Loadouts[usergroup] then return end
	
	WUMA.Loadouts[usergroup] = nil
	
	WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[usergroup] = nil
		
		return tbl
	end, function()
		WUMA.UpdateUsergroup(usergroup,function(user)
			WUMA.RefreshLoadout(user)
		end )
	end)
	
end

function WUMA.SetUserLoadoutPrimaryWeapon(users,item)
	users = WUMA.UserToTable(users)
	
	for _,user in pairs(users) do
		if user:HasLoadout() and not user:GetLoadout():IsPersonal() then return end

		user:GetLoadout():SetPrimary(item)
		
		WUMA.ScheduleUserFileUpdate(user,Loadout, function(tbl) 
			tbl:SetPrimary(item)
			
			return tbl
		end)
	end
end

function WUMA.AddUserLoadoutWeapon(users,item,primary,secondary)
	users = WUMA.UserToTable(users)
	 
	for _,user in pairs(users) do	
		WUMA.ScheduleUserFileUpdate(user,Loadout, function(tbl) 
			tbl:AddWeapon(item,primary,secondary)
			
			return tbl
		end, function()
			WUMA.RefreshLoadout(user)
		end)
	end
	
end

function WUMA.RemoveUserLoadoutWeapon(users,item)
	users = WUMA.UserToTable(users)
	
	for _,user in pairs(users) do
		if user:HasLoadout() then
			user:GetLoadout():RemoveWeapon(item,primary,secondary)
		end
		
		if (user:HasLoadout() and user:GetLoadout():GetWeaponCount() < 1) then
			WUMA.ClearUserLoadout(user)
		else		
			WUMA.ScheduleUserFileUpdate(user,Loadout, function(tbl) 
				tbl:RemoveWeapon(item)
				
				return tbl
			end, function()
				if (user:HasLoadout()) then
					WUMA.RefreshLoadout(user)
				end
			end)
			
		end
		
	end
		
end

function WUMA.ClearUserLoadout(users)
	users = WUMA.UserToTable(users)

	for _,user in pairs(users) do
		user:ClearLoadout()
		
		WUMA.ScheduleUserFileUpdate(user,Loadout, function(tbl) 
			tbl = false
				
			return tbl
		end, function()
			WUMA.RefreshUsergroupLoadout(user)
		end)
	end
	
end

function WUMA.GiveDefaultLoadout(user)
	hook.Call( "PlayerLoadout", GAMEMODE, user )
end

function WUMA.GiveLoadout(user)
	if user:HasLoadout() then
		return user:GiveLoadout()
	else
		WUMA.GiveDefaultLoadout(user)
	end
end

function WUMA.AssignLoadout(user)
	if not(WUMA.Loadouts[user:GetUserGroup()]) then return end
	
	user:SetLoadout(WUMA.Loadouts[user:GetUserGroup()]:Clone())
end

function WUMA.RefreshLoadout(user)
	user:ClearLoadout()
	WUMA.AssignLoadout(user)
	WUMA.AssignUserLoadout(user)
	WUMA.GiveLoadout(user)
end

function WUMA.RefreshUserLoadout(user)
	user:ClearLoadout()
	WUMA.AssignUserLoadout(user)
	WUMA.GiveLoadout(user)
end

function WUMA.RefreshUsergroupLoadout(user)
	user:ClearLoadout()
	WUMA.AssignLoadout(user)
	WUMA.GiveLoadout(user)
end