
local object = {}
local static = {}

object._id = "WUMA_WUMAObject"
static._id = "WUMA_WUMAObject"

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////
local function staticIndex(tbl, key)
	while (tbl) do
		local value = rawget(tbl, key)
		if value then return value end
		tbl = getmetatable(tbl)
	end
end

function static:Inherit(static, object)
	static._object = object
	setmetatable(static, getmetatable(self))
	local tbl = setmetatable({}, static)
	
	getmetatable(tbl).__index = staticIndex

	local stack = {}
	local metatable = static
	while (metatable) do
		table.insert(stack, rawget(metatable, "_object"))
		Msg((rawget(metatable, "_id") or "NO_ID").. " -> ")

		metatable = getmetatable(metatable)
	end
	Msg("\n")

	local count = table.Count
	getmetatable(tbl).new = function(self, tbl)
		local object = {}

		local metatable = object
		for i = 1, count(stack) do
			setmetatable(metatable, stack[i])

			Msg(stack[i]._id .. " -> ")
			
			metatable = getmetatable(metatable)
		end
		Msg("\n")
		
		local m = {}

		getmetatable(object).__index = function(self, key)
			if (key == "m") then return m end

			local value = rawget(m, key)
			if value then return value end
			
			local tbl = self
			while (tbl) do
				local value = rawget(tbl, key)
				if value then return value end
				tbl = getmetatable(tbl)
			end
		end

		object.m.super = function(fn, ...) getmetatable(getmetatable(object))[fn](object, ...) end
		object.m._uniqueid = WUMA.GenerateUniqueID()
		
		object:Construct(tbl or {})
		return object
	end
	getmetatable(tbl).New = getmetatable(tbl).new
	
	return tbl
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
static._object = object

WUMAObject = setmetatable({},static)