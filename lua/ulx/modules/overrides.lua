
local function echoFunction(args, affected, caller)

	if not args then return end

	if WUMA.EchoChanges then
		if WUMA.EchoToChat:GetBool() then
			local msg = args[1]
			table.remove(args, 1)
		
			msg = string.gsub(msg, "%%s", "#A", 1)
			msg = string.gsub(msg, "%%s", "#s")

			if (WUMA.EchoChanges:GetInt() == 1) then
				WUMA.GetAuthorizedUsers(function(users) 
					ulx.fancyLogAdmin(caller, users, msg, unpack(args))
				end)
			elseif (WUMA.EchoChanges:GetInt() == 2) then
				ulx.fancyLogAdmin(caller, player.GetAll(), msg, unpack(args))
			elseif (WUMA.EchoChanges:GetInt() == 3) then
				if affected and istable(affected) then 
					ulx.fancyLogAdmin(caller, table.ClearKeys(affected), msg, unpack(args))
				end
			end
		else
			local msg = args[1]
			table.remove(args, 1)
			
			local str = string.format(msg, caller:Nick(), unpack(args))

			if (WUMA.EchoChanges:GetInt() == 1) then
				WUMA.GetAuthorizedUsers(function(users) 
					for _, user in pairs(users) do
						user:PrintMessage(HUD_PRINTCONSOLE, str)
					end
				end)
			elseif (WUMA.EchoChanges:GetInt() == 2) then
				for _, user in pairs(player.GetAll()) do
					user:PrintMessage(HUD_PRINTCONSOLE, str)
				end 
			elseif (WUMA.EchoChanges:GetInt() == 3) then
				if affected and istable(affected) then 
					for _, user in pairs(affected) do
						user:PrintMessage(HUD_PRINTCONSOLE, str)
					end
				end
			end
		
			WUMALog(str)
		end
	end
end

hook.Add("OnWUMALoaded", "ULXOverideWUMALog", function()	
	for name, access in pairs(WUMA.AccessRegister) do
		access:SetLogFunction(echoFunction)
	end
end)