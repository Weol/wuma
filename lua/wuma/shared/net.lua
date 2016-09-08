
WUMA = WUMA or {}

WUMA.NET = WUMA.NET or {}
WUMA.NET.INTSIZE = 5

if SERVER then

	util.AddNetworkString("WUMACompressedDataStream")
	function WUMA.SendCompressedData(user,data,id)	
		if not data then return end
	
		net.Start("WUMACompressedDataStream")
			net.WriteUInt(data:len(),32)
			net.WriteString(id)
			net.WriteBool(await or false)
			net.WriteData(data,data:len())
		net.Send(user)
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
		
		WUMADebug("Information recieved! (ENUM: %s) (SIZE: %s kb)",tostring(enum),tostring(lenght/1024))
		
		WUMA.ProcessInformationUpdate(enum,data)
	end
	net.Receive("WUMAInformationStream", WUMA.RecieveInformation)
	
	//RECIVE COMPRESSED DATA
	function WUMA.RecieveCompressedData(lenght)
		local len = net.ReadUInt(32)
		local id = net.ReadString()
		local await = net.ReadBool()
		local data = net.ReadData(len)
		
		WUMADebug("Compressed data recieved! (SIZE: %s bytes)",tostring(lenght))
		
		WUMA.ProcessCompressedData(id,data)
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
