
WUMA = WUMA or {}

--Create server convars so we can access them on client side
CreateConVar("wuma_exclude_limits", "1", FCVAR_REPLICATED, "Exclude wuma limits from normal gamemode limits")
CreateConVar("wuma_personal_loadout_chatcommand", "!loadout", FCVAR_REPLICATED, "Chat command to open the loadout selector")
CreateConVar("wuma_log_level", "1", FCVAR_REPLICATED, "0=None, 1=Normal, 2=Debug")
CreateConVar("wuma_echo_changes", "2", FCVAR_REPLICATED, "0 = Nobody, 1 = Access, 2 = Everybody, 3 = Relevant")
CreateConVar("wuma_echo_to_chat", "1", FCVAR_REPLICATED, "Enable / disable echo in chat.")

function WUMA.Initialize()

	include("log.lua")
	include("datahandler.lua")

	--Include object factory before loading objects
	include("wuma/shared/objects.lua")
	AddCSLuaFile("wuma/shared/objects.lua")

	WUMADebug("Loading objects")
	WUMA.IncludeFolder("wuma/objects/")

	--Include CAMI before files that depend on it
	include("wuma/shared/cami.lua")
	AddCSLuaFile("wuma/shared/cami.lua")

	--Include net functions before files that depennd on it
	include("wuma/shared/net.lua")
	AddCSLuaFile("wuma/shared/net.lua")

	--Include RPC functions
	include("wuma/shared/rpc.lua")
	AddCSLuaFile("wuma/shared/rpc.lua")

	--Include subscription functions
	include("wuma/shared/subscriptions.lua")
	AddCSLuaFile("wuma/shared/subscriptions.lua")

	--restriction_types.lua is dependent of stuff in here
	include("wuma/shared/items.lua")
	AddCSLuaFile("wuma/shared/items.lua")

	include("wuma/shared/restriction_types.lua")
	AddCSLuaFile("wuma/shared/restriction_types.lua")

	--Load vgui folder
	WUMADebug("Loading VGUI folder")
	WUMA.IncludeFolder("wuma/client/vgui/")

	include("gui.lua")

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
	if not isstring(steamid) then return false end
	return (steamid == string.match(steamid, [[STEAM_%d:%d:%d*]]))
end

function WUMA.OnUsergroupRegistered(usergroup) --RPC from server
	WUMA.Usergroups[usergroup] = usergroup
end

function WUMA.OnUsergroupUnregistered(usergroup) --RPC from server
	WUMA.Usergroups[usergroup] = nil
end

local server_time_offset = 0
function WUMA.CalculateServerTimeDifference(server_time) --RPC from server
	server_time_offset = server_time - os.time()
end

function WUMA.GetServerTimeOffset()
	return server_time_offset
end

function WUMA.GetServerTime()
	return os.time() + server_time_offset
end

function WUMA.NotifyTypeRestriction(type) --RPC from server
	notification.AddLegacy(string.format("%s are restricted!", type), NOTIFY_ERROR, 3)
end

function WUMA.NotifyRestriction(type, str) --RPC from server
	notification.AddLegacy(string.format("This %s (%s) is restricted!", type, str), NOTIFY_ERROR, 3)
end

function WUMA.NotifyLimitHit(str) --RPC from server
	notification.AddLegacy(string.format("You've hit the %s limit!", str), NOTIFY_ERROR, 3)
	surface.PlaySound("buttons/button10.wav")
end

WUMA.Initialize()