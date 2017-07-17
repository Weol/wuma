
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.WUMALookupTable = "WUMALookup"
WUMA.Settings = WUMA.Settings or {}
WUMA.SettingsHooks = WUMA.SettingsHooks or {}
WUMA.Cache = {}

local uniqueIDs = 0
function WUMA.GenerateUniqueID()
	local id = uniqueIDs+1
	uniqueIDs = uniqueIDs + 1
	return id
end

function WUMA.AddLookup(user)
	WUMASQL("REPLACE INTO %s (steamid, nick, usergroup, t) values ('%s','%s','%s',%s);",WUMA.SQL.WUMALookupTable,user:SteamID(),user:Nick(),user:GetUserGroup(),tostring(os.time()))
end

function WUMA.RemoveLookup(user)
	WUMASQL("DELETE FROM %s WHERE steamid=%s;",WUMA.SQL.WUMALookupTable,user:SteamID())
end

function WUMA.Lookup(user)
	if (string.lower(type(user)) == "string") then
		if WUMA.IsSteamID(user) then
			return WUMASQL("SELECT * FROM %s WHERE steamid='%s';",WUMA.SQL.WUMALookupTable,sql.SQLStr(user,true))
		else
			return WUMASQL("SELECT * FROM %s WHERE nick='%s';",WUMA.SQL.WUMALookupTable,sql.SQLStr(user,true))
		end
	elseif (isnumber(user)) then
		return WUMASQL("SELECT * FROM %s ORDER BY t ASC LIMIT %s",WUMA.WUMALookupTable,sql.SQLStr(tostring(user),true))
	end
end

function WUMA.GetSteamIDbyNick(id)
	return WUMA.Lookup(user)
end

local cacheSize = 15
function WUMA.Cache(id, data)
	if (data) then
		if (WUMA.Cache[id]) then
			WUMA.Cache[id] = {data = data, uses = 1}
			return true
		end
	elseif (WUMA.Cache[id]) then
		WUMA.Cache[id].uses = WUMA.Cache[id].uses + 1
		return WUMA.Cache[id]
	end
	return false
end

function WUMA.InvalidateCache(id) 
	
end