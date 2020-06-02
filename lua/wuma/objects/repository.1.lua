
local object, static = WUMA.ClassFactory.Builder("WUMARepository")

object:AddProperty("table_name", "TableName")
object:AddProperty("keys", "Keys")
object:AddProperty("access", "Access")

object:AddMetaData("indexes", "Indexes")
object:AddMetaData("loaded_keys", "LoadedKeys", {})
object:AddMetaData("hooks", "Hooks", {})
object:AddMetaData("data", "Data", setmetatable({}, {__newindex = function(self, k, v) error("Cannot create new index on WUMA Repository") end}))
object:AddMetaData("network_string", "NetworkString")
object:AddProperty("subscribers", "Subscribers", {})

function object:__construct(args)
	hook.Add("PlayerDisconnected", "WUMARepositoryPlayerDisconnected" .. self:GetName(), function(player) self:Unsubscribe(player) end)

	local network_string = "WUMADataRepository_" .. self:GetName()
	if SERVER then
		local response = sql.Query(
			[[
				CREATE TABLE IF NOT EXISTS `%s` (
					%s,
					`value` TEXT NOT NULL,
					PRIMARY KEY (%s)
				)
			]],
			self:GetTableName(),
			string.format(string.rep("`%s` VARCHAR(45) NOT NULL", #self:GetKeys(), ", "), unpack(self:GetKeys())),
			string.format(string.rep("`%s`", #self:GetKeys(), ", "), unpack(self:GetKeys()))
		)

		if (response == false) then
			error(sql.LastError())
		end

		local indexes = {}
		for _, key in args.keys do
			indexes[key] = {}
		end
		self:SetIndexes(indexes)

		self:SetNetworkString(network_string)
		util.AddNetworkString(network_string)

		net.Receive(network_string, function(_, player)
			local subscribe = net.ReadBool()
			local index = net.ReadTable()

			if subscribe then
				self:Subscribe(player, index)
			else
				self:Unsubscribe(player, index)
			end
		end)
	else
		self:SetNetworkString(network_string)
		net.Receive(network_string, function()
			local await = net.ReadBool()
			local deletion = net.ReadBool()
			local data = net.ReadTable()

			self:RecieveUpdate(data, deletion, await)
		end)
	end
end

function object:__tostring()
	return self:GetName()
end

function object:AddHook(id, func)
	self:GetHooks()[id] = func
end

function object:RemoveHook(id)
	self:GetHooks()[id] = nil
end

function object:RunHook(update_data, delete_data)
	for func in self:GetHooks() do
		func(update_data, delete_data)
	end
end

function object:Get(key, index)
	if index then
		return self:GetIndexes()[index].index[key]
	end
	return self:GetData()[key]
end

local function createIndexTable()
	return setmetatable({}, {
		__mode = "kv",
		__newindex = function(self, k, v)
			error("cannot write to WUMA repository index table")
		end
	})
end

function object:CreateIndex(name)
	local indexes = self:GetIndexes()
	local index = {func = func, index = {}, counts = {}}
	indexes[name] = index

	for k, v in pairs(self:GetData()) do
		local key = func(k, v)
		index.index[key] = index.index[key] or createIndexTable()
		rawset(index.index, k ,v)
		index.counts[k] = index.counts[k] + 1
	end
end

if SERVER then
	object:AddMetaData("queue_head", "QueueHead")
	object:AddMetaData("queue_tail", "QueueTail")

	function object:PopSendQueue()
		local head = self:GetQueueHead()
		if head then
			net.Start(self:GetNetworkString())
				net.WriteBool(head.await)
				net.WriteBool(head.delete)
				net.WriteTable(head.data)
			net.Send(head.player)
		end

		if head.next then
			self:SetQueueHead(head.next)
		else
			self:SetQueueHead(nil)
			self:SetQueueTail(nil)

			timer.Remove(self:GetNetworkString() .. "_SendTimer")
		end
	end

	function object:SendData(player, delete, update)
		local compressed = util.Compress(util.TableToJSON(update))
		local len = string.len(compressed)

		local max = 60000
		for i = 0, len, max + 1 do
			local next = {player = player, delete = delete}
			if (i + max > len) then
				next.data = string.sub(compressed, i)
				next.await = false
			else
				next.data = string.sub(compressed, i, i+max)
				next.await = true
			end

			local tail = self:GetQueueTail()
			if not tail then
				self:SetQueueHead(next)
			else
				tail.next = next
			end
			self:SetQueueTail(next)

			if not timer.Exists(self:GetNetworkString() .. "_SendTimer") then
				timer.Create(self:GetNetworkString() .. "_SendTimer", 0.1, 0, function() self:PopSendQueue() end)
			end
		end
	end

	function object:Put(key, value)
		local data = self:GetData()
		if (value == nil) then error("cannot put nil value into WUMA repository, use delete") end

		local indexes = self:GetIndexes()
		for k, v in pairs(key) do
			if not indexes[k] then error(string.format("cannot put a value with an undefined key (%s)", k)) end
		end

		rawset(data, k, v)

		for player in self:GetSubscribers() do
			CAMI.PlayerHasAccess(player, self:GetAccess(), function(authorized)
				if authorized then
					self:SendData(player, false, update)
				else
					WUMADebug("%s (%s) is not authorized to read from this WUMA repository (%s), unsubscribing player!", player:Nick(), player:SteamID(), self:GetName())
					self:Unsubscribe(player)
				end
			end)
		end

		self:RunHook(self:GetData(), update, {})

		self:Persist()
	end

	function object:Delete(keys)
		local data = self:GetData()

		if not istable(keys) then keys = {keys} end

		local indexes = self:GetIndexes()
		for _, k in pairs(keys) do
			local v = data[k]

			if v then
				for name, index in pairs(indexes) do
					local key = index.func(k, v)
					local refs = index.index[key]
					if refs then
						rawset(refs, k, nil)

						local count = index.counts[key] - 1
						if (count <= 0) then
							index.index[key] = nil
							index.counts[key] = nil
						else
							index.counts[key] = count
						end
					end
				end
			end

			rawset(data, k, nil)
		end

		for player in self:GetSubscribers() do
			CAMI.PlayerHasAccess(player, self:GetAccess(), function(authorized)
				if authorized then
					self:SendData(player, true, keys)
				else
					WUMADebug("%s (%s) is not authorized to read from this WUMA repository (%s), unsubscribing player!", player:Nick(), player:SteamID(), self:GetName())
					self:Unsubscribe(player)
				end
			end)
		end

		self:RunHook(self:GetData(), {},  keys)

		self:Persist()
	end

	function object:Subscribe(player, index, key)
		local subscribers = self:GetSubscribers()

		subscribers[index] = subscribers[index] or {}
		subscribers[index][key] = subscribers[index][key] or {}

		subscribers[index][key][player:SteamID()] = player

		self:SendData(self:GetData(), {}, self:Get(key, index))
	end

	function object:Unsubscribe(player, index, key)
		local subscribers = self:GetSubscribers()
		if subscribers[index] and subscribers[index][key] and subscribers[index][key][player:SteamID()] then
			subscribers[index][key][player:SteamID()] = nil
			if table.Count(subscribers[index][key]) <= 0 then
				subscribers[index][key] = nil

				if table.Count(subscribers[index]) <= 0 then
					subscribers[index] = nil
				end
			end
		end
	end

	function object:SubscribeToKey(player, keys)
		local subscribers = self:GetSubscribers()

		subscribers[index] = subscribers[index] or {}
		subscribers[index][key] = subscribers[index][key] or {}

		subscribers[index][key][player:SteamID()] = player

		self:SendData(self:GetData(), {}, self:Get(key, index))
	end

	function object:UnsubscribeToKey(player, keys)
		local subscribers = self:GetSubscribers()
		if subscribers[index] and subscribers[index][key] and subscribers[index][key][player:SteamID()] then
			subscribers[index][key][player:SteamID()] = nil
			if table.Count(subscribers[index][key]) <= 0 then
				subscribers[index][key] = nil

				if table.Count(subscribers[index]) <= 0 then
					subscribers[index] = nil
				end
			end
		end
	end
else
	object:AddMetaData("update_buffer", "UpdateBuffer")
	function object:RecieveUpdate(data, deletion, await)
		local buffer = self:GetUpdateBuffer()
		table.insert(buffer, data)
		if not await then
			local data = util.Decompress(table.concat(buffer, ""))
			if deletion then
				self:OnDeleted(data)
			else
				self:OnPut(data)
			end
		end
	end

	function object:OnDeleted(keys)
		local data = self:GetData()

		local indexes = self:GetIndexes()
		for _, k in pairs(keys) do
			local v = data[key]
			if v then
				for name, index in pairs(indexes) do
					local key = index.func(k, v)
					local refs = index.index[key]
					if refs then
						rawset(refs, k, nil)

						local count = index.counts[key] - 1
						if (count <= 0) then
							index.index[key] = nil
							index.counts[key] = nil
						else
							index.counts[key] = count
						end
					end
				end
			end
			rawset(data, k, nil)
		end
		self:RunHook(self:GetData(), {}, keys)
	end

	function object:OnPut(update)
		local data = self:GetData()

		local indexes = self:GetIndexes()
		for k, v in pairs(update) do
			if (v == nil) then error("cannot put nil value into WUMA repository, use delete") end

			for name, index in pairs(indexes) do
				local key = index.func(k, v)
				local refs = index.index[key]
				if not refs then
					refs = createIndexTable()
					index.index[key] = refs
				end

				rawset(refs, k, v)
				index.counts[key] = index.counts[key] + 1
			end

			rawset(data, k, v)
		end

		self:RunHook(self:GetData(), data, {})
	end

	function object:Subscribe(key, index)
		net.Start(self:GetNetworkString())
			net.WriteBool(false)
			net.WriteString(index)
			net.WriteString(key)
		net.SendToServer()
	end

	function object:Unsubscribe(key, index)
		net.Start(self:GetNetworkString())
			net.WriteBool(true)
			net.WriteString(index)
			net.WriteString(key)
		net.SendToServer()
	end
end

WUMARepository = WUMA.ClassFactory.Create(object)