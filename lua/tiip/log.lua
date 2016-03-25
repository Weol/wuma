
TIIP = TIIP or {}
TIIP.Log = {}

function TIIP.Log.ServerLog(msg,...)
	local args = { ... }
	if args then
		msg = TIIP.SafeFormat(msg,args)
	end
	TIIP.Files.Append("log.txt",msg)
	msg = "[TIIP] " .. msg 
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg)
	end
end
TIIPLog = TIIP.Log.ServerLog --To save my fingers

function TIIP.Log.ChatPrint(msg,...)
	local args = { ... }
	if args then
		msg = TIIP.SafeFormat(msg,args)
	end
	for k,v in pairs(TIIP.ALL()) do
		v:ChatPrint(msg)
	end
end
TIIPChatPrint = TIIP.Log.ChatPrint --To save my fingers

function TIIP.Log.DebugLog(msg,...)
	local args = { ... }
	if args then
		msg = TIIP.SafeFormat(msg,args)
	end
	if TIIP.Debug then
		TIIP.Files.Append("log.txt",msg)
		if game.IsDedicated() then
			Msg(msg.."\n")
		else
			ServerLog(msg)
		end
	end
end
TIIPDebug = TIIP.Log.DebugLog

function TIIP.Log.Error(msg)
	TIIPLog("TIIP ERROR!\n")
	if game.IsDedicated() then
		Msg(msg.."\n")
	else
		ServerLog(msg)
	end
	debug.Trace()
end
TIIPError = TIIP.Log.Error --To save my fingers

function TIIP.Log.Alert(ply,msg,...)
	local args = { ... }
	if args then
		msg = TIIP.SafeFormat(msg,args)
	end
	ULib.tsayError( ply, msg, true )
end	
TIIPAlert = TIIP.Log.Alert --To save my fingers

function TIIP.ExtractValue(args)
	local value = args[1]
	table.remove(args,1)
	return value,args
end

function TIIP.SafeFormat(msg,args)
	if not args then return string.format(msg,"NO_ARGS") end
	if (table.Count(args) == 1) then
		args[1] = args[1] or "NO_DATA"
		msg = string.format(msg,args[1])
	else
		for k,v in pairs(args) do
			if  not v then
				args[k] = "NO_DATA"
			end
		end
		msg = string.format(msg,unpack(args))
	end
	return msg
end