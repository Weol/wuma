
Restriction = {}

local object = {}
local static = {}

Restriction._id = "TIIP_Restriction"
object._id = "TIIP_Restriction"

Restriction.types = {
	"entity",
	"prop",
	"npc",
	"vehicle",
	"swep",
	"pickup",
	"effect",
	"tool",
	"ragdoll",
	"use"
} 

--																								Static functions
function Restriction:new(tbl)
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.usergroup = tbl.usergroup or false
	obj.type = tbl.type or false
	obj.string = tbl.string or false
	obj.parent = tbl.parent or false 
	obj.print = obj.print or tbl.string
	obj.scope = tbl.scope or false 
  
	return obj
end 

function Restriction:GenerateID(type,str)
	return string.lower(type.."_"..str)
end 

function static:__eq(v1, v2)
	if v1._id and v2._id then return (v1._id == v2.__id) end
end

function static:GetTypes()
	return Restriction.types
end

--																								Object functions
function object:__call(type,str)
	self:Hit()
	return false
end

--[[
function object:__eq(obj1,obj2)
	if not(obj1.usergroup == obj2.usergroup) then return false end
	if not(obj1.type == obj2.type) then return false end
	if not(obj1.string == obj2.string) then return false end
	if not(obj1.parent == obj2.parent) then return false end
	if not(obj1.print == obj2.print) then return false end
	if not(obj1.scope == obj2.scope) then return false end
	return true
end
--]]

function object:__tostring()
	return string.format("Restriction [%s][%s]",self:GetType(),self:GetString())
end

function object:Hit()
	if (self.type == "use") then
		if self.m.lasthit and not (os.time() - self.m.lasthit > 1) then self.m.lasthit = os.time(); return end
	end

	self.m.lasthit = os.time()
	
	if (self.type == "pickup") then return end
 
	local str = self.print or self.str
	local scope = self.scope or ""
	
	self.parent:SendLua(string.format([[
			notification.AddLegacy("This %s (%s) is restricted%s!",NOTIFY_ERROR,3)
		]],self:GetType(),str,scope))
	self.parent:SendLua( [[surface.PlaySound( "buttons/button10.wav" )]] )
end
	
function object:Clone()
	return Restriction:new({usergroup=self.usergroup,type=self.type,string=self.string,parent=self.parent,print=self.print,scope=self.scope})
end

function object:Dispose()
	
end

function object:GetUsergroup()
	return self.usergroup
end

function object:SetUsergroup(str)
	self.usergroup = str
end

function object:GetType()
	return self.type
end

function object:SetType(str)
	self.type = str
end

function object:GetPrint()
	return self.print
end

function object:SetPrint(str)
	self.print = str
end

function object:GetScope()
	return self.scope
end
 
function object:SetScope(str)
	self.scope = str
end

function object:GetString()
	return self.string
end

function object:SetString(str)
	self.string = string
end

function object:SetParent(ply)
	self.parent = ply
end

function object:GetParent()
	return self.parent
end

function object:GetID()
	return string.lower(string.format("%s_%s",self.type,self.string))
end

object.__index = object
static.__index = static

setmetatable(Restriction,static)

