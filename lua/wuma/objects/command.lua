
local object, static = WUMA.ClassFactory.Builder("WUMACommand")

static.PLAYER = function(str)
	if isentity(str) then return str end

	for _, ply in pairs(player.GetAll()) do
		if (ply:Nick() == str) or (ply:SteamID() == str) then
			return ply
		end
	end

	if (WUMA.IsSteamID(str)) then return str end
	return false
end

static.STEAMID = function(str)
	if isplayer(str) then return str:SteamID() end

	if

	if (WUMA.IsSteamID(str)) then return str end
	return false
end

static.STRING = function(str)
	return str
end

static.USERGROUP = static.STRING

static.NUMBER = function(str)
	if isnumber(str) then return str end

	return tonumber(str)
end

static.SCOPE = function(str)
	if istable(str) then return Scope:new(tbl) end

	local tbl = util.JSONToTable(str)

	if not tbl or not tbl.type then return false end

	local scope = Scope:new{type=tbl.type, data=tbl.data}

	return scope
end

static.BOOLEAN = function(str)
	if isstring(str) then
		if (string.lower(str) == "true") then
			return true
		elseif (string.lower(str) == "false") then
			return false
		else
			str = tonumber(str)
		end
	end

	if isbool(str) then return str end

	if isnumber(str) then return (str == 1) end
end

object:AddProperty("function", "Function")
object:AddProperty("arguments", "Arguments", {})
object:AddProperty("name", "Name")
object:AddProperty("help", "Help")
object:AddProperty("default_access", "DefaultAccess")

object:AddMetaData("network_string", "NetworkString")

function object:__construct()
	local network_string = "WUMACommand_" .. self:GetName()
	if SERVER then
		self:SetNetworkString(network_string)
		util.AddNetworkString(network_string)

		net.Receive(network_string, function(len, player)
			local args = net.ReadTable()
			local id = net.ReadInt()

			self:Invoke(player, args, function(response)
				net.Start(self:GetNetworkString())
					net.WriteTable(response)
					net.WriteInt(id)
				net.Send(player)
			end)
		end)
	else
		self:SetNetworkString(network_string)
		net.Receive(network_string, function()
			local args = net.ReadTable()
			local id = net.ReadInt()

			self:OnResponse(args, id)
		end)
	end
end

function object:AddRequiredArgument(type, values)

end

function object:AddOptionalArgument(type, values)

end

function object:__tostring()
	return string.format("WUMA Command [%s]", self:GetName())
end

if SERVER then
	function object:Invoke(player, args, response_function)
		WUMA.HasAccess(self, self:GetAccess(), function(allow)
			if allow then
				local response = {self:GetFunction()(unpack(args))}
				if response_function then
					response_function(response)
				end
			else
				player:ChatPrint("You do not have access to "..self:GetName())
			end
		end)
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

		net.Start(self:GetNetworkString())
			net.WriteTable(args)
			net.WriteInt(id)
		net.SendToServer()
	end

	function object:OnResponse(args, id)
		local invocations = self:GetInvocations()
		if invocations[id] then
			invocations[id](unpack(args))
		end
	end
end

WUMACommand = WUMA.ClassFactory.Create(object)