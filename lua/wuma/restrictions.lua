
WUMA = WUMA or {}
WUMA.Restrictions = WUMA.Restrictions or {}
 
function WUMA.LoadRestrictions()
	local saved, tbl = WUMA.GetSavedRestrictions() or {}, {}

	for k,v in pairs(saved) do
		tbl[v:GetID()] = v
	end
	
	WUMA.Restrictions = tbl
end

function WUMA.GetSavedRestrictions(user)
	local tbl = {}
	
	if (user) then
		tbl = WUMA.ReadUserRestrictions(user)
	else
		saved = WUMA.GetCachedData(Restriction) or util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."restrictions.txt")) or {} 
		
		for key,obj in pairs(saved) do
			if istable(obj) then
				tbl[key] = Restriction:new(obj)
			else
				WUMADebug("%s has been marked %s",key,obj)
			end
		end
	end

	return tbl
end

function WUMA.ReadUserRestrictions(user)
	local tbl = {}
	
	saved = WUMA.GetCachedUserData(user,Restriction) or util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user,Restriction))) or {}
		
	for key,obj in pairs(saved) do
		obj.parent = user
		tbl[key] = Restriction:new(obj)
	end 
	
	return tbl
end

function WUMA.GetRestrictions(user)
	if user and not isstring(user) then
		return user:GetRestrictions()
	elseif user and isstring(user) then
		return WUMA.Restrictions[user]
	else
		return WUMA.Restrictions
	end
end

function WUMA.HasRestriction(usergroup,type,item)
	if isstring(usergroup) then
		if WUMA.GetSavedRestrictions()[Restriction:GenerateID(type,usergroup,item)] then return true end
	else
		if WUMA.GetSavedRestrictions()[usergroup:GetID()] then return true end
	end 
	return false
end

function WUMA.AddRestriction(caller,usergroup,type,item,anti,scope)

	WUMADebug("Huh")

	local restriction = Restriction:new({type=type,string=item,usergroup=usergroup,allow=anti,scope=scope})
	
	WUMA.Restrictions[usergroup] = WUMA.Restrictions[usergroup] or {}
	WUMA.Restrictions[usergroup][type] = WUMA.Restrictions[usergroup][type] or {}
	WUMA.Restrictions[usergroup][type][item] = restriction
	
	WUMA.UpdateUsergroup(usergroup,function(ply)
		ply:AddRestriction(restriction:Clone())
	end)
	
	WUMA.ScheduleClientUpdate(Restriction,function(tbl)
		tbl[restriction:GetID()] = restriction:GetBarebones()
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Restriction, function(tbl)
		tbl[restriction:GetID()] = restriction:GetBarebones()
		return tbl
	end)

end

function WUMA.RemoveRestriction(caller,usergroup,type,item)
	if not WUMA.Restrictions[usergroup] then return end
	if not WUMA.Restrictions[usergroup][type] then return end
	if not WUMA.Restrictions[usergroup][type][item] then return end
	 
	WUMA.Restrictions[usergroup][type][item] = nil

	WUMA.UpdateUsergroup(usergroup,function(ply)
		ply:RemoveRestriction(Restriction:GenerateID(type,usergroup,item))
	end)
	
	WUMA.ScheduleClientUpdate(Restriction,function(tbl)
		tbl[Restriction:GenerateID(type,usergroup,item)] = WUMA.DELETE
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Restriction, function(tbl)
		tbl[Restriction:GenerateID(type,usergroup,item)] = nil
		
		return tbl
	end)
end

function WUMA.AddUserRestriction(caller,users,type,item)
	local restriction = Restriction:new({type=type,string=item})
	users = WUMA.UserToTable(users)
	
	for _,user in pairs(users) do
		user:AddRestriction(restriction)
		
		WUMA.ScheduleUserFileUpdate(user,Restriction, function(tbl)
			tbl[restriction:GetID()] = restriction
			
			return tbl
		end)
	end
	
end

function WUMA.RemoveUserRestriction(caller,users,type,item)
	local id = Restriction:GenerateID(type,item)
	users = WUMA.UserToTable(users)
	
	for _,user in pairs(users) do
		user:RemoveRestriction(id,true)
		
		WUMA.ScheduleUserFileUpdate(user,Restriction, function(tbl)
			tbl[id] = nil
			
			return tbl
		end)
	end
end

function WUMA.AssignRestrictions(user)
	if not(WUMA.Restrictions[user:GetUserGroup()]) then return end
		
	for _,types in pairs(WUMA.Restrictions[user:GetUserGroup()]) do
		for _,object in pairs(types) do
			user:AddRestriction(object:Clone())
		end
	end
end

function WUMA.RefreshGroupRestrictions(user)
	for k,v in pairs(user:GetRestrictions()) do
		if v:GetUsergroup() then
			user:RemoveRestriction(v:GetID())
	 	end
	end
	
	WUMA.AssignRestrictions(user)
end

