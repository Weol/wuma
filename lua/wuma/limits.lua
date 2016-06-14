
WUMA = WUMA or {}
WUMA.Limits = WUMA.Limits or {}
 
function WUMA.LoadLimits()
	local saved, tbl = WUMA.GetSavedLimits() or {}, {}

	for k,v in pairs(saved) do
		if v.usergroup then
			tbl[v.usergroup] = tbl[v.usergroup] or {}
			if v.string then
				tbl[v.usergroup][v.string] = v
			end
		end
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
			tbl[key] = Limit:new(obj)
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

function WUMA.AddLimit(usergroup,item,limit)
	local limit = Limit:new({string=item,usergroup=usergroup,limit=limit})
	
	WUMA.Limits[usergroup] = WUMA.Limits[usergroup] or {}
	WUMA.Limits[usergroup][item] = limit
	
	WUMA.UpdateUsergroup(usergroup,function(user)
		user:AddLimit(limit:Clone())
	end)
	
	WUMA.ScheduleDataFileUpdate(Limit, function(tbl)
		tbl[limit:GetID()] = limit
		
		return tbl
	end)

end

function WUMA.RemoveLimit(usergroup,item)
	if not WUMA.Limits[usergroup] then return end
	if not WUMA.Limits[usergroup][item] then return end
	
	WUMA.Limits[usergroup][item] = nil

	WUMA.UpdateUsergroup(usergroup,function(user)
		user:RemoveLimit(Limit:GenerateID(item))
	end)
	
	WUMA.ScheduleDataFileUpdate(Limit, function(tbl)
		tbl[Limit:GenerateID(item)] = WUMA.EMPTY
		
		return tbl
	end)
end

function WUMA.AddUserLimit(users,item,limit)
	local limit = Limit:new({string=item,limit=limit})
	users = WUMA.UserToTable(users)
	
	for _,user in pairs(users) do
		user:AddLimit(limit)
		
		WUMA.ScheduleUserFileUpdate(user,Limit, function(tbl)
			tbl[limit:GetID()] = limit
			
			return tbl
		end)
	end
	
end

function WUMA.RemoveUserLimit(users,item)
	local id = Limit:GenerateID(item)
	users = WUMA.UserToTable(users)
	
	for _,user in pairs(users) do
		user:RemoveLimit(id)
		
		WUMA.ScheduleUserFileUpdate(user,Limit, function(tbl)
			tbl[id] = WUMA.EMPTY
			
			return tbl
		end)
	end
end

function WUMA.AssignLimits(user)
	if not(WUMA.Limits[user:GetUserGroup()]) then return end
		
	for _,object in pairs(WUMA.Limits[user:GetUserGroup()]) do
		user:AddLimit(object:Clone())
	end
end

function WUMA.RefreshGroupLimits(user)
	for k,v in pairs(user:GetLimits()) do
		if not v:IsPersonal() then
			user:RemoveLimit(v:GetID())
	 	end
	end
	
	WUMA.AssignLimits(user)
end

