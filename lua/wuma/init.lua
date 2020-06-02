
WUMA = WUMA or {}

WUMA.VERSION = "1.3.0"
WUMA.AUTHOR = "Erik 'Weol' Rahka"

WUMA.Settings = WUMA.Settings or {}

WUMA.AdditionalLimits = WUMA.AdditionalLimits or {}

function WUMA.Initialize()

	include("wuma/files.lua")
	include("wuma/log.lua")

	--Create Data folder
	WUMA.Files.CreateDir("wuma/")

	--Create userfiles folder
	WUMA.Files.CreateDir("wuma/users/")

	--Include object factory before loading objects
	include("wuma/shared/objects.lua")
	AddCSLuaFile("wuma/shared/objects.lua")

	--Load objects
	WUMA.LoadFolder("wuma/objects/")
	WUMA.LoadCLFolder("wuma/objects/")

	--Include CAMI before files that depend on it
	include("wuma/shared/cami.lua")
	AddCSLuaFile("wuma/shared/cami.lua")

	--Shared init is dependent of stuff in here
	include("wuma/shared/items.lua")
	AddCSLuaFile("wuma/shared/items.lua")

	--Include and run shared init
	include("wuma/shared/init.lua")
	AddCSLuaFile("wuma/shared/init.lua")

	--Include core
	include("wuma/util.lua")
	include("wuma/commands.lua")
	include("wuma/users.lua")
	include("wuma/limits.lua")
	include("wuma/restrictions.lua")
	include("wuma/loadouts.lua")
	include("wuma/inheritance.lua")
	include("wuma/hooks.lua")
	include("wuma/duplicator.lua")
	include("wuma/rpc.lua")
	include("wuma/subscriptions.lua")
	include("wuma/extentions/playerextention.lua")
	include("wuma/extentions/entityextention.lua")

	--Register WUMA access with CAMI
	CAMI.RegisterPrivilege{Name="wuma gui", MinAccess="superadmin", Description="Access to WUMA GUI"}

	--Who am I writing these for?
	WUMALog("Weol's User Management Addon version %s", WUMA.VERSION)

	--Initialize database tables
	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMALookup` (
			`steamid` varchar(22) NOT NULL PRIMARY KEY,
			`nick` varchar(42),
			`usergroup` varchar(42),
			`t` int
		)
	]])

	WUMASQL([[CREATE INDEX IF NOT EXISTS `WUMALOOKUPINDEX` ON WUMALookup(`nick`)]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMARestrictions` (
			`type` VARCHAR(45) NOT NULL,
			`parent` VARCHAR(45) NOT NULL,
			`item` VARCHAR(45) NOT NULL,
			`is_anti` INT(1) NULL,
			PRIMARY KEY (`type`, `parent`, `item`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMALimits` (
			`parent` VARCHAR(45) NOT NULL,
			`item` VARCHAR(45) NOT NULL,
			`limit` INT NOT NULL,
			`is_exclusive` INT(1) NULL,
			PRIMARY KEY (`parent`, `item`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMALoadouts` (
			`parent` INT NOT NULL,
			`class` VARCHAR(45) NOT NULL,
			`primary_ammo` INT NULL,
			`secondary_ammo` INT NULL,
			`ignore_restrictions` INT(1) NULL,
			PRIMARY KEY (`parent`, `class`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMAScopes` (
			`parent` VARCHAR(45) NOT NULL,
			`type` VARCHAR(45) NULL,
			`data` VARCHAR(45) NULL,
			PRIMARY KEY (`parent`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMASettings` (
			`parent` VARCHAR(45) NOT NULL,
			`key` VARCHAR(45) NULL,
			`value` VARCHAR(45) NULL,
			PRIMARY KEY (`parent`, `key`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMAInheritance` (
			`type` VARCHAR(45) NOT NULL,
			`usergroup` VARCHAR(45) NULL,
			`inheritFrom` VARCHAR(45) NULL,
			PRIMARY KEY (`type`, `usergroup`)
		)
	]])

	--Load shared files
	WUMALog("Loading shared files")

	include("wuma/shared/net.lua")
	AddCSLuaFile("wuma/shared/net.lua")

	--Load client files
	WUMALog("Loading client files")
	WUMA.LoadCLFolder("wuma/client/")

	--Allow the poor scopes to think
	--Scope:StartThink()

	--Add hook so playerextention loads when the first player joins
	hook.Add("PlayerAuthed", "WUMAPlayerAuthedPlayerExtentionInit", function()
		include("wuma/extentions/playerextention.lua")
		if E2Lib then include("wuma/expression2.lua") end
		hook.Remove("PlayerAuthed", "WUMAPlayerAuthedPlayerExtentionInit")
	end)

	--All overides should be loaded after WUMA
	hook.Call("OnWUMALoaded")
end

function WUMA.SetSetting(parent, key, value)
	if WUMA.Settings[parent] then
		WUMA.Settings[parent][key] = value
	end

	WUMASQL([[INSERT INTO `WUMASettings` (`parent`, `key`, `value`) VALUES ("%s", "%s", "%s")]], parent, key, value)

	hook.Call("WUMASettingChanged", nil, parent, key, value)
end

function WUMA.GetSetting(parent, key)
	if WUMA.Settings[parent] then
		return WUMA.Settings[parent][key]
	end
end

--Override CreateConvar in order to find out if any addons are creating sbox_max limits
local oldCreateConVar = CreateConVar
function CreateConVar(...)
	local args = {...}
	if (string.Left(args[1], 8) == "sbox_max") then
		WUMA.AdditionalLimits[string.sub(args[1], 9)] = true
	end
	return oldCreateConVar(...)
end

function WUMA.CreateConVar(...)
	local convar = CreateConVar(...)
	local setting = string.sub(convar:GetName(), 6)

	WUMA.Settings[setting] = convar:GetString()

	cvars.AddChangeCallback(convar:GetName(), function(convar, old, new)
		WUMA.Settings[setting] = new
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
