
WUMA.ClassFactory = {}

local uniqueIds = 0
local function generateUniqueId()
	uniqueIds = uniqueIds + 1
	return uniqueIds
end

local factory = {}

function factory:AddProperty(name, default, accessor, setter_function, getter_function)
	setter_function = setter_function or function(self, value) self[name] = value end
	getter_function = getter_function or function(self) return self[name] end

	self.properties[name] = function(self) setter_function(self, default) end
	builder.metatable["Set" .. accessor] = setter_function
	builder.metatable["Get" .. accessor] = getter_function
end

function factory:AddMetaData(name, default, accessor, setter_function, getter_function)
	setter_function = setter_function or function(self, value) self[name] = value end
	getter_function = getter_function or function(self) return self[name] end

	self.metadata[name] = function(self) setter_function(self, default) end
	builder.metatable["Set" .. accessor] = setter_function
	builder.metatable["Get" .. accessor] = getter_function
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
			rawset(builder.metatablem, k, v)
		end
	})

	return builder, builder.static_functions
end

WUMA.ClassFactory.Create(builder)
	local metatable = builder.metatable
	local static_functions = builder.static_functions

	static_functions._id = builder.metatable._id

	static_functions.new = function(self, tbl)
		tbl = tbl or {}
		local obj = setmetatable({}, metatable)

		for k, v in pairs(builder.properties) do
			obj[k] = tbl[k] or v(obj)
		end

		for k, v in pairs(builder.metadata) do
			obj[k] = tbl[k] or v(obj)
		end

		obj._uniqueid = generateUniqueId()

		if builder.__construct then builder.__construct(obj, tbl) end
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
	static_functions = metatable.GetUniqueID

	return static_functions
end
