

local log_level = CreateConVar("wuma_log_level", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "0=None, 1=Normal, 2=Debug", 0, 2)

local function safeFormat(msg, args)
	if not args then return string.format(msg, "NO_ARGS") end
	msg = tostring(msg)
	if (table.Count(args) == 1) then
		args[1] = tostring(args[1]) or "NO_DATA"
		msg = string.format(msg, args[1])
	else
		for k, v in pairs(args) do
			if not v then
				args[k] = "NO_DATA"
			else
				args[k] = tostring(args[k])
			end
		end
		msg = string.format(msg, unpack(args))
	end
	return msg
end

function WUMALog(msg, ...)
	if (log_level:GetInt() == 0) then return end
	local args = { ... }
	if args then
		msg = safeFormat(msg, args)
	end
	msg = "[WUMA] " .. msg
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg.."\n")
	end
end

function WUMADebug(msg, ...)
	if (log_level:GetInt() ~= 2 and SERVER) then return end
	if (istable(msg)) then
		PrintTable(msg)
		return false
	end
	local args = { ... }
	if args then
		msg = safeFormat(msg, args)
	end
	msg = "[WUMA] " .. msg
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg.."\n")
	end
	return false
end