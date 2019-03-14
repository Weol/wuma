
local object = {}
local static = {}

object._id = "UserObject"
static._id = "UserObject"

function object:Construct(tbl)
	self:SetParent(tbl.parent)
	
	if tbl.scope then self:SetScope(tbl.scope) else self.m.scope = "Permanent" end
end

function object:SetScope(scope)	
	if not self:GetOrigin() then
		self.scope = scope
		if not scope.m then self.scope = Scope:new(scope) end
	
		self.scope:SetParent(self)
		
		self.scope:AllowThink()
	end
end

function object:GetScope()
	return self.scope
end

function object:HasScope()
	return self.scope and not isstring(self.scope)
end

function object:DeleteScope()
	self.scope:Delete()
	self.scope = nil
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

function object:SetAncestor(ancestor)
	self.m.ancestor = ancestor
end

function object:GetAncestor()
	return self.m.ancestor
end

function object:GetParentID()
	return self.m.parentid
end

function object:GetParent()
	return self.m.parent
end

function object:SetParent(user)
	self.m.parent = user
	if isstring(self.m.parent) then self.m.parentid = self.m.parent elseif self.m.parent then self.m.parentid = self.m.parent:SteamID() end
end

UserObject = WUMAObject:Inherit(static, object)