
WUMA = WUMA or {}
WUMA.DATA = {}

function WUMA.GetSavedTable(enum,user)
	if (enum == Restriction) then
		return WUMA.GetSavedRestrictions(user)
	elseif (enum == Limit) then
		return WUMA.GetSavedLimits(user)
	elseif (enum == Loadout) then
		return WUMA.GetSavedLoadouts(user)
	end
end

local function isTableEmpty(tbl) 
	if (table.Count(tbl) < 1) then return true else return false end
end

--Global files
WUMA.DATA.GlobalSchedule = {}
WUMA.DATA.GlobalCache = {}

local tick_global = WUMA.DataUpdateCooldown + 1
function WUMA.ScheduleDataFileUpdate(enum,func,finally)
	table.insert(WUMA.DATA.GlobalSchedule,{enum=enum,func=func})
	
	WUMA.CacheData(enum,func,finally)
	
	tick_global = 0 
end


function WUMA.CacheData(enum,func,finally)
	WUMA.DATA.GlobalCache[enum] = func(WUMA.DATA.GlobalCache[enum] or WUMA.GetSavedTable(enum))
	if finally then finally() end
end

function WUMA.GetCachedData(enum)
	if WUMA.DATA.GlobalCache[enum] then return WUMA.DATA.GlobalCache[enum] end
	return false
end

function WUMA.SaveData(restrictions,limits,loadouts) 

	if (restrictions) then
		local str = util.TableToJSON(restrictions)
		WUMA.Files.Write(WUMA.DataDirectory.."restrictions.txt",str)	
	elseif (restrictions == WUMA.DELETE) then
		WUMA.Files.Delete(WUMA.DataDirectory.."restrictions.txt")
	end
	
	if (limits) then
		local str = util.TableToJSON(limits)
		WUMA.Files.Write(WUMA.DataDirectory.."limits.txt",str)
	elseif (limits == WUMA.DELETE) then
		WUMA.Files.Delete(WUMA.DataDirectory.."limits.txt")
	end
	
	if (loadouts) then
		local str = util.TableToJSON(loadouts)
		WUMA.Files.Write(WUMA.DataDirectory.."loadouts.txt",str)
	elseif (loadouts == WUMA.DELETE) then
		WUMA.Files.Delete(WUMA.DataDirectory.."loadouts.txt")
	end
	
end 

function WUMA.Update_Global()
	tick_global = tick_global + 1
	
	local restrictions, limits, loadouts = false
	local update = {}
	
	if (tick_global == WUMA.DataUpdateCooldown) then 
		WUMADebug("Saved data.\n")
	
		for _, tbl in pairs(WUMA.DATA.GlobalSchedule) do
			if (tbl.enum == Restriction) then
				restrictions = tbl.func(restrictions or WUMA.GetSavedRestrictions())
				update.restrictions = tbl.func(update.restrictions or {})
			elseif (tbl.enum == Limit)then
				limits = tbl.func(limits or WUMA.GetSavedLimits())
				update.limits = tbl.func(update.limits or {})
			elseif (tbl.enum == Loadout)then
				loadouts = tbl.func(loadouts or WUMA.GetSavedLoadouts())
				update.loadouts = tbl.func(update.loadouts or {})
			end
		end
			
		for _, tbl in pairs ({restrictions, limits, loadouts}) do
			if (isTableEmpty(tbl)) then tbl = WUMA.DELETE end
		end
		
		WUMA.DATA.GlobalSchedule = {}

		WUMA.SaveData(restrictions,limits,loadouts) 
		WUMA.UpdateClients(update)
		
		update = false
		restrictions, limits, loadouts = false
	end
end
timer.Create("WUMAUpdateGlobalTables", 1, 0, WUMA.Update_Global)   
 
--User files
WUMA.DATA.UserSchedule = {}
WUMA.DATA.UserCache = {}

local tick_user = WUMA.DataUpdateCooldown+1
function WUMA.ScheduleUserFileUpdate(user,enum,func,finally)
	table.insert(WUMA.DATA.UserSchedule,{user=user:SteamID(),enum=enum,func=func})
	
	WUMA.CacheUserData(user,enum,func,finally)
	
	tick_user = 0
end

function WUMA.CacheUserData(user,enum,func,finally)
	WUMA.DATA.UserCache[user] = WUMA.DATA.UserCache[user] or {}
	WUMA.DATA.UserCache[user][enum] = func(WUMA.DATA.UserCache[user][enum] or WUMA.GetSavedTable(enum,user))
	if finally then finally() end
