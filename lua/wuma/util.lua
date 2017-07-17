
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.WUMALookupTable = "WUMALookup"
WUMA.Settings = WUMA.Settings or {}
WUMA.SettingsHooks = WUMA.SettingsHooks or {}

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

local cacheCounter = 0
local cacheSize = 15
local head
local tail
function WUMA.Cache(id, data)
	if (data) then
		if not head then
			head = {id = id, data = data, next = nil}
			tail = head
			cacheCounter = cacheCounter + 1
		else 
			if (cacheCounter => cacheSize) then
				tail = tail.previous
			end
			
			local link = {id = id, data = data, next = head}
			tail.previous = tail
			tail = head
			head = link
			cacheCounter = cacheCounter + 1
		end
	else
		local link = head --Set link to head (first element)
		local previous --Declare pervious
		while (link != nil) do
			if (link.id == id) then --Check if link is what we are looking for
				if (previous) then --If previous is not nil then link is not head
					previous.next = link.next --Set the previous element to the the current links next element
					link.next = head --Set current links next to current head
					head = link --Set head to current link
				end
				return link.data --Return the data
			elseif (link.next != nil) then
				previous = link --Set previous to current link
				link = link.next --Set current link to next link
			end
		end
	end
end

function WUMA.InvalidateCache(id) 
	local link = head
	local previous
	while (link != nil) do
		if (link.id == id) then
			if (previous) then
				previous.next = link.next
			else 
				head = head.next
			end
			cacheCounter = cacheCounter - 1
		end
	end
end