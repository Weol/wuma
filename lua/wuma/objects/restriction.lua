
Restriction = {}

local object = {}
local static = {}

Restriction._id = "WUMA_Restriction"
object._id = "WUMA_Restriction"

Restriction.types = {
	entity = {print="Entity",search="Search..",items=function() return WUMA.GetEntities() end},
	prop = {print="Prop",search="Model"},
	npc = {print="NPC",search="Search..",items=function() return WUMA.GetNPCs() end},
	vehicle = {print="Vehicle",search="Search..",items=function() return WUMA.GetVehicles() end},
	swep = {print="Weapon",search="Search..",items=function() return WUMA.GetWeapons() end},
	pickup = {print="Pickup",search="Search..",items=function() return WUMA.GetWeapons() end},
	effect = {print="Effect",search="Model"},
	tool = {print="Tool",search="Search..",items=function() return WUMA.GetTools() end},
	ragdoll = {print="Ragdoll",search="Model"},
	use = {print="Use",search="Search..",items=function() return table.Merge(table.Merge(WUMA.GetEntities(),WUMA.GetVehicles()),WUMA.GetNPCs()) end}  
} 

--																								Static functions
function Restriction:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.usergroup = tbl.usergroup or false
	obj.type = tbl.type or false
	obj.string = tbl.string or false
	obj.parent = tbl.parent or false 
	obj.print = tbl.print or tbl.string
	obj.allow = tbl.allow or false
	
	if tbl.scope then obj:SetScope(tbl.scope) else obj.m.scope = "Permanent" end
	
	obj._id = Restriction._id
	
	obj.m.override = tbl.override or false
	obj.m.exceptions = {} 
  
	return obj
end 

function Restriction:GenerateID(type,usergroup,str)
	if usergroup then
		return string.lower(type.."_"..usergroup.."_"..str)
	else
		return string.lower(type.."_"..str)
	end
end 

function static:__eq(v1, v2)
	if v1._id and v2._id then return (v1._id == v2.__id) end
end

function static:GetID()
	return Restriction._id
end

function static:GetTypes(field)
	if field then
		local tbl = {}
		
		for _, type in pairs(Restriction.types) do 
			for key,value in pairs(type) do 
				if (key == field) then
					table.insert(tbl,value)
				end
			end
		end
		
		return tbl
	end

	return Restriction.types
end

function static:GetAllResitrictableItems()
	local tbl = {}
	
	for k,v in pairs(self:GetTypes()) do
		if v.items then
			table.Add(tbl,v.items())
		end
	end
	
end

--																								Object functions
function object:__call(type,str)
	if self:IsDisabled() then return end

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

function object:GetStatic()
	return Restriction
end

function object:Delete()
	if SERVER then
		if self:GetParent() then
			self:GetParent():RemoveRestriction(self:GetID(),self:IsPersonal())
		end
	end
	
	self = nil
end

function object:Disable()
	self.m.disabled = true
end

function object:Enable()
	self.m.disabled = false
end

function object:IsDisabled() 
	if self.m and self.m.disabled then return true end
	return false
end

function object:Hit()
	if (self.type == "pickup") then return end

	if (self.type == "use") then
		if self.m.lasthit and not (os.time() - self.m.lasthit > 1) then self.m.lasthit = os.time(); return end
	end

	self.m.lasthit = os.time()
 
	local str = self.print or self.string
	
	self.parent:SendLua(string.format([[
			notification.AddLegacy("This %s (%s) is restricted!",NOTIFY_ERROR,3)
		]],self:GetType(),str))
	self.parent:SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:IsPersonal()
	if self.usergroup then return false else return true end
end

function object:Clone()
	local obj = Restriction:new(table.Copy(self))
	
	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.orign = self
	end

	return obj
end

function object:GetBarebones()
	local tbl = {}
	for k,v in pairs(self) do
		if v then
			tbl[k] = v
		end
	end
	return tbl
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

function object:SetScope(scope)	
	self.scope = Scope:new(scope)
	
	self.scope:SetParent(self)
	
	self.scope:AllowThink()
end

function object:DeleteScope()
	self.scope:Delete()
	self.scope = nil
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

function object:GetOrigin()
	return self.origin
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
	return string.lower(string.format("%s_%s%s",self.type,self.usergroup.."_" or "",self.string))
end

object.__index = object
static.__index = static

setmetatable(Restriction,static)

