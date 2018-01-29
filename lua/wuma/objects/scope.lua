
local object = {}
local static = {}

object._id = "WUMA_Scope"
static._id = "WUMA_Scope"

static.types = {}

static.UNTIL = {
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
static.types.UNTIL = static.UNTIL

static.DURATION = {
	print="Duration",
	print2=function(obj)
		local time = obj:GetData()-WUMA.GetTime()
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
	processdata=function(data) return tonumber(data)+WUMA.GetTime() end,
	checkdata=os.time,
	checkfunction=function(obj) 
		return (os.time() <= obj:GetData())
	end,
	arguments={WUMAAccess.NUMBER}
}
static.types.DURATION = static.DURATION

static.MAP = {
	print="Map",
	print2=function(obj) return string.format("%s",obj:GetData()) end,
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
static.types.MAP = static.MAP

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////
function static:StartThink()
	if not timer.Exists("WUMAScopeStaticThinkTimer") then
		timer.Create("WUMAScopeStaticThinkTimer",1,0,function() self:Think() end)
		self.ThinkActive = true
		self:ExecuteThinkQueue()
	end
end

function static:IsThinking() 
	return (self.ThinkActive == true)
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

static.ScopeThinkHooks = {}
function static:Think()
	if SERVER then
		for id, scope in pairs(self.ScopeThinkHooks) do
			scope:Think()
		end
	end
end

function static:AddScopeThinkHook(scope)
	self.ScopeThinkHooks[scope:GetUniqueID()] = scope
end

function static:RemoveScopeThinkHook(scope)
	self.ScopeThinkHooks[scope:GetUniqueID()] = nil
end

function static:ExecuteThinkQueue()
	if self.thinkQueue then
		for id, scope in pairs(self.thinkQueue) do
			scope:Think()
		end
		self.thinkQueue = false
	end
end

function static:QueueThink(scope)
	self.thinkQueue = self.thinkQueue or {}
	self.thinkQueue[scope:GetUniqueID()] = scope
end

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:Construct(tbl)
	self.type = tbl.type or "Permanent"
	self.data = tbl.data or false
	self.class = tbl.class or false
	
	self.m.parent = tbl.parent or false
	
	if (self:GetType() != "MAP") then 
		self:GetStatic():AddScopeThinkHook(self)
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

function object:Delete()
	self:GetStatic():RemoveScopeThinkHook(self)
end	

function object:Shred()
	self:GetStatic():RemoveScopeThinkHook(self)
	self:GetParent():Shred()
end

function object:Think()
	if CLIENT then return end

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

function object:AllowThink()
	self.m.allowed_think = true
	if self:GetStatic():IsThinking() then
		self:Think()
	else
		self:GetStatic():QueueThink(self)
	end
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

Scope = WUMAObject:Inherit(static, object)