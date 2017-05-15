
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
WUMA.ServerGroups = WUMA.ServerGroups or {}
WUMA.ServerUsers = WUMA.ServerUsers or {}
WUMA.LookupUsers = WUMA.LookupUsers or {}
WUMA.UserData = WUMA.UserData or {}
WUMA.Restrictions = WUMA.Restrictions or {}
WUMA.Limits = WUMA.Limits or {}
WUMA.Loadouts = WUMA.Loadouts or {}
WUMA.Maps = WUMA.Maps or {}
WUMA.ServerSettings = WUMA.ServerSettings or {}
WUMA.ClientSettings = WUMA.ClientSettings or {}

//Hooks
WUMA.USERGROUPSUPDATE = "WUMAUserGroupsUpdate"
WUMA.LOOKUPUSERSUPDATE = "WUMALookupUsersUpdate"
WUMA.SERVERUSERSUPDATE = "WUMAServerUsersUpdate"
WUMA.USERDATAUPDATE = "WUMAUserDataUpdate"
WUMA.MAPSUPDATE = "WUMAMapsUpdate"
WUMA.SETTINGSUPDATE = "WUMASettingsUpdate"

WUMA.RESTRICTIONUPDATE = "WUMARestrictionUpdate"
WUMA.LIMITUPDATE = "WUMALimitUpdate"
WUMA.LOADOUTUPDATE = "WUMALoadoutUpdate"

//CVars
CreateClientConVar("wuma_autounsubscribe", "-1", true, false,"Time in seconds before unsubscribing from data. -1 = Never.")
CreateClientConVar("wuma_autounsubscribe_user", "900", true, false,"Time in seconds before unsubscribing from data. -1 = Never.")
CreateClientConVar("wuma_request_on_join", "0", true, false,"Wether or not to request data on join")

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
	
	local private = string.find(id,":::")
	if private then
		WUMA.UpdateUser(string.sub(id,private+3),string.sub(id,1,private-1),data)
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
	
	local tbl = util.JSONToTable(uncompressed_data)

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
		WUMA.GUI.Tabs.Restrictions:GetDataView():UpdateDataTable(WUMA.Restrictions)
	end
	
	for k, v in pairs(WUMA.Restrictions) do
		if (v == WUMA.DELETE) then
			WUMA.Restrictions[k] = nil
		end
	end
	
	hook.Call(WUMA.RESTRICTIONUPDATE, _, update)
end

function WUMA.UpdateLimits(update)

	for id, tbl in pairs(update) do
		if istable(tbl) then 
			tbl = Limit:new(tbl)		
		end
		WUMA.Limits[id] = tbl	
	end
	
	if WUMA.GUI.Tabs.Limits then
		WUMA.GUI.Tabs.Limits:GetDataView():UpdateDataTable(WUMA.Limits)
	end
	
	for k, v in pairs(WUMA.Limits) do
		if (v == WUMA.DELETE) then
			WUMA.Limits[k] = nil
		end
	end
	
	hook.Call(WUMA.LIMITUPDATE, _, update)

end

function WUMA.UpdateLoadouts(update)

	for id, tbl in pairs(update) do
		if istable(tbl) then 
			tbl = Loadout:new(tbl)
		end
		WUMA.Loadouts[id] = tbl
	end 

	if WUMA.GUI.Tabs.Loadouts then
		local tbl = {}
		for id, loadout in pairs(WUMA.Loadouts) do
			if istable(loadout) then
				for class, wep_tbl in pairs(loadout:GetWeapons()) do
					wep_tbl.class = class
					wep_tbl.usergroup = loadout:GetUserGroup()
					tbl[id.."_"..class] = wep_tbl
				end
				
				if (loadout:GetPrimary() and tbl[id.."_"..loadout:GetPrimary()]) then
					tbl[id.."_"..loadout:GetPrimary()].isprimary = true
				end
			end
		end

		WUMA.GUI.Tabs.Loadouts:GetDataView():SetDataTable(tbl)
	end
	
	for k, v in pairs(WUMA.Loadouts) do	
		if (v == WUMA.DELETE) then
			WUMA.Loadouts[k] = nil
		end
	end
	
	hook.Call(WUMA.LOADOUTUPDATE, _, update)

end

function WUMA.UpdateUser(id, enum, data)
	WUMA.UserData[id] = WUMA.UserData[id] or {}
	
	if (enum == Restriction:GetID()) then
		WUMA.UpdateUserRestrictions(id,data)
	end
		
	if (enum == Limit:GetID()) then
		WUMA.UpdateUserLimits(id,data)
	end
		
	if (enum == Loadout:GetID()) then
		WUMA.UpdateUserLoadouts(id,data)
	end
	
