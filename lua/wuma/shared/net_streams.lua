
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
WUMA.NET.GROUPS:AddInto(WUMA.NET.ENUMS)

/////////////////////////////////////////////////////////
/////        Users | Returns online players		    /////
/////////////////////////////////////////////////////////
WUMA.NET.USERS = WUMA_NET_STREAM:new{send=WUMA.SendInformation}
WUMA.NET.USERS:SetServerFunction(function(data)
	data = data or {}

	local users = {}
	for _,user in pairs(data.users or player.GetAll()) do
		users[user:SteamID()] = user:Nick()
	end
	return users
end) 
WUMA.NET.USERS:SetClientFunction(function(data)
	WUMA.ServerUsers = data
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
	WUMA.UserData[data.user] = data
end) 
WUMA.NET.USER:AddInto(WUMA.NET.ENUMS)