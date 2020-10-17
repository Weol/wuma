local object = WUMA.ClassFactory.Builder("WUMARPCFunction")

object:AddProperty("name", "Name")
object:AddProperty("func", "Function")
object:AddProperty("validator", "Validator")
object:AddProperty("privilage", "Privilage")
object:AddProperty("description", "Description")
object:AddProperty("respond", "DoesRespond", false)

object:AddMetaData("network_string", "NetworkString")

local function unpackTransactions(transactions)
    local invocations = {}
    local total = 1
    for _, args in pairs(transactions) do
        total = total * #args
    end

	local carry = 1
	for i, args in ipairs(transactions) do
		carry = carry * #args
        for j = 1, total do
			invocations[j] = invocations[j] or {}

            local argIndex = (math.floor((j - 1) / (total / carry))) % #args + 1
			local arg = args[argIndex]

            invocations[j][i] = arg
        end
    end

    return invocations
end

function object:__construct()
	local network_string = "WUMARPCFunction_" .. self:GetName()
	self:SetNetworkString(network_string)
	if SERVER then
		util.AddNetworkString(network_string)

		net.Receive(network_string, function(_, player)
			CAMI.PlayerHasAccess(player, self:GetPrivilage(), function(allow)
				if allow then
					local id = net.ReadInt(32)

					if (id ~= -2) then
						local args = net.ReadTable()

						local response_function = (id >= 0) and function(response)
							net.Start(network_string)
								net.WriteInt(id, 32)
								net.WriteTable(response)
							net.Send(player)
						end

						WUMADebug("%s (%s) invoked RPC function \"%s\" (%d)", player:Nick(), player:SteamID(), self:GetName(), id)
						WUMADebug(args)

						self:Invoke(player, args, response_function)
					else
						local transactions = net.ReadTable()

						WUMADebug("%s (%s) transacted RPC function \"%s\"", player:Nick(), player:SteamID(), self:GetName())
						WUMADebug(transactions)

						for _, args in pairs(unpackTransactions(transactions)) do
							self:Invoke(player, args)
						end
					end
				else
					player:ChatPrint("You do not have access to \"" .. self:GetName() .. "\"")
				end
			end)
		end)

		local privliges = CAMI.GetPrivileges()
		if not privliges[self:GetPrivilage()] then
			CAMI.RegisterPrivilege{Name = self:GetPrivilage(), MinAccess = "superadmin", Description = self:GetDescription()}
		end
	else
		net.Receive(network_string, function()
			local id = net.ReadInt(32)

			if (id >= 0) then
				local response = net.ReadTable()

				self:OnResponse(response, id)
			else
				local responses = net.ReadTable()

				for id, response in pairs(responses) do
					self:OnResponse(response, id)
				end
			end
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
	return string.format("WUMA RPC Function [%s]", self:GetName())
end

if SERVER then
	function object:Invoke(caller, args, response_function)
		local validator = self:GetValidator()
		local sucess, error
		if validator then
			sucess, error = pcall(validator, unpack(args))
		end

		if sucess or not validator then
			local response = {self:GetFunction()(caller, unpack(args))}
			if response_function then
				response_function(response)
			end
		else
			WUMADebug("RPC call of function \"%s\" failed due to validator error:", self:GetName())
			WUMADebug(error)
		end
	end

	function object:__call(args)
		local sucess, error = pcall(self:GetValidator(), unpack(args))
		if sucess then
			return self:GetFunction()(unpack(args))
		else
			WUMADebug("Call of function \"%s\" failed due to validator error:")
			WUMADebug(error)
		end
	end
else
	object:AddMetaData("invoke_ids", "InvokeId", 0)
	object:AddMetaData("invocations", "Invocations", {})

	function object:GenerateId()
		local id = self:GetInvokeId() + 1
		self:SetInvokeId(id)
		return id
	end

	function object:Transaction(...)
		local args = {...}

		for k, v in pairs(args) do
			if not istable(v) then
				args[k] = {v}
			else
				args[k] = table.ClearKeys(v)
			end
		end

		net.Start(self:GetNetworkString())
			net.WriteInt(-2, 32)
			net.WriteTable(args)
		net.SendToServer()
	end

	function object:Invoke(...)
		local id = self:GenerateId()

		local args = {...}

		local callback
		if not table.IsEmpty(args) then
			local maxn = table.maxn(args)
			if isfunction(args[maxn]) then
				callback = args[maxn]
				args[maxn] = nil
				self:GetInvocations()[id] = callback
			end
		end

		--WUMADebug("Calling function %s (%d)", self:GetName(), callback and id or -1)
		--WUMADebug(args)

		net.Start(self:GetNetworkString())
			net.WriteInt(callback and id or -1, 32)
			net.WriteTable(args)
		net.SendToServer()
	end

	function object:OnResponse(args, id)
		local invocations = self:GetInvocations()
		if invocations[id] then
			--WUMADebug("Responding to function %s (%d)",self:GetName(), id)
			--WUMADebug(args)

			invocations[id](unpack(args))
			invocations[id] = nil
		end
	end
end
WUMARPCFunction = WUMA.ClassFactory.Create(object)
