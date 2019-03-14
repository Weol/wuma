
WUMA = WUMA or {}
WUMA.SQL = WUMA.SQL or {}

local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.SQL.WUMALookupTable = "WUMALookup"

function WUMA.SQL.Initialize()
	if not sql.TableExists(WUMA.SQL.WUMALookupTable) then
		WUMA.SQL.CreateTable(WUMA.SQL.WUMALookupTable)
		sql.Query(string.format("CREATE INDEX WUMALOOKUPINDEX ON %s(nick);", WUMA.SQL.WUMALookupTable))
	end
end

function WUMA.SQL.CreateTable(str)
	sql.Query(string.format("CREATE TABLE %s (steamid varchar(22) NOT NULL PRIMARY KEY, nick varchar(42), usergroup varchar(42), t int);", str))
end

function WUMA.SQL.Query(str, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = sql.SQLStr(v, isstring(v))
	end
	
	local tbl = sql.Query(string.format(str, unpack(args)))
	return tbl
end
WUMASQL = WUMA.SQL.Query --You know why
