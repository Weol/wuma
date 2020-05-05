
WUMA = WUMA or {}

WUMA.ConVars = WUMA.ConVars or {}
WUMA.ConVars.Limits = WUMA.ConVars.Limits or {}
WUMA.ConVars.Settings = WUMA.ConVars.Settings or {}

WUMA.VERSION = "1.3.0"
WUMA.AUTHOR = "Erik 'Weol' Rahka"

--Enums
WUMA.DELETE = "WUMA_delete"
WUMA.EMPTY = "WUMA_empty"

function WUMA.Initialize()

	include("wuma/files.lua")
	include("wuma/log.lua")

	--Create Data folder
	WUMA.Files.CreateDir("wuma/")

	--Create userfiles folder
	WUMA.Files.CreateDir("wuma/users/")

	--Load objects
	WUMA.LoadFolder("wuma/objects/")
	WUMA.LoadCLFolder("wuma/objects/")

	--Include CAMI before files that depend on it
	include("wuma/shared/cami.lua")
	AddCSLuaFile("wuma/shared/cami.lua")

	--Include core
	include("wuma/sql.lua")
	include("wuma/util.lua")
	include("wuma/commands.lua")
	include("wuma/datahandler.lua")
	include("wuma/users.lua")
	include("wuma/limits.lua")
	include("wuma/restrictions.lua")
	include("wuma/loadouts.lua")
	include("wuma/inheritance.lua")
	include("wuma/hooks.lua")
	include("wuma/duplicator.lua")
	include("wuma/extentions/playerextention.lua")
	include("wuma/extentions/entityextention.lua")

	--Register WUMA access with CAMI
	CAMI.RegisterPrivilege{Name="wuma gui", MinAccess="superadmin", Description="Access to WUMA GUI"}

	--Who am I writing these for?
	WUMALog("Weol's User Management Addon version %s", WUMA.VERSION)

	--Initialize lookup table
	if not sql.TableExists(WUMA.SQL.WUMALookupTable) then
		sql.Query(string.format("CREATE TABLE %s (steamid varchar(22) NOT NULL PRIMARY KEY, nick varchar(42), usergroup varchar(42), t int);", str))
		sql.Query(string.format("CREATE INDEX WUMALOOKUPINDEX ON %s(nick);", WUMA.SQL.WUMALookupTable))
	end

	--Load data
	WUMA.LoadRestrictions()
	WUMA.LoadLimits()
	WUMA.LoadLoadouts()
	WUMA.LoadInheritance()

	--Load shared files
	WUMALog("Loading shared files")
	WUMA.LoadCLFolder("wuma/shared/")
	WUMA.LoadFolder("wuma/shared/")

	--Load client files
	WUMALog("Loading client files")
	WUMA.LoadCLFolder("wuma/client/")

	--Allow the poor scopes to think
	Scope:StartThink()

	--Add hook so playerextention loads when the first player joins
	hook.Add("PlayerAuthed", "WUMAPlayerAuthedPlayerExtentionInit", function()
		include("wuma/extentions/playerextention.lua")
		if E2Lib then include("wuma/expression2.lua") end
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