end

function WUMA.GetCachedUserData(user,enum)
	if WUMA.DATA.UserCache[user] and WUMA.DATA.UserCache[user][enum] then return WUMA.DATA.UserCache[user][enum] end
	return false
end

function WUMA.SaveUserData(user,restrictions,limits,loadouts) 
	
	WUMA.Files.CreateDir(WUMA.DataDirectory.."users/"..WUMA.GetUserFolder(user))
	
	if (restrictions) then
		local str = util.TableToJSON(restrictions)
		WUMA.Files.Write(WUMA.GetUserFile(user,Restriction),str)
	elseif (restrictions == WUMA.DELETE) then
		WUMA.DeleteUserFile(user,Restriction)
	end
	
	if (limits) then
		local str = util.TableToJSON(limits)
		WUMA.Files.Write(WUMA.GetUserFile(user,Limit),str)
	elseif (limits == WUMA.DELETE) then
		WUMA.DeleteUserFile(user,Limit)
	end

	if (loadouts) then
		local str = util.TableToJSON(loadouts)
		WUMA.Files.Write(WUMA.GetUserFile(user,Loadout),str)
	elseif (loadouts == WUMA.DELETE) then
		WUMA.DeleteUserFile(user,Loadout)
	end
	
end

function WUMA.Update_User()
	tick_user = tick_user + 1
	
	local restrictions = {}
	local limits = {}
	local loadouts = {}
	
	local update = {}
	
	if (tick_user == WUMA.DataUpdateCooldown) then 
		local users = {}
		for _, tbl in pairs(WUMA.DATA.UserSchedule) do
			if (tbl.enum == Restriction) then
				restrictions[tbl.user] = tbl.func(restrictions[tbl.user] or WUMA.GetSavedRestrictions(tbl.user))
			elseif (tbl.enum == Limit)then
				limits[tbl.user] = tbl.func(limits[tbl.user] or WUMA.GetSavedLimits(tbl.user))
			elseif (tbl.enum == Loadout)then
				loadouts[tbl.user] = tbl.func(loadouts[tbl.user] or WUMA.GetSavedLoadouts(tbl.user))
			end 
			
			if not table.HasValue(users,tbl.user) then table.insert(users,tbl.user) end
		end 

		for _, users in pairs ({restrictions, limits, loadouts}) do
			for user, tbl in pairs(users) do
				if (isTableEmpty(tbl)) then tbl = WUMA.DELETE end
			end
		end
		
		for _,user in pairs(users) do
			WUMA.SaveUserData(user,restrictions[user], limits[user], loadouts[user]) 
		end 
		
		Msg("Saved user data.\n")
		
	end
end
timer.Create("WUMAUpdateUserTables", 1, 0, WUMA.Update_User)

function WUMA.GetUserFolder(user)
	if (string.lower(type(user)) == "string") then
		return string.gsub(user,":","_").."/"
	else
		return string.gsub(user:SteamID(),":","_").."/"
	end
end

function WUMA.GetUserFile(user,enum)
	local folder = WUMA.GetUserFolder(user)

	if (enum == Restriction) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."/restrictions.txt"
	elseif (enum == Limit)then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."/limits.txt"
	elseif (enum == Loadout)then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."/loadout.txt"
	end
end

function WUMA.CheckUserFileExists(user,enum)
	return WUMA.Files.Exists(WUMA.GetUserFile(user,enum))
end

function WUMA.DeleteUserFile(user,enum)
	WUMA.Files.Delete(WUMA.GetUserFile(user,enum))
	if not WUMA.CheckUserFileExists(user,Restriction) and not WUMA.CheckUserFileExists(user,Limit) and not WUMA.CheckUserFileExists(user,Loadout) then
		WUMA.DeleteUserFolder(user)
	end
end

function WUMA.DeleteUserFolder(user)
	WUMA.Files.Delete(WUMA.DataDirectory..WUMA.UserDataDirectory..WUMA.GetUserFolder(user))
	
end
 
local function onShutdown()
	tick_user = WUMA.DataUpdateCooldown - 1
	tick_global = WUMA.DataUpdateCooldown -1
    WUMA.Update_User()
	WUMA.Update_Global()
end
hook.Add("ShutDown", "WUMADatahandlerShutdown", onShutdown)
