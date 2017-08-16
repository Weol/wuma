
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
local DataID = "WUMAInheritance"

WUMA.Inheritance = {}

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
	
	WUMA.Inheritance[enum][target] = usergroup
	
	WUMA.GetAuthorizedUsers(function(users) WUMA.NET.INHERITANCE:Send(users) end)
	
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
	
	WUMA.ScheduleDataUpdate(DataID, function(tbl) 
		if tbl[enum] then 
			tbl[enum][target] = nil 
			if (table.Count(tbl[enum]) < 1) then tbl[enum] = nil end
		end
		return tbl
	end)
end

function WUMA.GetUsergroupInheritance(enum, target)
	if not WUMA.Inheritance[enum] then return end
	return WUMA.Inheritance[enum][target]
end

function WUMA.GetAllInheritances() 
	return WUMA.Inheritance
end

WUMA.RegisterDataID(DataID, "inheritance.txt", WUMA.GetSavedInheritance)