
TIIP = TIIP or {}
TIIP.DATA = {}

--Global files
TIIP.DATA.GlobalSchedule = {}
local tick_global = TIIP.DataUpdateCooldown + 1
function TIIP.ScheduleDataFileUpdate(enum,func)
	table.insert(TIIP.DATA.GlobalSchedule,{enum=enum,func=func})
	tick_global = 0 
end

function TIIP.GetDataTable(enum)
	local tbl = {}
	
	if enum then return enum("string") end
	return TIIP.DATA.ALL("string")
end

function TIIP.SaveData(restrictions,limits,loadouts) 

	if (restrictions) then
		local str = util.TableToJSON(restrictions)
		TIIP.Files.Write(TIIP.DataDirectory.."restrictions.txt",str)	
	elseif (limits) then
		for _,user in pairs(limits) do
			local str = util.TableToJSON(limits)
			TIIP.Files.Write(TIIP.DataDirectory.."limits.txt",str)
		end
	elseif (loadouts) then
		for _,user in pairs(loadouts) do
			local str = util.TableToJSON(loadouts)
			TIIP.Files.Write(TIIP.DataDirectory.."loadouts.txt",str)
		end
	end
	
end 

function TIIP.Update_Global()
	tick_global = tick_global + 1
	
	local restrictions, limits, loadouts = false
	
	if (tick_global == TIIP.DataUpdateCooldown) then 
		Msg("Saved data.\n")
	
		for _, tbl in pairs(TIIP.DATA.GlobalSchedule) do
			if (tbl.enum == Restriction) then
				restrictions = tbl.func(restrictions or TIIP.GetSavedRestrictions())
			elseif (tbl.enum == Limit)then
				limits = tbl.func(limits or TIIP.GetSavedLimits())
			elseif (tbl.enum == Loadout)then
				loadouts = tbl.func(loadouts or Loadout:GetSavedTable())
			end
		end
		
		TIIP.DATA.GlobalSchedule = {}
		
		TIIP.SaveData(restrictions,limits,loadouts) 
		
		restrictions, limits, loadouts = false
	end
end
timer.Create( "TIIPUpdateGlobalTables", 1, 0, TIIP.Update_Global )   

--User files
TIIP.DATA.UserSchedule = {}
local tick_user = TIIP.DataUpdateCooldown+1
function TIIP.ScheduleUserFileUpdate(user,enum,func)
	table.insert(TIIP.DATA.UserSchedule,{user=user,enum=enum,func=func})
	tick_user = 0
end

function TIIP.GetUserTable(user,enum)
	local tbl = {}
	
	if enum then return enum:GetSavedTable() end
	return {Restrictions = Restriction:GetSavedTable(),Limits = Limit:GetSavedTable(),Loadouts = Loadout:GetSavedTable()}
end

function TIIP.SaveUserData(user,restrictions,limits,loadouts) 
	
	TIIP.Files.CreateDir(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user))
	
	if (restrictions) then
		local str = util.TableToJSON(restrictions)
		TIIP.Files.Write(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user).."restrictions.txt",str)
	elseif (limits) then
		for _,user in pairs(limits) do
			local str = util.TableToJSON(limits)
			TIIP.Files.Write(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user).."limits.txt",str)
		end
	elseif (loadouts) then
		for _,user in pairs(loadouts) do
			local str = util.TableToJSON(loadouts)
			TIIP.Files.Write(TIIP.DataDirectory.."users/"..TIIP.GetUserFolder(user).."loadouts.txt",str)
		end
	end
end

function TIIP.Update_User()
	tick_user = tick_user + 1
	
	local restrictions, limits, loadouts = false
	
	if (tick_user == TIIP.DataUpdateCooldown) then 
		local users = {}
		for _, tbl in pairs(TIIP.DATA.UserSchedule) do
			if (tbl.enum == Restriction) then
				restrictions = tbl.func(restrictions or TIIP.GetSavedRestrictions(tbl.user))
			elseif (tbl.enum == Limit)then
				limits = tbl.func(limits or tbl.enum(tbl.user))
			elseif (tbl.enum == Loadout)then
				loadouts = tbl.func(loadouts or tbl.enum(tbl.user))
			end
			
			users[tbl.user:UniqueID()] = tbl.user
		end
		
		for _,user in pairs(users) do
			TIIP.SaveUserData(user,restrictions, limits, loadouts) 
		end
		
		TIIPLog("Saved user data.")
		
	end
end
timer.Create( "TIIPUpdateUserTables", 1, 0, TIIP.Update_User )

function TIIP.GetUserFolder(user)
	return string.gsub(user:SteamID(),":","_").."/"
end

function TIIP.CheckUserFileExists(user)
	local file = TIIP.GetUserFolder(user)
	return TIIP.Files.Exists(TIIP.DataDirectory.."users/"..file)
end
 
local function onShutdown()
	tick_user = TIIP.DataUpdateCooldown - 1
	tick_global = TIIP.DataUpdateCooldown -1
    TIIP.Update_User()
	TIIP.Update_Global()
end
hook.Add( "ShutDown", "TIIPDatahandlerShutdown", onShutdown )
