
local EchoChanges
 
local function echoFunction(args, affected, caller)

	if not args then return end
	
	local msg = args[1]
	table.remove(args,1)

	msg = string.gsub(msg, "%%s", "#A", 1)
	msg = string.gsub(msg, "%%s", "#s")

	if EchoChanges then
		if (EchoChanges:GetInt() == 1) then
			--Access only
			ulx.fancyLogAdmin(caller, msg, unpack(args))
		elseif (EchoChanges:GetInt() == 2) then
			--To all
			ulx.fancyLogAdmin(caller, msg, unpack(args))
		elseif (EchoChanges:GetInt() == 3) then
			--To affected
			ulx.fancyLogAdmin(caller, msg, unpack(args))
		end
	end
end

hook.Add("PostWUMALoad","ULXOverideWUMALog",function()	
	EchoChanges = WUMA.EchoChanges

	for name, access in pairs(WUMA.AccessRegister) do
		access:SetLogFunction(echoFunction)
	end
end)