
WUMA = WUMA or {}

WUMA.NET = WUMA.NET or {}
WUMA.NET.INTSIZE = 5
WUMA.NET.MAX_SIZE = 10
WUMA.NET.INTERVAL = 0.5

if SERVER then

	util.AddNetworkString("WUMACompressedDataStream")
	local function doSendData(user,data,id,await) 
		if not data then return WUMADebug("No data :(") end

		net.Start("WUMACompressedDataStream")
			net.WriteUInt(data:len(),32)
			net.WriteString(id)
			net.WriteBool(await or false)
			net.WriteData(data,data:len())
		net.Send(user)
	end
	
	WUMA.DataQueue = {}
	function WUMA.QueueData(user,data,id,await)
		if not (timer.Exists("WUMAPopDataQueue")) then
			timer.Create("WUMAPopDataQueue", WUMA.NET.INTERVAL, 0, WUMA.PopDataQueue)
		end

		table.insert(WUMA.DataQueue,{user=user,data=data,id=id,await=await})
	end
	
	function WUMA.PopDataQueue()
		if (table.Count(WUMA.DataQueue) < 1) then
			timer.Remove("WUMAPopDataQueue")
		else
			local tbl = table.remove(WUMA.DataQueue,1)
			
			if tbl then
				doSendData(tbl.user,tbl.data,tbl.id,tbl.await)
			end
		end
	end
	
	function WUMA.SendCompressedData(user,data,id)	

		if not data then return end
	
		local keys = table.GetKeys(data)
		local max_size = WUMA.NET.MAX_SIZE
		local queuedata = WUMA.QueueData
		local compress = util.Compress
		local tojson = util.TableToJSON
	
		if (table.Count(data) > WUMA.NET.MAX_SIZE) then 
			for i = 0, table.Count(data),WUMA.NET.MAX_SIZE do
				if (i+max_size > table.Count(data)) then
					local segment = {}
					for k=i,max_size+i do
						if keys[k] then
							segment[keys[k]] = data[keys[k]] 
						end
					end
					
					queuedata(user,compress(tojson(segment)),id,false) 
				else
					local segment = {}
					for k=i,max_size+i do
						if keys[k] then
							segment[keys[k]] = data[keys[k]] 
						end
					end

					queuedata(user,compress(tojson(segment)),id,true) 
				end
			end
		else
			data = util.Compress(tojson(data))
		
			doSendData(user,data,id) 
		end
	end
	
	util.AddNetworkString("WUMAAccessStream")
	function WUMA.RecieveCommand(lenght,user)
		WUMADebug("Command recieved!(SIZE: %s kb)",tostring(lenght/1024))
	
		local tbl = net.ReadTable()
		local cmd = tbl[1]

		local data = {user}
		table.Add(data,tbl[2])

		WUMA.ProcessAccess(cmd,data)
	end
	net.Receive("WUMAAccessStream", WUMA.RecieveCommand)
	
	util.AddNetworkString("WUMAInformationStream")
	function WUMA.SendInformation(user,enum,data)
		if not enum then 
			WUMADebug("NET STREAM enum not found! (%s)",tostring(enum))
			return			
		end

		if not data then return end
		
		net.Start("WUMAInformationStream")
			net.WriteInt(enum:GetID(),WUMA.NET.INTSIZE)
			net.WriteTable(data)
		net.Send(user)	
	end
	
	util.AddNetworkString("WUMARequestStream")
	function WUMA.RecieveClientRequest(lenght,user)
		local enum = net.ReadInt(WUMA.NET.INTSIZE)
		local data = net.ReadTable()
		
		WUMADebug("Request recieved! (ENUM: %s) (SIZE: %s kb)",tostring(enum),tostring(lenght))
		
		if WUMA.NET.ENUMS[enum]:IsAuthorized(user) then
			WUMA.NET.ENUMS[enum]:Send(user,data)
		else
			WUMALog("An unauthorized user(%s) tried to request! (ENUM: %s)",user:SteamID(),tostring(enum))
		end

	end
	net.Receive("WUMARequestStream", WUMA.RecieveClientRequest)
		
else
	
	//RECIVE INFORMATION
	function WUMA.RecieveInformation(lenght,pl)
		local enum = net.ReadInt(WUMA.NET.INTSIZE)
		local data = net.ReadTable()
		
		WUMADebug("Information recieved! (ENUM: %s) (SIZE: %s bytes)",tostring(enum),tostring(lenght))
		
		WUMA.ProcessInformationUpdate(enum,data)
	end
	net.Receive("WUMAInformationStream", WUMA.RecieveInformation)
	
	total = 0
	
	//RECIVE COMPRESSED DATA
	function WUMA.RecieveCompressedData(lenght)
		local len = net.ReadUInt(32)
		local id = net.ReadString()
		local await = net.ReadBool()
		local data = net.ReadData(len)
		
		WUMADebug("Compressed data recieved! (SIZE: %s bytes)",tostring(lenght))

		total = total + lenght
		
		local tbl = util.JSONToTable(util.Decompress(data))
			
		WUMA.ProcessDataUpdate(id,tbl)
	end
	net.Receive("WUMACompressedDataStream", WUMA.RecieveCompressedData)
	
	//SEND COMMAND
	function WUMA.SendCommand(cmd,data,quiet)
		local tbl = {cmd, data}
		net.Start("WUMAAccessStream")
			net.WriteTable(tbl)
			net.WriteBool(quiet or false)
		net.SendToServer()
	end
	
	//SEND REQUEST
	function WUMA.RequestFromServer(enum,data)
		WUMADebug("Sending request! (ENUM: %s)",tostring(enum))
	
		if not istable(data) then data = {data} end
		net.Start("WUMARequestStream")
			net.WriteInt(enum,WUMA.NET.INTSIZE)
			net.WriteTable(data or {})
		net.SendToServer()
	end
	
end
