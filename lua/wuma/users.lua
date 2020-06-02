
function WUMA.IsUsergroupConnected(usergroup)
	for _, ply in pairs(player.GetAll()) do
		if (ply:GetUserGroup() == usergroup) then
			return true
		end
	end
	return false
end

function WUMA.GetPlayers(parent)
	if not parent then
		local tbl = {}
		for _, ply in pairs(player.GetAll()) do
			tbl[ply:SteamID()] = ply
		end
		return tbl
	end

	local tbl = {}
	for _, ply in pairs(player.GetAll()) do
		if (ply:GetUserGroup() == parent) or (ply:SteamID() == parent) then
			tbl[ply:SteamID()] = ply
		end
	end
	return tbl
end

function WUMA.IsSteamID(steamid)
	if not isstring(steamid) then return false end
	return (steamid == string.match(steamid, [[STEAM_%d:%d:%d*]]))
end

function WUMA.GetUserGroups()
	local groups = {"superadmin", "admin", "user"}
	for group, tbl in pairs(CAMI.GetUsergroups()) do
		if not table.HasValue(groups, group) then table.insert(groups, group) end
	end
	return groups
end

local function showWUMAMenuCommand(user)
	CAMI.PlayerHasAccess(user, "wuma gui", function(bool)
		if bool then
			user:SendLua([[WUMA.GUI.Toggle()]])
		else
			user:ChatPrint("You do not have access to this command")
		end
	end)
end
concommand.Add("wuma_menu", showWUMAMenuCommand)

local function showPersonalLoadoutCommand(ply)
	CAMI.PlayerHasAccess(ply, "wuma personalloadout", function(bool)
		if bool then
			ply:SendLua([[WUMA.GUI.CreateLoadoutSelector()]])
		else
			ply:ChatPrint("You do not have access to this command")
		end
	end)
end
concommand.Add("wuma_loadout", showPersonalLoadoutCommand)

local function playerChatCommand(user, text)
	if (text == WUMA.PersonalLoadoutCommand:GetString()) then
		user:SendLua([[WUMA.GUI.CreateLoadoutSelector()]])
		return ""
	end
end
hook.Add("PlayerSay", "WUMAChatCommand", playerChatCommand)

local function userDisconnect(user)
	WUMA.AddLookup(user)
end
hook.Add("PlayerDisconnected", "WUMAPlayerDisconnected", userDisconnect)

local function playerInitialSpawn(player)
	WUMARPC(player, "WUMA.CalculateServerTimeDifference", os.time())
end
hook.Add("PlayerInitialSpawn", "WUMAPlayerInitialSpawn", playerInitialSpawn)
