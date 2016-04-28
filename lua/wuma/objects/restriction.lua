
Restriction = {}

local object = {}
local static = {}

Restriction._id = "WUMA_Restriction"
object._id = "WUMA_Restriction"

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
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.usergroup = tbl.usergroup or false
	obj.type = tbl.type or false
	obj.string = tbl.string or false
	obj.parent = tbl.parent or false 
	obj.print = obj.print or tbl.string
	obj.scope = tbl.scope or false 
	obj.allow = tbl.allow or false
	
	obj.m.override = tbl.override or false
	obj.m.exceptions = {}
  
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
	if (self:HasException(str)) then 
		self:RemoveException(str)
		return
	end
	
	if self.override then 
		return self.override(type,str)
	else
		if not self.allow then
			self:Hit()
			return false
		end
	end
end



function object:__tostring()
	return string.format("Restriction [%s][%s]",self:GetType(),self:GetString())
end

function object:Hit()
	if (self.type == "pickup") then return end

	if (self.type == "use") then
		if self.m.lasthit and not (os.time() - self.m.lasthit > 1) then self.m.lasthit = os.time(); return end
	end

	self.m.lasthit = os.time()
 
	local str = self.print or self.str
	local scope = self.scope or ""
	
	self.parent:SendLua(string.format([[
			notification.AddLegacy("This %s (%s) is restricted%s!",NOTIFY_ERROR,3)
		]],self:GetType(),str,scope))
	self.parent:SendLua([[surface.PlaySound)"buttons/button10.wav")]])
end

function object:IsPersonal()
	if self.usergroup then return false else return true end
end
	
function object:Clone()
	return Restriction:new({usergroup=self.usergroup,type=self.type,string=self.string,parent=self.parent,print=self.print,scope=self.scope})
end

function object:AddException(str)
	self.m.exceptions[str] = true
end

function object:RemoveException(str)
	self.m.exceptions[str] = nil
end

function object:HasException(str)
	if self.m.exceptions[str] then return true end
	return false
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

function object:SetOverride(restriction)
	restriction:RemoveOverride(restriction)
	self.override = restriction
end

function object:GetOverride()
	return self.override 
end

function object:RemoveOverride()
	self.override = nil
end

function object:SetAllow(boolean)
	self.allow = boolean
end

function object:GetAllow()
	return self.allow 
end


function object:GetID()
	return string.lower(string.format("%s_%s",self.type,self.string))
end

object.__index = object
static.__index = static

setmetatable(Restriction,static)

