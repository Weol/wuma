
WUMA.ClassFactory = {}

local factory = {}

function factory:AddProperty(name, default, accessor, setter_function, getter_function)
	setter_function = setter_function or function(self, value) self[name] = value end
	getter_function = getter_function or function(self) return self[name] end

	self.properties[name] = default
	builder.metatable["Set" .. accessor] = setter_function
	builder.metatable["Get" .. accessor] = getter_function
end

function factory:AddMetaData(name, default, accessor, setter_function, getter_function)
	setter_function = setter_function or function(self, value) self[name] = value end
	getter_function = getter_function or function(self) return self[name] end

	self.metadata[name] = function()
	builder.metatable["Set" .. accessor] = setter_function
	builder.metatable["Get" .. accessor] = getter_function
end

function factory:AddFunction(name, func)
	builder.metatable[name] = func
end

factory.__index = factory

WUMA.ClassFactory.Builder(classname)
	local builder = setmetatable({}, factory)
	builder.metatable = {}
	builder.properties = {}
	builder.metadata = {}

	builder.metatable._id = classname
end

WUMA.ClassFactory.Create(builder)
	local metatable = builder.metatable
	metatable.new = function(self, tbl)
		tbl = tbl or {}
		local obj = setmetatable({}, metatable)

		for k, v in pairs()

		if builder.constructor then builder.constructor(obj, tbl) end
	end
end
