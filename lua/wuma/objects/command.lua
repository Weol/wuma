
module("WUMACommand", package.seeall)
 
local mt = {}
local methods = {}
mt.__index = methods

local UNDEFINED = "UNDEFINED"

mt.cmd = UNDEFINED
mt.func = UNDEFINED
mt.chat_cmd = UNDEFINED
mt.arguments = {}
mt.access = UNDEFINED
mt.players = {}
mt.format = UNDEFINED

mt.ArgumentTypes = {
	player = function(var) 
		if WUMA.IsSteamID(var) then
			return WUMA.STEAMID(var)
		else
			return WUMA.NICK(var)
		end
	end,
	number = function(var) return tonumber(var) end,
	string = function(var) return var end,
}
 
function new(cmd,usergroup,chat_cmd,func,...)
	local obj = {}
	obj.cmd = cmd or UNDEFINED
	obj.usergroup = usergroup or UNDEFINED
	obj.chat_cmd = chat_cmd or UNDEFINED
	obj.func = func

	setmetatable(obj, mt)
	return obj
end

function methods:ParseArguments(...)
	local args = {}
	for k,v in pairs({...}) do
		table.insert(args,self.ArgumentTypes[self.arguments[k]](v))
	end
	return unpack(args)
end

function methods:InitializeArguments(...)
	local args = {...}
	for k,v in pairs(args) do
		if (self.ArgumentTypes:GetKeys():HasValue(string.lower(type(v)))) then
			table.insert(self.arguments,string.lower(type(v)))
		else
			WUMAError("Invalid command argument type!")
		end
	end
end

function methods:__call(...)
	self.func(self.ParseArguments(...))

	self.LogSelf(ply,...)
end

function methods:LogSelf(...)
	local varargs, player = WUMA.ExtractValue({...})
	if WUMA.IsUlx then
		ulx.fancyLogAdmin( player, self.format, ... )
	else
		WUMAChatPrint(self.format,...)
	end
end

function methods:SetLogMessage(str)
	self.format = str
end

function methods:GetName()
	return self.cmd
end

function methods:SetName(cmd)
	self.cmd = cmd
end


function methods:GetChatName()
	return self.chat_cmd
end

function methods:SetChatName(chat_cmd)
	self.chat_cmd = chat_cmd
end

function methods:GetAccess()
	return self.access
end

function methods:SetAccess(access)
	self.access = access
end

function methods:GetFormat()
	return self.format
end

function methods:SetFormat(str)
	self.format = str
end

function methods:GetFunction()
	return self.func
end

function methods:SetFunction(func,...)
	self.func = func
end