end

function WUMA.UpdateUserRestrictions(user, update)
	WUMA.UserData[user].Restrictions = WUMA.UserData[user].Restrictions or {}

	for id, tbl in pairs(update) do
		if istable(tbl) then 
			tbl = Restriction:new(tbl)	
			tbl.usergroup = user
			tbl.parent = user
		end
		
		WUMA.UserData[user].Restrictions[id] = tbl	
	end

	if WUMA.GUI.Tabs.Users and WUMA.GUI.Tabs.Users.restrictions then
		if (WUMA.GUI.Tabs.Users:GetSelectedUser() == user) then
			WUMA.GUI.Tabs.Users.restrictions:GetDataView():UpdateDataTable(WUMA.UserData[user].Restrictions)
		end
	end
	
	for k, v in pairs(WUMA.UserData[user].Restrictions) do
		if (v == WUMA.DELETE) then
			WUMA.UserData[user].Restrictions[k] = nil
		end
	end
	
	hook.Call(WUMA.USERDATAUPDATE, _, user, Restriction:GetID(), update)
	
end

function WUMA.UpdateUserLimits(user, update)
	WUMA.UserData[user].Limits = WUMA.UserData[user].Limits or {}

	for id, tbl in pairs(update) do
		if istable(tbl) then 
			tbl = Limit:new(tbl)	
			tbl.parent = user
			tbl.usergroup = user
		end
		
		WUMA.UserData[user].Limits[id] = tbl	
	end
	
	if WUMA.GUI.Tabs.Users and WUMA.GUI.Tabs.Users.limits then
		if (WUMA.GUI.Tabs.Users:GetSelectedUser() == user) then
			WUMA.GUI.Tabs.Users.limits:GetDataView():UpdateDataTable(WUMA.UserData[user].Limits)
		end
	end
	
	for k, v in pairs(WUMA.UserData[user].Limits) do
		if (v == WUMA.DELETE) then
			WUMA.UserData[user].Limits[k] = nil
		end
	end

	hook.Call(WUMA.USERDATAUPDATE, _, user, Limit:GetID(), update)
	
end

function WUMA.UpdateUserLoadouts(user, update)
	WUMA.UserData[user].Loadouts = WUMA.UserData[user].Loadouts or {}
	
	hook.Call(WUMA.USERDATAUPDATE, _, user, Loadout:GetID(), update)

	if istable(update) and (update[1] ~= WUMA.DELETE) then
		update = Loadout:new(update)
		WUMA.UserData[user].Loadouts = update
		
		if WUMA.GUI.Tabs.Users and WUMA.GUI.Tabs.Users.loadouts and (WUMA.GUI.Tabs.Users:GetSelectedUser() == user) then
			local tbl = {}
			for class, weapon in pairs(update:GetWeapons()) do
				tbl[class] = {}
				for k, v in pairs(weapon) do
					tbl[class][k] = v 
				end
				tbl[class].parent = user
				tbl[class].usergroup = user
			end
			
			if (update:GetPrimary() and tbl[update:GetPrimary()]) then
				tbl[update:GetPrimary()].isprimary = true
			end

			WUMA.GUI.Tabs.Users.loadouts:GetDataView():SetDataTable(tbl)
		end
	else
		if WUMA.GUI.Tabs.Users and WUMA.GUI.Tabs.Users.loadouts and (WUMA.GUI.Tabs.Users:GetSelectedUser() == user) then
			WUMA.GUI.Tabs.Users.loadouts:GetDataView():SetDataTable({})
		end
	
		WUMA.UserData[user].Loadouts = nil
	end
	
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

function WUMA.RecievePushNotification(data) 

end

local DisregardSettingsChange = false
function WUMA.UpdateSettings(settings)
	DisregardSettingsChange = true
	
	if (WUMA.GUI.Tabs.Settings) then
		WUMA.GUI.Tabs.Settings:UpdateSettings(settings)
	end
	
	DisregardSettingsChange = false
end
hook.Add(WUMA.SETTINGSUPDATE,"WUMAGUISettings",function(settings) WUMA.UpdateSettings(settings) end)

function WUMA.OnSettingsUpdate(setting, value)
	if not (DisregardSettingsChange) then
		value = util.TableToJSON({value})

		local access = "changesettings"
		local data = {setting,value}
		 
		WUMA.SendCommand(access,data,true)
	end
end