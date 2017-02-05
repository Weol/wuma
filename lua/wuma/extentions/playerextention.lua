
local ENT = FindMetaTable("Player")
local self = ENT
  
function ENT:CheckLimit(str, WUMA) 
	
	WUMADebug("CheckLimit(%s,%s)",str or "_",WUMA or "_")
	
	if (game.SinglePlayer()) then return true end
	
	if WUMA then 
		if (self:HasLimit(WUMA)) then
			return self:GetLimit(WUMA):Check()
		elseif (self:HasLimit(str)) then
			return self:GetLimit(str):Check()
		end

		local c = cvars.Number("sbox_max"..str, 0)
	
		if (c < 0) then return true end
		if (self:GetCount(str) > c-1) then self:LimitHit(str) return false end
		return true
	end
	
	return true

end 
  
function ENT:AddCount(str, ent, WUMA)
 
	WUMADebug("AddCount(%s,%s,%s)",str or "_",tostring(ent) or "_",WUMA or "_")

	if (WUMA and self:HasLimit(WUMA)) then 
		self:GetLimit(WUMA):Add(ent)
	elseif (self:HasLimit(str)) then
		self:GetLimit(str):Add(ent)
	else

		if (SERVER) then

			local key = self:UniqueID()
			g_SBoxObjects[ key ] = g_SBoxObjects[ key ] or {}
			g_SBoxObjects[ key ][ str ] = g_SBoxObjects[ key ][ str ] or {}
			
			local tab = g_SBoxObjects[ key ][ str ]
			
			table.insert(tab, ent)
			
			-- Update count (for client)
			self:GetCount(str)
			
			ent:CallOnRemove("GetCountUpdate", function (ent, ply, str) ply:GetCount(str, 1) end, self, str)
		
		end
	
	end 
		 
	
end 
     
function ENT:GetCount(str, minus, WUMA)

	WUMADebug("GetCount(%s,%s,%s)",str or "_",tostring(minus) or "_",WUMA or "_")

	if (WUMA and self:HasLimit(WUMA)) then 
		local l = self:GetLimit(WUMA):GetCount()
		if (minus > 0) then self:GetLimit(WUMA):Subtract(minus) end
		return l
	elseif self:HasLimit(str) then
		local l = self:GetLimit(str):GetCount()
		if (minus > 0) then self:GetLimit(str):Subtract(minus) end
		return l
	else
		
		if (CLIENT) then
			return self:GetNetworkedInt("Count."..str, 0)
		end
		
		minus = minus or 0 
		
		if (!self:IsValid()) then return end

		local key = self:UniqueID()
		local tab = g_SBoxObjects[ key ]
		
		if (!tab || !tab[ str ]) then  
		
			self:SetNetworkedInt("Count."..str, 0)
			return 0 
			
		end
		
		local c = 0

		for k, v in pairs(tab[ str ]) do
		
			if (v:IsValid()) then 
				c = c + 1
			else
				tab[ str ][ k ] = nil
			end
		
		end
		
		self:SetNetworkedInt("Count."..str, c - minus)

		return c
			
	end
	
end

function ENT:LimitHit(str)

	WUMADebug("LimitHit(%s)",str or "_")
	
	if self:HasLimit(str) then
		self:GetLimit(str):Hit()
	else
		Limit:GenerateHit(str,self)
	end

end

function ENT:GetWUMAData()
	return {
		restrictions = self:GetRestrictions() or false,
		limits = self:GetLimits() or false,
		loadout = self:GetLoadout() or false
	}
end   

function ENT:HasWUMAData()
	if (self:GetRestrictions() or self:GetLimits() or self:GetLoadout()) then return true else return false end
end   
 
function ENT:CheckRestriction(type,str)
	WUMADebug("CheckRestriction(%s,%s)",type,str)
	 
	local key = Restriction:GenerateID(type,self:GetUserGroup(),str)
	local personal_key = Restriction:GenerateID(type,_,str)
	
	if self:GetRestrictions()[key] then 
		return self:GetRestrictions()[key](type,str)
	elseif self:GetRestrictions()[personal_key] then 
		return self:GetRestrictions()[personal_key](type,str)
	end
end   
 
