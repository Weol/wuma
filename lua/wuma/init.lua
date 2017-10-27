
WUMA = WUMA or {}

WUMA.ConVars = WUMA.ConVars or {}
WUMA.ConVars.CVarLimits = WUMA.ConVars.CVarLimits or {}
WUMA.ConVars.CVars = WUMA.ConVars.CVars or {}
WUMA.ConVars.ToClient = WUMA.ConVars.ToClient or {}

WUMA.VERSION = "1.2"
WUMA.AUTHOR = "Erik 'Weol' Rahka"
 
--Enums
WUMA.DELETE = "WUMA_delete"
WUMA.EMPTY = "WUMA_empty" 

--Paths
WUMA.DataDirectory = "wuma/"
WUMA.SharedDirectroy = "wuma/shared/"
WUMA.ClientDirectory = "wuma/client/"
WUMA.ObjectsDirectory = "wuma/objects/"
WUMA.UserDataDirectory = "users/"
WUMA.HomeDirectory = "wuma/"

WUMA.WUMAGUI = "wuma gui"

function WUMA.Initialize()
   
	Msg("WUMA.Initialize()\n")
 
	include(WUMA.HomeDirectory.."files.lua")
	include(WUMA.HomeDirectory.."log.lua")
	  
	--Initialize data files  
	WUMA.Files.Initialize()

	--Load objects
	WUMA.LoadFolder(WUMA.ObjectsDirectory)
	WUMA.LoadCLFolder(WUMA.ObjectsDirectory)

	--Include core
	include(WUMA.HomeDirectory.."sql.lua")
	include(WUMA.HomeDirectory.."util.lua") 	
	include(WUMA.HomeDirectory.."functions.lua")
	include(WUMA.HomeDirectory.."datahandler.lua")
	include(WUMA.HomeDirectory.."users.lua")
	include(WUMA.HomeDirectory.."limits.lua")
	include(WUMA.HomeDirectory.."restrictions.lua")
	include(WUMA.HomeDirectory.."loadouts.lua")
	include(WUMA.HomeDirectory.."inheritance.lua") 
	include(WUMA.HomeDirectory.."hooks.lua") 
	include(WUMA.HomeDirectory.."duplicator.lua")
	include(WUMA.HomeDirectory.."extentions/playerextention.lua")
	include(WUMA.HomeDirectory.."extentions/entityextention.lua")

	--Register WUMA access with CAMI
	CAMI.RegisterPrivilege{Name=WUMA.WUMAGUI,MinAccess="superadmin",Description="Access to WUMA GUI"}
	   
	--Who am I writing these for?
	WUMALog("Weol's User Management Addon version %s",WUMA.VERSION)
	
	--Initialize database
	WUMA.SQL.Initialize()
	
	--Load data 
	WUMA.LoadRestrictions()
	WUMA.LoadLimits()
	WUMA.LoadLoadouts()
	WUMA.LoadInheritance()
		
	--Load shared files
	WUMALog("Loading shared files")
	WUMA.LoadCLFolder(WUMA.SharedDirectroy)
	WUMA.LoadFolder(WUMA.SharedDirectroy) 
	
	--Load client files
	WUMALog("Loading client files")
	WUMA.LoadCLFolder(WUMA.ClientDirectory)
	
	--Allow the poor scopes to think
	Scope:StartThink()
	
	--Add hook so playerextention loads when the first player joins
	hook.Add("PlayerAuthed", "WUMAPlayerAuthedPlayerExtentionInit", function()  
		include(WUMA.HomeDirectory.."extentions/playerextention.lua")
		hook.Remove("WUMAPlayerAuthedPlayerExtentionInit")
	end)
	
	--All overides should be loaded after WUMA
	hook.Call("PostWUMALoad")
	
end

--Override CreateConvar in order to find out if any addons are creating sbox_max limits
local oldCreateConVar = CreateConVar
function CreateConVar(...)
	local args = {...}
	if (string.Left(args[1], 8) == "sbox_max") then
		table.insert(WUMA.ConVars.CVarLimits, string.sub(args[1], 9))
	end
	return oldCreateConVar(...)
end

function WUMA.CreateConVar(...)
	local convar = CreateConVar(...)
	WUMA.ConVars.CVars[convar:GetName()] = convar
	WUMA.ConVars.ToClient[convar:GetName()] = convar:GetString()
	
	cvars.AddChangeCallback(convar:GetName(), function(convar,old,new) 
		WUMA.ConVars.ToClient[convar] = new
	
		local tbl = {}
		tbl[convar] = new
		WUMA.GetAuthorizedUsers(function(users) 
			WUMA.SendInformation(users,WUMA.GetStream("settings"),tbl)
		end)
	end)
	
	return convar
end

function WUMA.GetTime()
	return os.time()
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
