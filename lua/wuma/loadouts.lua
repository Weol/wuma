
WUMA = WUMA or {}
WUMA.Loadouts = WUMA.Loadouts or {}

function WUMA.LoadLoadouts()
	local saved, tbl = WUMA.GetSavedLoadouts() or {}, {}

	for k,v in pairs(saved) do
		tbl[v:GetID()] = v
	end
	
	WUMA.Loadouts = tbl
end

function WUMA.GetSavedLoadouts(user)
	local tbl = {}
	
	if (user) then
		tbl = WUMA.ReadUserLoadout(user)
	else
		saved = WUMA.GetCachedData(Loadout) or util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."loadouts.txt")) or {}

		for key,obj in pairs(saved) do
			if istable(obj) then
				tbl[key] = Loadout:new(obj)
			else
				WUMADebug("%s has been marked %s",key,obj)
			end
		end
	end
	
	return tbl
end

function WUMA.ReadUserLoadout(user)
	saved = WUMA.GetCachedUserData(user,Loadout) or util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user,Loadout))) or Loadout:new()
		
	return Loadout:new(saved)
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

function WUMA.SetLoadoutPrimaryWeapon(caller,usergroup,item)
	if not(WUMA.Loadouts[usergroup]) then return WUMADebug("That usergroup has no loadout!") end
	
	WUMA.Loadouts[usergroup]:SetPrimary(item)
	
	WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[usergroup]:SetPrimary(item)

		return tbl
	end)
	
	WUMA.ScheduleClientUpdate(Restriction,function(tbl)
		tbl[usergroup] = WUMA.Loadouts[usergroup]:GetBarebones()
		return tbl
	end)
	
	WUMA.UpdateUsergroup(usergroup,function(user)
		if user:HasLoadout() and not user:GetLoadout():IsPersonal() then
			user:GetLoadout():SetPrimary(item)
		end
	end)
end

function WUMA.AddLoadoutWeapon(caller,usergroup,item,primary,secondary)
	if not(WUMA.Loadouts[usergroup]) then
		WUMA.Loadouts[usergroup] = Loadout:new({usergroup=usergroup})
	else
		if (WUMA.Loadouts[usergroup]:GetWeapon(item).primary == primary) and (WUMA.Loadouts[usergroup]:GetWeapon(item).secondary == secondary) then
			return WUMADebug("This group (%s) already has this weapon in their loadout",usergroup)
		end
	end
	
	WUMA.Loadouts[usergroup]:AddWeapon(item,primary,secondary)
	
	WUMA.ScheduleClientUpdate(Limit,function(tbl)
		tbl[usergroup] = WUMA.Loadouts[usergroup]:GetBarebones()
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[usergroup] = tbl[usergroup] or Loadout:new({usergroup=usergroup})
		tbl[usergroup]:AddWeapon(item,primary,secondary)
		
		return tbl
	end, function() 
		WUMA.UpdateUsergroup(usergroup,function(user)
			WUMA.RefreshLoadout(user)
		end)
	end)
	
end
 
function WUMA.RemoveLoadoutWeapon(caller,usergroup,item)
	if not WUMA.Loadouts[usergroup] then return end
	
	WUMA.Loadouts[usergroup]:RemoveWeapon(item)

	if (WUMA.Loadouts[usergroup]:GetWeaponCount() < 1) then
		WUMA.ClearLoadout(usergroup)
	else
		
		WUMA.ScheduleClientUpdate(Limit,function(tbl)
			tbl[usergroup] = WUMA.Loadouts[usergroup]:GetBarebones()
			return tbl
		end)
			
		WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
			tbl[usergroup]:RemoveWeapon(item)
			
			return tbl
		end, function() 
			WUMA.UpdateUsergroup(usergroup,function(user)
				WUMA.RefreshLoadout(user)
			end)
		end)
	end
	
end

function WUMA.ClearLoadout(caller,usergroup)
	if not WUMA.Loadouts[usergroup] then return end
	
	WUMA.Loadouts[usergroup] = nil
	
	WUMA.ScheduleClientUpdate(Limit,function(tbl)
		tbl[usergroup] = nil
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[usergroup] = nil
		
		return tbl
	end, function()
		WUMA.UpdateUsergroup(usergroup,function(user)
			WUMA.RefreshLoadout(user)
		end)
	end)
	
end

function WUMA.SetUserLoadoutPrimaryWeapon(caller,users,item)
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

function WUMA.AddUserLoadoutWeapon(caller,users,item,primary,secondary)
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

function WUMA.RemoveUserLoadoutWeapon(caller,users,item)
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

function WUMA.ClearUserLoadout(caller,users)
	users = WUMA.UserToTable(users)

	for _,user in pairs(users) do
		user:ClearLoadout()
		
		WUMA.ScheduleUserFileUpdate(user,Loadout, function(tbl) 
			tbl = nil
				
			return tbl
		end, function()
			WUMA.RefreshUsergroupLoadout(user)
		end)
	end
	
end

function WUMA.GiveDefaultLoadout(user)
	hook.Call("PlayerLoadout", GAMEMODE, user)
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