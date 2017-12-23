
local object = {}
local static = {}

object._id = "WUMA_Command"
static._id = "WUMA_Command"

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

static.STRING = function(str) 
	return str
end

static.USERGROUP = static.STRING

static.NUMBER = function(str) 
	if isnumber(str) then return str end

	local num = tonumber(str)
	if (str == nil) then return false end
	return num
end

static.SCOPE = function(str) 
	if istable(str) then return Scope:new(tbl) end
	
	local tbl = util.JSONToTable(str)

	if not tbl or not tbl.type then return false end

	local scope = Scope:new{type=tbl.type,data=tbl.data}
	
	return scope
end

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
///////////////////////////////////////////////////////// 
function static:GetID()
	return WUMAAccess._id
end

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:Construct(tbl)
	self.func = tbl.func or false
	self.cmd = tbl.name or false
	self.arguments = tbl.arguments or {}
	self.help = tbl.help or false
	self.access = tbl.access or false
	self.optional = tbl.optional or false
	self.log = tbl.log or false
	self.strict = tbl.strict or false
	self.log_function = tbl.log_function or false
end 

function object:__tostring()
	return string.format("WUMAAccess [%s]",self:GetName())
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

function object:AddArgument(arg,tbl,optional)
	table.insert(self.arguments,{arg,tbl,optional})
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

WUMAAccess = WUMAObject:Inherit(static, object)