
WUMA.ClassFactory = {}

local uniqueIds = 0
local function generateUniqueId()
	uniqueIds = uniqueIds + 1
	return uniqueIds
end

local factory = {}

function factory:AddProperty(name, accessor, default, setter_function, getter_function)
	if setter_function ~= false then
		setter_function = function(self, value) self[name] = value end
		builder.metatable["Set" .. accessor] = setter_function
	end

	if getter_function ~= false then
		getter_function = function(self) return self[name] end
		builder.metatable["Get" .. accessor] = getter_function
	end

	self.properties[name] = default
end

function factory:AddMetaData(name, accessor, default, setter_function, getter_function)
	if setter_function ~= false then
		setter_function = function(self, value) self[name] = value end
		builder.metatable["Set" .. accessor] = setter_function
	end

	if getter_function ~= false then
		getter_function = function(self) return self[name] end
		builder.metatable["Get" .. accessor] = getter_function
	end

	self.metadata[name] = default
end

factory.__index = factory

WUMA.ClassFactory.Builder(classname)
	local builder = {}
	builder.metatable = {}
	builder.static_functions = {}
	builder.properties = {}
	builder.metadata = {}

	builder.metatable._id = classname

	setmetatable(builder, {
		__newindex = function(k, v)
			rawset(builder.metatable, k, v)
		end
	})

	return builder, builder.static_functions
end

WUMA.ClassFactory.Create(builder)
	local metatable = builder.metatable
	local static_functions = builder.static_functions

	static_functions._id = builder.metatable._id

	static_functions.New = function(self, args)
		args = args or {}
		local obj = setmetatable({}, metatable)

		for k, v in pairs(builder.properties) do
			obj[k] = args[k] or v
		end

		for k, v in pairs(builder.metadata) do
			obj[k] = args[k] or v
		end

		obj._uniqueid = generateUniqueId()

		if builder.__construct then builder.__construct(obj, args) end

		return obj
	end

	metatable.GetStatic = function(self) return static_functions end

	metatable.Export = function(self)
		local tbl = {}

		for k, v in pairs(builder.properties) do
			tbl[k] = self[k]
		end

		return tbl
	end

	metatable.Clone = function(self)
		return static_functions:new(self:Export())
	end

	metatable.GetUniqueID = function(self)
		return self._uniqueid
	end

	return static_functions
end
