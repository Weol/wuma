
TIIP = TIIP or {}
TIIP.Loadouts = TIIP.Loadouts or {}
 
function TIIP.LoadLoadouts()
	local saved, tbl = TIIP.GetSavedLoadouts() or {}, {}

	for k,v in pairs(saved) do
		if v.usergroup then
			tbl[v.usergroup] = tbl[v.usergroup] or {}
			if v.string then
				tbl[v.usergroup][v.string] = v
			end
		end
	end
	
	TIIP.Loadouts = tbl
end

function TIIP.GetSavedLoadouts(user)
	local tbl = {}
	
	if (user) then
		saved = util.JSONToTable(TIIP.Files.Read(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user).."loadout.txt")) or {}
		
		for key,obj in pairs(saved) do
			obj.parent = user
			tbl[key] = Loadout:new(obj)
		end 
	else
		saved = util.JSONToTable(TIIP.Files.Read(TIIP.DataDirectory.."loadouts.txt")) or {} 

		for key,obj in pairs(saved) do
			tbl[key] = Loadout:new(obj)
		end
	end
	
	return tbl
end

function TIIP.GetLoadouts(user)
	if user and not isstring(user) then
		return user:GetLoadouts()
	elseif user and isstring(user) then
		return TIIP.Loadouts[user]
	else
		return TIIP.Loadouts
	end
end

function TIIP.AddLoadout(usergroup,item,Loadout)
	local Loadout = Loadout:new({string=item,usergroup=usergroup,Loadout=Loadout})
	
	TIIP.Loadouts[usergroup] = TIIP.Loadouts[usergroup] or {}
	TIIP.Loadouts[usergroup][item] = Loadout
	
	TIIP.UpdateUsergroup(usergroup,function(user)
		user:AddLoadout(Loadout:Clone())
	end )
	
	TIIP.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[Loadout:GetID()] = Loadout
		
		return tbl
	end)

end

function TIIP.RemoveLoadout(usergroup,item)
	if not TIIP.Loadouts[usergroup] then return end
	if not TIIP.Loadouts[usergroup][item] then return end
	
	TIIP.Loadouts[usergroup][item] = nil

	TIIP.UpdateUsergroup(usergroup,function(user)
		user:RemoveLoadout(Loadout:GenerateID(item))
	end )
	
	TIIP.ScheduleDataFileUpdate(Loadout, function(tbl)
		tbl[Loadout:GenerateID(item)] = nil
		
		return tbl
	end)
end

function TIIP.AddUserLoadout(users,item,Loadout)
	local Loadout = Loadout:new({string=item,Loadout=Loadout})

	for _,user in pairs(users) do
		user:AddLoadout(Loadout)
		
		TIIP.ScheduleUserFileUpdate(user,Loadout, function(tbl)
			tbl[Loadout:GetID()] = Loadout
			
			return tbl
		end)
	end
	
end

function TIIP.RemoveUserLoadout(users,item)
	local id = Loadout:GenerateID(item)
	
	for _,user in pairs(users) do
		user:RemoveLoadout(id)
		
		TIIP.ScheduleUserFileUpdate(user,Loadout, function(tbl)
			tbl[id] = nil
			
			return tbl
		end)
	end
end

function TIIP.AssignLoadouts(user)
	if not(TIIP.Loadouts[user:GetUserGroup()]) then return end
		
	for _,object in pairs(TIIP.Loadouts[user:GetUserGroup()]) do
		user:AddLoadout(object:Clone())
	end
end

//--------------------------------------------------------------------------------------------------------------------

TIIP = TIIP or {}

function TIIP.LoadLoadouts()
	local tbl = util.JSONToTable(TIIP.Files.Read("loadouts.txt"))
	if not tbl then
		ServerLog("loadouts.txt returned empty!\n")
		return false
	end
	TIIP.Loadouts = tbl
end

function TIIP.SaveLoadouts()
	TIIP.UpdateTable(TIIP.Loadouts,"TIIPLoadouts")
	local str = util.TableToJSON(TIIP.Loadouts,true)
	TIIP.Files.Write("loadouts.txt",str)
end

function TIIP.AddLoadoutWeapon(group,str,pri,sec)
	TIIP.Loadouts[group] = TIIP.Loadouts[group] or {}
	str = string.lower(str)
	TIIP.Loadouts[group][str] = {primary = pri,secondary = sec}
	TIIP.SaveLoadouts()
end

function TIIP.SetLoadout(group,tbl)
	TIIP.Loadouts[group] = tbl
end

function TIIP.SetLoadoutPrimary(group,str)
	TIIP.Loadouts[group] = TIIP.Loadouts[group] or {}
	if not TIIP.Loadouts[group][str] then return end
	str = string.lower(str)
	
	if (TIIP.Loadouts[group][str].spawn) then
		TIIP.Loadouts[group][str].spawn = nil
		TIIP.SaveLoadouts()
		return  
	end
	
	for class,tbl in pairs(TIIP.Loadouts[group]) do
		if (tbl.spawn) then tbl.spawn = nil end
	end
	
	TIIP.Loadouts[group][str].spawn = true
	TIIP.SaveLoadouts()
end

function TIIP.DeleteLoadout(group)
	TIIP.Loadouts[group] = nil
	TIIP.SaveLoadouts()
end

function TIIP.RemoveLoadoutWeapon(group,str)
	TIIP.Loadouts[group] = TIIP.Loadouts[group] or {}
	str = string.lower(str)
	if TIIP.Loadouts[group][str] then TIIP.Loadouts[group][str] = nil end
	TIIP.SaveLoadouts()
end

function TIIP.SetPlayerLoadout(ply)
	if not TIIP.Loadouts[ply:GetUserGroup()] then return end
	if table.Count(TIIP.Loadouts[ply:GetUserGroup()]) < 1 then return end
	ply:StripWeapons()
	for k,v in pairs(TIIP.Loadouts[ply:GetUserGroup()]) do
		ply:Give(k)
	end
	ply:StripAmmo()
	for k,v in pairs(TIIP.Loadouts[ply:GetUserGroup()]) do
		local weapon = ply:GetWeapon(k)
		if (weapon:GetPrimaryAmmoType() > - 1) or (weapon:GetSecondaryAmmoType() > -1) then
			local primary_default = math.abs((v.primary - weapon:Clip1())-v.primary)
			local secondary_default = math.abs((v.secondary - weapon:Clip1())-v.secondary)
			if (v.primary <= primary_default) then
				ply:GetWeapon(k):SetClip1(math.abs(v.primary))
			else
				local primary = v.primary - primary_default
				if (weapon:GetPrimaryAmmoType() > - 1) then
					ply:GiveAmmo(primary,weapon:GetPrimaryAmmoType())
				end
			end
			
			if (v.secondary <= secondary_default) then
				ply:GetWeapon(k):SetClip2(math.abs(v.secondary))
			else
				local secondary = v.secondary - secondary_default
				if (weapon:GetSecondaryAmmoType() > -1) then			
					ply:GiveAmmo(secondary,weapon:GetSecondaryAmmoType())
				end
			end
		end
		if v.spawn then
			ply:SelectWeapon(k)
		end
	end
	return false
end