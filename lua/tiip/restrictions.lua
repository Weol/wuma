
TIIP = TIIP or {}
TIIP.Restrictions = TIIP.Restrictions or {}
 
function TIIP.LoadRestrictions()
	local saved, tbl = TIIP.GetSavedRestrictions() or {}, {}

	for k,v in pairs(saved) do
		if v.usergroup then
			tbl[v.usergroup] = tbl[v.usergroup] or {}
			if v.type then
				tbl[v.usergroup][v.type] = tbl[v.usergroup][v.type] or {}
				if v.string then
					tbl[v.usergroup][v.type][v.string] = v
				end
			end
		end
	end
	
	TIIP.Restrictions = tbl
end

function TIIP.GetSavedRestrictions(user)
	local tbl = {}
	
	if (user) then
		saved = util.JSONToTable(TIIP.Files.Read(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user).."restrictions.txt")) or {}
		
		for key,obj in pairs(saved) do
			obj.parent = user
			tbl[key] = Restriction:new(obj)
		end 
	else
		saved = util.JSONToTable(TIIP.Files.Read(TIIP.DataDirectory.."restrictions.txt")) or {} 

		for key,obj in pairs(saved) do
			tbl[key] = Restriction:new(obj)
		end
	end
	
	return tbl
end

function TIIP.GetRestrictions(user)
	if user and not isstring(user) then
		return user:GetRestrictions()
	elseif user and isstring(user) then
		return TIIP.Restrictions[user]
	else
		return TIIP.Restrictions
	end
end

function TIIP.AddRestriction(usergroup,type,item)
	local restriction = Restriction:new({type=type,string=item,usergroup=usergroup})

	TIIP.Restrictions[usergroup] = TIIP.Restrictions[usergroup] or {}
	TIIP.Restrictions[usergroup][type] = TIIP.Restrictions[usergroup][type] or {}
	TIIP.Restrictions[usergroup][type][item] = restriction
	
	TIIP.UpdateUsergroup(usergroup,function(ply)
		ply:AddRestriction(restriction:Clone())
	end )
	
	TIIP.ScheduleDataFileUpdate(Restriction, function(tbl)
		tbl[restriction:GetID()] = restriction
		
		return tbl
	end)

end

function TIIP.RemoveRestriction(usergroup,type,item)
	if not TIIP.Restrictions[usergroup] then return end
	if not TIIP.Restrictions[usergroup][type] then return end
	if not TIIP.Restrictions[usergroup][type][item] then return end
	
	TIIP.Restrictions[usergroup][type][item] = nil

	TIIP.UpdateUsergroup(usergroup,function(ply)
		ply:RemoveRestriction(Restriction:GenerateID(type,item))
	end )
	
	TIIP.ScheduleDataFileUpdate(Restriction, function(tbl)
		tbl[Restriction:GenerateID(type,item)] = nil
		
		return tbl
	end)
end

function TIIP.AddUserRestriction(users,type,item)
	local restriction = Restriction:new({type=type,string=item})

	for _,user in pairs(users) do
		user:AddRestriction(restriction)
		
		TIIP.ScheduleUserFileUpdate(user,Restriction, function(tbl)
			tbl[restriction:GetID()] = restriction
			
			return tbl
		end)
	end
	
end

function TIIP.RemoveUserRestriction(users,type,item)
	local id = Restriction:GenerateID(type,item)
	
	for _,user in pairs(users) do
		user:RemoveRestriction(id)
		
		TIIP.ScheduleUserFileUpdate(user,Restriction, function(tbl)
			tbl[id] = nil
			
			return tbl
		end)
	end
end

function TIIP.AssignRestrictions(user)
	if not(TIIP.Restrictions[user:GetUserGroup()]) then return end
		
	for _,types in pairs(TIIP.Restrictions[user:GetUserGroup()]) do
		for _,object in pairs(types) do
			user:AddRestriction(object:Clone())
		end
	end
end

