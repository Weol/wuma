
WUMA.ClassFactory = {}

local uniqueIds = 0
local function generateUniqueId()
	uniqueIds = uniqueIds + 1
	return uniqueIds
end

local factory = {}

function factory:AddProperty(name, accessor, default, setter_function)
	if not setter_function and setter_function ~= false then
		self.metatable["Set" .. accessor] = function(self, value) self[name] = value end
	elseif setter_function ~= false then
		self.metatable["Set" .. accessor] = function(self, value) self[name] = setter_function(value) end
	end

	self.metatable["Get" .. accessor] = function(self) return self[name] end

	self.properties[name] = function() return default end
end

function factory:AddMetaData(name, accessor, default, setter_function)
	if not setter_function and setter_function ~= false then
		self.metatable["Set" .. accessor] = function(self, value) getmetatable(self)[name] = value end
	elseif setter_function ~= false then
		self.metatable["Set" .. accessor] = function(self, value) getmetatable(self)[name] = setter_function(value) end
	end

	self.metatable["Get" .. accessor] = function(self) return getmetatable(self)[name] end

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

		for k, v in pairs(metatable) do
			if string.StartWith(k, "__") and k ~= "__index" then
				getmetatable(obj)[k] = v
			end
		end

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

		if obj.__construct then
			obj:__construct(args)
		end

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
		return static_functions:New(self:Export())
	end

	metatable.GetUniqueID = function(self)
		return self._uniqueid
	end

	return static_functions
end

--Unnecessarily convuluted object printing below here, for debug purposes

local function saveTablePrintLines(t, indent, done, lines)
	local Msg = function(str) table.insert(lines, str) end

	done = done or {}
	indent = indent or 0
	local keys = table.GetKeys(t)

	table.sort(keys, function( a, b )
		if isnumber(a) and isnumber(b) then return a < b end
		return tostring(a) < tostring(b)
	end)

	done[t] = true

	for i = 1, #keys do
		local key = keys[i]
		local value = t[key]

		if (istable(value) and not done[value]) then
			done[value] = true
			Msg(string.rep("\t", indent) .. key .. ":")
			saveTablePrintLines(value, indent + 2, done, lines)
			done[value] = nil
		elseif not istable(value) then
			Msg(string.rep("\t", indent) .. key .. "\t=\t" .. tostring(value) .. "")
		end
	end
end

local function linelen(line)
	local len = 0
	for i = 1, #line do
		local c = line:sub(i,i)
		if (c == "\t") then
			if (len % 8 == 0) then
				len = len + 8
			else
				len = len + (8 - len % 8)
			end
		else
			len = len + 1
		end
	end
	return len
end

local function printObject(obj, indent)
	indent = indent or 0

	local props = {}
	saveTablePrintLines(obj, nil, nil, props)

	local metadata = {}
	saveTablePrintLines(getmetatable(obj), nil, nil, metadata)

	local max = 0
	for i, line in ipairs(props) do
		props[i] = "# " .. line
		max = math.max(max, linelen(props[i]))
	end

	for i, line in ipairs(metadata) do
		metadata[i] = "# " .. line
		max = math.max(max, linelen(metadata[i]))
	end

	MsgN(string.rep("\t", indent) .. string.rep("#", max + 2))

	for _, line in ipairs(props) do
		MsgN(string.rep("\t", indent).. line .. string.rep(" ", max - linelen(line)) .. " #")
	end

	MsgN(string.rep("\t", indent) .. string.rep("#", max + 2))

	for _, line in ipairs(metadata) do
		MsgN(string.rep("\t", indent) .. line .. string.rep(" ", max - linelen(line)) .. " #")
	end

	MsgN(string.rep("\t", indent) .. string.rep("#", max + 2))
end

local function printTable(t, indent, done)
	local Msg = Msg

	done = done or {}
	indent = indent or 0
	local keys = table.GetKeys(t)

	table.sort(keys, function(a, b)
		if isnumber(a) and isnumber(b) then return a < b end
		return tostring(a) < tostring(b)
	end)

	done[t] = true

	for i = 1, #keys do
		local key = keys[i]
		local value = t[key]
		Msg(string.rep("\t", indent))

		if istable(value) and not done[value] and not value._uniqueid then
			done[value] = true
			Msg(key, ":\n")
			printTable(value, indent + 2, done)
			done[value] = nil
		elseif istable(value) and not done[value] and value._uniqueid then
			Msg(key, ":\n")
			printObject(value, indent + 2)
		end
	end
end

function WUMAPrintObject(obj)
	if istable(obj) and obj._uniqueid then
		printObject(obj)
	elseif istable(obj) then
		printTable(obj)
	end
end