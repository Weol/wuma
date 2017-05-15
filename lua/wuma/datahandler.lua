
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.DATA = {}

WUMA.DataUpdateCooldown = WUMA.CreateConVar("wuma_data_save_delay", "30", FCVAR_ARCHIVE, "Delay before changes are saved.")

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
	if not istable(tbl) then return true end
	if (table.Count(tbl) < 1) then return true else return false end
end

--Pooling
WUMA.FunctionPool = {}
WUMA.FunctionTimers = {}

function WUMA.PopFunctionPool(id)
	if (WUMA.FunctionPool[id]) then
		local data = {}
		for k, tbl in pairs(WUMA.FunctionPool[id].data) do
			table.Merge(data, tbl)
		end
		
		local args = WUMA.FunctionPool[id].args
		args[WUMA.FunctionPool[id].datai] = data
		
		WUMA.FunctionPool[id].func(unpack(args))
		WUMA.FunctionPool[id] = nil
		WUMA.FunctionTimers[id] = nil
	end
end

function WUMA.PoolFunction(id, func, data, args, datai) 
	if not WUMA.FunctionTimers[id] then
		timer.Simple(1, function() WUMA.PopFunctionPool(id) end)
		WUMA.FunctionTimers[id] = true
	end

	if WUMA.FunctionPool[id] then 
		table.insert(WUMA.FunctionPool[id].data, data)
	else
		WUMA.FunctionPool[id] = {func=func, data={data}, args=args, datai=datai}
	end
end

--Update Clients
WUMA.DATA.Subscriptions = {}
WUMA.DATA.Subscriptions.users = {} 

function WUMA.AddDataSubscription(user,target,extra)
	if WUMA.IsSteamID(target) then
		WUMA.DATA.Subscriptions.users[target] = WUMA.DATA.Subscriptions.users[target] or {}
		WUMA.DATA.Subscriptions.users[target][extra] = WUMA.DATA.Subscriptions.users[target][extra] or {}
		WUMA.DATA.Subscriptions.users[target][extra][user:SteamID()] = user
	else
		if not (WUMA.DATA.Subscriptions[target]) then WUMA.DATA.Subscriptions[target] = {} end
		WUMA.DATA.Subscriptions[target][user:SteamID()] = user
	end
end

function WUMA.RemoveDataSubscription(user,target,extra)

	user = user:SteamID()
	
	if WUMA.IsSteamID(target) and WUMA.DATA.Subscriptions.users[target] then
		for k, v in pairs(WUMA.DATA.Subscriptions.users[target]) do
			if not extra then
				if v[user] then v[user] = nil end
				if (table.Count(v) < 1) then WUMA.DATA.Subscriptions.users[target][k] = nil end
			else
				if (extra == k) then
					if v[user] then v[user] = nil end
					if (table.Count(v) < 1) then WUMA.DATA.Subscriptions.users[target][k] = nil end
				end
			end
		end
		if (table.Count(WUMA.DATA.Subscriptions.users[target]) < 1) then WUMA.DATA.Subscriptions.users[target] = nil end
	elseif (WUMA.DATA.Subscriptions[target] ~= nil and WUMA.DATA.Subscriptions[target][user]) then
		WUMA.DATA.Subscriptions[target][user] = nil
		if (table.Count(WUMA.DATA.Subscriptions[target]) < 1) then WUMA.DATA.Subscriptions[target] = nil end
	end
	
end

function WUMA.GetDataSubsribers(target,enum)
	if WUMA.IsSteamID(target) then
		if not WUMA.DATA.Subscriptions.users[target] then return {} end
		if not WUMA.DATA.Subscriptions.users[target][enum] then return {} end
		return WUMA.DATA.Subscriptions.users[target][enum]
	else
		if not (WUMA.DATA.Subscriptions[target]) then return {} end 
		return WUMA.DATA.Subscriptions[target]
	end
end

function WUMA.RemoveClientUpdateUser(user)
	
	WUMA.RemoveDataSubscription(user,Restriction:GetID())
	WUMA.RemoveDataSubscription(user,Limit:GetID())
	WUMA.RemoveDataSubscription(user,Loadout:GetID())
	
	user = user:SteamID()
	
	for k, ply in pairs(WUMA.DATA.Subscriptions.users) do 
		for type, subscribers in pairs(ply) do
			for steamid, _ in pairs(subscribers) do
				if (steamid == user) then subscribers[steamid] = nil end
			end 
			if (table.Count(subscribers) < 1) then ply[type] = nil end
		end
		if (table.Count(ply) < 1) then WUMA.DATA.Subscriptions.users[k] = nil end
	end
