
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
local DataID = "WUMAInheritance"

WUMA.Inheritance = WUMA.Inheritance or {}

function WUMA.GetSavedInheritance() 
	local inheritance = {}
	if WUMA.Files.Exists(WUMA.DataDirectory.."inheritance.txt") then
		inheritance = util.JSONToTable(WUMA.Files.Read(WUMA.DataDirectory.."inheritance.txt")) or {}
	end
	return inheritance
end

function WUMA.LoadInheritance()
	WUMA.Inheritance = WUMA.GetSavedInheritance() 
end

function WUMA.SetUsergroupInheritance(enum, target, usergroup)
	WUMA.Inheritance[enum] = WUMA.Inheritance[enum] or {}
	
	if table.HasValue(WUMA.GetInheritanceTree(enum, target), usergroup) then return end 
	
	WUMA.Inheritance[enum][target] = usergroup
	
	WUMA.GetAuthorizedUsers(function(users) WUMA.GetStream("inheritance"):Send(users) end)
	
	WUMA.UpdateUsergroup(target, function(user) 
		if (enum == Restriction:GetID()) then
			WUMA.RefreshGroupRestrictions(user, target)
		elseif (enum == Limit:GetID()) then
			WUMA.RefreshGroupLimits(user, target)
		elseif (enum == Loadout:GetID()) then
			WUMA.RefreshUsergroupLoadout(user, target)
		end
	end)
			
	local function recursive(heirs) 
		for _, heir in pairs(heirs) do
			WUMA.UpdateUsergroup(heir, function(user) 
				if (enum == Restriction:GetID()) then
					WUMA.RefreshGroupRestrictions(user, heir)
				elseif (enum == Limit:GetID()) then
					WUMA.RefreshGroupLimits(user, heir)
				elseif (enum == Loadout:GetID()) then
					WUMA.RefreshUsergroupLoadout(user, heir)
				end
			end)
			recursive(WUMA.GetUsergroupHeirs(enum, heir))
		end
	end
	recursive(WUMA.GetUsergroupHeirs(enum, target))
	
	WUMA.ScheduleDataUpdate(DataID, function(tbl) 
		tbl[enum] = tbl[enum] or {}
		tbl[enum][target] = usergroup
		return tbl
	end)
end

function WUMA.UnsetUsergroupInheritance(enum, target)
	if not WUMA.Inheritance[enum] then return end
	
	WUMA.Inheritance[enum][target] = nil
	if (table.Count(WUMA.Inheritance[enum]) < 1) then WUMA.Inheritance[enum] = nil end
	
	WUMA.UpdateUsergroup(target, function(user) 
		if (enum == Restriction:GetID()) then
			WUMA.RefreshGroupRestrictions(user, target)
		elseif (enum == Limit:GetID()) then
			WUMA.RefreshGroupLimits(user, target)
		elseif (enum == Loadout:GetID()) then
			WUMA.RefreshUsergroupLoadout(user, target)
		end
	end)
			
	local function recursive(heirs) 
		for _, heir in pairs(heirs) do
			WUMA.UpdateUsergroup(heir, function(user) 
				if (enum == Restriction:GetID()) then
					WUMA.RefreshGroupRestrictions(user, heir)
				elseif (enum == Limit:GetID()) then
					WUMA.RefreshGroupLimits(user, heir)
				elseif (enum == Loadout:GetID()) then
					WUMA.RefreshUsergroupLoadout(user, heir)
				end
			end)
			recursive(WUMA.GetUsergroupHeirs(enum, heir))
		end
	end
	recursive(WUMA.GetUsergroupHeirs(enum, target))
	
	WUMA.ScheduleDataUpdate(DataID, function(tbl) 
		if tbl[enum] then 
			tbl[enum][target] = nil 
			if (table.Count(tbl[enum]) < 1) then tbl[enum] = nil end
		end
		return tbl
	end)
end

function WUMA.GetUsergroupAncestor(enum, target)
	if not WUMA.Inheritance[enum] then return end
	return WUMA.Inheritance[enum][target]
end

function WUMA.GetUsergroupHeirs(enum, usergroup)
	local tbl = {}
	for heir, ancestor in pairs(WUMA.Inheritance[enum] or {}) do
		if (ancestor == usergroup) then
			table.insert(tbl, heir)
		end
	end
	return tbl
end 

function WUMA.GetInheritanceTree(enum, usergroup) 
	local tbl = {}

	for _, heir in pairs(WUMA.GetUsergroupHeirs(enum, usergroup)) do
		table.insert(tbl, heir)
		
		local heirs = WUMA.GetUsergroupHeirs(enum, heir)
		if (table.Count(heirs) > 0) then
			table.Add(tbl, WUMA.GetInheritanceTree(enum, heir))
		end
	end
	
	return tbl
end

function WUMA.GetAllInheritances() 
	return WUMA.Inheritance
end

WUMA.RegisterDataID(DataID, "inheritance.txt", WUMA.GetSavedInheritance, WUMA.isTableEmpty)