
WUMA = WUMA or {}
WUMA.NET = WUMA.NET or {}

WUMA.NET.ENUMS = {}

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
WUMA.NET.GROUPS:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.GROUPS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////        Users | Returns online players		    /////
/////////////////////////////////////////////////////////
WUMA.NET.USERS = WUMA_NET_STREAM:new{send=WUMA.SendInformation,auto_update=true}
WUMA.NET.USERS:SetServerFunction(function(user,data)
	return {user, WUMA.NET.USERS, player.GetAll()}
end) 
WUMA.NET.USERS:SetClientFunction(function(data) 
	WUMA.ServerUsers = data[1]
	hook.Call(WUMA.SERVERUSERSUPDATE)
end) 
WUMA.NET.USERS:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.USERS:AddHook("PlayerDisconnected","PlayerInitialSpawn")
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
WUMA.NET.USER:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
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
		WUMA.LookupUsers[data[1][i].steamid] = data[1][i].nick
	end
	hook.Call(WUMA.LOOKUPUSERSUPDATE)
end) 
WUMA.NET.LOOKUP:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.LOOKUP:AddInto(WUMA.NET.ENUMS)

WUMA.NET.MAPS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.MAPS:SetServerFunction(function(user,data)
	local maps = {file.Find("maps/*.bsp", "GAME")}
	return {user, WUMA.NET.MAPS, maps[1]}
end) 
WUMA.NET.MAPS:SetClientFunction(function(data)
	WUMA.Maps = data[1]
	hook.Call(WUMA.MAPSUPDATE)
end) 
WUMA.NET.MAPS:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
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
WUMA.NET.WHOIS:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.WHOIS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////  RESTRICTIONS | Returns restrictions request	/////
/////////////////////////////////////////////////////////
WUMA.NET.RESTRICTION = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.RESTRICTION:SetServerFunction(function(user,data)
	if WUMA.Files.Exists(WUMA.DataDirectory.."restrictions.txt") then
		return {user, util.Compress(WUMA.Files.Read(WUMA.DataDirectory.."restrictions.txt")), Restriction:GetID()}
	end
end)  
WUMA.NET.RESTRICTION:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.RESTRICTION:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////        LIMIT | Returns limits request			/////
/////////////////////////////////////////////////////////
WUMA.NET.LIMIT = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.LIMIT:SetServerFunction(function(user,data)
	if WUMA.Files.Exists(WUMA.DataDirectory.."limits.txt") then
		return {user, util.Compress(WUMA.Files.Read(WUMA.DataDirectory.."limits.txt")), Limit:GetID()}
	end
end) 
WUMA.NET.LIMIT:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.LIMIT:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
///// 	   LOADOUT | Returns loadouts request		 /////
/////////////////////////////////////////////////////////
WUMA.NET.LOADOUT = WUMA_NET_STREAM:new{send=WUMA.SendCompressedData}
WUMA.NET.LOADOUT:SetServerFunction(function(user,data)
	if WUMA.Files.Exists(WUMA.DataDirectory.."loadouts.txt") then
		return {user, util.Compress(WUMA.Files.Read(WUMA.DataDirectory.."loadouts.txt")), Loadout:GetID()}
	end
end) 
WUMA.NET.LOADOUT:SetAuthenticationFunction(function(user) 
	return WUMA.HasAccess(user)
end)
WUMA.NET.LOADOUT:AddInto(WUMA.NET.ENUMS)