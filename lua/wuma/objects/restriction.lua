
local object = {}
local static = {}

object._id = "WUMA_Restriction"
static._id = "WUMA_Restriction"

static.types = {
	entity = {print="Entity",print2="Entities",search="Search..",items=function() return WUMA.GetEntities() end},
	prop = {print="Prop",print2="Props",search="Model"},
	npc = {print="NPC",print2="NPCs",search="Search..",items=function() return WUMA.GetNPCs() end},
	vehicle = {print="Vehicle",print2="Vehicles",search="Search..",items=function() return WUMA.GetVehicles() end},
	swep = {print="Weapon",print2="Weapons",search="Search..",items=function() return WUMA.GetWeapons() end},
	pickup = {print="Pickup",print2="Pickups",search="Search..",items=function() return WUMA.GetWeapons() end},
	effect = {print="Effect",print2="Effects",search="Model"},
	tool = {print="Tool",print2="Tools",search="Search..",items=function() return WUMA.GetTools() end},
	ragdoll = {print="Ragdoll",print2="Ragdolls",search="Model"},
	use = {print="Use",print2="Uses",search="Search..",items=function() 
		local tbl = {}
		table.Add(table.Add(table.Add(tbl, WUMA.GetEntities()),WUMA.GetVehicles()),WUMA.GetNPCs()) 
		return tbl
	end}  
} 

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////
function static:GenerateID(type,usergroup,str)
	if usergroup then
		if str then
			return string.lower(type.."_"..usergroup.."_"..str)
		else
			return string.lower(type.."_"..usergroup)
		end
	else
		if str then
			return string.lower(type.."_"..str)
		else
			return string.lower(type)
		end
	end
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

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:Construct(tbl)
	self.super("Construct", tbl)

	self.usergroup = tbl.usergroup or nil
	self.type = tbl.type or nil
	self.string = tbl.string or nil
	self.print = tbl.print or tbl.string
	self.allow = tbl.allow or nil 

	self.m.exceptions = {} 
end 

function object:__eq(v1, v2)
	return ((v1.usergroup == v2.usergroup) and (v1.type == v2.type) and (v1.string == v2.string) and (v1.allow == v2.allow))
end

function object:__call(type,str)
	if self:IsDisabled() then return end

	if (self:HasException(str)) then 
		self:RemoveException(str)
		return
	end
	
	if not self.allow then
		self:Hit()
		return false
	end
end

function object:__tostring()
	return string.format("Restriction [%s][%s]",self:GetType(),self:GetString())
end

function object:Delete()
	if self.scope then
		self.scope:Delete()
	end
end

function object:Shred()
	if self:IsPersonal() then
		WUMA.RemoveUserRestriction(_,self:GetParentID(),self:GetType(),self:GetString())
	else
		WUMA.RemoveRestriction(_,self:GetUserGroup(),self:GetType(),self:GetString())
	end
end

function object:Hit()
	if (self.type == "pickup") then return end
	
	if (self.type == "use") then
		if self.m.lasthit and not (os.time() - self.m.lasthit > 1) then self.m.lasthit = os.time(); return end
	end

	self.m.lasthit = os.time()

	local str = self.print or self.string
	
	if (self:IsGeneral()) then
		str = Restriction:GetTypes()[self:GetType()].print2
		
		self:GetParent():SendLua(string.format([[
			notification.AddLegacy("%s are restricted!",NOTIFY_ERROR,3)
		]],str))
	else
		self:GetParent():SendLua(string.format([[
			notification.AddLegacy("This %s (%s) is restricted!",NOTIFY_ERROR,3)
		]],string.lower(Restriction:GetTypes()[self:GetType()].print), str))
	end
	self:GetParent():SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

function object:IsPersonal()
	if self.usergroup then return nil else return true end
end

function object:IsGeneral()
	if self.string then return nil else return true end
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

function object:GetUserGroup()
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

function object:GetString()
	return self.string
end

function object:SetString(str)
	self.string = string
end

function object:SetAllow(boolean)
	self.allow = boolean
end

function object:GetAllow()
	return self.allow 
end

function object:GetID(short)
	if (not self:GetUserGroup()) or short then
		if self:GetString() then
			return string.lower(string.format("%s_%s",self.type,self.string))
		else
			return string.lower(self.type)
		end
	else
		if self:GetString() then
			return string.lower(string.format("%s_%s_%s",self.type,self.usergroup,self.string))
		else
			return string.lower(string.format("%s_%s",self.type,self.usergroup))
		end
	end
end

Restriction = UserObject:Inherit(static, object)