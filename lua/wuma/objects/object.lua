
local object = {}
local static = {}

object._id = "WUMA_WUMAObject"
static._id = "WUMA_WUMAObject"

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////
function static:new(_, tbl)
	tbl = tbl or {}
	
	local obj = setmetatable({},object)
	obj.m = {}
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
  
	return obj
end 

function static:Inherit(static, object)
	static._object = object
	setmetatable(static, self)
	local tbl = setmetatable(tbl, static)
	
	getmetatable(tbl).__index = function(tbl, key)
		while (tbl) do
			local value = rawget(tbl, key)
			if value then return value end
			tbl = getmetatable(tbl)
		end
	end
	
	local stack = {}
	local metatable = static
	while (metatable) do
		table.insert(stack, metatable._object)
		metatable = getmetatable(metatable)
	end
	
	local count = table.Count
	getmetatable(tbl).new = function(self, tbl)
		local object = {}
		
		local metatable = {}
		for i = 1, count(stack) do
			setmetatable(metatable, stack[i])
			
			metatable = getmetatable(metatable)
		end
		setmetatable(object, metatable)
		local m = {}
		
		getmetatable(object).__index = function(self, key)
			local value = rawget(m, key)
			if value then return value end
		
			while (self) do
				local value = rawget(self, key)
				if value then return value end
				self = getmetatable(self)
			end
		end

		object.m.super = 
		object.m._uniqueid = WUMA.GenerateUniqueID()
		
		object:Construct(tbl)
		return object
	end
	getmetatable(tbl).New = getmetatable(tbl).new
	
	return static
end

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:Construct(tbl)
	
end

function object:__tostring()
	return object._id
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:Clone()
	local obj = static:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.origin = self
	end

	return obj
end

function object:GetOrigin()
	return self.m.origin
end

static.__index = static 

WUMAObject = setmetatable({},static)