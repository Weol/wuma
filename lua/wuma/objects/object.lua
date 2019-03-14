
local object = {}
local static = {}

object._id = "WUMA_WUMAObject"
static._id = "WUMA_WUMAObject"

local function index(tbl, key)
	while (tbl) do
		local value = rawget(tbl, key)
		if value then return value end
		tbl = getmetatable(tbl)
	end
end

local uniqueIds = 0
local function generateUniqueId()
	uniqueIds = uniqueIds + 1
	return uniqueIds
end

function static:Inherit(static, object)
	static._object = object
	object._static = static
	
	local getmeta = getmetatable --We use this like, alot
	local setmeta = setmetatable --We use this like, alot
	
	setmeta(static, getmeta(self))
	local tbl = setmeta({}, static)
	
	getmeta(tbl).__index = index

	local metatableStack = {}
	local metamethodStack = {}
	local metatable = static
	while (metatable) do
		local entry = rawget(metatable, "_object")
		table.insert(metatableStack, entry)
		for k, v in pairs(entry) do
			if string.StartWith(k, "__") then
				metamethodStack[k] = v
			end
		end
		
		metatable = getmeta(metatable)
	end

	local count = table.Count
	getmeta(tbl).new = function(_, tbl)
		local object = setmeta({}, {m = {}})
		
		local metatable = getmeta(object)
		for i = 1, count(metatableStack) do
			setmeta(metatable, metatableStack[i])
			
			metatable = getmeta(metatable)
		end
		
		local metatable = getmeta(object)
		for k, v in pairs(metamethodStack) do
			metatable[k] = v
		end

		metatable.__index = index 
		
		metatable.super = setmeta({}, {__index = function(_, key) 
			return function(_, ...) 
				getmeta(getmeta(metatable))[key](object, ...) 
			end 
		end})
		
		object.m._uniqueid = generateUniqueId()
		
		object:Construct(tbl or {})
		return object
	end
	getmeta(tbl).New = getmeta(tbl).new
	
	return tbl
end

function static:GetID()
	return self._id
end

function object:Construct(tbl)
	
end

function object:GetStatic()
	return self._static
end

function object:__tostring()
	return object._id
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:GetBarebones()
	local tbl = {}
	for k, v in pairs(self) do
		if v then
			tbl[k] = v
		end
	end
	return tbl
end

function object:Clone()
	local obj = self:GetStatic():new(table.Copy(self))

	obj.m.origin = self.origin or self

	return obj
end

function object:GetOrigin()
	return self.m.origin
end

static.__index = static 
static._object = object

WUMAObject = setmetatable({}, static)