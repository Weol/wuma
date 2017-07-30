
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
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
		saved =util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."restrictions.txt")) or {} 
		
		for key,obj in pairs(saved) do
			if istable(obj) then
				tbl[key] = Restriction:new(obj)
			end
		end
	end

	return tbl
end

function WUMA.ReadUserRestrictions(user)
	if not isstring(user) then user = user:SteamID() end

	local tbl = {}
	
	saved = util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user,Restriction))) or {}
		
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

function WUMA.RestrictionsExist() 
	if (table.Count(WUMA.Restrictions) > 0) then return true end
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

	local restriction = Restriction:new({type=type,string=item,usergroup=usergroup,allow=anti,scope=scope})
	
	WUMA.Restrictions[restriction:GetID()] = restriction
	
	local affected = WUMA.UpdateUsergroup(usergroup,function(ply)
		ply:AddRestriction(restriction:Clone())
	end)
	
	WUMA.AddClientUpdate(Restriction,function(tbl)
		tbl[restriction:GetID()] = restriction:GetBarebones()
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Restriction, function(tbl)
		tbl[restriction:GetID()] = restriction:GetBarebones()
		return tbl
	end)

	return affected
	
end

function WUMA.RemoveRestriction(caller,usergroup,type,item)
 
	WUMA.Restrictions[Restriction:GenerateID(type,usergroup,item)]:Delete()
	WUMA.Restrictions[Restriction:GenerateID(type,usergroup,item)] = nil

	local affected = WUMA.UpdateUsergroup(usergroup,function(ply)
		ply:RemoveRestriction(Restriction:GenerateID(type,_,item))
	end)
	
	WUMA.AddClientUpdate(Restriction,function(tbl)
		tbl[Restriction:GenerateID(type,usergroup,item)] = WUMA.DELETE
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Restriction, function(tbl)
		tbl[Restriction:GenerateID(type,usergroup,item)] = nil
		
		return tbl
	end)
	
	return affected
end

function WUMA.AddUserRestriction(caller,user,type,item,anti,scope)
	local restriction = Restriction:new({type=type,string=item,allow=anti,scope=scope})
	
	if isentity(user) then
		user:AddRestriction(restriction)
		
		user = user:SteamID()
	end
		
	WUMA.AddClientUpdate(Restriction,function(tbl)
		tbl[restriction:GetID()] = restriction
		
		return tbl
	end, user)	
	
	WUMA.ScheduleUserFileUpdate(user,Restriction, function(tbl)
		tbl[restriction:GetID()] = restriction
		
		return tbl
	end)
	
end

function WUMA.RemoveUserRestriction(caller,user,type,item)
	local id = Restriction:GenerateID(type,_,item)
	
	if isstring(user) and WUMA.GetUsers()[user] then user = WUMA.GetUsers()[user] end
	if isentity(user) then
		user:RemoveRestriction(id,true)
		
		user = user:SteamID()
	end
	
	WUMA.AddClientUpdate(Restriction,function(tbl)
		tbl[id] = WUMA.DELETE
		
		return tbl
	end, user)
	
	WUMA.ScheduleUserFileUpdate(user,Restriction, function(tbl)
		tbl[id] = nil
		
		return tbl
	end)

end

function WUMA.RefreshGroupRestrictions(user,usergroup)
	for k,v in pairs(user:GetRestrictions() or {}) do
		if v:GetUserGroup() then
			user:RemoveRestriction(v:GetID(true))
	 	end
	end
	
	WUMA.AssignRestrictions(user,usergroup)
end

