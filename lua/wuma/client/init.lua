
if SERVER then return end

WUMA = WUMA or {}

WUMA.HomePath = "wuma/client/"

--Enums
WUMA.DELETE = "WUMA_delete"
WUMA.EMPTY = "WUMA_empty"
WUMA.ERROR = "WUMA_error"

function WUMA.Initialize()
	
	include("log.lua")
	include("datahandler.lua")
	include("gui.lua")
	
	//Load object folder
	WUMA.IncludeFolder("wuma/objects/")
	
	//Load shared folder
	WUMA.IncludeFolder("wuma/shared/")
	 
	//Load vgui folder
	WUMADebug("Loading VGUI Folder")
	WUMA.IncludeFolder(WUMA.HomePath.."vgui/")

end

function WUMA.IncludeFolder(dir)
	dir = dir or ""
	local files, directories = file.Find(dir.."*", "LUA")
	
	for _,file in pairs(files) do	
		WUMADebug(" %s",dir..file)
		
		include(dir..file) 
	end
	
	for _,directory in pairs(directories) do
		WUMA.IncludeFolder(dir..directory.."/")
	end
end

WUMA.UniqueIDs = 0
function WUMA.GenerateUniqueID()
	local id = WUMA.UniqueIDs
	WUMA.UniqueIDs = WUMA.UniqueIDs + 1
	return id
end

function WUMA.IsSteamID(steamid)
	return string.match(steamid,[[STEAM_\d{1}:\d{1}:\d*]])
end

function WUMA.GetTime()
	return os.time() + (WUMA.ServerSettings["server_time_offset"] or 0)
end

local stcache = {}
function WUMA.STCache(id, data)
	if data then
		stcache[id] = {data=data,t=os.time()}
	else
		local entry = stcache[id]
		if entry then
			if (entry.t + 2 > os.time()) then
				stcache[id].t = os.time()
				return stcache[id].data
			else
				stcache[id] = nil
			end
		end
	end
end

WUMA.Initialize()