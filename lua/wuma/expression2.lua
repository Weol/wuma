
local E2Functions = {}
local E2Types = {}
local PrefixTable = {}

for name, tbl in pairs(wire_expression_types) do
    E2Types[tbl[1]] = name
    local head = PrefixTable

    local iterator = string.gmatch(tbl[1], ".")
    local c = iterator()
    while c do
        next = iterator()
        if next then
            head[c] = head[c] or {}
        else
            head[c] = tbl[1]
        end
        head = head[c]
        c = next
    end
end

for k, v in pairs(wire_expression2_funcs) do
    if not string.StartWith(k, "op:") then
        local parenthesis = string.find(k, "%(")

        local name = string.Left(k, parenthesis - 1)
        local inner = string.sub(k, parenthesis + 1, -2)
        local target

        local colon = string.find(k, ":")
        if (colon) then
            target = string.sub(k, parenthesis + 1, colon - 1)
            inner = string.sub(inner, string.len(target) + 2)
        end

        local args = {}
        local head = PrefixTable
        local type = ""
        for c in string.gmatch(inner, ".") do
            if (c == ".") then
                if (args[#args]) then
                    args[#args] = args[#args] .. c
                else
                    table.insert(args, ".")
                end
            else
                type = type .. c
                if (istable(head[c])) then
                    head = head[c]
                else
                    table.insert(args, type)
                    head = PrefixTable
                    type = ""
                end
            end
        end

        local signature
        if target then
            signature = target .. ":" .. name .. "(" .. string.Implode(", ", args) .. ")"
        else
            signature = name .. "(" .. string.Implode(", ", args) .. ")"
        end
        E2Functions[k] = signature
    end
end

--[[]
WUMA.RestrictionTypes.e2func = {
    print="E2 Function",
    print2="E2 Functions",
    search="Search..",
    items=function() return E2Functions end,
}
]]--

--PrintTable(E2Functions)

old_compiler = old_compiler or E2Lib.Compiler.GetFunction
E2Lib.Compiler.GetFunction = function(self, instr, Name, Args)
	WUMADebug("GetFunction(%s, %s, %s)", tostring(instr), tostring(Name), tostring(Args))
	local returned = old_compiler(self, instr, Name, Args)
	PrintTable(returned)
	return returned
end

old_asd = old_asd or E2Lib.Compiler.GetMethod
E2Lib.Compiler.GetMethod = function(self, instr, Name, Meta, Args)
	WUMADebug("GetMethod(%s, %s, %s, %s)", tostring(instr), tostring(Name), tostring(Meta), tostring(Args))
	local returned = old_asd(self, instr, Name, Meta, Args)
	PrintTable(returned)
	--self:Error("This function is restricted " .. tps_pretty({ Meta }) .. ":" .. Name .. "(" .. tps_pretty(Args) .. ")", instr)
	return returned
end
