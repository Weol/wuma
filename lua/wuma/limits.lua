
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
WUMA.Limits = WUMA.Limits or {}
 
function WUMA.LoadLimits()
	local saved, tbl = WUMA.GetSavedLimits() or {}, {}

	for k,v in pairs(saved) do
		tbl[v:GetID()] = v
	end
	
	WUMA.Limits = tbl
end

function WUMA.GetSavedLimits(user)
	local tbl = {}
	
	if (user) then
		tbl = WUMA.ReadUserLimits(user)
	else
		saved = util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."limits.txt")) or {} 

		for key,obj in pairs(saved) do
			if istable(obj) then
				obj.parent = user
				tbl[key] = Limit:new(obj)
			end
		end
	end
	
	return tbl
end

function WUMA.ReadUserLimits(user)
	local tbl = {}
	
	saved = util.JSONToTable(WUMA.Files.Read(WUMA.GetUserFile(user,Limit))) or {}
		
	for key,obj in pairs(saved) do
		obj.parent = user
		tbl[key] = Limit:new(obj)
	end 
	
	return tbl
end

function WUMA.GetLimits(user)
	if user and not isstring(user) then
		return user:GetLimits()
	elseif user and isstring(user) then
		return WUMA.Limits[user]
	else
		return WUMA.Limits
	end
end

function WUMA.HasLimit(usergroup,item)
	if isstring(usergroup) then
		if WUMA.GetSavedLimits()[Limit:GenerateID(usergroup,item)] then return true end
	else
		if WUMA.GetSavedLimits()[usergroup:GetID()] then return true end
	end 
	return false
end

function WUMA.AddLimit(caller,usergroup,item,limit,exclusive,scope)

	if (item == limit) then return false end
	if (tonumber(item) != nil) then return false end

	local limit = Limit:new({string=item,usergroup=usergroup,limit=limit,exclusive=exclusive,scope=scope})

	WUMA.Limits[limit:GetID()] = limit
	
	local affected = WUMA.UpdateUsergroup(usergroup,function(user)
		user:AddLimit(limit:Clone())
	end)
	
	WUMA.AddClientUpdate(Limit,function(tbl)
		tbl[limit:GetID()] = limit:GetBarebones()
		
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Limit, function(tbl)
		tbl[limit:GetID()] = limit:GetBarebones()
		
		return tbl
	end)

end

function WUMA.RemoveLimit(caller,usergroup,item)
	local id = Limit:GenerateID(usergroup,item)
	
	if not WUMA.Limits[id] then return false end
	
	WUMA.Limits[id] = nil

	local affected = WUMA.UpdateUsergroup(usergroup,function(user)
		user:RemoveLimit(Limit:GenerateID(_,item))
	end)

	WUMA.AddClientUpdate(Limit,function(tbl)
		tbl[id] = WUMA.DELETE
		
		return tbl
	end)
	
	WUMA.ScheduleDataFileUpdate(Limit, function(tbl)
		tbl[id] = nil
		
		return tbl
	end)
end

function WUMA.AddUserLimit(caller,user,item,limit,exclusive,scope)

	if (item == limit) then return false end
	if (tonumber(item) != nil) then return false end
	
	local limit = Limit:new({string=item,limit=limit,exclusive=exclusive,scope=scope})

	if isentity(user) then
		user:AddLimit(limit)
		
		user = user:SteamID()
	end
	
	WUMA.AddClientUpdate(Limit,function(tbl)
		tbl[limit:GetID()] = limit:GetBarebones()
		
		return tbl
	end,user)
	
	WUMA.ScheduleUserFileUpdate(user,Limit, function(tbl)
		tbl[limit:GetID()] = limit:GetBarebones()
		
		return tbl
	end)
	
end

function WUMA.RemoveUserLimit(caller,user,item)
	local id = Limit:GenerateID(_,item)
	
	if isstring(user) and WUMA.GetUsers()[user] then user = WUMA.GetUsers()[user] end
	if isentity(user) then
		user:RemoveLimit(id, true)
		
		user = user:SteamID()
	end
	
	WUMA.AddClientUpdate(Limit,function(tbl)
		tbl[id] = WUMA.DELETE
		
		return tbl
	end,user)
		
	WUMA.ScheduleUserFileUpdate(user,Limit, function(tbl)
		tbl[id] = nil
			
		return tbl
	end)
end

function WUMA.AssignLimits(user, usergroup)
	for _,object in pairs(WUMA.Limits) do
		if (object:GetUserGroup() == (usergroup or user:GetUserGroup())) then
			user:AddLimit(object:Clone())
		end
	end
end

function WUMA.RefreshGroupLimits(user, usergroup)
	for k,v in pairs(user:GetLimits()) do
		if not v:IsPersonal() then
			user:RemoveLimit(v:GetID(true))
	 	end
	end
	
	WUMA.AssignLimits(user, usergroup)
end

