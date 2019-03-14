
WUMAAccess = {}

WUMAAccess.PLAYER = function(str) 
	if isentity(str) then return str end

	for _, ply in pairs(player.GetAll()) do
		if (ply:Nick() == str) or (ply:SteamID() == str) then
			return ply
		end
	end
	
	if (WUMA.IsSteamID(str)) then return str end
	return false
end

WUMAAccess.STRING = function(str) 
	return str
end

WUMAAccess.USERGROUP = WUMAAccess.STRING

WUMAAccess.NUMBER = function(str) 
	if isnumber(str) then return str end

	local num = tonumber(str)
	if (str == nil) then return false end
	return num
end

WUMAAccess.SCOPE = function(str) 
	if istable(str) then return Scope:new(tbl) end
	
	local tbl = util.JSONToTable(str)

	if not tbl or not tbl.type then return false end

	local scope = Scope:new{type=tbl.type, data=tbl.data}
	
	return scope
end

local object = {}
local static = {}

WUMAAccess._id = "WUMA_Command"
object._id = "WUMA_Command"

function WUMAAccess:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({}, mt)
	
	obj.func = tbl.func or false
	obj.cmd = tbl.name or false
	obj.arguments = tbl.arguments or {}
	obj.help = tbl.help or false
	obj.access = tbl.access or false
	obj.optional = tbl.optional or false
	obj.log = tbl.log or false
	obj.strict = tbl.strict or false
	obj.log_function = tbl.log_function or false

	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	return obj
end 
 
function static:GetID()
	return WUMAAccess._id
end

function object:__tostring()
	return string.format("WUMAAccess [%s]", self:GetName())
end
 
function object:__call(...)
	local tbl = {...}
	self:GetAccessFunction()(self, tbl[1], function(allow)
		if allow then
			local log, affected, caller = self.func(unpack(tbl))
			if self.log_function then self.log_function(log, affected, caller) end
		else
			tbl[1]:ChatPrint("You do not have access to "..self:GetName())
		end
	end)
end

function object:Clone()
	local obj = WUMAAccess:new(table.Copy(self))
	
	return obj
end

function object:GetUniqueID()
	return obj.m._uniqueid or false
end

function object:Delete()
	self = nil
end

function object:IsStrict()
	return self.strict
end

function object:SetAccess(str)
	self.access = str
end

function object:GetAccess(str)
	return self.access
end	

function object:SetFunction(func)
	self.func = func
end

function object:GetFunction()
	return self.func
end

function object:SetAccessFunction(func)
	self.access_func = func
end

function object:GetAccessFunction()
	return self.access_func
end

function object:AddArgument(arg, tbl, optional)
	table.insert(self.arguments, {arg, tbl, optional})
end

function object:GetArguments()
	return self.arguments
end

function object:SetName(str)
	self.cmd = str
end

function object:GetName()
	return self.cmd
end

function object:SetLog(bool)
	self.log = bool
end

function object:GetLog()
	return self.log
end

function object:SetLogFunction(func)
	self.log_function = func
end

function object:GetLogFunction()
	return self.log_function
end

function object:SetHelp(str)
	self.help = str
end

function object:GetHelp()
	return self.help
end

object.__index = object
static.__index = static

setmetatable(WUMAAccess, static) 