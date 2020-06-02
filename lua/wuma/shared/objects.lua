
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
		self.metatable["Set" .. accessor] = setter_function
	end

	if getter_function ~= false then
		getter_function = function(self) return self[name] end
		self.metatable["Get" .. accessor] = getter_function
	end

	self.properties[name] = function() return default end
end

function factory:AddMetaData(name, accessor, default, setter_function, getter_function)
	if setter_function ~= false then
		setter_function = function(self, value) getmetatable(self)[name] = value end
		self.metatable["Set" .. accessor] = setter_function
	end

	if getter_function ~= false then
		getter_function = function(self) return getmetatable(self)[name] end
		self.metatable["Get" .. accessor] = getter_function
	end

	self.metadata[name] = function() return default end
end

function WUMA.ClassFactory.Builder(classname)
	local builder = {}
	builder.metatable = {}
	builder.static_functions = {}
	builder.properties = {}
	builder.metadata = {}

	builder.metatable._id = classname

	setmetatable(builder, {
		__newindex = function(_, k, v)
			rawset(builder.metatable, k, v)
		end,
		__index = factory
	})

	return builder, builder.static_functions
end

function WUMA.ClassFactory.Create(builder)
	local metatable = builder.metatable
	local static_functions = builder.static_functions

	static_functions._id = builder.metatable._id

	static_functions.New = function(_, args)
		args = args or {}

		local metadata = setmetatable({}, metatable)
		local obj = setmetatable({}, metadata)

		getmetatable(metadata).__index = metatable
		getmetatable(obj).__index = metadata

		for k, v in pairs(builder.properties) do
			if args[k] then
				obj[k] = args[k]
			else
				if istable(v()) then
					obj[k] = table.Copy(v())
				else
					obj[k] = v()
				end
			end
		end

		for k, v in pairs(builder.metadata) do
			if args[k] then
				metadata[k] = args[k]
			else
				if istable(v()) then
					metadata[k] = table.Copy(v())
				else
					metadata[k] = v()
				end
			end
		end

		metadata._uniqueid = generateUniqueId()

		if builder.__construct then builder.__construct(obj, args) end

		return obj
	end

	metatable.GetStatic = function() return static_functions end

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
