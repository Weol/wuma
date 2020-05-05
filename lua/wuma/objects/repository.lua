
local object, static = WUMA.ClassFactory.Builder("WUMARepository")

object:AddProperty("name", "Name")
object:AddProperty("server_put_preprocessor", "ServerPutPreprocessor")
object:AddProperty("server_delete_preprocessor", "ServerDeletePreprocessor")
object:AddProperty("client_put_preprocessor", "ClientPutPreprocessor")
object:AddProperty("client_delete_preprocessor", "ClientDeletePreprocessor")
object:AddProperty("access", "Access")
object:AddProperty("data", "Data", setmetatable({}, {__newindex = function(self, k, v) WUMAError("Cannot create new index on WUMA Repository") end}))
object:AddProperty("subscribers", "Subscribers", {})
object:AddProperty("hooks", "Hooks", {})
object:AddProperty("persist_file", "PersistFile")

object:AddMetaData("network_string", "NetworkString")

function object:__construct(args)
	hook.Add("PlayerDisconnected", "WUMARepositoryPlayerDisconnected" .. self:GetName(), function(player) self:Unsubscribe(player) end)

	local network_string = "WUMADataRepository_" .. self:GetName()
	if SERVER then
		if self:GetPersistFile() then
			local data = util.JSONToTable(WUMA.Files.Read(self:GetPersistFile()))
			setmetatable(data, {__newindex = function(self, k, v) WUMAError("Cannot create new index on WUMA Repository") end})
			self:SetData(data)
		end

		self:SetNetworkString(network_string)
		util.AddNetworkString(network_string)

		net.Receive(network_string, function(len, player)
			local subscribe = net.ReadBool()

			if subscribe then
				self:Subscribe(player)
			else
				self:Unsubscribe(player)
			end
		end)
	else
		self:SetNetworkString(network_string)
		net.Receive(network_string, function()
			local deletion = net.ReadBool()
			local data = net.ReadTable()

			if deletion then
				self:OnDeleted(data)
			else
				self:OnPut(data)
			end
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

function object:Get(key)
	return self:GetData()[key]
end

if SERVER then
	function object:Persist()
		local file = self:GetPersistFile()
		if file then
			WUMA.Files.Write(file, util.TableToJSON(self:GetData()))
		end
	end

	function object:Put(key, value)
		if value and not istable(key) then
			key = {key = value}
		end

		local data = self:GetData()

		local update = {}
		local preprocessor = self:GetServerPutPreprocessor()
		for k, v in key do
			if preprocessor then
				k, v = preprocessor(k, v)
			end

			data[k] = v
			update[k] = v
		end

		for player in self:GetSubscribers() do
			CAMI.PlayerHasAccess(player, self:GetAccess(), function(authorized)
				if authorized then
					net.Start(self:GetNetworkString())
						net.WriteBool(false)
						net.WriteTable(update)
					net.Send(player)
				else
					WUMADebug("%s (%s) is not unauthorized to read from this WUMA repository (%s), unsubscribing player!", player:Nick(), player:SteamID(), self:GetName())
					self:Unsubscribe(player)
				end
			end)
		end

		self:RunHook(self:GetData(), update, {})
	end

	function object:Delete(key)
		local data = self:GetData()

		if not istable(key) then
			key = {key}
		end

		local update = {}
		local preprocessor = self:GetServerDeletePreprocessor()
		for _, k in pairs(key) do
			if preprocessor then
				k = preprocessor(k)
			end
			data[k] = nil
			table.insert(update, k)
		end

		net.Start(self:GetNetworkString())
			net.WriteBool(true)
			net.WriteTable(update)
		net.Send(self:GetSubscribers())

		self:RunHook(self:GetData(), {}, update)

		self:Persist()
	end

	function object:Subscribe(player)
		self:GetSubscribers()[player:SteamID()] = player
		self:Send(self:GetData(), {player})
	end

	function object:Unsubscribe(player)
		self:GetSubscribers()[player:SteamID()] = nil
	end
else
	function object:OnDeleted(keys)
		if self:GetClientDeletePreprocessor() then
			keys = self:GetClientDeletePreprocessor()(keys)
		end

		local data = self:GetData()
		for _, key in pairs(keys) do
			data[key] = nil
		end
		self:RunHook(self:GetData(), {}, keys)
	end

	function object:OnPut(data)
		if self:GetClientPutPreprocessor() then
			data = self:GetClientPutPreprocessor()(data_update)
		end

		table.Merge(self:GetData(), data)
		self:RunHook(self:GetData(), data, {})
	end

	function object:Subscribe()
		net.Start(self:GetNetworkString())
			net.WriteBool(true)
		net.SendToServer()
	end

	function object:Unsubscribe()
		net.Start(self:GetNetworkString())
			net.WriteBool(false)
		net.SendToServer()
	end
end

WUMARepository = WUMA.ClassFactory.Create(object)