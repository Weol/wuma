
WUMA = WUMA or {}

WUMA.ConVars = WUMA.ConVars or {}
WUMA.ConVars.Limits = WUMA.ConVars.Limits or {}
WUMA.ConVars.Settings = WUMA.ConVars.Settings or {}

WUMA.VERSION = "1.3.0"
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

	include(WUMA.HomeDirectory.."files.lua")
	include(WUMA.HomeDirectory.."log.lua")

	--Initialize data files
	WUMA.Files.Initialize()

	--Load objects
	WUMA.LoadFolder(WUMA.ObjectsDirectory)
	WUMA.LoadCLFolder(WUMA.ObjectsDirectory)

	--Include CAMI before files that depend on it
	include(WUMA.HomeDirectory.."shared/cami.lua")
	AddCSLuaFile(WUMA.HomeDirectory.."shared/cami.lua")

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
	include(WUMA.HomeDirectory.."extentions/entityextention.lua")

	include(WUMA.HomeDirectory.."extentions/playerextention.lua")
	AddCSLuaFile(WUMA.HomeDirectory.."extentions/playerextention.lua")

	--Register WUMA access with CAMI
	CAMI.RegisterPrivilege{Name=WUMA.WUMAGUI, MinAccess="superadmin", Description="Access to WUMA GUI"}

	--Who am I writing these for?
	WUMALog("Weol's User Management Addon version %s", WUMA.VERSION)

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
		hook.Remove("PlayerAuthed", "WUMAPlayerAuthedPlayerExtentionInit")
	end)

	--All overides should be loaded after WUMA
	hook.Call("OnWUMALoaded")
end

--Override CreateConvar in order to find out if any addons are creating sbox_max limits
local oldCreateConVar = CreateConVar
function CreateConVar(...)
	local args = {...}
	if (string.Left(args[1], 8) == "sbox_max") then
		table.insert(WUMA.ConVars.Limits, string.sub(args[1], 9))
	end
	return oldCreateConVar(...)
end

function WUMA.CreateConVar(...)
	local convar = CreateConVar(...)
	WUMA.ConVars.Settings[convar:GetName()] = convar:GetString()

	cvars.AddChangeCallback(convar:GetName(), function(convar, old, new)
		WUMA.ConVars.Settings[convar] = new

		local tbl = {}
		tbl[convar] = new
		WUMA.GetAuthorizedUsers(function(users)
			WUMA.SendInformation(users,WUMA.GetStream("settings"),tbl)
		end)
	end)

	return convar
end

function WUMA.LoadFolder(dir)
	local files, directories = file.Find(dir.."*", "LUA")

	for _, file in pairs(files) do
		WUMADebug(" %s", file)

		include(dir..file)
	end

	for _, directory in pairs(directories) do
		WUMA.LoadFolder(dir..directory.."/")
	end
end

function WUMA.LoadCLFolder(dir)
	local files, directories = file.Find(dir.."*", "LUA")

	for _, file in pairs(files) do
		WUMADebug(" %s", dir..file)

		AddCSLuaFile(dir..file)
	end

	for _, directory in pairs(directories) do
		WUMA.LoadCLFolder(dir..directory.."/")
	end
end

WUMA.Initialize()
