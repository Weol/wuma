
local object, static = WUMA.ClassFactory.Builder("WUMAAction")

object:AddProperty("name", "Name")
object:AddProperty("send_function", "SendFunction")
object:AddProperty("server_processor", "ServerProcessor")
object:AddProperty("client_send_pre_processor", "ClientSendPreProcessor")
object:AddProperty("client_recieve_pre_processor", "ClientRecievePreProcessor")
object:AddProperty("authentication_callback", "AuthenticationCallback")

function object:__tostring()
	return self:GetName()
end

if SERVER then
	function object:Recieve(player, data, response_function)
		if (self:IsAuthorized(player, function(authorized)
			if authorized then
				response = data:GetServerProcessor()(player, data)

				response_function(player, self:GetName(), response)
			else
				response_function(player, self:GetName())
			end
		end))
	end
else
	function object:Send(data)
		if self:ClientPreProcessor() then
			data = data:ClientPreProcessor()(data)
		end

		self:GetSendFunction()(self:GetName(), data)
	end
end

function object:IsAuthorized(player, callback)
	if not self:GetAuthenticationCallback() then
		WUMAError("FATAL SECURITY ERROR! A WUMASTREAM OBJECT HAS NO AUTHORIZATION FUNCTION!")
		callback(false)
	else
		self:GetAuthenticationCallback(player, callback)
	end
end

WUMAAction = WUMA.ClassFactory.Create()