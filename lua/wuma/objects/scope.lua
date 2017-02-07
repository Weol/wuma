 
Scope = {}
Scope.types = {}

local object = {}
local static = {}

Scope.UNTIL = {
	print="Until date",
	print2=function(obj) return string.format("%s/%s/%s",obj:GetData().day,obj:GetData().month,obj:GetData().year) end,
	log_prefix="until",
	parts={"date_chooser"},
	save=true,
	checkfunction=function(obj) 
		local tbl = obj:GetData()
		if (tonumber(os.date("%Y", os.time())) > tbl.year) then 
			return false 
		elseif (tonumber(os.date("%Y", os.time())) == tbl.year) then	
			if (tonumber(os.date("%m", os.time())) > tbl.month) then 
				return false 
			elseif (tonumber(os.date("%m", os.time())) == tbl.month) then
				if (tonumber(os.date("%d", os.time())) > tbl.day) then 
					return false 
				elseif (tonumber(os.date("%d", os.time())) == tbl.day) then
					return false
				else
					return true
				end
			else
				return true
			end
		else
			return true
		end
	end,
	arguments={WUMAAccess.NUMBER} 
}
Scope.types.UNTIL = Scope.UNTIL

Scope.DURATION = {
	print="Duration",
	print2=function(obj) return string.format("%s seconds",obj:GetData()-os.time()) end,
	log_prefix="for",
	parts={"time_chooser"},
	save=true,
	processdata=function(data) return tonumber(data)+os.time() end,
	checkfunction=function(obj) 
		if (os.time() > obj:GetData()) then return false else return true end 
	end,
	arguments={WUMAAccess.NUMBER}
}
Scope.types.DURATION = Scope.DURATION

Scope.MAP = {
	print="Map",
	print2=function(obj) return string.format("Map %s",obj:GetData()) end,
	log_prefix="on",
	parts={"map_chooser"},
	save=true,
	keep=true,
	checkdata=game.GetMap,
	checkfunction = function(obj, data) 
		if (obj:GetData() == data) then 
			return true 
		else 
			return false  
		end 
	end,
	arguments={WUMAAccess.STRING}, 
}
Scope.types.MAP = Scope.MAP

Scope.PERIOD = {
	print="Time period",
	print2=function(obj) 
		return string.format("%s to %s",math.floor(obj:GetData().from/3600)..":"..(obj:GetData().from/3600 - math.floor(obj:GetData().from/3600)) * 60,math.floor(obj:GetData().to/3600)..":"..(obj:GetData().to/3600 - math.floor(obj:GetData().to/3600)) * 60) 
	end,
	log_prefix="from",
	parts={"period_chooser"},
	save=true,
	keep=true,
	checkfunction = function(obj)
		local time = tonumber(os.date("%M", os.time()))*60 + tonumber(os.date("%H", os.time()))*3600

		if (time >= obj:GetData().from and time < obj:GetData().to) then return true end

		return false
	end,
	arguments={WUMAAccess.NUMBER,WUMAAccess.NUMBER}
}
Scope.types.PERIOD = Scope.PERIOD
 
Scope._id = "WUMA_Scope"
Scope.Objects = Scope.Objects or {}

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////
function Scope:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.m.parent = tbl.parent or false
	obj.type = tbl.type or "Permanent"
	obj.data = tbl.data or false
	obj.class = tbl.class or false

	hook.Add("WUMAScopeThink","WUMAScopeThink"..tostring(obj:GetUniqueID()),function() obj:Think() end)
  
	return obj
end 

function static:StartThink()
	if not timer.Exists("WUMAScopeStaticThinkTimer") then
		timer.Create("WUMAScopeStaticThinkTimer",1,0,Scope.Think)
	end
end

function static:GetTypes(field)
	if field then
	
		local tbl = {}
		
		for _, type in pairs(Scope.types) do 
			for key,value in pairs(type) do 
				if (key == field) then
					table.insert(tbl,value)
				end
			end
		end
		 
		return tbl
	end

	return Scope.types
end

function static:GetUniqueID()
	return false
end

function static:__eq(v1, v2)
	if v1._id and v2._id then return (v1._id == v2.__id) end
end

function static:Think()
	hook.Call("WUMAScopeThink")
end


/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:__tostring()
	local scope = Scope.types[self:GetType()]
	if scope.print2 then 
		return scope.print2(self)
	else
		return scope.print
	end
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:GetStatic()
	return Scope
end

function object:Delete()
	hook.Remove("WUMAScopeThink","WUMAScopeThink"..tostring(self:GetUniqueID()))
	self = nil
end	

function object:Think()
	if self:CanThink() then
		if not self:GetParent() then return self:Delete() end
	
		local typ = Scope.types[self:GetType()]
		local checkdata = nil
		if typ.checkdata then checkdata = typ.checkdata() end
			
		if not typ.checkfunction(self,checkdata) then
			if not self:GetParent():IsDisabled() then
				if typ.keep then
					if self:GetParent() then
						self:GetParent():Disable()
					else
						WUMADebug("Warning! Scope has no parent!")
					end
				else
					self:Delete()
					self:GetParent():Shred()
				end
			end
		else
			if self:GetParent():IsDisabled() then
				self:GetParent():Enable()
			end
		end
	end
end

function object:SetProperty(id, value)
	self[id] = value
end

function object:Clone()
	local obj = Scope:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.orign = self
	end

	return obj
end

function object:AllowThink()
	self.m.allowed_think = true
	self:Think()
end

function object:DisallowThink()
	self.m.allowed_think = false
end

function object:CanThink()
	return self.m.allowed_think
end

function object:SetData(data)
	self.data = data
end

function object:GetData()
	return self.data
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:GetPrint2()
	local scope = Scope.types[self:GetType()]
	if scope.print2 then 
		return scope.print2(self)
	else
		return scope.print
	end
end

function object:GetPrint()
	local scope = Scope.types[self:GetType()]
	return scope.print
end

function object:SetParent(obj)
	self.m.parent = obj
end

function object:GetParent()
	return self.m.parent
end

function object:GetScopeType()
	return Scope.types[self.type]
end

function object:GetType()
	return self.type
end

function object:GetOrigin()
	return self.origin
end

object.__index = object
static.__index = static 

setmetatable(Scope,static)