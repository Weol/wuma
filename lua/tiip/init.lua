
if not SERVER then return end

TIIP = TIIP or {}

--Definitions
TIIP.VERSION = "1.1 Alpha"
TIIP.AUTHOR = "Erik 'Weol' Rahka"
 
--Paths
TIIP.DataDirectory = "tiip/"
TIIP.SharedDirectroy = "tiip/shared/"
TIIP.ClientDirectory = "tiip/client/"
TIIP.ObjectsDirectory = "tiip/objects/"
TIIP.UserDataDirectory = "users/"
TIIP.HomeDirectory = "tiip/"

--Settings
TIIP.DataUpdateCooldown = 10
TIIP.Debug = true

function TIIP.Initialize()

	--Bootstrap
	include(TIIP.HomeDirectory.."files.lua")
	include(TIIP.HomeDirectory.."log.lua")
	
	--Loading objects
	TIIP.LoadCLFolder(TIIP.ObjectsDirectory)
	
	--Include core
	include(TIIP.HomeDirectory.."datahandler.lua")
	include(TIIP.HomeDirectory.."players.lua")
	include(TIIP.HomeDirectory.."limits.lua")
	include(TIIP.HomeDirectory.."restrictions.lua")
	include(TIIP.HomeDirectory.."loadouts.lua")
	include(TIIP.HomeDirectory.."hooks.lua") 
	include(TIIP.HomeDirectory.."extentions/playerextention.lua")
	
	--Who am I writing these for?
	TIIPLog("User Management version %s",TIIP.VERSION)
	
	--Loading shared files
	TIIPLog("Loading shared files")
	TIIP.LoadCLFolder(TIIP.SharedDirectroy)
	
	--Loading client files
	TIIPLog("Loading client files")
	TIIP.LoadCLFolder(TIIP.ClientDirectory)
	
	--Initialize data files
	TIIP.Files.Initialize()
	
	--Load data 
	TIIP.LoadRestrictions()
	TIIP.LoadLimits()
	TIIP.LoadLoadouts()
	
end

function TIIP.LoadFolder(dir)
	local files, directories = file.Find( dir.."*", "LUA" )
	
	for _,file in pairs(files) do
		TIIPLog(" %s",file)
	
		include(dir..file)
	end
	
	for _,directory in pairs(directories) do
		TIIP.LoadFolder(dir..directory.."/") 
	end
end

function TIIP.LoadCLFolder(dir)
	local files, directories = file.Find( dir.."*", "LUA" )
	
	for _,file in pairs(files) do	
		TIIPLog(" %s",file)
		
		include(dir..file)
		AddCSLuaFile(dir..file)
	end
	
	for _,directory in pairs(directories) do
		TIIP.LoadCLFolder(dir..directory.."/")
	end
end

TIIP.Loaded = true
