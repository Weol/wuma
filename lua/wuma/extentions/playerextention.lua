
local ENT = FindMetaTable("Player")
  
function ENT:CheckLimit(str, WUMA) 

	if (game.SinglePlayer()) then return true end
	
	if (WUMA and self:HasLimit(WUMA)) then
		return self:GetLimit(WUMA):Check()
	elseif (self:HasLimit(str)) then
		return self:GetLimit(str):Check()
	else

		local c = cvars.Number("sbox_max"..str, 0)

		if (c < 0) then return true end
		if (self:GetCount(str) > c-1) then self:LimitHit(str) return false end
		return true
	
	end

end 
  
function ENT:AddCount(str, ent, WUMA)

	if (WUMA and self:HasLimit(WUMA)) then 
		self:GetLimit(WUMA):Add(ent)
	elseif (self:HasLimit(str)) then
		self:GetLimit(str):Add(ent)
	elseif str then

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

	local key = Restriction:GenerateID(type,_,str)
	
	if self:GetRestriction(key) then 
		return self:GetRestrictions()[key](type,str)
	end
end   
   
function ENT:AddRestriction(restriction) 
	if not self:GetRestrictions() then self.Restrictions = {} end

	local id = restriction:GetID(true)
	restriction:SetParent(self)
	
	local old = self:GetRestriction(id)
	local new = restriction

	if (not old) or (new:IsPersonal() == old:IsPersonal()) then
		self:GetRestrictions()[id] = new
	elseif new:IsPersonal() then
		new:SetAncestor(old)
		self:GetRestrictions()[id] = new
	elseif old:IsPersonal() then
		old:SetAncestor(new)
	else
		self:GetRestrictions()[id] = new
	end
end 

function ENT:AddRestrictions(tbl)
	for _,object in pairs(tbl) do
		self:AddRestriction(object)
	end
end

function ENT:RemoveRestriction(id,personal) 
	local restriction = self:GetRestriction(id)
	if not restriction then return end
	
	if (restriction:IsPersonal() == personal) then
		local ancestor = restriction:GetAncestor()
		self:GetRestrictions()[id] = ancestor
	elseif (restriction:IsPersonal()) then
		restriction:SetAncestor(nil)
	elseif (personal) then
		local ancestor = restriction:GetAncestor()
		self:GetRestrictions()[id] = ancestor
	end
end

function ENT:GetRestrictions()
	return self.Restrictions 
end
 
function ENT:GetRestriction(type,str)
	if not self:GetRestrictions() then return nil end
	if str then
		local key = Restriction:GenerateID(type,_,str)
		return self:GetRestrictions()[key]
	else
		return self:GetRestrictions()[type]
	end
end 

function ENT:AddLimit(limit)
	if not self:GetLimits() then self.Limits = {} end

	local id = limit:GetID(true)
	limit:SetParent(self)
	
	local old = self:GetLimit(id)
	local new = limit
	
	if (not old) or (new:IsPersonal() == old:IsPersonal()) then
		self:GetLimits()[id] = new
	elseif new:IsPersonal() then
		new:SetAncestor(old)
		new:InheritEntities(old)
		
		self:GetLimits()[id] = new
	elseif old:IsPersonal() then
		old:SetAncestor(new)
	else
		self:GetLimits()[id] = new
	end
end
 
function ENT:RemoveLimit(id,personal)
	local limit = self:GetLimit(id)
	if not limit then return end
	
	if (limit:IsPersonal() == personal) then
		local ancestor = limit:GetAncestor()
		if ancestor then ancestor:InheritEntities(limit) end
		
		self:GetLimits()[id] = ancestor
	elseif (limit:IsPersonal()) then
		limit:SetAncestor(nil) 
	elseif (personal) then
		local ancestor = limit:GetAncestor()
		if ancestor then ancestor:InheritEntities(limit) end
		
		self:GetLimits()[id] = ancestor
	end
end

function ENT:GetLimits()
	return self.Limits
end 

function ENT:GetLimit(str)
	local id = Limit:GenerateID(_,str)
	return self:GetLimits()[id]
end

function ENT:HasLimit(str)
	local id = Limit:GenerateID(_,str)
	if self:GetLimits()[id] then return true end
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