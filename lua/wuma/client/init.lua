
if SERVER then return end

WUMA = WUMA or {}
WUMA.HomePath = "wuma/client/"

WUMA.Debug = true

--Enums
WUMA.DELETE = "WUMA_delete"
WUMA.EMPTY = "WUMA_empty"

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

WUMA.Initialize()
	
WUMA.Loaded = true