local object = WUMA.ClassFactory.Builder("WUMACommand")

object:AddProperty("function", "Function")
object:AddProperty("arguments", "Arguments", {})
object:AddProperty("name", "Name")
object:AddProperty("privilage", "Privilage")
object:AddProperty("help", "Help")

object:AddMetaData("network_string", "NetworkString")

function object:__construct()
	local network_string = "WUMACommand_" .. self:GetName()
	self:SetNetworkString(network_string)
	if SERVER then
		util.AddNetworkString(network_string)

		net.Receive(network_string, function(_, player)
			local args = net.ReadTable()
			local id = net.ReadInt()

			self:Invoke(player,args,function(response)
				net.Start(self:GetNetworkString())
					net.WriteTable(response)
					net.WriteInt(id)
				net.Send(player)
			end)
		end)
	else
		net.Receive(network_string, function()
			local args = net.ReadTable()
			local id = net.ReadInt()

			self:OnResponse(args, id)
		end)
	end
end

function object:GetPrivilage()
	return self.privilage or self:GetName()
end

function object:AddRequiredArgument(type, values)
	local legal_values = {}
	for k, v in pairs(values or {}) do
		legal_values[v] = true
	end

	table.insert(self:GetArguments(), {parse_func = type, legal_values = legal_values, required = true})
end

function object:AddOptionalArgument(type, values)
	local legal_values = {}
	for k, v in pairs(values or {}) do
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
		processed_args[i] = argument.parse_func(args[i])
	end
	return processed_args
end

function object:Invoke(args)
	self:GetFunction()(unpack(self:PreprocessArguments(args)))
end

WUMACommand = WUMA.ClassFactory.Create(object)
