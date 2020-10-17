
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

	--Include net functions before files that depend on it
	include("wuma/shared/net.lua")
	AddCSLuaFile("wuma/shared/net.lua")

	--restriction_types.lua is dependent of stuff in here
	include("wuma/shared/items.lua")
	AddCSLuaFile("wuma/shared/items.lua")

	include("wuma/shared/restriction_types.lua")
	AddCSLuaFile("wuma/shared/restriction_types.lua")

	--Include core
	include("wuma/util.lua")
	include("wuma/users.lua")
	include("wuma/limits.lua")
	include("wuma/restrictions.lua")
	include("wuma/loadouts.lua")
	include("wuma/inheritance.lua")
	include("wuma/hooks.lua")
	include("wuma/duplicator.lua")
	include("wuma/extentions/entityextention.lua")

	--Clients need this for client-side GetCount
	AddCSLuaFile("wuma/extentions/playerextention.lua")

	--Include RPC functions
	include("wuma/shared/rpc.lua")
	AddCSLuaFile("wuma/shared/rpc.lua")

	--Include subscription functions
	include("wuma/shared/subscriptions.lua")
	AddCSLuaFile("wuma/shared/subscriptions.lua")

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
			`type` TEXT NOT NULL,
			`parent` TEXT NOT NULL,
			`item` TEXT NOT NULL,
			`is_anti` INT(1) NULL,
			PRIMARY KEY (`type`, `parent`, `item`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMALimits` (
			`parent` TEXT NOT NULL,
			`item` TEXT NOT NULL,
			`limit` TEXT NOT NULL,
			`is_exclusive` INT(1) NULL,
			PRIMARY KEY (`parent`, `item`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMALoadouts` (
			`parent` TEXT NOT NULL,
			`class` TEXT NOT NULL,
			`primary_ammo` INT NULL,
			`secondary_ammo` INT NULL,
			PRIMARY KEY (`parent`, `class`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMAScopes` (
			`parent` TEXT NOT NULL,
			`type` TEXT NULL,
			`data` TEXT NULL,
			PRIMARY KEY (`parent`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMASettings` (
			`parent` TEXT NOT NULL,
			`key` TEXT NULL,
			`value` TEXT NULL,
			PRIMARY KEY (`parent`, `key`)
		)
	]])

	WUMASQL([[
		CREATE TABLE IF NOT EXISTS `WUMAInheritance` (
			`type` TEXT NOT NULL,
			`usergroup` TEXT NULL,
			`inheritFrom` TEXT NULL,
			PRIMARY KEY (`type`, `usergroup`)
		)
	]])

	--Load inheritance from database
	WUMA.LoadInheritance()

	--Load client files
	WUMALog("Loading client files")
	WUMA.LoadCLFolder("wuma/client/")

	--Allow the poor scopes to think
	--Scope:StartThink()

	--Add hook so playerextention loads when the first player joins
	hook.Add("PlayerAuthed", "WUMA_INIT_PlayerAuthed", function(ply)
		include("wuma/extentions/playerextention.lua")
		ply:SendLua([[include("wuma/extentions/playerextention.lua")]])

		if E2Lib then include("wuma/expression2.lua") end
		hook.Remove("PlayerAuthed", "WUMA_INIT_PlayerAuthed")
	end)

	--All overides should be loaded after WUMA
	hook.Call("OnWUMALoaded")
end

function WUMA.SetSetting(parent, key, value)
	if WUMA.Settings[parent] then
		WUMA.Settings[parent][key] = value
	end

	if value then
		WUMASQL([[REPLACE INTO `WUMASettings` (`parent`, `key`, `value`) VALUES ("%s", "%s", "%s")]], parent, key, value)
	else
		WUMASQL([[DELETE FROM `WUMASettings` WHERE `parent` == "%s" AND `key` == "%s"]], parent, key)
	end

	hook.Call("WUMAOnSettingChanged", nil, parent, key, value)
end

local function convertSettingValue(value)
	if value == "'true'" or value == "true" then
		return true
	end

	if (tonumber(value) ~= nil) then
		return tonumber(value)
	end

	return value
end

function WUMA.GetSetting(parent, key)
	local settings = WUMASQL([[SELECT * FROM `WUMASettings` WHERE `parent` == "%s" AND `key` == "%s"]], parent, key)

	if not settings then return nil end

	return convertSettingValue(settings[1].value)
end

function WUMA.ReadSettings(parent)
	local settings = WUMASQL([[SELECT * FROM `WUMASettings` WHERE `parent` == "%s"]], parent)

	if not settings then return {} end

	local tbl = {}
	for i, setting in pairs(settings) do
		tbl[settings[i].key] = convertSettingValue(settings[i].value)
	end

	return tbl
end

local function userDisconnect(user)
	WUMA.Settings[user:SteamID()] = nil
end
hook.Add("PlayerDisconnected", "WUMA_INIT_PlayerDisconnected", userDisconnect)

local function playerInitialSpawn(player)
	WUMA.Settings[player:SteamID()] = WUMA.ReadSettings(player:SteamID()) or {}
end
hook.Add("PlayerInitialSpawn", "WUMA_INIT_PlayerInitialSpawn", playerInitialSpawn)

local function usergroupRegistered(usergroup)
	WUMA.Settings[usergroup] = WUMA.ReadSettings(usergroup) or {}
end
hook.Add("CAMI.OnUsergroupRegistered", "WUMA_INIT_CAMI.OnUsergroupRegistered", usergroupRegistered)

local function usergroupUnregistered(usergroup)
	WUMA.Settings[usergroup] = nil
end
hook.Add("CAMI.OnUsergroupUnregistered", "WUMA_INIT_CAMI.OnUsergroupUnregistered", usergroupUnregistered)

--Override CreateConvar in order to find out if any addons are creating sbox_max limits
local oldCreateConVar = CreateConVar
function CreateConVar(...)
	local args = {...}
	if (string.Left(args[1], 8) == "sbox_max") then
		WUMA.AdditionalLimits[string.sub(args[1], 9)] = true
	end
	return oldCreateConVar(...)
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
