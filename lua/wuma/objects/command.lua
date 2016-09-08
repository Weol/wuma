
WUMACommand = {}

WUMACommand.PLAYER = function(str) 
	for _, ply in pairs(player.GetAll()) do
		if (ply:Nick() == str) or (ply:SteamID() == str) then
			return ply
		end
	end
	return false
end

WUMACommand.PLAYERS = function(str) 
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

WUMACommand.STRING = function(str,tbl) 
	if tbl then
		if table.HasValue(tbl,str) then return str end
	end
	return str
end

WUMACommand.NUMBER = function(str) 
	local num = tonumber(str)
	if (str == nil) then return false end
	return num
end

WUMACommand.SCOPE = function(str) 
	local tbl = util.JSONToTable(str)
	
	if not tbl.type then return end
	
	for _, data in pairs(tbl.data) do
		for _, arg in pairs(Scope[tbl.type].arguments) do
			data = arg(data)
		end
	end
	
	local scope = Scope:new{type=tbl.type,data=tbl.data}
end

local object = {}
local static = {}

WUMACommand._id = "WUMA_Command"
object._id = "WUMA_Command"

--																								Static functions
function WUMACommand:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.func = tbl.func or false
	obj.cmd = tbl.cmd or false
	obj.arguments = tbl.arguments or {}
	obj.help = tbl.help or false

	if SERVER then obj.m._uniqueid = WUMA.GenerateUniqueID() end
	
	return obj
end 
 
function static:GetID()
	return WUMACommand._id
end

--																								Object functions
function object:__tostring()
	return string.format("WUMACommand [%s][%s/%s]",self:GetString(),tostring(self:GetCount()),tostring(self:Get()))
end
 
function object:__call(ply)
	
end

function object:Clone()
	local obj = WUMACommand:new(self)
	
	return obj
end

function object:GetUniqueID()
	return obj._uniqueid or false
end

function object:Delete()
	self = nil
end

function object:SetFunction(func)
	self.func = func
end

function object:AddArgument(arg,tbl)
	if tbl then
		table.insert(self.arguments,arg)
	else
		table.insert(self.arguments,{arg,tbl})
	end
end

function object:SetHelp(str)
	self.help = str
end

function object:GetHelp()
	return self.help
end

object.__index = object
static.__index = static

setmetatable(WUMACommand,static) 