function ENT:AddRestriction(restriction) 
	if not self.Restrictions then self.Restrictions = {} end

	local key = restriction:GetID() 

	restriction:SetParent(self)
	
	if not self:GetRestrictions()[key] or not restriction:IsPersonal() then
		self:GetRestrictions()[key] = restriction
	else
		self:GetRestrictions()[key]:SetOverride(restriction)
	end
end 

function ENT:AddRestrictions(tbl)
	for _,object in pairs(tbl) do
		self:AddRestriction(object)
	end
end

function ENT:RemoveRestriction(id,personal) 
	if not id then return end
	if not self:GetRestrictions()[id] then return end
	
	if personal then
		if not self:GetRestrictions()[id]:IsPersonal() and self:GetRestrictions()[id]:GetOverride() then
			if (self:GetRestrictions()[id]:GetOverride():GetID() == id) then
				self:GetRestrictions()[id]:RemoveOverride()
				return
			end
		end  
	end
	
	self:GetRestrictions()[id] = nil
end

function ENT:GetRestrictions()
	return self.Restrictions or {}
end
 
function ENT:GetRestriction(type,str)
	if not str then return end
	local key = Restriction:GenerateID(type,self:GetUserGroup(),str)
	
	if (isstring(str) and type and isstring(type)) then 
		return self:GetRestrictions()[key]
	end  
end 

function ENT:AddLimit(limit)
	if not self.Limits then self.Limits = {} end

	limit:SetParent(self)

	if not self:GetLimits()[limit:GetID()] or not limit:IsPersonal() then
		self:GetLimits()[limit:GetID()] = limit
	else
		self:GetLimits()[limit:GetID()]:SetOverride(limit)
	end
end
 
function ENT:RemoveLimit(id,personal)

	if personal then
		if not self:GetLimits()[id]:IsPersonal() and self:GetLimits()[id]:GetOverride() then
			if (self:GetLimits()[id]:GetOverride():GetID() == id) then
				self:GetLimits()[id]:RemoveOverride()
				return
			end
		end
	end

	self:GetLimits()[id] = nil
end

function ENT:GetLimits()
	return self.Limits or {}
end 

function ENT:GetLimit(str)
	local id = Limit:GenerateID(self:GetUserGroup(),str)
	local id_personal = Limit:GenerateID(_,str)
	return self:GetLimits()[id] or self:GetLimits()[id_personal]
end

function ENT:HasLimit(str)
	local id = Limit:GenerateID(self:GetUserGroup(),str)
	local id_personal = Limit:GenerateID(_,str)
	if self:GetLimits()[id] or self:GetLimits()[id_personal] then return true end
	return false
end

function ENT:GiveLoadout()
	if self:HasLoadout() then
		self:GetLoadout():Give()
		return true
	end
end

function ENT:SetPrimaryWeapon(weapon)
	self:GetLoadout():SetPrimaryWeapon(weapon)
end

function ENT:SetLoadout(loadout)
	loadout:SetParent(self)
	if self:HasLoadout() and not self:GetLoadout():IsPersonal() then 
		loadout:SetAncestor(self:GetLoadout()) 
	end
	self.Loadout = loadout
	self:GetLoadout():Give()
end 
 
function ENT:ClearLoadout() 
	if (self.Loadout and self.Loadout:IsPersonal()) then
		if (self.Loadout:GetAncestor()) then
			local ancestor = self.Loadout:GetAncestor()
			
			self.Loadout = ancestor
			
			self.Loadout:Give()
		else
			self.Loadout:Delete()
			self.Loadout = nil
			
			WUMA.GiveDefaultLoadout(self)
		end
	elseif self.Loadout then
		self.Loadout:Delete()
		self.Loadout = nil 
		
		WUMA.GiveDefaultLoadout(self)
	end
end

function ENT:HasLoadout()
	if self:GetLoadout() then return true else return false end
end

function ENT:GetLoadout()
	return self.Loadout
end

ENT.DisregardTable = {}
function ENT:DisregardNextPickup(class)
	self.DisregardTable[class] = true
end

function ENT:ShouldDisregardPickup(class)
	if self.DisregardTable[class] then 
		self.DisregardTable[class] = nil
		return true 
	else
		return false
	end
end