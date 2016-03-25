
TIIP = TIIP or {}
TIIP.Limits = TIIP.Limits or {}
 
function TIIP.LoadLimits()
	local saved, tbl = TIIP.GetSavedLimits() or {}, {}

	for k,v in pairs(saved) do
		if v.usergroup then
			tbl[v.usergroup] = tbl[v.usergroup] or {}
			if v.string then
				tbl[v.usergroup][v.string] = v
			end
		end
	end
	
	TIIP.Limits = tbl
end

function TIIP.GetSavedLimits(user)
	local tbl = {}
	
	if (user) then
		saved = util.JSONToTable(TIIP.Files.Read(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user).."limit.txt")) or {}
		
		for key,obj in pairs(saved) do
			obj.parent = user
			tbl[key] = Limit:new(obj)
		end 
	else
		saved = util.JSONToTable(TIIP.Files.Read(TIIP.DataDirectory.."limits.txt")) or {} 

		for key,obj in pairs(saved) do
			tbl[key] = Limit:new(obj)
		end
	end
	
	return tbl
end

function TIIP.GetLimits(user)
	if user and not isstring(user) then
		return user:GetLimits()
	elseif user and isstring(user) then
		return TIIP.Limits[user]
	else
		return TIIP.Limits
	end
end

function TIIP.AddLimit(usergroup,item,limit)
	local limit = Limit:new({string=item,usergroup=usergroup,limit=limit})
	
	TIIP.Limits[usergroup] = TIIP.Limits[usergroup] or {}
	TIIP.Limits[usergroup][item] = limit
	
	TIIP.UpdateUsergroup(usergroup,function(user)
		user:AddLimit(limit:Clone())
	end )
	
	TIIP.ScheduleDataFileUpdate(Limit, function(tbl)
		tbl[limit:GetID()] = limit
		
		return tbl
	end)

end

function TIIP.RemoveLimit(usergroup,item)
	if not TIIP.Limits[usergroup] then return end
	if not TIIP.Limits[usergroup][item] then return end
	
	TIIP.Limits[usergroup][item] = nil

	TIIP.UpdateUsergroup(usergroup,function(user)
		user:RemoveLimit(Limit:GenerateID(item))
	end )
	
	TIIP.ScheduleDataFileUpdate(Limit, function(tbl)
		tbl[Limit:GenerateID(item)] = nil
		
		return tbl
	end)
end

function TIIP.AddUserLimit(users,item,limit)
	local limit = Limit:new({string=item,limit=limit})

	for _,user in pairs(users) do
		user:AddLimit(limit)
		
		TIIP.ScheduleUserFileUpdate(user,Limit, function(tbl)
			tbl[limit:GetID()] = limit
			
			return tbl
		end)
	end
	
end

function TIIP.RemoveUserLimit(users,item)
	local id = Limit:GenerateID(item)
	
	for _,user in pairs(users) do
		user:RemoveLimit(id)
		
		TIIP.ScheduleUserFileUpdate(user,Limit, function(tbl)
			tbl[id] = nil
			
			return tbl
		end)
	end
end

function TIIP.AssignLimits(user)
	if not(TIIP.Limits[user:GetUserGroup()]) then return end
		
	for _,object in pairs(TIIP.Limits[user:GetUserGroup()]) do
		user:AddLimit(object:Clone())
	end
end

