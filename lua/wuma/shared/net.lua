
WUMA = WUMA or {}

WUMA.NET = {}
WUMA.NET.INTSIZE = 6

if SERVER then

	function WUMA.UpdateClients(update)
		local users = WUMA.GetUsers(WUMA.NET.ACCESS)
		for _,user in pairs(users) do 
			WUMA.SendDataUpdate(user,update)
		end
	end
	
	util.AddNetworkString("WUMADataStream")
	function WUMA.SendDataUpdate(user,tbl)
		net.Start("WUMADataStream")
			net.WriteTable(tbl)
		net.Send(user)	
	end
	
	util.AddNetworkString("WUMACommandStream")
	function WUMA.RecieveCommand(user)
		WUMADebug("Command recieved!(SIZE: %s bytes)",tostring(lenght))
	
		local cmd, tbl = WUMA.ExtractValue(net.ReadTable())
	end
	net.Receive("WUMACommandStream", WUMA.onRecieveTable)
	
	util.AddNetworkString("WUMAInformationStream")
	function WUMA.SendInformation(user,tbl,enum)
		net.Start("WUMAInformationStream")
			net.WriteInt(enum,WUMA.NET.INTSIZE)
			if tbl then net.WriteTable(tbl) end
		net.Send(user)	
	end
	
	util.AddNetworkString("WUMARequestStream")
	function WUMA.RecieveClientRequest(lenght,user)
		local enum = net.ReadInt(WUMA.NET.INTSIZE)
		local data = net.ReadTable()
		
		WUMADebug("Request recieved! (ENUM: %s) (SIZE: %s bytes)",tostring(enum),tostring(lenght))

		WUMA.NET.ENUMS[enum](user,data)
	end
	net.Receive("WUMARequestStream", WUMA.RecieveClientRequest)
		
else
	
	//RECIVE DATA
	function WUMA.RecieveDataUpdate(lenght)
		WUMA.ProcessDataUpdate(net.ReadTable())
		
		WUMADebug("Data recieved! (SIZE: %s bytes)",tostring(lenght))
	end
	net.Receive("WUMADataStream", WUMA.RecieveDataUpdate)
	
	//RECIVE INFORMATION
	function WUMA.RecieveInformation(lenght)
		WUMADebug("Information recieved! (ENUM: %s) (SIZE: %s bytes)",tostring(net.ReadInt(WUMA.NET.INTSIZE)),tostring(lenght))
	
		local enum = net.ReadInt(WUMA.NET.INTSIZE)
		local data = net.ReadTable()
		
		WUMA.NET.ENUMS[enum](data)
	end
	net.Receive("WUMAInformationStream", WUMA.RecieveInformation)
	
	//SEND COMMAND
	function WUMA.SendCommand(cmd,data)
		local tbl = {cmd, data}
		net.Start("WUMACommandStream")
			net.WriteTable(tbl)
		net.SendToServer()
	end
	
	//SEND REQUEST
	function WUMA.RequestFromServer(enum,data)
		net.Start("WUMARequestStream")
			net.WriteInt(enum,WUMA.NET.INTSIZE)
			net.WriteTable(data)
		net.SendToServer()
	end
	
end