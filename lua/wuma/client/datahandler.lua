
WUMA = WUMA or {}
WUMA.ServerGroups = WUMA.ServerGroups or {}
WUMA.ServerUsers = WUMA.ServerUsers or {}
WUMA.LookupUsers = WUMA.LookupUsers or {}
WUMA.UserData = WUMA.UserData or {}
WUMA.Restrictions = WUMA.Restrictions or {}
WUMA.Limits = WUMA.Limits or {}
WUMA.Loadouts = WUMA.Loadouts or {}
WUMA.Maps = WUMA.Maps or {}

//Hooks
WUMA.USERGROUPSUPDATE = "WUMAUserGroupsUpdate"
WUMA.LOOKUPUSERSUPDATE = "WUMALookupUsersUpdate"
WUMA.SERVERUSERSUPDATE = "WUMAServerUsersUpdate"
WUMA.USERDATAUPDATE = "WUMAUserDataUpdate"
WUMA.MAPSUPDATE = "WUMAMapsUpdate"

WUMA.RESTRICTIONUPDATE = "WUMARestrictionUpdate"
WUMA.LIMITUPDATE = "WUMALimitUpdate"
WUMA.LOADOUTUPDATE = "WUMALoadoutUpdate"

--Data update
function WUMA.ProcessDataUpdate(id,data)
	WUMADebug("Process Data Update: (%s)",id)
	
	if (id == Restriction:GetID()) then
		WUMA.UpdateRestrictions(data)
	end
		
	if (id == Limit:GetID()) then
		WUMA.UpdateLimits(data)
	end
		
	if (id == Loadout:GetID()) then
		WUMA.UpdateLoadouts(data)
	end
	
end

--Data update
function WUMA.ProcessCompressedData(id,data)
	WUMADebug("Processing compressed data. Size: %s",data:len())

	uncompressed_data = util.Decompress(data)
	if not uncompressed_data then
		WUMADebug("Failed to uncompress data! Size: %s",string.len(data)) 
		return
	end 
	WUMADebug("Data sucessfully decompressed. Size: %s",string.len(uncompressed_data))
	
	tbl = util.JSONToTable(uncompressed_data)

	WUMA.ProcessDataUpdate(id, tbl)
	
end

function WUMA.UpdateRestrictions(update)

	for id, tbl in pairs(update) do
		if istable(tbl) then 
			tbl = Restriction:new(tbl)	
		end
		WUMA.Restrictions[id] = tbl		
	end
	
	if WUMA.GUI.Tabs.Restrictions then
		WUMA.GUI.Tabs.Restrictions:UpdateDataTable(WUMA.Restrictions)
	end
	
	for id, data in pairs(WUMA.Restrictions) do
		if not istable(data) then data = nil end
	end
	
	hook.Call(WUMA.RESTRICTIONUPDATE, update)
end

function WUMA.UpdateLimits(update)

end

function WUMA.UpdateLoadouts(update)

	
end

--Information update
function WUMA.ProcessInformationUpdate(enum,data)
	WUMADebug("Process Information Update:")

	if WUMA.NET.ENUMS[enum] then
		WUMA.NET.ENUMS[enum](data)
	else	
		WUMADebug("NET STREAM enum not found! (%s)",tostring(enum))
	end
end