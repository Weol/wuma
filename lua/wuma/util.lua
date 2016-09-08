
WUMA = WUMA or {}

WUMA.WUMALookupTable = "WUMALookup"
WUMA.UniqueIDs = {}

function WUMA.GenerateUniqueID()
	local id = table.Count(WUMA.UniqueIDs)+1
	table.insert(WUMA.UniqueIDs,id)
	return id
end

function WUMA.AddLookup(user)
	WUMASQL("REPLACE INTO %s (steamid, nick, t) values ('%s','%s',%s);",WUMA.SQL.WUMALookupTable,user:SteamID(),user:Nick(),tostring(os.time()))
end

function WUMA.RemoveLookup(user)
	WUMASQL("DELETE FROM %s WHERE steamid=%s;",WUMA.SQL.WUMALookupTable,user:SteamID())
end

function WUMA.Lookup(user)
	if (string.lower(type(user)) == "string") then
		if WUMA.IsSteamID(user) then
			return WUMASQL("SELECT nick FROM %s WHERE steamid='%s';",WUMA.SQL.WUMALookupTable,sql.SQLStr(user,true))
		else
			return WUMASQL("SELECT steamid FROM %s WHERE nick REGEXP '%s' ORDER BY t ASC;",WUMA.SQL.WUMALookupTable,sql.SQLStr(user,true))
		end
	elseif (isnumber(user)) then
		return WUMASQL("SELECT steamid,nick FROM %s ORDER BY t ASC LIMIT %s",WUMA.WUMALookupTable,sql.SQLStr(tostring(user),true))
	end
end

function WUMA.GetSteamIDbyNick(id)
	return WUMA.Lookup(user)
end
