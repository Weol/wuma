
if SERVER then
	---------------------------------------------------------------------------------------------
	-- REMOTE PROCEDURE CALLS - CLIENTS CAN ONLY CALL FUNCTIONS CONTAINED IN WUMA.RPC          --
	-- SERVER CAN CALL ANY CLIENT FUNCTION, AS LONG AS IT IS AVAILABLE IN THE GLOBAL NAMESPACE --
	---------------------------------------------------------------------------------------------
	util.AddNetworkString("WUMARPC")
	function WUMARPC(player, fn, ...)
		player = istable(player) and player or {player}

		local recipeients = {}
		for k, v in pairs(player) do
			table.insert(recipeients, v) --For some reason net.Send does not work with key-value pairs
		end

		net.Start("WUMARPC")
			net.WriteString(fn)
			net.WriteTable({...})
		net.Send(recipeients)
	end
else
	---------------------------------------------------------------------------------------------
	-- REMOTE PROCEDURE CALLS        														   --
	-- SERVER CAN CALL ANY CLIENT FUNCTION, AS LONG AS IT IS AVAILABLE IN THE GLOBAL NAMESPACE --
	---------------------------------------------------------------------------------------------
	local function recieveRPC()
		local fname = net.ReadString()
		local args = net.ReadTable()

		local fn

		local components = string.Explode(".", fname, false)
		local tbl = _G
		for _, component in pairs(components) do
			fn = tbl and istable(tbl) and tbl[component]
			tbl = fn
		end

		if fn then
			WUMADebug("Calling \"%s\" with arguments: ", fname)
			for k, v in pairs(args) do
				WUMADebug("   %s", tostring(v))
			end
			fn(unpack(args))
		else
			WUMADebug("RPC Failed! Could not find function (%s)", fname)
		end
	end
	net.Receive("WUMARPC", recieveRPC)

end
