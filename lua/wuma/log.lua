
WUMA = WUMA or {}
WUMA.Log = {}

local log_level = WUMA.CreateConVar("wuma_log_level", "1", FCVAR_ARCHIVE, "0=None, 1=Normal, 2=Debug")

function WUMA.Log.ServerLog(msg, ...)
	if (log_level:GetInt() == 0) then return end
	local args = { ... }
	if args then
		msg = WUMA.SafeFormat(msg, args)
	end
	msg = "[WUMA] " .. msg 
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg.."\n")
	end
end
WUMALog = WUMA.Log.ServerLog --To save my fingers

function WUMA.Log.ChatPrint(msg, ...)
	local args = { ... }
	if args then
		msg = WUMA.SafeFormat(msg, args)
	end
	for k, v in pairs(player.GetAll()) do
		v:ChatPrint(msg)
	end
end
WUMAChatPrint = WUMA.Log.ChatPrint --To save my fingers

function WUMA.Log.DebugLog(msg, ...)
	if (log_level:GetInt() ~= 2 and SERVER) then return end
	if (istable(msg)) then 
		PrintTable(msg) 
		return false
	end
	local args = { ... }
	if args then
		msg = WUMA.SafeFormat(msg, args)
	end
	msg = "[WUMA] " .. msg 
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg.."\n")
	end
	return false
end
WUMADebug = WUMA.Log.DebugLog

function WUMA.Log.Error(msg)
	Msg("WUMA ERROR!\n")
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg.."\n")
	end
	debug.Trace()
end
WUMAError = WUMA.Log.Error --To save my fingers

function WUMA.SafeFormat(msg, args)
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