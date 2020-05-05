local object, static = WUMA.ClassFactory.Builder("WUMACommand")

static.STEAMID = function(str)
	if isplayer(str) then
		return str:SteamID()
	end

	if (WUMA.IsSteamID(str)) then
		return str
	end

	return str, true
end

static.STRING = function(str)
	return tostring(str)
end

static.USERGROUP = function(str)
	local usergroups = WUMA.GetUserGroups()

	if table.HasValue(usergroups, str) then
		return str
	end

	return str, true
end

static.NUMBER = function(str)
	if isnumber(str) then
		return str
	end

	if tonumber(str) ~= nil then
		return tonumber(str)
	end
	return str, true
end

static.SCOPE = function(str)
	if istable(str) then
		return Scope:new(tbl)
	end

	if (isstring(str)) then
		local tbl = util.JSONToTable(str)

		if tbl and tbl.type then
			return Scope:new {type = tbl.type, data = tbl.data}
		end
	end
	return str, true
end

static.BOOLEAN = function(str)
	if isbool(str) then
		return str
	end

	if isstring(str) then
		if (string.lower(str) == "true") then
			return true
		elseif (string.lower(str) == "false") then
			return false
		else
			str = tonumber(str)
		end
	end

	if str and isnumber(str) then
		if str == 1 then
			return true
		elseif (str == 0) then
			return false
		end
	end
	return str, true
end

object:AddProperty("function", "Function")
object:AddProperty("arguments", "Arguments", {})
object:AddProperty("name", "Name")
object:AddProperty("privilage", "Privilage")
object:AddProperty("help", "Help")
object:AddProperty("logger", "LogFunction")

object:AddMetaData("arguments", "Arguments")
object:AddMetaData("network_string", "NetworkString")

function object:__construct()
	local network_string = "WUMACommand_" .. self:GetName()
	if SERVER then
		self:SetNetworkString(network_string)
		util.AddNetworkString(network_string)

		net.Receive(
			network_string,
			function(len, player)
				local args = net.ReadTable()
				local id = net.ReadInt()

				self:Invoke(
					player,
					args,
					function(response)
						net.Start(self:GetNetworkString())
						net.WriteTable(response)
						net.WriteInt(id)
						net.Send(player)
					end
				)
			end
		)
	else
		self:SetNetworkString(network_string)
		net.Receive(
			network_string,
			function()
				local args = net.ReadTable()
				local id = net.ReadInt()

				self:OnResponse(args, id)
			end
		)
	end
end

function object:GetPrivilage()
	return self.privilage or self:GetName()
end

function object:AddRequiredArgument(type, values)
	local legal_values = {}
	for k, v in pairs(values) do
		legal_values[v] = true
	end

	table.insert(self:GetArguments(), {parse_func = type, legal_values = legal_values, required = true})
end

function object:AddOptionalArgument(type, values)
	local legal_values = {}
	for k, v in pairs(values) do
		legal_values[v] = true
	end

	table.insert(self:GetArguments(), {parse_func = type, legal_values = legal_values, required = false})
end

function object:__tostring()
	return string.format("WUMA Command [%s]", self:GetName())
end

function object:PreprocessArguments(args)
	local processed_args = {}
	for i, argument in ipairs(self:GetArguments()) do
		if argument.legal_values and not argument.legal_values[args[i]] then
			return WUMADebug('Illegal argument to command (%s) argument %d was "%s"', self:GetName(), i, args[i])
		end
		parsed, failed = argument.parse_func(args[i])
		if not failed then
			processed_args[i] = parsed
		else
			return WUMADebug('Failed to parse argument to command (%s) argument %d was "%s"', self:GetName(), i, args[i])
		end
	end
	return processed_args
end

if SERVER then
	function object:Invoke(player, args, response_function)
		CAMI.PlayerHasAccess(
			self,
			self:GetAccess(),
			function(allow)
				if allow then
					args = self:PreprocessArguments(args)
					if args then
						local response = {self:GetFunction()(unpack(args))}
						if response_function then
							response_function(response)
						end
					else
						WUMADebug("Rejecting command invocation of command (%s) by %s (%s) due to parsing failure", self:GetName(), player:Nick(), player:SteamID())
					end
				else
					player:ChatPrint("You do not have access to " .. self:GetName())
				end
			end
		)
	end
else
	object:AddMetaData("invoke_ids", "InvokeId", 0)
	object:AddMetaData("invocations", "Invocations", {})

	function object:GenerateId()
		local id = self:GetInvokeId() + 1
		self:SetInvokeId(id)
		return id
	end

	function object:Invoke(args, response_function)
		local id = self:GenerateId()

		if response_function then
			self:GetInvocations()[id] = response_function
		end

		args = self:PreprocessArguments(args)

		if args then --If arguments were sucessfully preprocessed
			net.Start(self:GetNetworkString())
			net.WriteTable(args)
			net.WriteInt(id)
			net.SendToServer()
		else
			WUMADebug("Did not sent command invokation of command (%s)", self:GetName())
		end
	end

	function object:OnResponse(args, id)
		local invocations = self:GetInvocations()
		if invocations[id] then
			invocations[id](unpack(args))
		end
	end
end

WUMACommand = WUMA.ClassFactory.Create(object)
