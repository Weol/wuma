
WUMAAccess = {}

WUMAAccess.PLAYER = function(str) 
	--WUMADebug("%s (%s)",str,"PLAYER")
	
	if isentity(str) then return str end

	for _, ply in pairs(player.GetAll()) do
		if (ply:Nick() == str) or (ply:SteamID() == str) then
			return ply
		end
	end
	return false
end

WUMAAccess.PLAYERS = function(str) 
	--WUMADebug("%s (%s)",str,"PLAYERS")

	if isstring(str) then
		local players = {}
		for _, ply in pairs(player.GetAll()) do
			if (ply:GetUsergroup() == str) then
				table.insert(players,ply)
			end
		end
		return players
	elseif istable(str) then
		local players = {}
		for _, ply in pairs(player.GetAll()) do
			for _, id in pairs(str) do
				if (ply:Nick() == id) or (ply:SteamID() == id) then
					table.insert(players,ply)
				end
			end
		end
		return players
	end
	return false
end

WUMAAccess.STRING = function(str) 
	--WUMADebug("%s (%s)",str,"STRING")

	return str
end

WUMAAccess.USERGROUP = WUMAAccess.STRING

WUMAAccess.NUMBER = function(str) 
	--WUMADebug("%s (%s)",str,"NUMBER")
	
	if isnumber(str) then return str end

	local num = tonumber(str)
	if (str == nil) then return false end
	return num
end

WUMAAccess.SCOPE = function(str) 
	--WUMADebug("%s (%s)",str,"SCOPE")

	if istable(str) then return Scope:new(tbl) end
	
	local tbl = util.JSONToTable(str)

	if not tbl or not tbl.type then return false end

	local scope = Scope:new{type=tbl.type,data=tbl.data}
	
	return scope
end

local object = {}
local static = {}

WUMAAccess._id = "WUMA_Command"
object._id = "WUMA_Command"

--																								Static functions
function WUMAAccess:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.func = tbl.func or false
	obj.cmd = tbl.cmd or false
	obj.arguments = tbl.arguments or {}
	obj.help = tbl.help or false
	obj.access = tbl.access or false
	obj.optional = tbl.optional or false

	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	return obj
end 
 
function static:GetID()
	return WUMAAccess._id
end

--																								Object functions
function object:__tostring()
	return string.format("WUMAAccess [%s][%s/%s]",self:GetString(),tostring(self:GetCount()),tostring(self:Get()))
end
 
function object:__call(...)
	self.func(...)
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

function object:SetAccess(str)
	self.access = str
end

function object:GetAccess(str)
	return self.access
end	

function object:SetFunction(func)
	self.func = func
end

function object:AddArgument(arg,tbl,optional)
	if tbl and not isbool(tbl) then
		table.insert(self.arguments,{arg,tbl,optional or false})
	else
		table.insert(self.arguments,{arg,optional or false})
	end
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

function object:SetLogFunction(func)
	self.log_function = log_function
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

setmetatable(WUMAAccess,static) 