
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.DATA = {}

WUMA.DataUpdateCooldown = WUMA.CreateConVar("wuma_data_save_delay", "10", FCVAR_ARCHIVE, "Delay before changes are saved.")

function WUMA.GetSavedTable(enum, user)
	if (enum == Restriction) then
		return WUMA.GetSavedRestrictions(user)
	elseif (enum == Limit) then
		return WUMA.GetSavedLimits(user)
	elseif (enum == Loadout) then
		return WUMA.GetSavedLoadouts(user)
	end
end

function WUMA.isTableEmpty(tbl) 
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

function WUMA.AddDataSubscription(user, target, extra)
	if WUMA.IsSteamID(target) then
		WUMA.DATA.Subscriptions.users[target] = WUMA.DATA.Subscriptions.users[target] or {}
		WUMA.DATA.Subscriptions.users[target][extra] = WUMA.DATA.Subscriptions.users[target][extra] or {}
		WUMA.DATA.Subscriptions.users[target][extra][user:SteamID()] = user
	else
		if not (WUMA.DATA.Subscriptions[target]) then WUMA.DATA.Subscriptions[target] = {} end
		WUMA.DATA.Subscriptions[target][user:SteamID()] = user
	end
end

function WUMA.RemoveDataSubscription(user, target, extra)

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

function WUMA.GetDataSubsribers(target, enum)
	if WUMA.IsSteamID(target) then
		if not WUMA.DATA.Subscriptions.users[target] then return {} end
		if not WUMA.DATA.Subscriptions.users[target][enum] then return {} end --Stops here
		return WUMA.DATA.Subscriptions.users[target][enum]
	else
		if not (WUMA.DATA.Subscriptions[target]) then return {} end 
		return WUMA.DATA.Subscriptions[target]
	end
end

function WUMA.RemoveClientUpdateUser(user)
	
	WUMA.RemoveDataSubscription(user, Restriction:GetID())
	WUMA.RemoveDataSubscription(user, Limit:GetID())
	WUMA.RemoveDataSubscription(user, Loadout:GetID())
	
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
hook.Add("PlayerDisconnected", "WUMADataHandlerPlayerDisconnected", WUMA.RemoveClientUpdateUser, 0)

function WUMA.SendData(user)
 
	if WUMA.Files.Exists(WUMA.DataDirectory.."restrictions.txt") then
		WUMA.SendCompressedData(user, WUMA.GetSavedRestrictions(), Restriction:GetID())
	end
	
	if WUMA.Files.Exists(WUMA.DataDirectory.."limits.txt") then
		WUMA.SendCompressedData(user, WUMA.GetSavedLimits(), Limit:GetID())
	end

	if WUMA.Files.Exists(WUMA.DataDirectory.."loadouts.txt") then
		WUMA.SendCompressedData(user, WUMA.GetSavedLoadouts(), Loadout:GetID())
	end
	
end

--Client updates
WUMA.DATA.ClientUpdates = {}
WUMA.DATA.ClientUpdates.users = {}

local tick_clients = false
function WUMA.AddClientUpdate(enum, func, user)
	if (table.Count(player.GetAll()) == 0) then return end --Why bother?
	if isentity(user) then user = user:SteamID() end
	enum = enum:GetID()

	if (user) then
		local tbl = WUMA.DATA.ClientUpdates.users
		
		if not (tbl[user]) then tbl[user] = {} end
		if not (tbl[user][enum]) then tbl[user][enum] = {} end
		tbl[user][enum] = func(tbl[user][enum])
	else
		local tbl = WUMA.DATA.ClientUpdates
		
		if not (tbl[enum]) then tbl[enum] = {} end
		tbl[enum] = func(tbl[enum])
	end
	
	if not tick_clients then
		hook.Add("Think", "WUMAClientUpdateCooldown", WUMA.Clients_Tick)
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
				WUMA.SendCompressedData(WUMA.GetDataSubsribers(enum), tbl, enum)
			end
		end

		for user, tbl in pairs (WUMA.DATA.ClientUpdates.users) do
			for enum, data in pairs(tbl) do
				for _, subscriber in pairs(WUMA.GetDataSubsribers(user, enum)) do
					WUMA.SendCompressedData(subscriber, data, enum..":::"..user)
				end
			end
		end

		WUMA.DATA.ClientUpdates = {}
		WUMA.DATA.ClientUpdates.users = {}
	end
end

WUMA.DATA.DataRegistry = {}
WUMA.DATA.DataSchedule = {}

local tick_global = WUMA.DataUpdateCooldown:GetInt() + 1
function WUMA.ScheduleDataUpdate(id, func)
	if WUMA.DATA.DataRegistry[id] then
		table.insert(WUMA.DATA.DataSchedule, {id=id, func=func})
		
		tick_global = 0
		
		WUMA.InvalidateCache(id)
	else
		WUMADebug("Tried to schedule unregistered data update (%s)!", id)
	end
end

function WUMA.RegisterDataID(id, path, init)
	WUMA.DATA.DataRegistry[id] = {path=path, init=init}
end

function WUMA.SaveData(data) 
	
	local dataregistry = WUMA.DATA.DataRegistry
	
	for id, tbl in pairs(data) do
		if (tbl and tbl ~= WUMA.DELETE) then
			local str = util.TableToJSON(tbl)
			WUMA.Cache(id, util.Compress(str)) --Cache the compressed data
			WUMA.Files.Write(WUMA.DataDirectory..dataregistry[id].path, str)	
		elseif (tbl == WUMA.DELETE) then
			WUMA.Files.Delete(WUMA.DataDirectory..dataregistry[id].path)
		end
	end
	
