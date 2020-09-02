
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

function WUMA.Lookup(limit, offset, search)
	offset = offset or 0

	local users
	if search and search ~= "" then
		if WUMA.IsSteamID(search) then
			users = WUMASQL("SELECT * FROM WUMALookup WHERE steamid LIKE '%s%%' LIMIT %s OFFSET %s;", search, tostring(limit), tostring(offset))
		else
			users = WUMASQL("SELECT * FROM WUMALookup WHERE nick LIKE '%%%s%%' LIMIT %s OFFSET %s;", search, tostring(limit), tostring(offset))
		end
	else
		users = WUMASQL("SELECT * FROM WUMALookup ORDER BY t DESC LIMIT %s OFFSET %s", tostring(limit), tostring(offset))
	end

	for _, user in ipairs(users) do
		user.t = tonumber(user.t)
	end

	return users
end