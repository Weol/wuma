
if SERVER then
	---------------------------------------------------------------------------------------------
	-- REMOTE PROCEDURE CALLS - CLIENTS CAN ONLY CALL FUNCTIONS CONTAINED IN WUMA.RPC          --
	-- SERVER CAN CALL ANY CLIENT FUNCTION, AS LONG AS IT IS AVAILABLE IN THE GLOBAL NAMESPACE --
	---------------------------------------------------------------------------------------------
	util.AddNetworkString("WUMARPC")
	function WUMARPC(player, fn, ...)
		net.Start("WUMARPC")
			net.WriteString(fn)
			net.WriteTable({...})
			net.WriteInt(-1, 32)
		net.Send(player)
	end

	local function recieveRPC(_, player)
		local fname = net.ReadString()
		local args = net.ReadTable()
		local unique_id = net.ReadInt(32)

		local fn

		local components = string.Explode(".", fname, false)
		local tbl = WUMA.RPC
		for _, component in pairs(components) do
			fn = tbl and istable(tbl) and tbl[component]
		end

		if fn and isfunction(fn) then
			local response = {fn(player, unpack(args))}
			if (unique_id >= 0) then
				net.Start("WUMARPC")
					net.WriteString(fn)
					net.WriteTable(response)
					net.WriteInt(unique_id)
				net.Send(player)
			end
		else
			WUMADebug(string.format("RPC Failed! Could not find function (%s)", fname))
		end
	end
	net.Receive("WUMARPC", recieveRPC)
else
	---------------------------------------------------------------------------------------------
	-- REMOTE PROCEDURE CALLS - CLIENTS CAN ONLY CALL FUNCTIONS CONTAINED IN WUMA.RPC          --
	-- SERVER CAN CALL ANY CLIENT FUNCTION, AS LONG AS IT IS AVAILABLE IN THE GLOBAL NAMESPACE --
	---------------------------------------------------------------------------------------------
	local unique_ids = 0
	local pending_callbacks = {}
	function WUMARPC(fn, args, callback)
		unique_ids = unique_ids + 1

		if callback then
			pending_callbacks[unique_ids] = callback
		end

		net.Start("WUMARPC")
			net.WriteString(fn)
			net.WriteTable(args)
			net.WriteInt(callback and unique_ids or -1, 32)
		net.SendToServer()
	end

	local function recieveRPC()
		local fname = net.ReadString()
		local args = net.ReadTable()
		local unique_id = net.ReadInt(32)

		if (unique_id >= 0) then --Means this is a response to a client RPC
			if pending_callbacks[unique_id] then
				pending_callbacks[unique_id](args)
			end
		else
			local fn

			local components = string.Explode(".", fname, false)
			local tbl = _G
			for _, component in pairs(components) do
				fn = tbl and istable(tbl) and tbl[component]
			end

			if fn then
				fn(unpack(args))
			else
				WUMADebug("RPC Failed! Could not find function (%s)", fname)
			end
		end
	end
	net.Receive("WUMARPC", recieveRPC)

end
