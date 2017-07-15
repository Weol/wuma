
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
			WUMA.Restrictions[id] = tbl	
		else
			WUMA.Restrictions[id] = nil	
		end
		
		update[id] = tbl
	end
	
	hook.Call(WUMA.RESTRICTIONUPDATE, _, update)
end

function WUMA.UpdateLimits(update)

	for id, tbl in pairs(update) do
		if istable(tbl) then 
			tbl = Limit:new(tbl)	
			WUMA.Limits[id] = tbl			
		else 
			WUMA.Limits[id] = nil
		end
			
		update[id] = tbl
	end
	
	hook.Call(WUMA.LIMITUPDATE, _, update)

end

function WUMA.UpdateLoadouts(update)

	PrintTable(update)

	for id, weapon in pairs(update) do
		if istable(weapon) then
			local usergrup = weapon.usergroup
			update[id] = Loadout_Weapon:new(weapon)
			update[id].usergroup = usergrup
			WUMA.Loadouts[id] = update[id]
		else
			WUMA.Loadouts[id] = nil
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
			
			WUMA.UserData[user].Restrictions[id] = tbl	
		else 
			WUMA.UserData[user].Restrictions[id] = nil	
		end
		
		update[id] = tbl
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
			
			WUMA.UserData[user].Limits[id] = tbl	
		else
			WUMA.UserData[user].Limits[id] = nil	
		end
		
		update[id] = tbl	
	end

	hook.Call(WUMA.USERDATAUPDATE, _, user, Limit:GetID(), update)
	
end

function WUMA.UpdateUserLoadouts(user, update)
	WUMA.UserData[user].Loadouts = WUMA.UserData[user].Loadouts or {}

	local tbl = {}
	for class, weapon in pairs(update) do
		if istable(weapon) then
			weapon.parent = user
			weapon.usergroup = user
			weapon = Loadout_Weapon:new(weapon)
			
			WUMA.UserData[user].Loadouts[class] = weapon
		else
			WUMA.UserData[user].Loadouts[class] = nil
		end
	end

	hook.Call(WUMA.USERDATAUPDATE, _, user, Loadout:GetID(), update)
	
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