end
hook.Add("PlayerDisconnected","WUMADataHandlerPlayerDisconnected", WUMA.RemoveClientUpdateUser, 0)

function WUMA.SendData(user)
 
	if WUMA.Files.Exists(WUMA.DataDirectory.."restrictions.txt") then
		WUMA.SendCompressedData(user,WUMA.GetSavedRestrictions(),Restriction:GetID())
	end
	
	if WUMA.Files.Exists(WUMA.DataDirectory.."limits.txt") then
		WUMA.SendCompressedData(user,WUMA.GetSavedLimits(),Limit:GetID())
	end

	if WUMA.Files.Exists(WUMA.DataDirectory.."loadouts.txt") then
		WUMA.SendCompressedData(user,WUMA.GetSavedLoadouts(),Loadout:GetID())
	end
	
end

--Client updates
WUMA.DATA.ClientUpdates = {}
WUMA.DATA.ClientUpdates.users = {}

local tick_clients = false
function WUMA.AddClientUpdate(enum, func, user)
	if (table.Count(player.GetAll()) == 0) then return end
	if isentity(user) then user = user:SteamID() end
	enum = enum:GetID()

	if (user) then
		tbl = WUMA.DATA.ClientUpdates.users
		
		if not (tbl[user]) then tbl[user] = {} end
		if not (tbl[user][enum]) then tbl[user][enum] = {} end
		tbl[user][enum] = func(tbl[user][enum])
	else
		tbl = WUMA.DATA.ClientUpdates
		
		if not (tbl[enum]) then tbl[enum] = {} end
		tbl[enum] = func(tbl[enum])
	end
	
	if not tick_clients then
		hook.Add("Think","WUMAClientUpdateCooldown",WUMA.Clients_Tick)
		tick_clients = 0
	end
end

function WUMA.Clients_Tick()
	tick_clients = tick_clients + 1
	if (tick_clients > 10) then		
		hook.Remove("Think", "WUMAClientUpdateCooldown")
		tick_clients = false
	
		for enum, tbl in pairs (WUMA.DATA.ClientUpdates) do
			if not (enum == "users") then
				WUMA.SendCompressedData(WUMA.GetDataSubsribers(enum),tbl,enum)
			end
		end

		for user, tbl in pairs (WUMA.DATA.ClientUpdates.users) do
			for enum, data in pairs(tbl) do
				for _, subscriber in pairs(WUMA.GetDataSubsribers(user,enum)) do
					WUMA.SendCompressedData(subscriber,data,enum..":::"..user)
				end
			end
		end

		WUMA.DATA.ClientUpdates = {}
		WUMA.DATA.ClientUpdates.users = {}
	end
end

--Global files
WUMA.DATA.GlobalSchedule = {}
WUMA.DATA.GlobalCache = {}

local tick_global = WUMA.DataUpdateCooldown:GetInt() + 1
function WUMA.ScheduleDataFileUpdate(enum,func)
	table.insert(WUMA.DATA.GlobalSchedule,{enum=enum,func=func})
	
	tick_global = 0 
end

function WUMA.SaveData(restrictions,limits,loadouts) 
	
	if (restrictions and restrictions ~= WUMA.DELETE) then
		local str = util.TableToJSON(restrictions)
		WUMA.Files.Write(WUMA.DataDirectory.."restrictions.txt",str)	
	elseif (restrictions == WUMA.DELETE) then
		WUMA.Files.Delete(WUMA.DataDirectory.."restrictions.txt")
	end

	if (limits and limits ~= WUMA.DELETE) then
		local str = util.TableToJSON(limits)
		WUMA.Files.Write(WUMA.DataDirectory.."limits.txt",str)
	elseif (limits == WUMA.DELETE) then
		WUMA.Files.Delete(WUMA.DataDirectory.."limits.txt")
	end

	if (loadouts and loadouts ~= WUMA.DELETE) then
		local str = util.TableToJSON(loadouts)
		WUMA.Files.Write(WUMA.DataDirectory.."loadouts.txt",str)
	elseif (loadouts == WUMA.DELETE) then
		WUMA.Files.Delete(WUMA.DataDirectory.."loadouts.txt")
	end
	
end 

