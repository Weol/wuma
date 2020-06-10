
function WUMASQL(str, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = sql.SQLStr(v, isstring(v))
	end

	local query = string.format(str, unpack(args))
	local response = sql.Query(query)
	if (response == false) then
		WUMADebug("SQL ERROR")
		WUMADebug(sql.LastError())
		error(string.format("query failed (%s)", query))
	end
	WUMADebug("Executed query:\n%s", query)
	return response
end

function WUMA.AddLookup(user)
	WUMASQL("REPLACE INTO WUMALookup (steamid, nick, usergroup, t) values ('%s', '%s', '%s', %s);", user:SteamID(), user:Nick(), user:GetUserGroup(), tostring(os.time()))
end

function WUMA.RemoveLookup(user)
	WUMASQL("DELETE FROM WUMALookup WHERE steamid=%s;", user:SteamID())
end

function WUMA.Lookup(user)
	if isstring(user) then
		if WUMA.IsSteamID(user) then
			return WUMASQL("SELECT * FROM WUMALookup WHERE steamid LIKE '%s%s LIMIT 50;", user, "%'")
		else
			return WUMASQL("SELECT * FROM WUMALookup WHERE nick LIKE %s%s%s LIMIT 50;", "'%", user, "%'")
		end
	elseif (isnumber(user)) then
		return WUMASQL("SELECT * FROM WUMALookup ORDER BY t ASC LIMIT %s", tostring(user))
	end
end