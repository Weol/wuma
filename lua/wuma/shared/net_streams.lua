
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog
WUMA.NET = WUMA.NET or {}

WUMA.NET.ENUMS = {}

/////////////////////////////////////////////////////////
/////    Settings | Sends server's wuma settings	/////
/////////////////////////////////////////////////////////
WUMA.NET.SETTINGS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.SETTINGS:SetServerFunction(function(user,data)
	return {user, WUMA.NET.SETTINGS, table.Merge(WUMA.ConVars.ToClient,{wuma_server_time=os.time()})}
end) 
WUMA.NET.SETTINGS:SetClientFunction(function(data) 
	for name, value in pairs(data[1]) do
		WUMA.ServerSettings[string.sub(name,6)] = value
	end
	hook.Call(WUMA.SETTINGSUPDATE, _,WUMA.ServerSettings)
	WUMA.ServerSettings["server_time_offset"] = WUMA.ServerSettings["server_time"] - os.time()
end)
WUMA.NET.SETTINGS:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.SETTINGS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////  SUBSCRIPTION | Subscribes client to a table  /////
/////////////////////////////////////////////////////////
WUMA.NET.SUBSCRIPTION = WUMA_NET_STREAM:new()
WUMA.NET.SUBSCRIPTION:SetServerFunction(function(user,data)
	if (data[2]) then
		WUMA.RemoveDataSubscription(user,data[1],data[3])
	else
		WUMA.AddDataSubscription(user,data[1],data[3])
	end
end) 
WUMA.NET.SUBSCRIPTION:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.SUBSCRIPTION:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////   Push | Notifies clients about data updates  /////
/////////////////////////////////////////////////////////
WUMA.NET.PUSH = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.PUSH:SetServerFunction(function(user,data)
	return {user, WUMA.NET.PUSH, data}
end) 
WUMA.NET.PUSH:SetClientFunction(WUMA.RecievePushNotification)
WUMA.NET.PUSH:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.PUSH:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////     Groups | Returns all the usergroups		/////
/////////////////////////////////////////////////////////
WUMA.NET.GROUPS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.GROUPS:SetServerFunction(function(user,data)
	return {user, WUMA.NET.GROUPS, WUMA.GetUserGroups()}
end) 
WUMA.NET.GROUPS:SetClientFunction(function(data)
	WUMA.ServerGroups = data[1]
	hook.Call(WUMA.USERGROUPSUPDATE)
end)
WUMA.NET.GROUPS:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.GROUPS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////        Users | Returns online players		    /////
/////////////////////////////////////////////////////////
WUMA.NET.USERS = WUMA_NET_STREAM:new{send=WUMA.SendInformation,auto_update=true}
WUMA.NET.USERS:SetServerFunction(function(user,data)	
	local users = {}
	for _, ply in pairs(player.GetAll()) do
		local id = ply:SteamID()
		
		users[id] = {}
		users[id].usergroup = ply:GetUserGroup()
		users[id].nick = ply:Nick()
		users[id].steamid = id
		users[id].t = os.time()
		users[id].ent = ply
	end
	return {user, WUMA.NET.USERS, users}
end) 
WUMA.NET.USERS:SetClientFunction(function(data) 
	local players = {}
	for _, v in pairs(data[1]) do
		players[v.steamid] = v

		if not WUMA.LookupUsers[v.steamid] then 
			v.t=tostring(v.t)
			WUMA.LookupUsers[v.steamid] = v
		end
	end
	WUMA.ServerUsers = players
	hook.Call(WUMA.SERVERUSERSUPDATE)
end) 
WUMA.NET.USERS:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.USERS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////          User | Returns  player(s) data	 	/////
/////////////////////////////////////////////////////////
WUMA.NET.USER = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.USER:SetServerFunction(function(user,data)
	return {user, WUMA.NET.USER, WUMA.GetUserData(data[1])}
end) 
WUMA.NET.USER:SetClientFunction(function(data)
	if not data.steamid then return end
	WUMA.UserData[data.steamid] = data
	hook.Call(WUMA.USERDATAUPDATE, data.steamid)
end)  
WUMA.NET.USER:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.USER:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////          Lookup | Returns lookup request	 	/////
/////////////////////////////////////////////////////////
WUMA.NET.LOOKUP = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.LOOKUP:SetServerFunction(function(user,data)
	return {user, WUMA.NET.LOOKUP, WUMA.Lookup(data[1])}
end) 
WUMA.NET.LOOKUP:SetClientFunction(function(data)
	for i=1,table.Count(data[1]) do
		WUMA.LookupUsers[data[1][i].steamid] = data[1][i]
	end
	hook.Call(WUMA.LOOKUPUSERSUPDATE)
end) 
WUMA.NET.LOOKUP:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.LOOKUP:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////          MAPS | Returns maps request   	   	/////
/////////////////////////////////////////////////////////
WUMA.NET.MAPS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.MAPS:SetServerFunction(function(user,data)
	local maps = {file.Find("maps/*.bsp", "GAME")}
	return {user, WUMA.NET.MAPS, maps[1]}
end) 
WUMA.NET.MAPS:SetClientFunction(function(data)
	WUMA.Maps = data[1]
	hook.Call(WUMA.MAPSUPDATE)
end) 
WUMA.NET.MAPS:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.MAPS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////          WHOIS | Returns whois request	   	/////
/////////////////////////////////////////////////////////
WUMA.NET.WHOIS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.WHOIS:SetServerFunction(function(user,data)
	return {user, WUMA.NET.MAPS, WUMA.Lookup(data[1])}
end) 
WUMA.NET.WHOIS:SetClientFunction(function(data)
	WUMA.LookupUsers[data.steamid] = data.nick 
end) 
WUMA.NET.WHOIS:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.WHOIS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////  RESTRICTIONS | Returns restrictions request	/////
/////////////////////////////////////////////////////////
WUMA.NET.RESTRICTION = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.RESTRICTION:SetServerFunction(function(user,data)
	if data[1] then
		if WUMA.CheckUserFileExists(data[1],Restriction) then
			local tbl = WUMA.GetSavedRestrictions(data[1])
			if (table.Count(tbl) < 1) then tbl = false end
			return {user, tbl, Restriction:GetID()..":::"..data[1]}
		end
	else
		if WUMA.RestrictionsExist() then
			return {user, WUMA.GetSavedRestrictions(), Restriction:GetID()}
		end
	end
end)  
WUMA.NET.RESTRICTION:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.RESTRICTION:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////        LIMIT | Returns limits request			/////
/////////////////////////////////////////////////////////
WUMA.NET.LIMIT = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.LIMIT:SetServerFunction(function(user,data)
	if data[1] then
		if WUMA.CheckUserFileExists(data[1],Limit) then
			local tbl = WUMA.GetSavedLimits(data[1])
			if (table.Count(tbl) < 1) then tbl = false end
			return {user, tbl, Limit:GetID()..":::"..data[1]}
		end
	else
		if WUMA.LimitsExist() then
			return {user, WUMA.GetSavedLimits(), Limit:GetID()}
		end
	end
end) 
WUMA.NET.LIMIT:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.LIMIT:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
///// 	   LOADOUT | Returns loadouts request		/////
/////////////////////////////////////////////////////////
WUMA.NET.LOADOUT = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.LOADOUT:SetServerFunction(function(user,data)
	if data[1] then
		if WUMA.CheckUserFileExists(data[1],Loadout) then
			local tbl = WUMA.GetSavedLoadouts(data[1])
			if (tbl:GetWeaponCount() < 1) then tbl = false end
			return {user, tbl, Loadout:GetID()..":::"..data[1]}
		end
	else
		if WUMA.LoadoutsExist() then
			return {user, WUMA.GetSavedLoadouts(), Loadout:GetID()}
		end
	end
end) 
WUMA.NET.LOADOUT:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback)
end)
WUMA.NET.LOADOUT:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
///// 	   PERSONAL | Returns personal request		/////
/////////////////////////////////////////////////////////
WUMA.NET.PERSONAL = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.PERSONAL:SetServerFunction(function(user,data)
	if (data[1] == "subscribe") then
		WUMA.AddDataSubscription(user,user:SteamID(),user:SteamID())
		
		hook.Add(WUMA.USERRESTRICTIONADDED, user:SteamID() .. WUMA.USERRESTRICTIONADDED, function(hook_user, restriction) 
			if (user == hook_user) and not restriction:IsPersonal() then
				local tbl = {}
				tbl[restriction:GetID()] = restriction
				
				local id = Restriction:GetID() .. ":::" .. user:SteamID()
				
				WUMA.PoolFunction(WUMA.SendCompressedData, "SendPersonalCompressedData", data, {user, "_DATA", id}, 1)
			end
		end)
		
		hook.Add(WUMA.USERRESTRICTIONREMOVED, user:SteamID() .. WUMA.USERRESTRICTIONREMOVED, function(hook_user, restriction) 
			if (user == hook_user) and not restriction:IsPersonal() then
				local tbl = {}
				tbl[restriction:GetID()] = WUMA.DELETE
				
				local id = Restriction:GetID() .. ":::" .. user:SteamID()
				
				WUMA.PoolFunction(WUMA.SendCompressedData, "SendPersonalCompressedData", data, {user, "_DATA", id}, 1)			
			end
		end)
	elseif (data[1] == "unsubscribe") then 
		WUMA.RemoveDataSubscription(user,user:SteamID(),user:SteamID())
	
		hook.Remove(WUMA.USERRESTRICTIONADDED, user:SteamID() .. WUMA.USERRESTRICTIONADDED)
		hook.Remove(WUMA.USERRESTRICTIONREMOVED, user:SteamID() .. WUMA.USERRESTRICTIONREMOVED)
	elseif (data[1] == "restrictions") then
		return {user, user:GetRestrictions(), Restriction:GetID()..":::"..user:SteamID()}
	elseif (data[1] == "loadout") then
		if user:HasLoadout() then
			return {user, user:GetLoadout():GetBarebones(), Loadout:GetID()..":::"..user:SteamID()}
		end
	end
end) 
WUMA.NET.PERSONAL:SetAuthenticationFunction(function(user, callback) 
	WUMA.HasAccess(user, callback, "wuma personalloadout")
end)
WUMA.NET.PERSONAL:AddInto(WUMA.NET.ENUMS)