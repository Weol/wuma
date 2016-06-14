
WUMA = WUMA or {}
WUMA.NET = WUMA.NET or {}

WUMA.NET.ENUMS = {}

/////////////////////////////////////////////////////////
/////     Groups | Returns all the usergroups		/////
/////////////////////////////////////////////////////////
WUMA.NET.GROUPS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.GROUPS:SetServerFunction(function()
	return WUMA.GetUserGroups()
end) 
WUMA.NET.GROUPS:SetClientFunction(function(data)
	WUMA.ServerGroups = data
end)
WUMA.NET.GROUPS:SetAuthenticationFunction(function(user) 
	return true
end)
WUMA.NET.GROUPS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////        Users | Returns online players		    /////
/////////////////////////////////////////////////////////
WUMA.NET.USERS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.USERS:SetServerFunction(function(data)
	data = data.users or player.GetAll()

	local users = {}
	for _,user in pairs(data) do
		users[user:SteamID()] = user:Nick()
	end
	return users
end) 
WUMA.NET.USERS:SetClientFunction(function(data)
	WUMA.ServerUsers = data
end) 
WUMA.NET.USERS:SetAuthenticationFunction(function(user) 
	return true
end)
WUMA.NET.USERS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////          User | Returns  player(s) data	 	/////
/////////////////////////////////////////////////////////
WUMA.NET.USER = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.USER:SetServerFunction(function(data)
	return WUMA.GetUserData(data.user)
end) 
WUMA.NET.USER:SetClientFunction(function(data)
	WUMA.UserData[data.steamid] = data
end) 
WUMA.NET.USER:SetAuthenticationFunction(function(user) 
	return true
end)
WUMA.NET.USER:AddInto(WUMA.NET.ENUMS)y

/////////////////////////////////////////////////////////
/////          Lookup | Returns lookup request	 	/////
/////////////////////////////////////////////////////////
WUMA.NET.LOOKUP = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.LOOKUP:SetServerFunction(function(data)
	return data = WUMA.Lookup(data.count)
end) 
WUMA.NET.LOOKUP:SetClientFunction(function(data)
	WUMA.LookupUsers = data
end) 
WUMA.NET.LOOKUP:SetAuthenticationFunction(function(user) 
	return true
end)
WUMA.NET.LOOKUP:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////          WHOIS | Returns whois request	   	/////
/////////////////////////////////////////////////////////
WUMA.NET.WHOIS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.WHOIS:SetServerFunction(function(data)
	return data = WUMA.Lookup(data.user)
end) 
WUMA.NET.WHOIS:SetClientFunction(function(data)
	WUMA.LookupUsers[data.steamid] = data.nick 
end) 
WUMA.NET.WHOIS:SetAuthenticationFunction(function(user) 
	return true
end)
WUMA.NET.WHOIS:AddInto(WUMA.NET.ENUMS)