end 

function WUMA.UpdateGlobal()
	if (tick_global >= 0) then
		tick_global = tick_global + 1
	end

	if (tick_global >= WUMA.DataUpdateCooldown:GetInt()) then 
		local tbl = {}
		local dataregistry = WUMA.DATA.DataRegistry
		
		for _, update in pairs(WUMA.DATA.DataSchedule) do
			tbl[update.id] = update.func(tbl[update.id] or dataregistry[update.id].init())
		end
		
		for _, update in pairs(WUMA.DATA.DataSchedule) do
			tbl[update.id].m = nil
		end
		
		for id, update in pairs(dataregistry) do
			if (WUMA.isTableEmpty(tbl[id]) and tbl[id] ~= nil) then 
				tbl[id] = WUMA.DELETE 
			end
		end

		WUMA.DATA.DataSchedule = {}

		WUMA.SaveData(tbl) 

		tick_global = -1
	end
end
timer.Create("WUMAUpdateData", 1, 0, WUMA.UpdateGlobal) 

WUMA.DATA.UserDataRegistry = {}
WUMA.DATA.UserDataSchedule = {}

local tick_user = WUMA.DataUpdateCooldown:GetInt() + 1
function WUMA.ScheduleUserDataUpdate(user, id, func)
	if WUMA.DATA.UserDataRegistry[id] then
		if isentity(user) then user = user:SteamID() end
		table.insert(WUMA.DATA.UserDataSchedule, {id=id, func=func, user=user})
		
		tick_user = 0
	else
		WUMADebug("Tried to schedule unregistered userdata update (%s)!", id)
	end
end

function WUMA.RegisterUserDataID(id, path, init, delete)
	WUMA.DATA.UserDataRegistry[id] = {path=path, init=init, delete=delete}
end

function WUMA.SaveUserData(data) 
	
	local dataregistry = WUMA.DATA.UserDataRegistry
	for user, tbls in pairs(data) do
		for id, tbl in pairs(tbls) do
			if (tbl and tbl ~= WUMA.DELETE) then
				local str = util.TableToJSON(tbl)
				WUMA.Files.CreateDir(WUMA.DataDirectory..WUMA.UserDataDirectory..WUMA.GetUserFolder(user))
				WUMA.Files.Write(WUMA.DataDirectory..WUMA.UserDataDirectory..WUMA.GetUserFolder(user)..dataregistry[id].path, str)	
			elseif (tbl == WUMA.DELETE) then
				WUMA.DeleteUserFile(user, id)
			end
		end
	end
	
end 

function WUMA.UpdateUser()
	if (tick_user >= 0) then
		tick_user = tick_user + 1
	end

	if (tick_user >= WUMA.DataUpdateCooldown:GetInt()) then 
		local tbl = {}
		local dataregistry = WUMA.DATA.UserDataRegistry

		for _, update in pairs(WUMA.DATA.UserDataSchedule) do
			tbl[update.user] = tbl[update.user] or {}
			tbl[update.user][update.id] = update.func(tbl[update.user][update.id] or dataregistry[update.id].init(update.user))
		end
		
		for _, update in pairs(WUMA.DATA.UserDataSchedule) do
			if tbl[update.user] then
				tbl[update.user][update.id].m = nil
			end
		end
		
		for id, data in pairs(dataregistry) do
			for user, updates in pairs(tbl) do
				if (data.delete(updates[id] or data.init(user)) and updates[id] ~= nil) then 
					updates[id] = WUMA.DELETE 
				end
			end
		end

		WUMA.DATA.UserDataSchedule = {}

		WUMA.SaveUserData(tbl) 

		tick_user = -1
	end
end
timer.Create("WUMAUpdateUserData", 1, 0, WUMA.UpdateUser)

function WUMA.GetUserFolder(user)
	if (isstring(user)) then
		return string.gsub(user, ":", "_").."/"
	else
		return string.gsub(user:SteamID(), ":", "_").."/"
	end
end

function WUMA.GetUserFile(user, enum)
	local folder = WUMA.GetUserFolder(user)

	if (enum == Restriction or enum == Restriction:GetID()) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."restrictions.txt"
	elseif (enum == Limit or enum == Limit:GetID()) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."limits.txt"
	elseif (enum == Loadout or enum == Loadout:GetID()) then
		return WUMA.DataDirectory..WUMA.UserDataDirectory..folder.."loadouts.txt"
	end
end

function WUMA.CheckUserFileExists(user, enum)
	return WUMA.Files.Exists(WUMA.GetUserFile(user, enum))
end

function WUMA.DeleteUserFile(user, enum)
	WUMA.Files.Delete(WUMA.GetUserFile(user, enum))

	timer.Simple(2, function()
		if not WUMA.CheckUserFileExists(user, Restriction) and not WUMA.CheckUserFileExists(user, Limit) and not WUMA.CheckUserFileExists(user, Loadout) then
			WUMA.DeleteUserFolder(user)
		end
	end)
end

function WUMA.DeleteUserFolder(user)
	local path = WUMA.DataDirectory..WUMA.UserDataDirectory..WUMA.GetUserFolder(user)
	WUMA.Files.Delete(string.Left(path, string.len(path)-1))
end
 
local function onShutdown()
	tick_user = WUMA.DataUpdateCooldown:GetInt() - 1
	tick_global = WUMA.DataUpdateCooldown:GetInt() -1
WUMA.UpdateUser()
	WUMA.UpdateGlobal()
end
hook.Add("ShutDown", "WUMADatahandlerShutdown", onShutdown)