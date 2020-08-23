
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

	WUMADebug("Loading objects")
	include("wuma/objects/object.lua")
	include("wuma/objects/userobject.lua")
	include("wuma/objects/access.lua")
	include("wuma/objects/stream.lua")
	include("wuma/objects/scope.lua")
	include("wuma/objects/loadout.lua")
	include("wuma/objects/loadout_weapon.lua")
	include("wuma/objects/restriction.lua")
	include("wuma/objects/limit.lua")

	hook.Add("PostGamemodeLoaded", "WUMAPostGamemodeLoadedPlayerExtentionInit", function()
		include("wuma/extentions/playerextention.lua")
		hook.Remove("PostGamemodeLoaded", "WUMAPostGamemodeLoadedPlayerExtentionInit")
	end)

	--Load shared folder
	WUMADebug("Loading shared folder")
	WUMA.IncludeFolder("wuma/shared/")

	--Load vgui folder
	WUMADebug("Loading VGUI folder")
	WUMA.IncludeFolder(WUMA.HomePath.."vgui/")

	--All overides should be loaded after WUMA
	hook.Call("OnWUMALoaded")
end

function WUMA.IncludeFolder(dir)
	dir = dir or ""
	local files, directories = file.Find(dir.."*", "LUA")

	for _, file in pairs(files) do
		WUMADebug(" %s", dir..file)

		include(dir..file)
	end

	for _, directory in pairs(directories) do
		WUMA.IncludeFolder(dir..directory.."/")
	end
end

local uniqueIDs = 0
function WUMA.GenerateUniqueID()
	local id = uniqueIDs+1
	uniqueIDs = uniqueIDs + 1
	return id
end

function WUMA.IsSteamID(steamid)
	return string.match(steamid, [[STEAM_\d{1}:\d{1}:\d*]])
end

function WUMA.GetServerTime()
	return os.time() + (WUMA.ServerSettings["server_time_offset"] or 0)
end

function WUMA.NotifyTypeRestriction(type)
	notification.AddLegacy(string.format("%s are restricted!", type), NOTIFY_ERROR, 3)
end

function WUMA.NotifyRestriction(type, str)
	notification.AddLegacy(string.format("This %s (%s) is restricted!", type, str), NOTIFY_ERROR, 3)
end

function WUMA.NotifyLimitHit(str)
	notification.AddLegacy(string.format("You've hit the %s limit!", str), NOTIFY_ERROR, 3)
	surface.PlaySound("buttons/button10.wav")
end

WUMA.Initialize()