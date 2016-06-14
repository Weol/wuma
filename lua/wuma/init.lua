
if not SERVER then return end

WUMA = WUMA or {}

--Definitions
WUMA.VERSION = "1.4.1 Alpha"
WUMA.AUTHOR = "Erik 'Weol' Rahka"
 
--Enums
WUMA.DELETE = "WUMA_delete"
WUMA.EMPTY = "WUMA_empty" 

--Paths
WUMA.DataDirectory = "WUMA/"
WUMA.SharedDirectroy = "WUMA/shared/"
WUMA.ClientDirectory = "WUMA/client/"
WUMA.ObjectsDirectory = "WUMA/objects/"
WUMA.UserDataDirectory = "users/"
WUMA.HomeDirectory = "WUMA/"

--Settings
WUMA.DataUpdateCooldown = 10
WUMA.Debug = true
WUMA.ULXGUI = "xgui_wuma"
WUMA.RegisterSize = 200

function WUMA.Initialize()
   
	Msg("WUMA.Initialize()\n")
 
	--Bootstrap
	include(WUMA.HomeDirectory.."files.lua")
	include(WUMA.HomeDirectory.."log.lua")
	  
	--Loading objects
	WUMA.LoadFolder(WUMA.ObjectsDirectory)
	WUMA.LoadCLFolder(WUMA.ObjectsDirectory)
	    
	--Include core
	include(WUMA.HomeDirectory.."datahandler.lua")
	include(WUMA.HomeDirectory.."users.lua")
	include(WUMA.HomeDirectory.."sql.lua") 
	include(WUMA.HomeDirectory.."logistics.lua") 
	include(WUMA.HomeDirectory.."limits.lua")
	include(WUMA.HomeDirectory.."restrictions.lua")
	include(WUMA.HomeDirectory.."loadouts.lua")
	include(WUMA.HomeDirectory.."hooks.lua") 
	include(WUMA.HomeDirectory.."extentions/playerextention.lua")
	include(WUMA.HomeDirectory.."extentions/entityextention.lua")
	   
	--Who am I writing these for?
	WUMALog("User Management Addon version %s",WUMA.VERSION)
	 
	--Loading shared files
	WUMALog("Loading shared files")
	WUMA.LoadCLFolder(WUMA.SharedDirectroy)
	WUMA.LoadFolder(WUMA.SharedDirectroy) 
	 
	--Loading client files
	WUMALog("Loading client files")
	WUMA.LoadCLFolder(WUMA.ClientDirectory)
	
	--Initialize data files  
	WUMA.Files.Initialize()
	
	--Initialize SQL
	WUMA.SQL.Initialize()
	 
	--Load data 
	WUMA.LoadRestrictions()
	WUMA.LoadLimits()
	WUMA.LoadLoadouts()
	
end

function WUMA.LoadFolder(dir)
	local files, directories = file.Find(dir.."*", "LUA")
	
	for _,file in pairs(files) do
		WUMADebug(" %s",file)
	
		include(dir..file)
	end
	
	for _,directory in pairs(directories) do
		WUMA.LoadFolder(dir..directory.."/") 
	end
end

function WUMA.LoadCLFolder(dir)
	local files, directories = file.Find(dir.."*", "LUA")
	
	for _,file in pairs(files) do	
		WUMADebug(" %s",dir..file)
		
		AddCSLuaFile(dir..file) 
	end
	
	for _,directory in pairs(directories) do
		WUMA.LoadCLFolder(dir..directory.."/")
	end
end
WUMA.Initialize()

WUMA.Loaded = true
