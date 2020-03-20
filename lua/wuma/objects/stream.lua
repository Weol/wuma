
local object, static = WUMA.ClassFactory.Builder("WUMAStream")

object:AddProperty("name", "Name")
object:AddProperty("send_function", "SendFunction")
object:AddProperty("server_put_preprocessor", "ServerPutPreprocessor")
object:AddProperty("server_delete_preprocessor", "ServerDeletePreprocessor")
object:AddProperty("client_put_preprocessor", "ClientPutPreprocessor")
object:AddProperty("client_delete_preprocessor", "ClientDeletePreprocessor")
object:AddProperty("authentication_callback", "AuthenticationCallback")
object:AddProperty("data", "Data")
object:AddProperty("subscribers", "Subscribers")
object:AddProperty("hooks", "Hooks")

function object:__construct(tbl)
	hook.Add("PlayerDisconnected", "WUMAStreamPlayerDisconnected" .. self:GetName(), function(player) self:Unsubscribe(player) end)
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

function object:Put(key, value)
	local data = self:GetData()
	if istable(key) then
		for k, v in pairs(key) do
			data[k] = v
		end
		self:Send(key, self:GetSubscribers())
	else
		data[k] = v
		self:Send({k = v}, self:GetSubscribers())
	end
end

function object:Delete(key)
	local data = self:GetData()
	if istable(key) then
		for k in key do
			data[k] = nil
		end
		self:Send(key, self:GetSubscribers(), true)
	else
		data[k] = v
		self:Send({k = v}, self:GetSubscribers(), true)
	end
end

if SERVER then
	function object:Send(data, player, delete)
		if not delete and self:ServerPutPreprocessor() then
			data = self:ServerPutPreprocessor()(data)
		elseif delete and self:ServerDeletePreprocessor() then
			data = self:ServerDeletePreprocessor()(data)
		end

		local headers = {delete = delete, stream = self:GetName()}
		for player in players do
			self:IsAuthorized(player, function(authorized)
				if authorized then
					self:GetSendFunction()(player, data, headers)
				else
					WUMADebug("%s (%s) is not unauthorized to read from this datastream (%s), unsubscribing player!", player:Nick(), player:SteamID(), self:GetName())
					self:Unsubscribe(player)
				end
			end)
		end
	end

	function object:Subscribe(player)
		self:GetSubscribers()[player:SteamID()] = player
		self:Send(self:GetData(), {player})
	end

	function object:Unsubscribe(player)
		self:GetSubscribers()[player:SteamID()] = nil
	end
else
	function object:Recieve(data_update, headers)
		if (headers.delete) then
			if self:GetClientDeletePreprocessor() then
				data_update = self:GetClientDeletePreprocessor()(data_update)
			end

			local data = self:GetData()
			for key in pairs(data_update) do
				data[key] = nil
			end
			self:RunHook({}, data)
		else
			if self:GetClientPutPreprocessor() then
				data_update = self:GetClientPutPreprocessor()(data_update)
			end

			table.Merge(self:GetData(), data_update)
			self:RunHook(data, {})
		end
	end

	function object:Subscribe()

	end

	function object:Unsubscribe()

	end
end

function object:IsAuthorized(user, callback)
	if not self:GetAuthenticationCallback() then
		WUMAError("FATAL SECURITY RISK! A NET_STREAM OBJECT HAS NO AUTHORIZATION FUNCTION!")
		callback(false)
	else
		self:GetAuthenticationCallback(user, callback)
	end
end

WUMAStream = WUMA.ClassFactory.Create()