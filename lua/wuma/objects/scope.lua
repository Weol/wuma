 
Scope = {}
Scope.types = {}

local object = {}
local static = {}

Scope.UNTIL = {
	print="Until date",
	print2=function(obj) return string.format("%02d/%02d/%04d", tonumber(obj:GetData().day), tonumber(obj:GetData().month), tonumber(obj:GetData().year)) end,
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
	print2=function(obj)
		local time = obj:GetData()-os.time()
		local str = ""

		local form = {
			{3600*60*24*365, "years"},
			{math.Round(52/12*(3600*60*24*7)), "months"},
			{3600*60*24*7, "weeks"},
			{3600*24, "days"},
			{60*60, "hours"},
			{60, "minutes"},
			{1, "seconds"}
		}
		
		for k, v in pairs(form) do
			local dur = v[1]
			if (time >= dur) then
				local t = math.floor(time/dur)
				str = str .. t .. " " .. v[2] .. " "
				time = time - t*dur
			end
		end

		return str
	end,
	log_prefix="for",
	parts={"time_chooser"},
	save=true,
	processdata=function(data) return tonumber(data)+os.time() end,
	checkdata=os.time,
	checkfunction=function(obj) 
		return (os.time() <= obj:GetData())
	end,
	arguments={WUMAAccess.NUMBER}
}
Scope.types.DURATION = Scope.DURATION

Scope.MAP = {
	print="Map",
	print2=function(obj) return string.format("%s", obj:GetData()) end,
	log_prefix="on",
	parts={"map_chooser"},
	save=true,
	keep=true,
	checkdata=game.GetMap,
	checkfunction = function(obj, data) 
		return (data == obj:GetData())
	end,
	arguments={WUMAAccess.STRING}, 
}
Scope.types.MAP = Scope.MAP
 
Scope._id = "WUMA_Scope"
Scope.Objects = Scope.Objects or {}

function Scope:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({}, mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.type = tbl.type or "Permanent"
	obj.data = tbl.data or false
	obj.class = tbl.class or false
	
	obj.m.parent = tbl.parent or false
	
	if (obj:GetType() ~= "MAP") then
		hook.Add("WUMAScopeThink", "WUMAScopeThink_"..tostring(obj:GetUniqueID()), function() obj:Think() end)
	end
 
	return obj
end 

function static:StartThink()
	if not timer.Exists("WUMAScopeStaticThinkTimer") then
		timer.Create("WUMAScopeStaticThinkTimer", 1, 0, Scope.Think)
	end
end

function static:GetTypes(field)
	if field then
	
		local tbl = {}
		
		for _, type in pairs(Scope.types) do 
			for key, value in pairs(type) do 
				if (key == field) then
					table.insert(tbl, value)
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
	if SERVER then
		hook.Call("WUMAScopeThink")
	end
end

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
	hook.Remove("WUMAScopeThink", "WUMAScopeThink_"..tostring(self:GetUniqueID()))
end	

function object:Shred()
	hook.Remove("WUMAScopeThink", "WUMAScopeThink_"..tostring(self:GetUniqueID()))
	self:GetParent():Shred()
end

function object:Think()
	if CLIENT then return end

	if self:CanThink() then
		if not self:GetParent() then return self:Delete() end

		local typ = Scope.types[self:GetType()]
		local checkdata = nil
		if typ.checkdata then checkdata = typ.checkdata() end

		if not typ.checkfunction(self, checkdata) then
			if not self:GetParent():IsDisabled() then
				if typ.keep then
					if self:GetParent() then
						self:GetParent():Disable()
					else
						WUMADebug("Warning! Scope has no parent!")
					end
				else
					self:Shred()
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
		obj.m.origin = self
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
	return self.m.origin
end

object.__index = object
static.__index = static 

setmetatable(Scope, static)