function WUMA.Update_Global()
	if (tick_global >= 0) then
		tick_global = tick_global + 1
	end
	
	local restrictions, limits, loadouts = false

	if (tick_global >= WUMA.DataUpdateCooldown:GetInt()) then 
		for _, tbl in pairs(WUMA.DATA.GlobalSchedule) do
			if (tbl.enum == Restriction) then
				restrictions = tbl.func(restrictions or WUMA.GetSavedRestrictions())
			elseif (tbl.enum == Limit)then
				limits = tbl.func(limits or WUMA.GetSavedLimits())
			elseif (tbl.enum == Loadout)then
				loadouts = tbl.func(loadouts or WUMA.GetSavedLoadouts())
			end
		end

		if (isTableEmpty(restrictions) and limits ~= nil) then 
			restrictions = WUMA.DELETE 
		end
		
		if (isTableEmpty(limits) and limits ~= nil) then 
			limits = WUMA.DELETE 
		end
		
		if (isTableEmpty(loadouts) and limits ~= nil) then 
			loadouts = WUMA.DELETE 
		end
		
		WUMA.DATA.GlobalSchedule = {}

		WUMA.SaveData(restrictions,limits,loadouts) 
		
		restrictions, limits, loadouts = false
		
		tick_global = -1
	end
end
timer.Create("WUMAUpdateGlobalTables", 1, 0, WUMA.Update_Global)   
 
--User files
WUMA.DATA.UserSchedule = {}
WUMA.DATA.UserCache = {}

local tick_user = WUMA.DataUpdateCooldown:GetInt()+1
function WUMA.ScheduleUserFileUpdate(user,enum,func)
	if isentity(user) then user = user:SteamID() end
	table.insert(WUMA.DATA.UserSchedule,{user=user,enum=enum,func=func})

	tick_user = 0
end

function WUMA.SaveUserData(user,restrictions,limits,loadouts) 
	
	WUMA.Files.CreateDir(WUMA.DataDirectory.."users/"..WUMA.GetUserFolder(user))
	
	if (restrictions and restrictions ~= WUMA.DELETE) then
		local str = util.TableToJSON(restrictions)
		WUMA.Files.Write(WUMA.GetUserFile(user,Restriction),str)
	elseif (restrictions == WUMA.DELETE) then
		WUMA.DeleteUserFile(user,Restriction)
	end
	
	if (limits and limits ~= WUMA.DELETE) then
		local str = util.TableToJSON(limits)
		WUMA.Files.Write(WUMA.GetUserFile(user,Limit),str)
	elseif (limits == WUMA.DELETE) then
		WUMA.DeleteUserFile(user,Limit)
	end

	if (loadouts and loadouts ~= WUMA.DELETE) then
		local str = util.TableToJSON(loadouts)
		WUMA.Files.Write(WUMA.GetUserFile(user,Loadout),str)
	elseif (loadouts == WUMA.DELETE) then
		WUMA.DeleteUserFile(user,Loadout)
	end
	
end

function WUMA.Update_User()
	if (tick_user >= 0) then
		tick_user = tick_user + 1
	end
	
	local restrictions = {}
	local limits = {}
	local loadouts = {}
	
	if (tick_user >= 1) then 
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

		WUMA.DATA.UserSchedule = {}
		
		for _, user in pairs(users) do
			if (isTableEmpty(restrictions[user]) and restrictions[user] ~= nil) then 
				restrictions[user] = WUMA.DELETE 
			end
			
			if (isTableEmpty(limits[user]) and limits[user] ~= nil) then 
				limits[user] = WUMA.DELETE 
			end
			
			if (isTableEmpty(loadouts[user]) and loadouts[user] ~= nil) then 
				loadouts[user] = WUMA.DELETE 
			end
		end
		
		
		for _,user in pairs(users) do
			WUMA.SaveUserData(user,restrictions[user], limits[user], loadouts[user]) 
		end 

		tick_user = -10
		
	end
end
timer.Create("WUMAUpdateUserTables", 1, 0, WUMA.Update_User)

function WUMA.GetUserFolder(user)
	if (isstring(user)) then
		return string.gsub(user,":","_").."/"
	else
		return string.gsub(user:SteamID(),":","_").."/"
	end
end

function WUMA.GetUserFile(user,enum)
	local folder = WUMA.GetUserFolder(user)

	if (enum == Restriction) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."restrictions.txt"
	elseif (enum == Limit) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."limits.txt"
	elseif (enum == Loadout) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."loadout.txt"
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
	local path = string.lower(WUMA.DataDirectory..WUMA.UserDataDirectory..WUMA.GetUserFolder(user))
	WUMA.Files.Delete(string.Left(path,string.len(path)-1))
end
 
local function onShutdown()
	tick_user = WUMA.DataUpdateCooldown:GetInt() - 1
	tick_global = WUMA.DataUpdateCooldown:GetInt() -1
    WUMA.Update_User()
	WUMA.Update_Global()
end
hook.Add("ShutDown", "WUMADatahandlerShutdown", onShutdown)