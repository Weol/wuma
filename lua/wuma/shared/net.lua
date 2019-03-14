
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.NET = WUMA.NET or {}
WUMA.NET.INTSIZE = 5

if SERVER then

	WUMA.NET.MAX_SIZE = WUMA.CreateConVar("wuma_net_send_size", 32, FCVAR_ARCHIVE, "How much data is sent from the server simultaneously (in kb). Cannot be over 60kb.")
	cvars.AddChangeCallback(WUMA.NET.MAX_SIZE:GetName(), function(convar, old, new) 
		if (tonumber(new) > 60) then WUMA.NET.MAX_SIZE:SetInt(60) end
		if (tonumber(new) < 1) then WUMA.NET.MAX_SIZE:SetInt(1) end
	end)
	
	WUMA.NET.INTERVAL = WUMA.CreateConVar("wuma_net_send_interval", "0.2", FCVAR_ARCHIVE, "How fast data is sent from the server (Time in seconds between chunks).")

	util.AddNetworkString("WUMACompressedDataStream")
	local function doSendData(users, data, id, await, index) 
		if not data then return end
		if not istable(users) then users = {users} end

		for _, user in pairs(users) do
			net.Start("WUMACompressedDataStream")
				net.WriteUInt(string.len(data), 32)
				net.WriteString(id)
				net.WriteBool(await or false)
				net.WriteData(data, data:len())
				net.WriteInt(index or -1, 32)
			net.Send(user)
		end
	end
	
	WUMA.DataQueue = {}
	function WUMA.QueueData(user, data, id, await)
		if not (timer.Exists("WUMAPopDataQueue")) then
			timer.Create("WUMAPopDataQueue", WUMA.NET.INTERVAL:GetFloat(), 0, WUMA.PopDataQueue)
		end

		table.insert(WUMA.DataQueue, {user=user, data=data, id=id, await=await})
	end
	
	function WUMA.PopDataQueue()
		if (table.Count(WUMA.DataQueue) < 1) then
			timer.Remove("WUMAPopDataQueue")
		else
			local index = table.Count(WUMA.DataQueue)
			local tbl = table.remove(WUMA.DataQueue, 1)
			
			if tbl then
				doSendData(tbl.user, tbl.data, tbl.id, tbl.await, index)
			end
		end
	end
	
	function WUMA.SendCompressedData(user, data, id, compressed)	
	
		if not data then return end
	
		local max_size = WUMA.NET.MAX_SIZE:GetInt()
		local queuedata = WUMA.QueueData
		local compress = util.Compress
		local tojson = util.TableToJSON
	
		if not compressed then
			data = compress(tojson(data))
		end
		local data_len = string.len(data) 
		
		max_size = math.Clamp(max_size, 1, 60) --Clamp size to 60kb, leaving 2kb free for overhead.
		local mx = math.ceil(max_size*1000)

		if (data_len > mx) then 
			for i = 0, data_len, mx + 1 do
				if (i+mx > data_len) then
					queuedata(user, string.sub(data, i), id, false) 
				else
					queuedata(user, string.sub(data, i, i+mx), id, true) 
				end
			end
		else		
			doSendData(user, data, id) 
		end
	
	end
	
	util.AddNetworkString("WUMAAccessStream")
	function WUMA.RecieveCommand(lenght, user)
		WUMADebug("Command recieved!(SIZE: %s bits)", lenght)
	
		local len = net.ReadUInt(32)
		local data = net.ReadData(len)
	
		local tbl = util.JSONToTable(util.Decompress(data))
		local cmd = tbl[1]
		
		--WUMADebug(cmd)
		--PrintTable(tbl)
		
		local data = {user}
		table.Add(data, tbl[2])
		
		WUMA.ProcessAccess(cmd, data)
	end
	net.Receive("WUMAAccessStream", WUMA.RecieveCommand)
	
	util.AddNetworkString("WUMAInformationStream")
	function WUMA.SendInformation(user, stream, data)
		if (istable(user)) then 
			for _, v in pairs(user) do 
				WUMA.SendInformation(v, stream, data) 
			end 
			return
		end
		
		if not data then return end
		if not istable(data) then data = {data} end

		local name = stream:GetName()
		
		net.Start("WUMAInformationStream")
			net.WriteString(name)
			net.WriteTable(data)
		net.Send(user)	
	end
	
	util.AddNetworkString("WUMARequestStream")
	function WUMA.RecieveClientRequest(length, user)
		local name = net.ReadString()
		local data = net.ReadTable()
		
		WUMADebug("Request recieved! (NAME: %s) (SIZE: %s bits)", tostring(name), tostring(length))
		
		local stream = WUMA.GetStream(name)
		stream:IsAuthorized(user, function(allowed)
			if allowed then
				stream:Send(user, data)
			else
				WUMALog("An unauthorized user (%s) tried to request! (NAME: %s)", user:SteamID(), tostring(name))
			end
		end)
	end
	net.Receive("WUMARequestStream", WUMA.RecieveClientRequest)
		
else
	
	--RECIVE INFORMATION
	function WUMA.RecieveInformation(length, ply)
		local name = net.ReadString()
		local data = net.ReadTable()
		
		WUMADebug("Information recieved! (NAME: %s) (SIZE: %s bits)", tostring(name), tostring(length))
		
		WUMA.ProcessInformationUpdate(name, data)
	end
	net.Receive("WUMAInformationStream", WUMA.RecieveInformation)
	
	--RECIVE COMPRESSED DATA
	function WUMA.RecieveCompressedData(lenght)
		local len = net.ReadUInt(32)
		local id = net.ReadString()
		local await = net.ReadBool()
		local data = net.ReadData(len)
		local index = net.ReadInt(32)
		
		WUMADebug("%d: Compressed data recieved! (SIZE: %s bits)", index, tostring(lenght))

		WUMA.ProcessCompressedData(id, data, await, index)
	end
	net.Receive("WUMACompressedDataStream", WUMA.RecieveCompressedData)
	
	--SEND COMMAND
	function WUMA.SendCommand(cmd, data, quiet)
		local tbl = {cmd, data}
		local compressed_data = util.Compress(util.TableToJSON(tbl))
		
		net.Start("WUMAAccessStream")
			net.WriteUInt(compressed_data:len(), 32)
			net.WriteData(compressed_data, compressed_data:len())
			net.WriteBool(quiet or false)
		net.SendToServer()
	end
	
	--SEND REQUEST
	function WUMA.RequestFromServer(name, data)
		WUMADebug("Sending request! (NAME: %s)", tostring(name))

		if data and not istable(data) then data = {data} end
		net.Start("WUMARequestStream")
			net.WriteString(name)
			net.WriteTable(data or {})
		net.SendToServer()
	end
	
end
