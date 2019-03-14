
local ENT = FindMetaTable("Entity")

function ENT:AddWUMAParent(limit)
	self.WUMAParents = self.WUMAParents or {}
	
	self.WUMAParents[limit:GetUniqueID()] = limit
	self:CallOnRemove("NotifyWUMAParents", function(ent) ent:NotifyWUMAParents() end)
end

function ENT:RemoveWUMAParent(limit)
	self.WUMAParents[limit:GetUniqueID()] = nil
end

function ENT:GetWUMAParents()
	return self.WUMAParents
end

function ENT:NotifyWUMAParents() 
	for _, parent in pairs(self:GetWUMAParents()) do 
		parent:DeleteEntity(self:GetCreationID())
	end
end
