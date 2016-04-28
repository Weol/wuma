
WUMA = WUMA or {}
WUMA.SQL = WUMA.SQL or {}

WUMA.SQL.WUMALookupTable = "WUMALookup"

function WUMA.SQL.Initialize()
	if not sql.TableExists(WUMA.SQL.WUMALookupTable) then
		WUMA.SQL.CreateTable(WUMA.SQL.WUMALookupTable)
		sql.Query(string.format("CREATE UNIQUE INDEX WUMALOOKUPINDEX ON %s(steamid);",WUMA.SQL.WUMALookupTable))
	end
end

function WUMA.SQL.CreateTable(str)
	sql.Query(string.format("CREATE TABLE %s (steamid varchar(255), nick varchar(255), t int);",str))
end

function WUMA.SQL.Query(str,...)
	return sql.Query(string.format(str),...)
end
WUMASQL = WUMA.SQL.Query --You know why