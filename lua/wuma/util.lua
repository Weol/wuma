
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.Settings = WUMA.Settings or {}
WUMA.SettingsHooks = WUMA.SettingsHooks or {}

local uniqueIDs = 0
function WUMA.GenerateUniqueID()
	local id = uniqueIDs+1
	uniqueIDs = uniqueIDs + 1
	return id
end

local function query(str, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = sql.SQLStr(v, isstring(v))
	end

	local query = string.format(str, unpack(args))
	local response = sql.Query(query)
	if (response == false) then
		error(string.format("query failed (%s)", query))
	end
	return response
end
WUMASQL = query

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

function WUMA.GetSteamIDbyNick(id)
	return WUMA.Lookup(user)
end

local cacheCounter = 0
local cacheSize = 20
local head
local tail
function WUMA.Cache(id, data)
	if (data) then
		if not head then
			head = {id = id, data = data, next = nil}
			tail = head
			cacheCounter = cacheCounter + 1
		else
			local link = {id = id, data = data, next = head}
			head = link
			cacheCounter = cacheCounter + 1
		end

		if (cacheCounter >= cacheSize) then
			local counter = 0
			local l = head
			while l do
				if (counter > cacheSize - 2) then
					l.next = nil
					l = nil
					cacheCounter = counter
				else
					l = l.next
					counter = counter + 1
				end
			end
		end
	else
		local link = head --Set link to head (first element)
		local previous --Declare pervious
		while (link ~= nil) do
			if (link.id == id) then --Check if link is what we are looking for
				if (previous) then --If previous is not nil then link is not head
					previous.next = link.next --Set the previous element to the the current links next element
					link.next = head --Set current links next to current head
					head = link --Set head to current link
				end
				return link.data --Return the data
			end

			previous = link --Set previous to current link
			link = link.next --Set current link to next link
		end
	end
end